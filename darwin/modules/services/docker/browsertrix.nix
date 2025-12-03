# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/browsertrix.nix
#
# BROWSERTRIX CRAWLER CONTAINER
# ============================================================
# - Uses your unified container root:
#       /Users/ven/dotfiles/containers/browsertrix
# - Mounts it at:
#       /data   (from mkContainer)
#       /crawls (explicit extra volume)
# - Runs a one-shot crawl (NOT a daemon):
#       - tfthacker.com/Welcome
#       - publish.obsidian.md
#
# IMPORTANT:
#   - runAtLoad = false → does NOT auto-run at boot
#   - keepAlive = false → does NOT loop forever
# ============================================================

{
  name  = "browsertrix";
  image = "ghcr.io/webrecorder/browsertrix-crawler:latest";

  # Do NOT auto-run on boot, and do NOT restart when finished.
  runAtLoad = false;
  keepAlive = false;

  # Extra volume: map the same host dir to /crawls
  # (mkContainer already maps it to /data by default)
  extraVolumes = [
    "/Users/ven/dotfiles/containers/browsertrix:/crawls"
  ];

  # Browsertrix CLI arguments
  extraArgs = [
    "crawl"
    "--url" "https://tfthacker.com/Welcome"
    "--url" "https://publish.obsidian.md/"
    "--scopeType" "host"
    "--crawlDepth" "10"
    "--generateWACZ"
  ];
}
