# darwin/terminal/commands/chmod.nix
#
# =====================================================================
# QUICK ACTIONS: XSCRIPT
#
# ---- xscript -> chmod script file or scripts in folder ---- #
# Makes one script executable, or all scripts in a folder
# =====================================================================

{ ... }:

{
  programs.fish.functions = {
    # -----------------------------------------------------------------
    xscript = ''

      # Check if any arguments were provided; if not, display usage instructions and return an error
      if test (count $argv) -eq 0

      	# Display usage instructions for the xscript function
        echo "Usage:"

        # Display usage for making a single script file executable
        echo "  xscript <script-file>"

        # Display usage for making all scripts in a folder executable
        echo "  xscript <folder>"

        # Return an error code indicating that the function was called incorrectly
        return 1
      end

      # Combine all provided arguments into a single string to form the target path
      set target (string join " " $argv)

      # ---- HELPER FUNCTION FOR CHMOD ---- #

      # Helper function to make a file executable if it is a recognized script
      function __xscript_chmod_file

      	# Get the file path from the first argument and determine its extension
        set file "$argv[1]"

        # Determine the file extension in lowercase for comparison
        set ext (string lower (path extension "$file"))


        # Check if the file extension matches common script extensions; if so, make it executable and print a message
        if contains "$ext" .py .sh .bash .zsh .fish .command
          chmod +x "$file"
          echo "Executable: $file"
          return 0
        end


        # Check if the first line of the file starts with a shebang (#!); if so, make it executable and print a message
        if head -n 1 "$file" 2>/dev/null | string match -q '#!*'
          chmod +x "$file"
          echo "Executable: $file"
          return 0
        end

        return 1
      end

      # ---- MAIN LOGIC ---- #

      # Check if the target is a file; if so, attempt to make it executable using the helper function and print a message
      if test -f "$target"
        __xscript_chmod_file "$target"; or echo "Skipped, not detected as script: $target"
        return 0
      end

      # Check if the target is a directory; if so, find all files in the directory and attempt to make them executable using the helper function
      if test -d "$target"
        find "$target" -maxdepth 1 -type f -print0 |
        while read -lz file
          __xscript_chmod_file "$file"
        end

        return 0
      end

      # If the target is neither a file nor a directory, print an error message and return an error code
      echo "Not found: $target"
      return 1
    '';
    # -----------------------------------------------------------------
  };
}
