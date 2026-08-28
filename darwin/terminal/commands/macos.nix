# darwin/terminal/commands/macos.nix
#
# =====================================================================
# FISH FUNCTIONS: MACOS
#
# macOS commands and functions
# =====================================================================

{ ... }:

{
  programs.fish.functions = {
  # -----------------------------------------------------------------
    # ---- appqu -> Remove quarantine attributes from app(s) ---- #
    # Command for removing quarantine attributes from
    # one or more apps or files
    # -----------------------------------------------------------------

    # Define the appqu function with a description for removing quarantine attributes from one or more apps/files
    appqu = {
      description = "Remove quarantine attributes from one or more apps/files";

      body = ''
        	# Check if any arguments were provided; if not, display usage instructions and return an error
          if test (count $argv) -eq 0

          	# Display usage instructions for the appqu function
            echo "Usage: appqu <path> [path ...]"

            # Return an error code indicating that the function was called incorrectly
            return 1
          end


          # Loop through each provided path and remove quarantine attributes using the xattr command
          for path in $argv

          	# Print a message indicating the path being processed
            echo "Removing quarantine: $path"

            # Use the xattr command to recursively remove quarantine attributes from the specified path
            xattr -cr "$path"
          end
      '';
    };
    # -----------------------------------------------------------------

    # -----------------------------------------------------------------
    # ---- icloudfix -> Restart iCloud/FileProvider services ---- #
    # Restarts Finder and iCloud-related daemons when iCloud
    # folders or app containers stop appearing correctly
    #
    # Example:
    # icloudfix
    # -----------------------------------------------------------------
    icloudfix = ''
      echo "Restarting iCloud/FileProvider services..."

      # Kill Finder and iCloud-related daemons to force a restart of the services
      killall Finder 2>/dev/null; or true
      killall fileproviderd 2>/dev/null; or true
      killall bird 2>/dev/null; or true
      killall cloudd 2>/dev/null; or true

      # Set the sleep duration to allow the services to restart properly
      sleep 3

      # Open the iCloud Mobile Documents folder in Finder to verify that the folders are now visible
      open "/Users/ven/Library/Mobile Documents/NK37SPV8GQ~cn~winat~EasyVoice"

      # Print a message indicating that the process is complete and suggest rebooting if iCloud folders are still missing
      echo "Done. If iCloud folders are still missing, reboot once."
    '';
    # -----------------------------------------------------------------
  };
}
