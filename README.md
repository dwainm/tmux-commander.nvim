# tmux-runner.nvim

Smart tmux window management and command execution for Neovim.

## Features

🎯 **Smart Window Selection** - Automatically finds idle tmux windows or creates new ones
🔔 **Completion Notifications** - Get notified when long-running commands finish
📜 **Command History** - Quick access to previously run commands with `<leader>rh`
⌨️ **Custom Commands** - Define your own commands with keymaps
🔑 **Which-key Integration** - Automatic keymap descriptions
💬 **Interactive Support** - Handles commands requiring user input (passwords, prompts)

## Installation

### lazy.nvim

```lua
{
  "dwainm/tmux-runner.nvim",
  opts = {
    commands = {
      {
        name = "deploy",
        cmd = "kamal deploy",
        key = "d",
        desc = "Deploy with Kamal",
      },
    },
  },
}
```

See [SPEC.md](./SPEC.md) for complete configuration options.

## Quick Start

1. Define your commands in the plugin config
2. Press `<leader>r` to see available commands
3. Run commands like `<leader>rd` (deploy)
4. Press `<leader>rh` to view command history

## Default Keymaps

- `<leader>rh` - Command history
- `<leader>rr` - Repeat last command
- `<leader>ri` - Jump to runner window
- `<leader>rx` - Kill running command
- `<leader>rl` - List runner windows

## Status

🚧 **In Development** - See [SPEC.md](./SPEC.md) for planned features

## License

MIT
