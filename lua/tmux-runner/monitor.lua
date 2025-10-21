local M = {}

M.active_monitors = {}

-- Start monitoring a command
function M.start(window_index, cmd, config)
  local start_time = vim.loop.now()
  local window = require("tmux-runner.window")
  local history = require("tmux-runner.history")

  -- Notification on start
  if config.notify_on.start then
    vim.notify(string.format("🚀 %s started in window %d", cmd, window_index), vim.log.levels.INFO)
  end

  -- Create timer to check status
  local timer = vim.loop.new_timer()
  M.active_monitors[window_index] = {
    timer = timer,
    cmd = cmd,
    start_time = start_time,
  }

  timer:start(
    config.monitor_interval,
    config.monitor_interval,
    vim.schedule_wrap(function()
      local current_cmd = window.get_window_command(window_index)

      -- Check if back to idle shell
      if current_cmd and window.is_idle_shell(current_cmd, config.idle_shells) then
        -- Command finished
        M.stop(window_index, config)
      end
    end)
  )
end

-- Stop monitoring
function M.stop(window_index, config)
  local monitor = M.active_monitors[window_index]
  if not monitor then
    return
  end

  -- Stop timer
  monitor.timer:stop()
  monitor.timer:close()

  -- Calculate duration
  local duration = math.floor((vim.loop.now() - monitor.start_time) / 1000)

  -- For now, assume success (we'll add exit code detection later)
  local exit_code = 0
  local history = require("tmux-runner.history")
  history.add(monitor.cmd, window_index, exit_code, duration)

  -- Notification on completion
  if config.notify_on.success and exit_code == 0 then
    vim.notify(
      string.format("✅ %s completed (%ds)", monitor.cmd, duration),
      vim.log.levels.INFO
    )
  elseif config.notify_on.failure and exit_code ~= 0 then
    vim.notify(
      string.format("❌ %s failed (exit code %d)", monitor.cmd, exit_code),
      vim.log.levels.ERROR
    )
  end

  M.active_monitors[window_index] = nil
end

-- Kill running command
function M.kill(window_index)
  vim.fn.system(string.format("tmux send-keys -t :%d C-c", window_index))
  M.stop(window_index, require("tmux-runner").config)
end

return M
