local M = {}

M.commands = {}  -- Simple key-value: { deploy = "kamal deploy" }
M.last_command = nil

-- Set commands from config
function M.set_commands(commands)
  M.commands = commands
end

-- Internal function to execute a command
local function execute_command(cmd, config)
  if not cmd or cmd == "" then
    return
  end

  local window = require("tmux-runner.window")
  local monitor = require("tmux-runner.monitor")

  -- Find or create window
  local window_index, err = window.find_or_create_window(config.idle_shells)
  if not window_index then
    vim.notify("Failed to find window: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Send command
  local success, send_err = window.send_command(window_index, cmd)
  if not success then
    vim.notify("Failed to send command: " .. (send_err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Start monitoring
  monitor.start(window_index, cmd, config)

  -- Store as last command
  M.last_command = cmd
end

-- Run a named command from config
function M.run(name, config)
  local cmd = M.commands[name]

  if not cmd then
    vim.notify(string.format("Command '%s' does not exist", name), vim.log.levels.ERROR)
    return
  end

  execute_command(cmd, config)
end

-- Run a custom command (from prompt)
function M.run_custom(cmd, config)
  execute_command(cmd, config)
end

-- Repeat last command
function M.repeat_last(config)
  if not M.last_command then
    vim.notify("No previous command", vim.log.levels.WARN)
    return
  end

  execute_command(M.last_command, config)
end

return M
