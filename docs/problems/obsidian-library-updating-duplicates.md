The option downloading plugins leaves this folder after:
`.gitdll-tmp`

"Check for updates" still prints list of plugins and themes:

```
Checked 33/2163: building the selectable update list…Checked 34/2163: building the selectable update list…                                          Checked 35/2163: building the selectable update list…                                          Checked 36/2163: building the selectable update list…                                          Checked 37/2163: building the selectable update list…
```

---

- After using gitdll --plugins "links.txt" it at some point stops without downloading the rest of the plugins and gives this error

```fish
Repository:
  https://github.com/ntsiris/obsidian-popup-dictionary
Saved:
  /Users/ven/Downloads/gitdll-plugins/popup-dictionary
Files:
  manifest.json
  main.js
  styles.css
  repo/assets/demo.gif
  repo/README.md
Successful
fish: Unknown command: __gitdll_canonical_repository_url
~/.config/fish/functions/gitdll.fish (line 2):
            __gitdll_canonical_repository_url "$source_repository_url"
            ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
in command substitution
        called on line 1152 of file ~/.config/fish/functions/gitdll.fish
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
~/.config/fish/functions/gitdll.fish (line 1152): Unknown command
                        set --local repository_url (
            __gitdll_canonical_repository_url "$source_repository_url"
          )
                                                   ^
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
fish: Unknown command: __gitdll_canonical_repository_url
~/.config/fish/functions/gitdll.fish (line 2):
            __gitdll_canonical_repository_url "$source_repository_url"
            ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
in command substitution
        called on line 1152 of file ~/.config/fish/functions/gitdll.fish
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
~/.config/fish/functions/gitdll.fish (line 1152): Unknown command
                        set --local repository_url (
            __gitdll_canonical_repository_url "$source_repository_url"
          )
                                                   ^
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
fish: Unknown command: __gitdll_canonical_repository_url
~/.config/fish/functions/gitdll.fish (line 2):
            __gitdll_canonical_repository_url "$source_repository_url"
            ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
in command substitution
        called on line 1152 of file ~/.config/fish/functions/gitdll.fish
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
~/.config/fish/functions/gitdll.fish (line 1152): Unknown command
                        set --local repository_url (
            __gitdll_canonical_repository_url "$source_repository_url"
          )
                                                   ^
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
fish: Unknown command: __gitdll_canonical_repository_url
~/.config/fish/functions/gitdll.fish (line 2):
            __gitdll_canonical_repository_url "$source_repository_url"
            ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
in command substitution
        called on line 1152 of file ~/.config/fish/functions/gitdll.fish
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
~/.config/fish/functions/gitdll.fish (line 1152): Unknown command
                        set --local repository_url (
            __gitdll_canonical_repository_url "$source_repository_url"
          )
                                                   ^
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
fish: Unknown command: __gitdll_canonical_repository_url
~/.config/fish/functions/gitdll.fish (line 2):
            __gitdll_canonical_repository_url "$source_repository_url"
            ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
in command substitution
        called on line 1152 of file ~/.config/fish/functions/gitdll.fish
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
~/.config/fish/functions/gitdll.fish (line 1152): Unknown command
                        set --local repository_url (
            __gitdll_canonical_repository_url "$source_repository_url"
          )
                                                   ^
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
fish: Unknown command: __gitdll_canonical_repository_url
~/.config/fish/functions/gitdll.fish (line 2):
            __gitdll_canonical_repository_url "$source_repository_url"
            ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
in command substitution
        called on line 1152 of file ~/.config/fish/functions/gitdll.fish
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
~/.config/fish/functions/gitdll.fish (line 1152): Unknown command
                        set --local repository_url (
            __gitdll_canonical_repository_url "$source_repository_url"
          )
                                                   ^
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
fish: Unknown command: __gitdll_canonical_repository_url
~/.config/fish/functions/gitdll.fish (line 2):
            __gitdll_canonical_repository_url "$source_repository_url"
            ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
in command substitution
        called on line 1152 of file ~/.config/fish/functions/gitdll.fish
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
~/.config/fish/functions/gitdll.fish (line 1152): Unknown command
                        set --local repository_url (
            __gitdll_canonical_repository_url "$source_repository_url"
          )
                                                   ^
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
fish: Unknown command: __gitdll_canonical_repository_url
~/.config/fish/functions/gitdll.fish (line 2):
            __gitdll_canonical_repository_url "$source_repository_url"
            ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
in command substitution
        called on line 1152 of file ~/.config/fish/functions/gitdll.fish
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
~/.config/fish/functions/gitdll.fish (line 1152): Unknown command
                        set --local repository_url (
            __gitdll_canonical_repository_url "$source_repository_url"
          )
                                                   ^
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
fish: Unknown command: __gitdll_canonical_repository_url
~/.config/fish/functions/gitdll.fish (line 2):
            __gitdll_canonical_repository_url "$source_repository_url"
            ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
in command substitution
        called on line 1152 of file ~/.config/fish/functions/gitdll.fish
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
~/.config/fish/functions/gitdll.fish (line 1152): Unknown command
                        set --local repository_url (
            __gitdll_canonical_repository_url "$source_repository_url"
          )
                                                   ^
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
fish: Unknown command: __gitdll_remove_completed_source_link
~/.config/fish/functions/gitdll.fish (line 1211):
            if test (count $completed_source_parts) -ne 2; or not __gitdll_remove_completed_source_link \
                                                                  ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
fish: Unknown command: __gitdll_remove_completed_source_link
~/.config/fish/functions/gitdll.fish (line 1211):
            if test (count $completed_source_parts) -ne 2; or not __gitdll_remove_completed_source_link \
                                                                  ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
fish: Unknown command: __gitdll_remove_completed_source_link
~/.config/fish/functions/gitdll.fish (line 1211):
            if test (count $completed_source_parts) -ne 2; or not __gitdll_remove_completed_source_link \
                                                                  ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
fish: Unknown command: __gitdll_remove_completed_source_link
~/.config/fish/functions/gitdll.fish (line 1211):
            if test (count $completed_source_parts) -ne 2; or not __gitdll_remove_completed_source_link \
                                                                  ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
fish: Unknown command: __gitdll_remove_completed_source_link
~/.config/fish/functions/gitdll.fish (line 1211):
            if test (count $completed_source_parts) -ne 2; or not __gitdll_remove_completed_source_link \
                                                                  ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
fish: Unknown command: __gitdll_remove_completed_source_link
~/.config/fish/functions/gitdll.fish (line 1211):
            if test (count $completed_source_parts) -ne 2; or not __gitdll_remove_completed_source_link \
                                                                  ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
fish: Unknown command: __gitdll_remove_completed_source_link
~/.config/fish/functions/gitdll.fish (line 1211):
            if test (count $completed_source_parts) -ne 2; or not __gitdll_remove_completed_source_link \
                                                                  ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
fish: Unknown command: __gitdll_remove_completed_source_link
~/.config/fish/functions/gitdll.fish (line 1211):
            if test (count $completed_source_parts) -ne 2; or not __gitdll_remove_completed_source_link \
                                                                  ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
fish: Unknown command: __gitdll_write_failure_report
~/.config/fish/functions/gitdll.fish (line 1229):
        __gitdll_write_failure_report
        ^~~~~~~~~~~~~~~~~~~~~~~~~~~~^
in function 'gitdll' with arguments '--plugins /Users/ven/Downloads/links.txt'
Failed. Details: /Users/ven/Downloads/gitdll-plugins/failed-plugin-downloads.txt
```

