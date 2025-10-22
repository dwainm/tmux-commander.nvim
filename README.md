# 🚀 tmux-commander.nvim

**Neovim plugin for executing commands in tmux windows with smart window management and completion notifications.**

https://github.com/dwainm/tmux-commander.nvim

---

## ✨ Features

- 🎯 **Smart Window Selection** - automatically finds idle tmux windows or creates new ones
- 🔔 **Completion Notifications** - get notified when long-running commands finish (success/failure)
- 📜 **Command History** - persistent history with Snacks.nvim picker to re-run commands
- 🔍 **Live Window Preview** - browse all tmux windows with real-time content preview
- 🤖 **Auto-Adopt Commands** - automatically monitor all running tmux commands with one keypress
- ⌨️ **Simple API** - just one function: `run_prompt(cmd)` - pass command or prompt user
- 🎨 **Customizable** - define your own keymaps, configure notifications and behavior
- 🔐 **Auto-Prompt for Input** - cursor-based detection automatically prompts for passwords, confirmations, and interactive input

## 📦 Installation

Install the plugin with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "dwainm/tmux-commander.nvim",
  dependencies = {
    "folke/snacks.nvim", -- for picker UI
  },
  keys = {
    -- Window commands - runs in separate tmux windows
    { "<leader>rd", function() require("tmux-commander").run_prompt("kamal deploy") end, desc = "Deploy with Kamal" },
    { "<leader>rt", function() require("tmux-commander").run_prompt("bin/rails test") end, desc = "Run Rails tests" },
    { "<leader>rC", function() require("tmux-commander").run_prompt("bin/rails console") end, desc = "Rails console" },
    { "<leader>rc", function() require("tmux-commander").run_prompt() end, desc = "Run custom command" },

    -- Pane commands - runs in panes within current window
    { "<leader>pd", function() require("tmux-commander").run_panel_prompt("npm run dev") end, desc = "Dev server" },
    { "<leader>pt", function() require("tmux-commander").run_panel_prompt("npm run test:watch") end, desc = "Test watcher" },
    { "<leader>pc", function() require("tmux-commander").run_panel_prompt() end, desc = "Run custom command in pane" },

    -- Built-in utilities
    { "<leader>ra", function() require("tmux-commander").adopt() end, desc = "Adopt running command" },
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
- [snacks.nvim](https://github.com/folke/snacks.nvim) - for picker UI with tmux preview
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
    target_session = "",  -- Target specific tmux session, or "" for current session

    notify_on = {
      start = true,   -- "🚀 Command started in window 2"
      success = true, -- "✅ Command completed (5m 32s)"
      failure = true, -- "❌ Command failed (exit code 1)"
    },

    history = {
      enabled = true,
      max_entries = 100,
    },

    input_detection = {
      enabled = true,  -- Auto-prompt for input when command needs it

      -- How long to wait for output to stabilize before detecting (ms)
      stability_timeout = 2000,

      -- Commands that wait for stdin without showing a prompt
      -- These will trigger a notification instead of an input prompt
      stdin_waiters = {
        action = "notify",  -- "notify" | "ignore" | "prompt"
        commands = {
          "cat", "grep", "sort", "wc", "tee", "tr",
          "sed", "awk", "head", "tail", "less", "more",
          "uniq", "cut", "paste"
        }
      },

      -- Patterns that indicate a password prompt (for hidden input)
      password_patterns = {
        "password:",
        "passphrase:",
      }
    },
  },
  keys = {
    -- Your keymaps here...
  },
}
```

</details>

## 🔥 API

### Core Functions

**`run_prompt(cmd?)`**

Runs a command in a tmux **window** (creates new windows as needed).

- **With command:** `run_prompt("bin/rails test")` - runs the command directly
- **Without command:** `run_prompt()` - prompts user for input

```lua
-- Direct command execution in a window
vim.keymap.set("n", "<leader>rd", function()
  require("tmux-commander").run_prompt("kamal deploy")
end)

-- Prompt for command in a window
vim.keymap.set("n", "<leader>rc", function()
  require("tmux-commander").run_prompt()
end)
```

**`run_panel_prompt(cmd?)`**

Runs a command in a tmux **pane** within the current window (splits panes as needed).

- **With command:** `run_panel_prompt("npm run dev")` - runs the command directly
- **Without command:** `run_panel_prompt()` - prompts user for input

```lua
-- Direct command execution in a pane
vim.keymap.set("n", "<leader>pd", function()
  require("tmux-commander").run_panel_prompt("npm run dev")
end)

