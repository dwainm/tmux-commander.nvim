local M = {}

M.last_command = nil

-- Execute a command
function M.run(cmd, config)
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

-- Repeat last command
function M.repeat_last(config)
  if not M.last_command then
    vim.notify("No previous command", vim.log.levels.WARN)
    return
  end

  M.run(M.last_command, config)
end

return M