---

Plugins and themes aren't sorted by names. Rather they're shown in groups who are sorted by names so I see plugins A-Z, but then I would see again plugins from A-Z.

---

Search is horrible.
When I try to search through plugins and themes, the view gets chaotic and I see only descriptions. There's also too many columns that don't seem to shorten, hiding content of the next column.
See screenshot.
I search for "portals" and get shown plugins that have nothing to do with the plugin

---

It would be nice if the list that is being build "Check for updates" didn't rebuild each time I choose the option. When I accidentally close the terminal, I need to build the list from scratch which takes a long time with over 2k plugins/themes. It would be nice if obsidian-library was able to build the list of plugins and themes and know

- My version of the plugins/themes
- The remote version of a plugin/themes
- Date of the last build
  This way it can just check the date of the update on the website and check against my date and know if the date of the remote update did not change there's no need to recheck the specific plugin/theme.

---

with gitdll still files land in the `repo/` folder even if there's less than three files in it:

```
/Users/ven/Downloads/gitdll-plugins/sidecar-notes/repo/settings.png
/Users/ven/Downloads/gitdll-plugins/sidecar-notes/repo/notes.png
/Users/ven/Downloads/gitdll-plugins/sidecar-notes/repo/README.md
```

Fix it

---

Some themes show this error:

