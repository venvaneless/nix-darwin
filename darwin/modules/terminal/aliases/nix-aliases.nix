# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/aliases/nix-aliases.nix

{ lib, ... }:

{
  programs.zsh.shellAliases = {
		# -------------------------------------
		# Evaluates the flake
  	# Builds all derivations
    # Doesn't switch to the current flake
    # -------------------------------------
    drb = "sudo -H darwin-rebuild build --flake ~/.config/nix/nix-darwin#macbook";
    
    # -------------------------------------
		# Evaluates the flake
		# Builds all derivations
		# Switches to the current flake config
		# -------------------------------------
    drs = "sudo -H darwin-rebuild switch --flake ~/.config/nix/nix-darwin#macbook";
    
    # -------------------------------------
		# Checks the full nix-darwin system configuration
		# Analyses for any bugs and any syntax errors
		# No rebuilding/applying
		# -------------------------------------
    drc = "sudo -H darwin-rebuild check --flake ~/.config/nix/nix-darwin#macbook";
    
    # ------------------------------------------------------------
	  # Checks the flake itself, NOT the Darwin configuration
	  # Checks if darwinConfigurations.macbook exist as an output
	  # Checks if the flake.nix is syntactically valid
	  # Checks declared outputs
	  # Tests if tests/builds defined in checks run
	  # Checks if devShells evaluate
		# Checks if overlays evaluate
		# ------------------------------------------------------------
	  ndc  = "sudo -H nix flake check ~/.config/nix/nix-darwin";
		
		# Recreates the lock file of a flake (flake.lock)
		# -------------------------------------------------
		ndl  = "sudo -H nix flake update ~/.config/nix/nix-darwin";
		
		# Updates the flake after new lockfile
		# ------------------------------------
		# ndu  = "nix flake update --flake ~/.config/nix/nix-darwin";
		
		# Temporary
		# 🔴 PROOF ALIAS (temporary)
		HMPROOF = "echo HM_SEES_THIS";
		dcc  = "sudo -H nix flake check ~/ven-dots/conf/nix/nix-darwin";
  };
}
