programs.bat = {
  enable = true;

  themes = {
    rose-pine-moon = {
      src = pkgs.fetchFromGitHub {
        owner = "drluckyspin";
        repo = "rose-pine-bat";
        rev = "main";
        hash = lib.fakeHash;
      };
      file = "Rose-Pine-Moon.tmTheme";
    };
  };

  settings = {
    theme = "Rose-Pine-Moon";
    paging = "auto";
    pager = "less -R";
  };
};