```
Notice: README preview image was not found in the repository: Images/layouts.png
Notice: README preview image was not found in the repository: Images/color-settings.png
Notice: README preview image was not found in the repository: Images/named-colors.png
Notice: README preview image was not found in the repository: Images/accent-based-colors.png
Notice: README preview image was not found in the repository: Images/callout-metadata.png
Notice: README preview image was not found in the repository: Images/alternative-checkboxes.png
```

... which is contradictory because it literally downloaded these

---

Some plugins get this error despite having everything they need on the release page or direct in the remote repo:

```
╭─  ven   ~  󰈺 fish
╰─❯ gitdll --plugin "https://github.com/dy-sh/obsidian-find-and-replace-in-selection"

Repository:
https://github.com/dy-sh/obsidian-find-and-replace-in-selection
Notice: No GitHub release was found.
Error: This repository does not provide an Obsidian plugin main.js.
Failed. Details: /Users/ven/Downloads/gitdll-plugins/failed-plugin-downloads.txt
```

```
Repository:
  https://github.com/coignard/obsidian-typographer
Notice: No GitHub release was found.
Saved:
  /Users/ven/Downloads/gitdll-plugins/typographer
Files:
  manifest.json
  main.js
  README.md
```

... and won't stop downloading the plugin, but some still do.

---

the way the plugins are checked makes my Github rate be exceeded and I then am not able to update any plugins:

```
Update 1 selected plugins now? [y/N]: y
Error: [FAILED] Advanced Line Numbers: gh: API rate limit exceeded for user ID 209770139. If you reach out to GitHub Support for help, please include the request ID C90B:2D73A2:1829A692:177E2658:6AAD8067 and timestamp 2026-09-18 18:18:16 UTC. For more on scraping GitHub and how it may affect your rights, please review our Terms of Service (https://docs.github.com/en/site-policy/github-terms/github-terms-of-service) (HTTP 403)
```

Any way around this?

---

What does gitdll try to download here?

```
╭─  ven   Downloads  󰈺 fish
╰─❯ gitdll --plugin "https://github.com/mprojectscode/obsidian-meta-bind-plugin"

Repository:
  https://github.com/mprojectscode/obsidian-meta-bind-plugin
.zip
```

... it always takes so long when it shows up

---

for some reason for this plugin gitdll put everything in the `repo/` folder, although there are only two files:

```
/Users/ven/Downloads/gitdll-plugins/version/repo/README.md
/Users/ven/Downloads/gitdll-plugins/version/repo/acceptance-matrix.md
```

.... instead of directly in:

```
/Users/ven/Downloads/gitdll-plugins/version/acceptance-matrix.md
/Users/ven/Downloads/gitdll-plugins/version/README.md
```

---

I was not able to download this plugin, got this error:

```
╭─  ven   Downloads  󰈺 fish
╰─❯ gitdll --plugin "https://github.com/mszturc/obsidian-advanced-slides"

Repository:
  https://github.com/mszturc/obsidian-advanced-slides
curl: (56) Failure writing output to destination, passed 1369 returned 4294967295
curl: (56) Failure writing output to destination, passed 289 returned 4294967295
curl: (56) Failure writing output to destination, passed 561 returned 4294967295
curl: (56) Failure writing output to destination, passed 289 returned 4294967295
Notice: Could not fetch repository file: manifest.json
curl: (56) Failure writing output to destination, passed 561 returned 4294967295
Notice: Could not fetch repository file: styles.css
curl: (56) Failure writing output to destination, passed 808 returned 4294967295
Notice: Could not fetch repository README.
find: ‘/Users/ven/Downloads/gitdll-plugins/.gitdll-tmp/gitdll-plugins.YKbkCrgYam/repository’: No such file or directory
curl: (56) Failure writing output to destination, passed 807 returned 4294967295
warning: An error occurred while redirecting file '/Users/ven/Downloads/gitdll-plugins/.gitdll-tmp/gitdll-plugins.YKbkCrgYam/repository/manifest.json'
warning: Path '/Users/ven/Downloads/gitdll-plugins/.gitdll-tmp' does not exist
Error: Could not generate plugin manifest.json.
Failed. Details: /Users/ven/Downloads/gitdll-plugins/failed-plugin-downloads.txt
```

Though the release page and remote repo has everything that makes a plugin.
Please fix.

---

With some plugins, like:
https://github.com/mdelobelle/fileclass

...gitdll completely refuses to download further, like here which I tried with

```
gitdll --plugins "links.txt"
```
