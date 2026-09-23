# Podman Rewrite — Instructions

Complete rewrite of the container stack: Docker → Podman, targeting **macOS and NixOS**.

The current implementation grew a lot of defensive boilerplate while I was learning Nix.
The rewrite exists to remove that boilerplate, not to reproduce it with a different runtime.

---

## 1. Goal

- Replace Docker / Docker Desktop with Podman on both platforms.
- Move **all** container configuration into knobs, and **all** logic into options modules.
- Eliminate, or reduce to a single shared implementation, every activation script and
  `writeShellScriptBin` runner that currently exists per service.
- Keep the rewrite declarative: a machine change (network, hardware, paths, certificates)
  must be a knob edit, never a walk through per-service boilerplate.

---

## 2. Hard constraint: file layout

**Nothing new may be added to `darwin/`, `nixos/`, or any folder other than the two below.**

| Path | Contents |
| --- | --- |
| `shared/services/podman-services.nix` | Knobs only. Values. No logic, no conditionals, no functions. |
| `options/services/podman/<name>.nix` | One file per package or container (`vaultwarden.nix`, `nginx.nix`, `archivebox.nix`, …): its option declarations and anything genuinely specific to it. |
| `options/services/podman/helper.nix` | Everything shared: unit generation, platform resolution, the recreate marker, readiness checks. Any logic two `<name>.nix` files would both contain lives here instead. |

### The old stack is left alone

The existing `darwin/services/docker/` tree is **not edited, not ported and not deleted**.
The Podman stack is written from scratch in the two paths above, and the containers are
created fresh — only the **data** is kept.

The old tree is deactivated, not modified: drop its entry from the `imports` list so the
files stay byte-identical on disk and reactivation is a one-line revert. Prefer that over
commenting out module bodies, which leaves thousands of dead lines in the tree.

Read the old modules freely as a reference for behaviour that must be preserved. Do not
carry their structure across — reproducing the old boilerplate in a new folder defeats the
point of the rewrite.

**The two stacks must never be active at once.** They would collide on host ports,
container names and data directories. Exactly one is in the `imports` list at any time.

### No 1:1 rewrites

The new stack is designed for Podman and for the logic/knobs split — it is not the old
code moved to a new path. Concretely:

- Keep one file per package or container in `options/services/podman/` — `vaultwarden.nix`,
  `nginx.nix`, `archivebox.nix`, and so on. What must not repeat is the *logic*: anything
  two of those files would both contain belongs in `helper.nix` instead, written once.
- Do not carry over anything that existed only to work around Docker Desktop — the daemon
  wait loops, the per-service `ensureDir` scripts, the activation hooks.
- Do not preserve the old file boundaries. Vaultwarden currently spans five files
  (`vaultwarden.nix`, `vaultwarden-service.nix`, `vaultwarden-nginx.nix`,
  `vaultwarden-mkcert.nix`, `vaultwarden-android-cert.nix`) to describe one service;
  the rewrite should not.

This applies to **nginx and mkcert as much as to the containers.** They are in scope:
nginx terminates TLS for Vaultwarden and mkcert issues the certificate, so neither can
stay behind in `darwin/`. Their logic moves to `options/` and their settings become knobs
(§7), rewritten to fit the new architecture rather than transplanted. `nginx.nix` in
particular is 411 lines of generated config text and launchd wiring; most of it should
become options with defaults, not string templates copied across.

The one behaviour worth preserving deliberately is the stable-path indirection that keeps
generated content out of the plist (§8.2) — preserve the *property*, not the code.

---

## 3. Knob shape

**All** knobs live in the single file `shared/services/podman-services.nix`, regardless
of which tree they belong to. One file, several roots:

```nix
system.shared.services.podman.containers.vaultwarden = { ... };
system.shared.services.podman.containers.karakeep   = { ... };
system.shared.packages.mkcert                        = { ... };
system.shared.services.nginx                         = { ... };
```

Containers sit under `services.podman.containers.<name>`. Things that are not containers
keep their own root — mkcert is a package, nginx is a host service — and are **not**
forced under the `podman` tree just because they are configured alongside it.

Example — Vaultwarden:

```nix
system.shared.services.podman.containers.vaultwarden = {
  enable = true;
  containerName = "vaultwarden";
  RunAtLoad = true;

  image = "vaultwarden/server:1.37.3";

  hostPort = { mac = 8080; linux = 8088; };
  internalPort = 80;

  dataDir = { mac = "${paths.mac.podman.data}/vaultwarden";
              linux = "${paths.linux.podman.data}/vaultwarden"; };

  domain = { mac = "https://192.168.2.125"; linux = "https://vaultwarden.lan"; };
  ip.address = { mac = "192.168.2.125"; linux = "192.168.2.130"; };

  environment = {
    PASSWORD_HINTS = "true";
    PASSWORD_ITERATIONS = "100000";
  };

  logDir      = "${paths.mac.system.tmp}/com.ven.vaultwarden.out.log";
  errorLogDir = "${paths.mac.system.tmp}/com.ven.vaultwarden.err.log";
};
```

