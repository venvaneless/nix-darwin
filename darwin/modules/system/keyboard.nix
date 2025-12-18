# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/keyboard.nix

targets.darwin.defaults.NSGlobalDomain = {
  # Disable automatic capitalization
  NSAutomaticCapitalizationEnabled = false;

  # Disable smart dashes
  NSAutomaticDashSubstitutionEnabled = true;

  # Disable smart quotes
  NSAutomaticQuoteSubstitutionEnabled = false;

  # Disable automatic period substitution
  NSAutomaticPeriodSubstitutionEnabled = false;

  # Disable spell correction
  NSAutomaticSpellingCorrectionEnabled = false;
};