-- Prompt for command in a pane
vim.keymap.set("n", "<leader>pc", function()
  require("tmux-commander").run_panel_prompt()
end)
```

**When to use windows vs panes?**

- **Windows** (`run_prompt`): For long-running tasks you want isolated (deploys, test suites)
- **Panes** (`run_panel_prompt`): For side-by-side work in same window (dev server + logs)

### Utility Functions

**`adopt()`** - Automatically adopt all running tmux commands in the current session for monitoring. Scans all windows, adopts non-idle commands, and shows a summary notification. Already monitored and idle windows are skipped.

**`show_history()`** - Show command history in Snacks.nvim picker with formatted entries (✓/✗ status icons, timestamps). Select an entry to re-run that command.

**`repeat_last()`** - Re-run the last executed command

**`inspect()`** - Jump to the active runner window (useful for interactive commands)

**`kill()`** - Send Ctrl-C to running command and kill it

**`list_windows()`** - Show all tmux windows in Snacks.nvim picker with **live content preview**. Browse windows, preview their output in real-time, and press Enter to switch to the selected window.

## 🎯 How It Works

### Smart Window Selection (`run_prompt`)

1. Lists all tmux windows: `tmux list-windows`
2. Finds first window running an idle shell (`zsh`, `bash`, `sh`, `fish`)
3. If found → sends command to that window
4. If not found → creates new window with `tmux new-window`

### Smart Pane Selection (`run_panel_prompt`)

1. Lists all tmux panes in current window: `tmux list-panes`
2. Finds first pane running an idle shell (`zsh`, `bash`, `sh`, `fish`)
3. If found → sends command to that pane
4. If not found → creates new pane with `tmux split-window -h` (vertical split)

### Command Monitoring

1. Starts async timer (checks every `monitor_interval` ms)
2. Checks if window is back to idle shell
3. Checks for input prompts (password, confirmations, etc.)
4. When command finishes:
   - Shows completion notification
   - Saves to command history
   - Stops monitoring

### Auto-Prompt for Input

When a monitored command needs user input, the plugin automatically detects it using cursor position and prompts you in Neovim:

**Detection method:**
- Monitors tmux cursor position (`#{cursor_x}`) during command execution
- When cursor is mid-line (cursor_x > 0) and output is stable → prompt is waiting for input
- Captures the last line to show as prompt text in Neovim

**Smart handling:**

1. **Visible prompts** - Auto-prompt in Neovim:
   - `sudo` password prompts
   - `cp -i`, `rm -i`, `mv -i` confirmations
   - Python `input()`, shell `read -p`
   - Any command showing a prompt

2. **Silent stdin waiters** - Notify only:
   - `cat`, `grep` (no args) waiting for input
   - Configurable list in `stdin_waiters.commands`
   - Shows: "⚠️ cat is waiting for input. Press <leader>ri to interact"

3. **Password detection** - Hidden input:
   - Checks prompt text against `password_patterns`
   - Automatically hides characters for password prompts

**Example workflow:**
```
1. Press <leader>rd to run "kamal deploy"
2. Command hits password prompt in tmux
3. Detection: cursor_x=10, last_line="password:"
4. Neovim shows: "Input for kamal (window 2): password:"
5. Type password (hidden), sent to tmux
6. Command hits confirmation: "Deploy to production? (y/n)"
7. Neovim shows: "Input for kamal (window 2): Deploy to production? (y/n)"
8. Type "y", sent to tmux
9. Deploy continues...
```

**Benefits:**
- ✅ No pattern configuration needed - works with any prompt
- ✅ Detects 90%+ of real-world input scenarios
- ✅ Smart handling of edge cases (stdin waiters)
- ✅ Fallback: `<leader>ri` still works for any case

You can customize stdin waiters or disable this feature in configuration.

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

**Adopt existing commands to get notifications:**

Already have commands running in tmux? Use `adopt()` to automatically monitor them all! The plugin will scan all windows, adopt running commands, and notify you when they complete.

```lua
-- Press <leader>ta to adopt all running commands
-- Shows: "✓ Adopted 2 windows, 3 idle, 1 already monitored"
-- Get notified when they finish!
{ "<leader>ta", function() require("tmux-commander").adopt() end }
```

**Keep dev servers in panes, tests in windows:**

```lua
-- Dev server runs in a pane (always visible alongside editor)
{ "<leader>pd", function() require("tmux-commander").run_panel_prompt("npm run dev") end }

-- Tests run in separate window (don't clutter current workspace)
{ "<leader>rt", function() require("tmux-commander").run_prompt("npm test") end }
```

**Auto-prompt handles password and confirmation prompts automatically:**

Commands that need input (passwords, confirmations) are automatically detected. Just type the input in Neovim when prompted - no need to jump to tmux!

```lua
-- The plugin will detect password prompts automatically
{ "<leader>rd", function() require("tmux-commander").run_prompt("kamal deploy") end }
-- When password is needed, you'll see: "Input needed in tmux window 2: password:"

-- You can still manually jump to window if needed
{ "<leader>ri", function() require("tmux-commander").inspect() end }
```

**For interactive commands** (consoles, REPLs), use `inspect()` to jump to the window:

```lua
-- Run console
{ "<leader>rC", function() require("tmux-commander").run_prompt("bin/rails console") end }

-- Jump to it immediately
{ "<leader>ri", function() require("tmux-commander").inspect() end }
```

**Use with which-key** for discoverable commands:

When you press `<leader>r` or `<leader>p`, which-key will show all your defined runner commands.

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

This plugin is in active development. Recent improvements:

- ✅ **Snacks.nvim integration** - Full picker support with live window previews
- ✅ **Auto-adopt** - Automatically monitor all running commands
- ✅ **Live preview** - Real-time tmux window content in picker
- ✅ **Auto-prompt for input** - Automatically detect and prompt for passwords and confirmations

Current limitations:

- Exit code detection assumes success (monitors shell return, not actual exit code)
- Single runner window per session (TODO: support multiple runners)

See [SPEC.md](./SPEC.md) for planned features and detailed specification.

## 📝 License

MIT

---

<div align="center">
  <sub>Built with ❤️ for Neovim and tmux users</sub>
</div>
