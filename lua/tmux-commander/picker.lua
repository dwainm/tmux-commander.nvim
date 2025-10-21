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
      text = string.format("Window %d: %s", win.index, win.command),
      index = win.index,
      command = win.command,
    })
  end

  -- Show picker with preview
  snacks.picker.pick({
    prompt = "Tmux Windows",
    items = items,
    format = function(item)
      return item.text
    end,
    preview = function(item, opts)
      -- Get tmux window content for preview
      local pane_contents = vim.fn.system(string.format("tmux capture-pane -t :%d -p", item.index))
      if vim.v.shell_error == 0 then
        return pane_contents
      else
        return "Preview not available"
      end
    end,
    confirm = function(item)
      -- Focus the selected window
      window.focus_window(item.index)
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
    local time_ago = os.difftime(os.time(), entry.timestamp)
    local status = entry.exit_code == 0 and "✅" or "❌"

    -- Format time ago
    local time_str
    if time_ago < 60 then
      time_str = string.format("%ds ago", time_ago)
    elseif time_ago < 3600 then
      time_str = string.format("%dm ago", math.floor(time_ago / 60))
    elseif time_ago < 86400 then
      time_str = string.format("%dh ago", math.floor(time_ago / 3600))
    else
      time_str = string.format("%dd ago", math.floor(time_ago / 86400))
    end

    table.insert(items, {
      text = string.format("%s %s (%s) - %ds", status, entry.command, time_str, entry.duration),
      command = entry.command,
    })
  end

  -- Show picker
  snacks.picker.pick({
    prompt = "Command History",
    items = items,
    format = function(item)
      return item.text
    end,
    confirm = function(item)
      -- Re-run the selected command
      local commands = require("tmux-commander.commands")
      local config = require("tmux-commander").config
      commands.run(item.command, config)
    end,
  })
end

return M
