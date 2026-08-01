# darwin/packages/codex/default.nix
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

# We use stdenvNoCC here because codex-profile is a shell script and does not require a compiler to build. This avoids unnecessary dependencies on compilers and related tools, making the package lighter and faster to build.
stdenvNoCC.mkDerivation {
  pname = "codex-profile";
  version = "0.8.0";

  # Download the source directly from Github
  src = fetchFromGitHub {
    owner = "Ducksss";
    repo = "codex-profiles";

    rev = "b0df2dd0ab955eb712436f234bbab984cc017992";

    # Put the hash you obtained here.
    hash = "sha256-3V/RzSQDc6gORZdEi6kfUQcAeULinhXSOY6K723wdsM=";
  };

  # Use a patch to change the default profile storage location from ~/.codex-<profile> to ~/.config/codex/<profile>
  patches = [
    ./xdg-profile-root.patch
  ];

  # Use makeWrapper to create a wrapper script that sets the PATH environment variable to include bash, ensuring that the codex-profile script can find bash when executed.
  nativeBuildInputs = [
    makeWrapper
  ];

  # Don't build the source code since codex-profile is a shell script and does not require compilation
  dontBuild = true;

  # Install the codex-profile script to the output bin directory and wrap it with a script that sets the PATH environment variable to include bash.
  installPhase = ''
    runHook preInstall

    # Install the codex-profile script to the output bin directory with executable permissions
    install -Dm755 \
      bin/codex-profile \
      "$out/bin/codex-profile"

    # Wrap the codex-profile script with a wrapper that sets the PATH environment variable to include bash, ensuring that the script can find bash when executed.
    wrapProgram "$out/bin/codex-profile" \
      --prefix PATH : ${lib.makeBinPath [ bash ]}

    # Run a hook after the installation is complete to perform any additional setup or configuration tasks
    runHook postInstall
  '';

  # Metadata for the package, including description, homepage, license, supported platforms, and the main program to be executed when the package is run.
  meta = {
    description = "Manage separate Codex CLI and ChatGPT profiles";
    homepage = "https://github.com/Ducksss/codex-profiles";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "codex-profile";
  };
}