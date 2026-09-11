# shared/terminal/aliases/nix-aliases.nix
#
# =====================================================================
# NIX: ALIASES
#
# Shared Nix aliases and Fish functions for macOS and Linux.
# The same alias names are used on every machine, with the underlying
# rebuild commands selected automatically for nix-darwin or NixOS.
# =====================================================================

{ nixAliasValues, terminalAliasEntries, ... }:

let
  shellAliases = {

    # ---- Open the Nix configuration repository
    ## Changes the current terminal to the flake's root directory
    ncfg = {
      command = {
        darwin = "cd ${nixAliasValues.flakePath.darwin}";
        linux = "cd ${nixAliasValues.flakePath.linux}";
      };
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    # ---- Open the Nix scripts directory
    ## Changes the current terminal to the directory containing helper scripts
    nscripts = {
      command = {
        darwin = "cd ${nixAliasValues.scriptsPath.darwin}";
        linux = "cd ${nixAliasValues.scriptsPath.linux}";
      };
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };


    # ---------------------------------------------------------
    # ---- REBUILD COMMANDS ---- #
    # Uses darwin-rebuild on macOS and nixos-rebuild on Linux.
    # The host-specific flake name is configured explicitly, because
    # it is not necessarily the operating system hostname.
    # ---------------------------------------------------------

    # ---- Build and activate the system configuration
    ## Creates a new system generation, switches to it, and runs activation
    drs = {
      command = {
        darwin = "sudo -H darwin-rebuild switch --flake ${nixAliasValues.flakePath.darwin}#${nixAliasValues.flakeHost}";
        linux = "sudo -H nixos-rebuild switch --flake ${nixAliasValues.flakePath.linux}#${nixAliasValues.flakeHost}";
      };
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    # ---- Build the system configuration without activating it
    ## Builds the system without switching generations
    drb = {
      command = {
        darwin = "sudo -H darwin-rebuild build --flake ${nixAliasValues.flakePath.darwin}#${nixAliasValues.flakeHost}";
        linux = "sudo -H nixos-rebuild build --flake ${nixAliasValues.flakePath.linux}#${nixAliasValues.flakeHost}";
      };
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    # ---- Build + check-mode activation
    ## Tests the configuration without permanently switching generations
    rcheck = {
      command = {
        darwin = "sudo -H darwin-rebuild check --flake ${nixAliasValues.flakePath.darwin}#${nixAliasValues.flakeHost}";
        linux = "sudo -H nixos-rebuild test --flake ${nixAliasValues.flakePath.linux}#${nixAliasValues.flakeHost}";
      };
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };


    # ---------------------------------------------------------
    # ---- VALIDATION COMMANDS ---- #
    # ---------------------------------------------------------

    # ---- Validate the flake configuration
    ## Evaluates standard flake outputs and builds anything declared under checks
    ncheck = {
      command = {
        darwin = "nix flake check ${nixAliasValues.flakePath.darwin}";
        linux = "nix flake check ${nixAliasValues.flakePath.linux}";
      };
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    # ---- Validate the flake configuration with build logs
    ## Same as ncheck, but prints detailed output for each check build
    "nl-check" = {
      command = {
        darwin = "nix flake check ${nixAliasValues.flakePath.darwin} --print-build-logs";
        linux = "nix flake check ${nixAliasValues.flakePath.linux} --print-build-logs";
      };
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    # ---- Evaluate the current system configuration without building it
    ## Prints the system derivation path without building or activating
    neval = {
      command = {
        darwin = "nix eval ${nixAliasValues.flakePath.darwin}#darwinConfigurations.${nixAliasValues.flakeHost}.system.drvPath";
        linux = "nix eval ${nixAliasValues.flakePath.linux}#nixosConfigurations.${nixAliasValues.flakeHost}.config.system.build.toplevel.drvPath";
      };
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    # ---- Build the current system configuration without activation
    ## Builds the full system without creating a result link or switching generations
    rsafe = {
      command = {
        darwin = "sudo -H nix build ${nixAliasValues.flakePath.darwin}#darwinConfigurations.${nixAliasValues.flakeHost}.system --no-link";
        linux = "sudo -H nix build ${nixAliasValues.flakePath.linux}#nixosConfigurations.${nixAliasValues.flakeHost}.config.system.build.toplevel --no-link";
      };
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };


    # ---------------------------------------------------------
    # ---- FLAKE COMMANDS ---- #
    # ---------------------------------------------------------

    # ---- Show the flake outputs
    ## Lists packages, applications, systems, and other exposed outputs
    nshow = {
      command = {
        darwin = "nix flake show ${nixAliasValues.flakePath.darwin}";
        linux = "nix flake show ${nixAliasValues.flakePath.linux}";
      };
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    # ---- Update the flake inputs
    ## Fetches the latest inputs and updates flake.lock
    "flake-update" = {
      command = {
        darwin = "nix flake update --flake ${nixAliasValues.flakePath.darwin}";
        linux = "nix flake update --flake ${nixAliasValues.flakePath.linux}";
      };
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };
  };

  functions = {

    # ---------------------------------------------------------
    # ---- nvalidate -> Evaluate, build, and save the output ---- #
    #
    # Evaluates and then builds the current system without switching
    # generations or running activation.
    #
    # Works on:
    # macOS -> darwinConfigurations
    # Linux -> nixosConfigurations
    #
    # Both command outputs are shown in the terminal and saved in
    # the user's Downloads folder.
    # ---------------------------------------------------------

    nvalidate = {
      enable = true;
      help = "Evaluate and build the Nix system configuration with a Downloads log";
      installOn = {
        darwin = true;
        linux = true;
      };
      command = {
        # Configurable values. Each is a default and can be overridden by a host.
        flake.path = {
          darwin = nixAliasValues.flakePath.darwin;
          linux = nixAliasValues.flakePath.linux;
        };
        flake.host = {
          darwin = nixAliasValues.flakeHost;
          linux = nixAliasValues.flakeHost;
        };
        date.format = "+%Y-%m-%d-%H%M%S";
        log.directory = {
          darwin = nixAliasValues.validationLogDirectory.darwin;
          linux = nixAliasValues.validationLogDirectory.linux;
        };
        log.file = "$timestamp-nix-eval.log";
        system = {
          configurations = {
            darwin = "darwinConfigurations";
            linux = "nixosConfigurations";
          };
          buildTarget = {
            darwin = "darwinConfigurations.${nixAliasValues.flakeHost}.system";
            linux = "nixosConfigurations.${nixAliasValues.flakeHost}.config.system.build.toplevel";
          };
          derivationTarget = {
            darwin = "darwinConfigurations.${nixAliasValues.flakeHost}.system.drvPath";
            linux = "nixosConfigurations.${nixAliasValues.flakeHost}.config.system.build.toplevel.drvPath";
          };
        };
      };
    };

    # ---------------------------------------------------------


    # ---------------------------------------------------------
    # ---- pinflake -> Archive and protect flake inputs ---- #
    #
    # Fetches all inputs for a flake and creates indirect GC roots
    # so nix-collect-garbage does not remove them.
    #
    # Defaults to the configured Nix repository.
    #
    # Examples:
    #
    # pinflake
    # pinflake ~/.config/nix/nix-config
    # ---------------------------------------------------------

    pinflake = {
      command.pinflake = {
        # Configurable defaults. The function accepts another flake path as $argv[1].
        flake.path = {
          darwin = nixAliasValues.flakePath.darwin;
          linux = nixAliasValues.flakePath.linux;
        };
        gcRoots.path = {
          darwin = nixAliasValues.flakeInputGCRoots.darwin;
          linux = nixAliasValues.flakeInputGCRoots.linux;
        };
        store.path = nixAliasValues.storePath;
        replaceExistingRoots = true;
      };
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    # ---------------------------------------------------------
  };
in
{
  config = {
    ven.features.terminal.aliases.shell = terminalAliasEntries.mkDefaults shellAliases;

    ven.features.terminal.aliases.functions = terminalAliasEntries.mkDefaults functions;
  };
}
