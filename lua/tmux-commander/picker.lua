local M = {}

-- Show windows in a picker with tmux preview
function M.show_windows()
  local window = require("tmux-commander.window")
  local windows, err = window.list_windows()

  if not windows then
    vim.notify("Failed to list windows: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  if #windows == 0 then
    vim.notify("No tmux windows found", vim.log.levels.INFO)
    return
  end

  -- Check if snacks is available
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    -- Fallback to simple notification
    local lines = {}
    for _, win in ipairs(windows) do
      table.insert(lines, string.format("Window %d: %s", win.index, win.command))
    end
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
    return
  end

  -- Format windows for picker
  local items = {}
  for _, win in ipairs(windows) do
    table.insert(items, {
      idx = win.index,
      cmd = win.command,
    })
  end

  -- Show picker with preview
  snacks.picker.pick({
    prompt = "Tmux Windows",
    items = items,
    format = function(item)
      return { string.format("Window %d: %s", item.idx, item.cmd) }
    end,
    preview = function(item, opts)
      -- Get tmux window content for preview
      local pane_contents = vim.fn.system(string.format("tmux capture-pane -t :%d -p", item.idx))
      if vim.v.shell_error == 0 then
        return vim.split(pane_contents, "\n")
      else
        return { "Preview not available" }
      end
    end,
    confirm = function(item)
      -- Focus the selected window
      window.focus_window(item.idx)
    end,
  })
end

-- Show history in a picker
function M.show_history()
  local history = require("tmux-commander.history")
  local entries = history.get()

  if #entries == 0 then
    vim.notify("No command history", vim.log.levels.INFO)
    return
  end

  -- Check if snacks is available
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    vim.notify(string.format("Command history has %d entries", #entries), vim.log.levels.INFO)
    return
  end

  -- Format history entries
  local items = {}
  for i = #entries, 1, -1 do
    local entry = entries[i]
    local time_ago = os.difftime(os.time(), entry.timestamp or os.time())
    local status = (entry.exit_code or 0) == 0 and "✅" or "❌"

    -- Format time ago
    local time_str
    if time_ago < 60 then
      time_str = string.format("%ds ago", math.floor(time_ago))
    elseif time_ago < 3600 then
      time_str = string.format("%dm ago", math.floor(time_ago / 60))
    elseif time_ago < 86400 then
      time_str = string.format("%dh ago", math.floor(time_ago / 3600))
    else
      time_str = string.format("%dd ago", math.floor(time_ago / 86400))
    end

    table.insert(items, {
      cmd = entry.command or "unknown",
      status_icon = status,
      time = time_str,
      duration = entry.duration or 0,
    })
  end

  -- Show picker
  snacks.picker.pick({
    prompt = "Command History",
    items = items,
    format = function(item)
      return { string.format("%s %s (%s) - %ds", item.status_icon or "?", item.cmd or "unknown", item.time or "?", item.duration or 0) }
    end,
    confirm = function(item)
      -- Re-run the selected command
      local commands = require("tmux-commander.commands")
      local config = require("tmux-commander").config
      commands.run(item.cmd, config)
    end,
  })
end

-- Show windows/panes with running commands and adopt selected one
function M.show_adopt()
  local window = require("tmux-commander.window")
  local pane = require("tmux-commander.pane")
  local commands = require("tmux-commander.commands")
  local config = require("tmux-commander").config

  -- Get all windows
  local windows, err = window.list_windows()
  if not windows then
    vim.notify("Failed to list windows: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Get all panes in current window
  local panes, pane_err = pane.list_panes()
  if not panes then
    panes = {}
  end

  -- Build list of adoptable items (running commands, not idle)
  local items = {}

  -- Add windows with running commands
  for _, win in ipairs(windows) do
    if not window.is_idle_shell(win.command, config.idle_shells) then
      table.insert(items, {
        type = "window",
        idx = win.index,
        cmd = win.command,
      })
    end
  end

  -- Add panes with running commands
  for _, p in ipairs(panes) do
    if not pane.is_idle_shell(p.command, config.idle_shells) then
      table.insert(items, {
        type = "pane",
        idx = p.index,
        cmd = p.command,
      })
    end
  end

  if #items == 0 then
    vim.notify("No running commands to adopt", vim.log.levels.INFO)
    return
  end

  -- Check if snacks is available
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    -- Fallback to simple notification
    local lines = {}
    for _, item in ipairs(items) do
      table.insert(lines, string.format("%s %d: %s", item.type, item.idx, item.cmd))
    end
    vim.notify("Running commands:\n" .. table.concat(lines, "\n"), vim.log.levels.INFO)
    return
  end

  -- Show picker
  snacks.picker.pick({
    prompt = "Adopt Command",
    items = items,
    format = function(item)
      return { string.format("%s %d: %s", item.type == "window" and "Window" or "Pane", item.idx, item.cmd) }
    end,
    preview = function(item, opts)
      if item.type == "window" then
        local pane_contents = vim.fn.system(string.format("tmux capture-pane -t :%d -p", item.idx))
        if vim.v.shell_error == 0 then
          return vim.split(pane_contents, "\n")
        end
      else
        local pane_contents = vim.fn.system(string.format("tmux capture-pane -t %d -p", item.idx))
        if vim.v.shell_error == 0 then
          return vim.split(pane_contents, "\n")
        end
      end
      return { "Preview not available" }
    end,
    confirm = function(item)
      if item.type == "window" then
        commands.adopt_window(item.idx, config)
      else
        commands.adopt_pane(item.idx, config)
      end
    end,
  })
end

return M
