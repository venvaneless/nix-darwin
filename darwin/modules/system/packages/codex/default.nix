# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/codex/default.nix
#
# CODEX PROFILE: PACKAGE
# =====================================================================
# Packages codex-profile and patches profile storage to use:
#
#   ~/.config/codex/<profile>
#
# instead of:
#
#   ~/.codex-<profile>
# =====================================================================

{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  bash,
}:

stdenvNoCC.mkDerivation {
  pname = "codex-profile";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "Ducksss";
    repo = "codex-profiles";

    rev = "b0df2dd0ab955eb712436f234bbab984cc017992";

    # Put the hash you obtained here.
    hash = "sha256-3V/RzSQDc6gORZdEi6kfUQcAeULinhXSOY6K723wdsM=";
  };

  patches = [
    ./xdg-profile-root.patch
  ];

  nativeBuildInputs = [
    makeWrapper
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 \
      bin/codex-profile \
      "$out/bin/codex-profile"

    wrapProgram "$out/bin/codex-profile" \
      --prefix PATH : ${lib.makeBinPath [ bash ]}

    runHook postInstall
  '';

  meta = {
    description = "Manage separate Codex CLI and ChatGPT profiles";
    homepage = "https://github.com/Ducksss/codex-profiles";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "codex-profile";
  };
}