local M = {}

M.active_monitors = {} -- window monitors
M.active_pane_monitors = {} -- pane monitors

-- Start monitoring a command in a window
function M.start_window(window_index, cmd, config)
  local start_time = vim.loop.now()
  local window = require("tmux-commander.window")

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
        M.stop_window(window_index, config)
      else
        -- Check for input prompts if enabled
        if config.input_prompt and config.input_prompt.enabled then
          local monitor_data = M.active_monitors[window_index]
          if monitor_data and not monitor_data.waiting_for_input then
            local input_detector = require("tmux-commander.input_detector")
            local content = input_detector.capture_pane_content(window_index, true)
            if content then
              local match_info = input_detector.detect_input_prompt(content, config.input_prompt.patterns)
              if match_info then
                -- Mark that we're waiting for input to avoid repeated prompts
                monitor_data.waiting_for_input = true
                input_detector.prompt_and_send(window_index, true, match_info)
                -- Reset flag after a delay to allow for additional prompts
                vim.defer_fn(function()
                  if M.active_monitors[window_index] then
                    M.active_monitors[window_index].waiting_for_input = false
                  end
                end, 5000)
              end
            end
          end
        end
      end
    end)
  )
end

-- Start monitoring a command in a pane
function M.start_pane(pane_index, cmd, config)
  local start_time = vim.loop.now()
  local pane = require("tmux-commander.pane")

  -- Notification on start
  if config.notify_on.start then
    vim.notify(string.format("🚀 %s started in pane %d", cmd, pane_index), vim.log.levels.INFO)
  end

  -- Create timer to check status
  local timer = vim.loop.new_timer()
  M.active_pane_monitors[pane_index] = {
    timer = timer,
    cmd = cmd,
    start_time = start_time,
  }

  timer:start(
    config.monitor_interval,
    config.monitor_interval,
    vim.schedule_wrap(function()
      local current_cmd = pane.get_pane_command(pane_index)

      -- Check if back to idle shell
      if current_cmd and pane.is_idle_shell(current_cmd, config.idle_shells) then
        -- Command finished
        M.stop_pane(pane_index, config)
      else
        -- Check for input prompts if enabled
        if config.input_prompt and config.input_prompt.enabled then
          local monitor_data = M.active_pane_monitors[pane_index]
          if monitor_data and not monitor_data.waiting_for_input then
            local input_detector = require("tmux-commander.input_detector")
            local content = input_detector.capture_pane_content(pane_index, false)
            if content then
              local match_info = input_detector.detect_input_prompt(content, config.input_prompt.patterns)
              if match_info then
                -- Mark that we're waiting for input to avoid repeated prompts
                monitor_data.waiting_for_input = true
                input_detector.prompt_and_send(pane_index, false, match_info)
                -- Reset flag after a delay to allow for additional prompts
                vim.defer_fn(function()
                  if M.active_pane_monitors[pane_index] then
                    M.active_pane_monitors[pane_index].waiting_for_input = false
                  end
                end, 5000)
              end
            end
          end
        end
      end
    end)
  )
end

-- Stop monitoring a window
function M.stop_window(window_index, config)
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
  local history = require("tmux-commander.history")
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

-- Stop monitoring a pane
function M.stop_pane(pane_index, config)
  local monitor = M.active_pane_monitors[pane_index]
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
  local history = require("tmux-commander.history")
  history.add(monitor.cmd, pane_index, exit_code, duration)

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

  M.active_pane_monitors[pane_index] = nil
end

-- Kill running command in window
function M.kill(window_index)
  vim.fn.system(string.format("tmux send-keys -t :%d C-c", window_index))
  M.stop_window(window_index, require("tmux-commander").config)
end

return M
