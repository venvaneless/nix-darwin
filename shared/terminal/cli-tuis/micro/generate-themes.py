#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path


SOURCE_DIR = Path.home() / ".config/micro/colorschemes"
DESTINATION_DIR = (
    Path.home()
    / ".config/nix/nix-config/shared/terminal/cli-tuis/micro/themes"
)

def humanize_theme_name(name: str) -> str:
    special_words = {
        "cmc": "CMC",
        "tc": "TC",
        "16": "16",
    }

    words = name.split("-")

    return " ".join(
        special_words.get(word.lower(), word.capitalize())
        for word in words
    )


def indent_theme_content(content: str) -> str:
    lines = content.splitlines()

    return "\n".join(
        f"      {line}" if line else ""
        for line in lines
    )


def escape_nix_indented_string(content: str) -> str:
    # Prevent Nix from treating ${...} in a Micro theme as interpolation.
    return content.replace("${", "''${")


def module_name_for_theme(theme_name: str) -> str:
    # default.nix is the registry, so retain the real theme separately.
    if theme_name == "default":
        return "default-theme"

    return theme_name


def build_nix_module(
    theme_name: str,
    module_name: str,
    theme_content: str,
) -> str:
    human_name = humanize_theme_name(theme_name)

    theme_content = escape_nix_indented_string(theme_content)
    indented_content = indent_theme_content(theme_content)

    return f'''# shared/terminal/cli-tuis/micro/themes/{module_name}.nix
#
# =====================================================================
# MICRO: {human_name.upper()} THEME
#
# - {human_name} theme for Micro
# - Selected directly in ../micro.nix with selectedTheme = "{theme_name}"
# =====================================================================

{{ config, lib, ... }}:

let
  microCfg = config.ven.features.terminal.cliTuis.micro;
  cfg = microCfg.themes.{theme_name};
in
{{
  options.ven.features.terminal.cliTuis.micro.themes.{theme_name}.enable = lib.mkOption {{
    type = lib.types.bool;
    default = false;
    description = "Internal switch for the {human_name} theme selected in micro.nix.";
  }};

  config = lib.mkIf (microCfg.enable && cfg.enable) {{
    # Micro loads custom colour schemes from this XDG colourschemes directory.
    xdg.configFile."micro/colorschemes/{theme_name}.micro".text = ''
{indented_content}
    '';
  }};
}}
'''


def generate_themes(write: bool, force: bool) -> None:
    if not SOURCE_DIR.is_dir():
        raise SystemExit(
            f"Source directory does not exist: {SOURCE_DIR}"
        )

    DESTINATION_DIR.mkdir(parents=True, exist_ok=True)

    source_files = sorted(SOURCE_DIR.glob("*.micro"))

    if not source_files:
        raise SystemExit(
            f"No .micro themes found in: {SOURCE_DIR}"
        )

    created = 0
    skipped_existing = 0

    for source_file in source_files:
        theme_name = source_file.stem
        module_name = module_name_for_theme(theme_name)
        destination_file = DESTINATION_DIR / f"{module_name}.nix"

        if destination_file.exists() and not force:
            print(f"SKIP existing:  {destination_file.name}")
            skipped_existing += 1
            continue

        source_content = source_file.read_text(encoding="utf-8")
        generated_content = build_nix_module(
            theme_name,
            module_name,
            source_content,
        )

        if write:
            destination_file.write_text(
                generated_content,
                encoding="utf-8",
            )
            print(f"CREATE:         {destination_file.name}")
        else:
            print(
                f"WOULD CREATE:   {destination_file.name}"
            )

        created += 1

    print()
    print("Summary")
    print("-------")

    if write:
        print(f"Created:          {created}")
    else:
        print(f"Would create:     {created}")

    print(f"Skipped existing: {skipped_existing}")

    if not write:
        print()
        print(
            "Dry run only. Run again with --write to create the files."
        )


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Convert Micro .micro colorschemes into Nix-managed "
            "Home Manager theme modules."
        )
    )

    parser.add_argument(
        "--write",
        action="store_true",
        help="Actually create the generated .nix files.",
    )

    parser.add_argument(
        "--force",
        action="store_true",
        help=(
            "Overwrite existing generated .nix files. "
            "Has no effect without --write."
        ),
    )

    args = parser.parse_args()

    generate_themes(
        write=args.write,
        force=args.force,
    )


if __name__ == "__main__":
    main()
