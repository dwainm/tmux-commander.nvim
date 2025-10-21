# 🚀 tmux-commander.nvim

**Neovim plugin for executing commands in tmux windows with smart window management and completion notifications.**

https://github.com/dwainm/tmux-commander.nvim

---

## ✨ Features

- 🎯 **Smart Window Selection** - automatically finds idle tmux windows or creates new ones
- 🔔 **Completion Notifications** - get notified when long-running commands finish (success/failure)
- 📜 **Command History** - persistent history with quick access to previously run commands
- ⌨️ **Simple API** - just one function: `run_prompt(cmd)` - pass command or prompt user
- 🎨 **Customizable** - define your own keymaps, configure notifications and behavior
- 💬 **Interactive Support** - handles commands requiring user input (consoles, prompts, etc.)

## 📦 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "dwainm/tmux-commander.nvim",
  keys = {
    -- Your custom commands - pass the command directly to run_prompt()
    { "<leader>rd", function() require("tmux-commander").run_prompt("kamal deploy") end, desc = "Deploy with Kamal" },
    { "<leader>rt", function() require("tmux-commander").run_prompt("bin/rails test") end, desc = "Run Rails tests" },
    { "<leader>rC", function() require("tmux-commander").run_prompt("bin/rails console") end, desc = "Rails console" },

    -- Prompt for custom command
    { "<leader>rc", function() require("tmux-commander").run_prompt() end, desc = "Run custom command" },

    -- Built-in utilities
    { "<leader>rh", function() require("tmux-commander").show_history() end, desc = "Command history" },
    { "<leader>rr", function() require("tmux-commander").repeat_last() end, desc = "Repeat last command" },
    { "<leader>ri", function() require("tmux-commander").inspect() end, desc = "Jump to runner window" },
    { "<leader>rx", function() require("tmux-commander").kill() end, desc = "Kill running command" },
    { "<leader>rl", function() require("tmux-commander").list_windows() end, desc = "List runner windows" },
  },
}
```

## ⚡️ Requirements

- Neovim >= 0.9.0
- tmux >= 3.0
- [nvim-notify](https://github.com/rcarriga/nvim-notify) or [noice.nvim](https://github.com/folke/noice.nvim) (recommended for notifications)

## 🎬 Quick Start

1. Install the plugin with your package manager
2. Define keymaps that call `run_prompt("your command")`
3. Press your keymap to run the command in a tmux window
4. Get notified when the command completes

**Example workflow:**

```lua
-- Press <leader>rd to deploy
-- → Plugin finds idle tmux window or creates new one
-- → Sends "kamal deploy" to the window
-- → Shows: "🚀 kamal deploy started in window 2"
-- → Monitors command execution every 2 seconds
-- → When finished: "✅ kamal deploy completed (5m 32s)"
```

## ⚙️ Configuration

<details>
<summary>Default configuration</summary>

```lua
{
  "dwainm/tmux-commander.nvim",
  opts = {
    notification = true,
    monitor_interval = 2000,  -- Check command status every 2 seconds
    idle_shells = { "zsh", "bash", "sh", "fish" },  -- What counts as idle

    notify_on = {
      start = true,   -- "🚀 Command started in window 2"
      success = true, -- "✅ Command completed (5m 32s)"
      failure = true, -- "❌ Command failed (exit code 1)"
    },

    history = {
      enabled = true,
      max_entries = 100,
    },
  },
  keys = {
    -- Your keymaps here...
  },
}
```

</details>

## 🔥 API

### Core Function

**`run_prompt(cmd?)`**

The main (and only) function you need. It runs a command in a tmux window.

- **With command:** `run_prompt("bin/rails test")` - runs the command directly
- **Without command:** `run_prompt()` - prompts user for input

```lua
-- Direct command execution
vim.keymap.set("n", "<leader>rd", function()
  require("tmux-commander").run_prompt("kamal deploy")
end)

-- Prompt for command
vim.keymap.set("n", "<leader>rc", function()
  require("tmux-commander").run_prompt()
end)
```

### Utility Functions

**`show_history()`** - Show command history (TODO: add telescope/fzf picker)

**`repeat_last()`** - Re-run the last executed command

**`inspect()`** - Jump to the active runner window (useful for interactive commands)

**`kill()`** - Send Ctrl-C to running command and kill it

**`list_windows()`** - Show all tmux windows

## 🎯 How It Works

### Smart Window Selection

1. Lists all tmux windows: `tmux list-windows`
2. Finds first window running an idle shell (`zsh`, `bash`, `sh`, `fish`)
3. If found → sends command to that window
4. If not found → creates new window with `tmux new-window`

### Command Monitoring

1. Starts async timer (checks every `monitor_interval` ms)
2. Checks if window is back to idle shell
3. When command finishes:
   - Shows completion notification
   - Saves to command history
   - Stops monitoring

### History Storage

Commands are saved to `~/.local/share/nvim/tmux-commander-history.json`:

```json
[
  {
    "command": "kamal deploy",
    "timestamp": 1729512345,
    "window": 2,
    "exit_code": 0,
    "duration": 332
  }
]
```

## 💡 Tips

**For interactive commands** (consoles, REPLs), use `inspect()` to jump to the window:

```lua
-- Run console
{ "<leader>rC", function() require("tmux-commander").run_prompt("bin/rails console") end }

-- Jump to it immediately
{ "<leader>ri", function() require("tmux-commander").inspect() end }
```

**Use with which-key** for discoverable commands:

When you press `<leader>r`, which-key will show all your defined runner commands.

**Multiple projects?** Define different keymaps per filetype:

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "ruby",
  callback = function()
    vim.keymap.set("n", "<leader>rt", function()
      require("tmux-commander").run_prompt("bin/rails test")
    end, { buffer = true, desc = "Run Rails tests" })
  end,
})
```

## 🚧 Status

This plugin is in active development. Current limitations:

- Exit code detection assumes success (monitors shell return, not actual exit code)
- History viewer is basic (TODO: add telescope/fzf integration)
- Single runner window per session (TODO: support multiple runners)

See [SPEC.md](./SPEC.md) for planned features and detailed specification.

## 📝 License

MIT

---

<div align="center">
  <sub>Built with ❤️ for Neovim and tmux users</sub>
</div>
