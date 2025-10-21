# tmux-runner.nvim - Plugin Specification

A Neovim plugin for smart tmux window management and command execution with notifications.

## Core Features

- **Smart window selection**: Automatically finds idle tmux windows or creates new ones
- **Command monitoring**: Tracks command execution and notifies on completion
- **Command history**: Quick access to previously run commands
- **Which-key integration**: Automatic keymap registration and descriptions
- **Interactive commands**: Support for commands requiring user input (passwords, prompts)

## Installation

```lua
{
  "dwainm/tmux-runner.nvim",
  opts = {
    -- Default behavior
    notification = true,  -- Use vim.notify for completion
    monitor_interval = 2000,  -- Check every 2 seconds
    idle_shells = { "zsh", "bash", "sh", "fish" },  -- What counts as idle
    keymap_prefix = "<leader>r",  -- Key prefix for all commands

    -- Notification preferences
    notify_on = {
      start = true,   -- "🚀 Deploy started in window 2"
      success = true, -- "✅ Deploy completed (5m 32s)"
      failure = true, -- "❌ Deploy failed (exit code 1)"
    },

    -- History settings
    history = {
      enabled = true,
      max_entries = 100,  -- Keep last 100 commands
      -- Stored in vim.fn.stdpath("data") .. "/tmux-runner-history.json"
    },

    -- Define your commands with keymaps
    commands = {
      {
        name = "deploy",
        cmd = "kamal deploy",
        key = "d",  -- Creates <leader>rd
        desc = "Deploy with Kamal",
        opts = {
          confirm = true,  -- Ask "Run 'kamal deploy'? (y/n)" before running
          focus = false,   -- Don't switch to window
          window_name = "deploy",  -- Name tmux window
        },
      },
      {
        name = "test",
        cmd = "bin/rails test",
        key = "t",
        desc = "Run Rails tests",
        opts = {
          timeout = 600,  -- Kill after 10 minutes
        },
      },
      {
        name = "custom",
        cmd = function()
          return vim.fn.input("Command: ")
        end,
        key = "c",
        desc = "Run custom command",
      },
      {
        name = "rails-console",
        cmd = "bin/rails console",
        key = "C",
        desc = "Rails console",
        opts = {
          interactive = true,  -- Mark as interactive (auto-focus on start)
          focus = true,        -- Switch to window immediately
        },
      },
    },
  },
  keys = {
    -- Automatically generated from commands above:
    -- <leader>rd, <leader>rt, <leader>rc, <leader>rC

    -- Built-in utility keymaps
    { "<leader>rh", "<cmd>SmartRunnerHistory<cr>", desc = "Command history" },
    { "<leader>rr", "<cmd>SmartRunnerRepeat<cr>", desc = "Repeat last command" },
    { "<leader>ri", "<cmd>SmartRunnerInspect<cr>", desc = "Jump to runner window" },
    { "<leader>rx", "<cmd>SmartRunnerKill<cr>", desc = "Kill running command" },
    { "<leader>rl", "<cmd>SmartRunnerList<cr>", desc = "List runner windows" },
  },
}
```

## Command Options

Each command can have the following options:

### Required
- `name` (string): Internal identifier for the command
- `cmd` (string|function): Command to run, or function returning command string
- `key` (string): Single key for keymap (prefixed with `keymap_prefix`)
- `desc` (string): Description shown in which-key

### Optional (`opts` table)
- `confirm` (boolean): Prompt user before running (default: false)
- `focus` (boolean): Switch to runner window after starting (default: false)
- `interactive` (boolean): Command needs user input, auto-focus (default: false)
- `window_name` (string): Custom tmux window name (default: auto-generated)
- `timeout` (number): Kill command after N seconds (default: nil/no timeout)
- `cwd` (string): Change to directory before running (default: current dir)
- `env` (table): Environment variables { KEY = "value" }

## Smart Window Selection Logic

1. Query all tmux windows: `tmux list-windows -F '#{window_index}:#{pane_current_command}'`
2. Find first window running idle shell (`zsh`, `bash`, `sh`, `fish`)
3. If found: Send command to that window
4. If not found: Create new window with `tmux new-window -d`
5. Track window index for monitoring

## Command Monitoring

1. Start async timer (check every `monitor_interval` ms)
2. Check if pane is still running: `tmux display -pt :window_index '#{pane_current_command}'`
3. When idle (back to shell):
   - Get exit status from pane history or track separately
   - Show success/failure notification
   - Add to command history
   - Stop timer

## Command History

**Storage:**
- JSON file: `vim.fn.stdpath("data") .. "/tmux-runner-history.json"`
- Format:
  ```json
  [
    {
      "command": "kamal deploy",
      "timestamp": 1729512345,
      "duration": 332,
      "exit_code": 0,
      "window": 2
    }
  ]
  ```

**Interface (<leader>rh):**
- Show picker (Telescope/fzf-lua) with history entries
- Display: `"kamal deploy" (5m 32s ago) ✅`
- Select: Re-run that command
- Format: `"{cmd}" ({time_ago}) {status_icon}`

**Features:**
- Max entries configurable
- Sorted by most recent
- Shows success/failure status
- Shows duration and time ago

## Built-in Commands

### `<leader>rh` - SmartRunnerHistory
Open picker with command history. Select to re-run.

### `<leader>rr` - SmartRunnerRepeat
Re-run the last executed command (no picker).

### `<leader>ri` - SmartRunnerInspect
Jump to the active runner window (for interactive commands).

### `<leader>rx` - SmartRunnerKill
Send Ctrl-C to running command and kill it.

### `<leader>rl` - SmartRunnerList
Show all runner windows currently open.

## Notification Examples

**On Start:**
```
🚀 Deploy started in window 2
```

**On Success:**
```
✅ Deploy completed (5m 32s)
```

**On Failure:**
```
❌ Deploy failed (exit code 1)
Click to view output
```

**Interactive Waiting:**
```
⏳ Rails console waiting for input (window 3)
Press <leader>ri to jump
```

## Which-key Integration

When user presses `<leader>r`, which-key shows:

```
Runner
  d → Deploy with Kamal
  t → Run Rails tests
  c → Run custom command
  C → Rails console
  ─────────────────────
  h → Command history
  r → Repeat last command
  i → Jump to runner window
  x → Kill running command
  l → List runner windows
```

## Implementation Notes

### File Structure
```
tmux-runner.nvim/
├── lua/
│   └── tmux-runner/
│       ├── init.lua          # Main plugin entry
│       ├── window.lua         # Window selection logic
│       ├── monitor.lua        # Command monitoring
│       ├── history.lua        # History management
│       ├── notifications.lua  # Notification helpers
│       └── commands.lua       # Command registry
├── SPEC.md                    # This file
└── README.md                  # User documentation
```

### Dependencies
- Neovim 0.9+ (for async, vim.loop)
- tmux 3.0+
- Optional: Telescope or fzf-lua (for history picker)
- Optional: which-key.nvim (for keymap display)

## Future Enhancements

- [ ] Multiple runner windows (tmux sessions per project)
- [ ] Output capture and display in Neovim buffer
- [ ] Integration with DAP for debugging
- [ ] Command templates with variable substitution
- [ ] Per-project command configurations
- [ ] Command chaining/pipelines