Every key above must be **declared as an option with a sensible default** in
`options/services/podman/`. The knob file then only carries what actually differs
from the default for this setup — it never has to restate the obvious.

`containerName`, `logDir`, `errorLogDir` and `dataDir` all have defaults derivable
from the attribute name plus `paths`. They remain overridable knobs, but writing
them out is optional.

---

## 4. Platform-dependent values

Any knob whose value differs per platform is written as an attrset:

```nix
hostPort = { mac = 8080; linux = 8088; };
```

A bare scalar means "identical on both platforms":

```nix
internalPort = 80;
```

Rules:

- The option type accepts **either** form: `either <base> (submodule { mac; linux; })`.
- Resolution of `{ mac, linux }` → a single value happens in **`options/platforms.nix`**.
  No other module performs platform detection, and no knob file contains an `if`.
- The knob declares the values; the logic layer decides which one applies.

### 4.3 Data paths are always written out per platform

Any path pointing at **real data** is written in the explicit `{ mac, linux }` form in the
knob file, even where `paths.nix` could resolve the prefix by itself:

```nix
# where the Vaultwarden password database lives
dataDir = { mac   = "${paths.mac.podman.data}/vaultwarden";
            linux = "${paths.linux.podman.data}/vaultwarden"; };

# where Karakeep stores saved content
dataDir = { mac   = "${paths.mac.podman.data}/karakeep";
            linux = "${paths.linux.podman.data}/karakeep"; };
```

The same applies to certificate and CA directories (§7), backup sources and destinations,
and any other location holding data that must survive.

The reason is legibility, not necessity: for a path that holds a password vault or a
personal archive, both destinations should be readable at a glance in the knob file,
rather than inferred from a selector in another module. `paths.nix` still supplies the
prefixes — the knob composes on top of them — but the per-platform choice stays visible.

Paths that hold no data (log locations, runtime directories, store-backed config) may
use the resolved form.

`paths.nix` is the home for every path, on **all platforms** — it defines
`darwinHome` / `linuxHome`, parallel home and backup trees, and a `forPlatform`
selector. It is not macOS-only.

Rules for paths in this rewrite:

- New Podman paths are **added to `paths.nix`**, in the section they belong to, defined
  for both platforms — not invented inline in a module and not hardcoded in a knob.
- Read existing entries wherever they already cover the case; only add what is missing.
- Where the value depends on which platform is running, resolution comes from
  `platforms.nix`, the same as any other path.
- The knobs then reference the `paths` tree rather than repeating literals — in the
  explicit per-platform form for data paths (§4.3), in the resolved form otherwise:

```nix
# data path — both platforms spelled out
dataDir = { mac   = "${paths.mac.podman.data}/vaultwarden";
            linux = "${paths.linux.podman.data}/vaultwarden"; };

# non-data path — resolved form is fine
runtimeDir = "${paths.podman.runtime}";
```

Do not mirror the old `paths.darwin.docker.*` subtree into a Podman-shaped copy. It is
darwin-only because containers have so far run only on the Mac; the new entries are
defined for both platforms from the start.

---

## 5. Option declaration rules

These correct mistakes in the current implementation. They are requirements, not style
preferences.

**5.1 — Defaults belong in `mkOption`, never in an `or` fallback.**

```nix
# WRONG — dead code. Once the option is declared, the attribute always exists,
# so `or 8080` can never fire.
hostPort = config.ven.vaultwarden.hostPort or 8080;

# RIGHT
hostPort = lib.mkOption {
  type = lib.types.port;
  default = 8080;
  description = "Host port published for the container.";
};
```

Every `X or Y` of this shape in the current codebase is unreachable and must not be
carried over.

**5.2 — The default in `options/` is the fallback; the knob overrides it.**

This is the intended behaviour — "logic holds defaults, knobs override them" — and the
option system already provides it. It does not need to be encoded as a list.

```nix
# options/services/podman/containers.nix — the fallback lives here
image = lib.mkOption {
  type = lib.types.str;
  default = "vaultwarden/server:1.37.3";
  description = "Pinned container image.";
};
```

```nix
# shared/services/podman-services.nix — omit the knob to accept the default…
system.shared.services.podman.containers.vaultwarden = {
  enable = true;
};

# …or set it to override, on this machine only
system.shared.services.podman.containers.vaultwarden = {
  enable = true;
  image = "vaultwarden/server:1.38.0";
};
```

So the knob file stays minimal: it carries only what differs from the default. Writing
the value in two places is never required.

