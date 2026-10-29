# comnyang-qs

Desktop pet cat for Arch Linux, Wayland, Hyprland, built with Quickshell (QML).

## Requirements
- quickshell, hyprland
- libinput (`libinput debug-events`), and your user in the `input` group
- Claude Code hooks (optional) writing to ~/.local/state/comnyang/agent-state.json

## Run
    qs -p ~/comnyang-qs

## Config
~/.config/comnyang/config.json

## Status
Untested early version. Known bugs: cat teleports to the cursor during mouse hunt,
"agent done" fires repeatedly, sprite art needs a redo. See PLAN.md.
