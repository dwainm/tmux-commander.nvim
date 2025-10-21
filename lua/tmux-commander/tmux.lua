-- lua/tmux-commander/tmux.lua
-- Tmux utility functions for tmux-commander.nvim

local M = {}

-----------------------------------------------------------------------
-- Get window content for preview
-- @param window_id string The window index
-- @return string Window content (captured pane text)
-----------------------------------------------------------------------
function M.get_window_content(window_id)
	local result = vim.fn.system(string.format("tmux capture-pane -t :%s -p -S -50", window_id))
	if vim.v.shell_error ~= 0 then
		return "Failed to capture window content"
	end
	return vim.trim(result)
end

-----------------------------------------------------------------------
-- Get target session (from config or current)
-- @return string Session name or empty string for current
-----------------------------------------------------------------------
local function get_target_session()
	local config = require("tmux-commander").config
	return config.target_session or ""
end

-----------------------------------------------------------------------
-- List all tmux windows with their running commands
-- @return table Array of window objects { id:number, name:string, command:string, active:boolean }
-----------------------------------------------------------------------
function M.list_windows()
	local session = get_target_session()
	local cmd = session ~= ""
		and string.format("tmux list-windows -t '%s' -F '#{window_index}:#{window_name}:#{pane_current_command}:#{window_active}'", session)
		or "tmux list-windows -F '#{window_index}:#{window_name}:#{pane_current_command}:#{window_active}'"

	local result = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		return {}
	end

	local windows = {}
	for line in result:gmatch("[^\r\n]+") do
		local id, name, cmd, active = line:match("^([^:]+):([^:]+):([^:]+):([01])$")
		if id and name and cmd then
			table.insert(windows, {
				id = tonumber(id),
				name = name,
				command = cmd,
				active = (active == "1"),
			})
		end
	end

	return windows
end

-----------------------------------------------------------------------
-- Switch to a specific tmux window
-- @param window_id number The window index to switch to
-----------------------------------------------------------------------
function M.switch_window(window_id)
	vim.fn.system(string.format("tmux select-window -t :%d", window_id))
	if vim.v.shell_error ~= 0 then
		vim.notify("Failed to switch to window: " .. window_id, vim.log.levels.ERROR)
	end
end

return M