```nix
# WRONG — not a fallback, just a list of two unrelated values. Nix reads
# "config.ven.vaultwarden.image" as a literal string, not as a reference.
image = [ "config.ven.vaultwarden.image" "vaultwarden/server:1.37.3" ];
```

What is **not** possible is the conditional part — "use the knob if it works, otherwise
the default." Nix cannot test whether a value works; see 5.3.

**5.3 — Nix cannot probe the running system.**

Evaluation happens at build time, possibly on another machine. A knob can never mean
"use 8080, but detect the real port if that fails." Runtime discovery requires runtime
code, which is precisely the boilerplate being removed. Declare the value; override it
per machine when it genuinely differs.

**5.4 — Use precise types.**

`lib.types.port` (an int, range-checked) rather than a string. Strings defer errors to
runtime; the point of the option system is to catch them at build time.

---

## 6. Ports

- **`internalPort` is a property of the image, not a free choice.** It is the port the
  application listens on inside the container — Vaultwarden's image sets `ROCKET_PORT=80`.
  Changing it means changing the application's own configuration. It is therefore the
  same value on macOS and NixOS.
- **`hostPort` is freely chosen**, within these bounds:
  - Must be free on the host.
  - **Must be ≥ 1024.** Rootless Podman cannot bind privileged ports without lowering
    `net.ipv4.ip_unprivileged_port_start`, and rootless is a primary reason for this move.
  - **On macOS, avoid 5000 and 7000** — AirPlay Receiver binds both, and the resulting
    failure is hard to trace because it is a system service, not a visible app.
- nginx proxies to `127.0.0.1:<hostPort>`; `internalPort` never appears in a vhost.

---

## 7. Required knob coverage

The Vaultwarden example above is not the full set. Every setting that changes with
network, hardware, machine, paths or certificates must be a knob. At minimum:

### Per container

- `enable`, `containerName`, `RunAtLoad`
- `image` (pinned tag — never `latest`, see §9)
- `hostPort`, `internalPort`, extra published ports
- `dataDir` and any additional bind mounts
- `environment` (attrset), and secret-bearing env via sops
- `domain`, `ip.address`
- `logDir`, `errorLogDir`
- restart policy, healthcheck, network membership
- labels (see §9 on the recreate marker)
- dependencies on other containers

### Certificates (mkcert)

Knobs must state where certificates are generated, stored and installed:

```nix
system.shared.packages.mkcert = {
  caRoot  = { mac   = "${paths.mac.home.config}/mkcert";
              linux = "${paths.linux.home.config}/mkcert"; };
  certDir = { mac   = "${paths.mac.home.ssl}/vaultwarden";
              linux = "${paths.linux.home.ssl}/vaultwarden"; };

  certName = "vaultwarden.local.pem";
  keyName  = "vaultwarden.local-key.pem";

  sans = [ "vaultwarden.local" "192.168.2.125" ];

  installTargets = [ "system" "firefox" ];
};
```

These are written in the explicit `{ mac, linux }` form on purpose, even though
`paths.nix` could resolve the prefix on its own — see §4.3.

### nginx

nginx is a host service, not a container, and keeps its own root:

```nix
system.shared.services.nginx = {
  enable = true;

  virtualHosts.vaultwarden = {
    serverNames = [ "vaultwarden.local" "192.168.2.125" ];
    proxyPort   = 8080;          # the container's hostPort
    certDir     = { mac   = "${paths.mac.home.ssl}/vaultwarden";
                    linux = "${paths.linux.home.ssl}/vaultwarden"; };
    websockets  = true;
  };
};
```

Note what is *not* here: no config-file text, no `proxy_set_header` lines, no launchd
wiring. Those are implementation and belong in `options/services/podman/nginx.nix` as
defaults. A vhost knob should state the handful of facts that vary — names, port,
certificate, whether websockets are needed — and nothing else.

Notes carried from experience:

- Keys must stay **outside** the Nix store — the store is world-readable.
- `sans` must include every name and IP a client will actually connect to. A client
  reaching the server by IP sends no SNI, so the IP must be in the SAN list.
- Firefox uses its own trust store and needs the CA imported separately from the OS.
- On iOS, installing the CA profile is not sufficient; it must additionally be enabled
  under Settings → General → About → Certificate Trust Settings. Worth documenting in
  the module description, since it is invisible from the server side.

### Backups

- source directory, destination directory, archive prefix, schedule, encryption.
- Any container data held in **anonymous volumes** is invisible to the current backup
  framework — see §10.

---

## 8. Runtime behaviour requirements

These encode problems hit with the Docker implementation. The rewrite must not
reintroduce them, and must solve them **once in the shared logic**, not per service.

**8.1 — The runtime starts late.**

Docker Desktop is a GUI app whose daemon appears long after login, which is why every
current runner carries its own 60 × 2s wait loop. Podman's machine is headless and
CLI-controlled.

Requirement: **one** unit owns "is the Podman machine up." Per-container units do not
each re-implement a readiness wait. On macOS launchd has no dependency ordering, so a
readiness check must still exist somewhere — but exactly once, in `helper.nix`.

On NixOS this is free: systemd has real ordering, so generated units declare it.

**8.2 — Stale launchd units must not recur.**

Rules:

- **nix-darwin owns every unit.** Never hand-write a plist into `/Library/LaunchDaemons`
  or `/Library/LaunchAgents`; units created by hand are invisible to nix-darwin's cleanup
  and are what previously required manual `bootout`.
- **One label, one domain.** A label is either an agent (`gui/<uid>`) or a daemon
  (`system`), never both. Containers are agents. Only nginx is a daemon, because it binds
  443. Mixing the two is why `launchctl bootout system/com.ven.vaultwarden` silently did
  nothing — the job was an agent and lived in a different domain.
- **Keep generated content out of the plist.** Point the unit at a stable path
  (`/etc/ven/services/run-<name>`) so the plist is byte-identical across rebuilds. launchd
  then never unloads mid-activation and never drops a bound port. This is the one piece of
  the current design worth carrying over verbatim.

**8.3 — Backends per platform.**

| Platform | Mechanism |
| --- | --- |
| macOS | `launchd.agents.<name>`, generated by the options module |
| NixOS | systemd units / Quadlet, in the style of `virtualisation.oci-containers` |

Both are generated from the **same knobs**. The knob file is platform-agnostic; only
`options/services/podman/` knows which backend is being emitted.

**Current scope: build for both, deploy only on macOS.** Nothing is installed on the
NixOS machines yet. The modules must be written so that enabling a container there is a
knob change and nothing more — the NixOS backend is implemented and kept correct, but no
service is stood up on NixOS as part of this work. Do not defer the Linux side "until
later": paths, option types and backend selection are designed for both platforms from
the start, because retrofitting them afterwards is what produced the boilerplate in the
old stack.

---

## 9. Lessons that must be encoded

From the Docker implementation, confirmed in practice:

- **Never `:latest`.** The old runner pulled only when the image was *absent*, so `latest`
  froze at whatever was first pulled — the server sat at a release four months stale while
  appearing to track upstream. Pin an explicit tag as a knob.
- **A container's image and environment are immutable after creation.** `docker/podman run`
  applies them once; subsequent starts ignore config changes. Three declared environment
  variables never reached the running Vaultwarden container for this reason.
  Requirement: hash the resolved spec (image, ports, env, mounts) into a container **label**,
  compare on each run, and recreate when it differs. Implement once in `helper.nix`.
- **A rebuild does not re-run a launchd agent.** `darwin-rebuild switch` swaps the runner
  on disk, but with `KeepAlive.SuccessfulExit = false` the agent stays stopped. Either the
  module triggers the run, or the instruction to run it is surfaced to the user explicitly.
- **`DOMAIN` must match the URL clients actually use.** With it unset, Vaultwarden
  advertises `http://localhost` from `/api/config`, which breaks clients that honour the
  server-provided environment URLs. Changing it invalidates all existing sessions (JWT
  issuer mismatch), so every device must log in again — expected, worth stating in the
  option description.

---

## 10. Migration risks

- **ArchiveBox uses two anonymous volumes** (`/out`, `/data/personas`) that live inside the
  Docker VM and will **not** survive the move to Podman. They are also outside the current
  backup framework. Convert them to bind mounts under the container data root **before**
  migrating, and verify, since this is the only data-loss risk in the stack.
- Vaultwarden, Karakeep, Wallabag and Meilisearch use bind mounts to
  `~/.config/containers/...`, so their data is on the host and survives untouched.
- **Karakeep, Wallabag and ArchiveBox are compose-based.** `podman compose` delegates to
  `docker-compose` or `podman-compose` and does not behave identically — inter-service
  networking and healthcheck semantics are where the work is. Budget for this; it is not a
  flag change.
- All images are re-pulled on first run under Podman. Expected, no action needed.
- Docker Desktop stays installed and the old module tree stays on disk until the new stack
  is verified. Rollback is swapping which tree is in `imports` and rebuilding — the old
  containers are recreated from the same on-disk data.
- **ArchiveBox's anonymous volumes are the exception to that rollback.** Converting them to
  bind mounts changes the old stack's own data layout, so do it deliberately and verify
  under Docker first.

Suggested order: ArchiveBox volumes → full backup pass → Podman module + one simple
service → remaining services → **Vaultwarden last**, since it is the one in daily use.

---

## 11. Open decisions

- **File name.** This document — `docs/instructions/vaultwarden-new.md` — now covers the
  whole container stack rather than Vaultwarden alone. Renaming it to `podman-rewrite.md`
  is optional and affects nothing else.
