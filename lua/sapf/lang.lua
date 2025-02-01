local _L = {}
local config = require 'sapf.config'
local debug = require 'sapf.debug'
local replwin = require 'sapf.replwin'

local job, buffer_id

local function create_repl_buffer()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, "*" .. config.window.buffer.name .. "*")
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'hide'
    vim.bo[buf].fileformat = "unix"
    vim.bo[buf].swapfile = false
    debug.log("created repl buffer: " .. buf)
    return buf
end

local function create_repl_window()
    local width = math.floor(vim.o.columns * config.window.size)
    local height = math.floor(vim.o.lines * config.window.size)
    -- local height = vim.o.lines - 4

    local win_conf = {
        -- relative = 'editor',
		-- split = config.window.position or 'left',
		split = 'below',
		vertical = false,
        width = width,
        height = height,
    }

    local win = vim.api.nvim_open_win(buffer_id, false, win_conf)
    for option, value in pairs(replwin.WIN_OPTS) do
        vim.wo[win][option] = value
    end
    debug.log("Created new window: " .. win)
    return win
end

--- create repl buffer
local function repl_buffer()
    if not buffer_id or not vim.api.nvim_buf_is_valid(buffer_id) then
        buffer_id = create_repl_buffer()
    end
end

local function close_floating_help(bufnr, winid)
	vim.api.nvim_win_close(winid, true)
	vim.api.nvim_buf_delete(bufnr, { force = true })
end


local function create_help_buffer()
	buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, "*" .. " sapf-help " .. "*")
	vim.api.nvim_set_option_value("buftype", "nofile",{buf=buf})
	vim.api.nvim_set_option_value("bufhidden", "hide",{buf=buf})
	vim.api.nvim_set_option_value("filetype", "sapf",{buf=buf})
	-- vim.api.nvim_set_option_value("swapfile", false,{buf=buf})
	debug.log("created help buffer: " .. buf)
	return buf
end

local function help_buffer()
	if not help_buffer_id or not vim.api.nvim_buf_is_valid(help_buffer_id) then
        help_buffer_id = create_help_buffer()
    end
end

local function open_help_win()
	local opts = {
		footer = "sapf help",
		border = "rounded",
		relative = "editor",
		style = "minimal",
		height = math.ceil(vim.o.lines * 0.5),
		width = math.ceil(vim.o.columns * 0.5),
		row = 1,
		col = math.ceil(vim.o.columns * 0.5),
	}
	win_id = vim.api.nvim_open_win(help_buffer_id, true, opts)
	vim.api.nvim_win_set_cursor(0, {1, 0})

	vim.keymap.set('n', 'q', function()
		close_floating_help(help_buffer_id, win_id)
	end, { buffer = help_buffer_id, noremap = true, silent = true })
	-- vim.api.nvim_buf_attach(help_buffer_id, false, {
	-- 	on_detach = function()
	-- 		close_floating_help(help_buffer_id, win_id)
	-- 	end
	-- })
end

local function remove_evaluated(line)
		if string.match(line, "sapf> ") then
		if line ~= "sapf> stop" and line ~= "sapf> clear" and line ~= "sapf> cleard" then
			return ""  -- remove entire line
		else
			line = line:gsub("sapf> ", "")
		end
	end
	if string.match(line, "\\sapf> ") then
		return ""  -- remove entire line
	end
	line = line:gsub("{sapf> ", "")
	line = line:gsub("%(sapf> ", "")
	line = line:gsub("^%s+", "")
    return line
end

_L.stdout_behavior = 'vanilla'
local buffer = ""
local function on_stdout(_, data, _)
    if not (data and #data > 0) then return end
	debug.log("stdout behavior: " .. tostring(_L.stdout_behavior))
	if _L.stdout_behavior == 'vanilla' then
		vim.schedule(function()
			if not (buffer_id and vim.api.nvim_buf_is_valid(buffer_id)) then return end
			local text = table.concat(data, "")
			buffer = buffer .. text
			local lines = {}
			for line in buffer:gmatch("[^\r\n]+") do
				-- line = remove_evaluated(line)
				if line ~= "" then
					lines[#lines + 1] = line
				end
			end
			if text:match("[\r\n]$") then
				buffer = ""
			else
				buffer = lines[#lines] or ""
				lines[#lines] = nil
			end

			-- -- Helper table to track unique items
			-- local unique_items = {}
			-- local result = {}
			-- -- Iterate over the original table
			-- for _, v in ipairs(lines) do
			-- 	-- Check if the item has not been seen before
			-- 	if not unique_items[v] then
			-- 		-- If it's unique, add it to the result table and mark it as seen
			-- 		table.insert(result, v)
			-- 		unique_items[v] = true
			-- 	end
			-- end
			-- lines = result


			if #lines > 0 then
				pcall(function()
					vim.api.nvim_buf_set_lines(buffer_id, -1, -1, false, lines)
					local win_id = vim.fn.bufwinid(buffer_id)
					if win_id ~= -1 then
						vim.api.nvim_win_set_cursor(win_id, { vim.api.nvim_buf_line_count(buffer_id), 0 })
					end
				end)
			end
		end)
	else
		if _L.stdout_behavior == 'help' then
			local line = data[1]
			line = line:gsub("\r", "")
			vim.lsp.util.open_floating_preview({ line }, 'sapf', {focusable = false, border = 'single'})
		end
		if _L.stdout_behavior == 'helpall' then
			help_buffer()
			open_help_win()
			for i,line in ipairs(data) do
				line = line:gsub("sapf> ", "") -- remove <sapf
				line = line:gsub("\r", "") -- remove ^M
				vim.api.nvim_buf_set_lines(help_buffer_id, i-1, i-1, true, { line })
			end
		end
	end
end

local function open_replwin()
    if vim.fn.bufwinid(buffer_id) == -1 and buffer_id then
        create_repl_window()
    end
end

function _L.start()
    if job then
        vim.notify("A sapf process is already running", vim.log.levels.ERROR)
        return
    end
    repl_buffer()
    open_replwin()

	local cmd = config.lang.executable
	local flag = ""
	local pre = ""
	if config.lang.prelude then
		print(string.format('using prelude: %s', config.lang.prelude))
		-- cmd = config.lang.executable .. ' -p ' .. config.lang.prelude
		flag = '-p'
		pre = config.lang.prelude
	end

    local job_opts = {
        on_stdout = on_stdout,
        on_stderr = on_stdout,
        stdout_buffered = false,
        stderr_buffered = false,
        pty = true,
    }
	job = vim.fn.jobstart({cmd, flag, pre}, job_opts)
	--   local job_opts = {
		-- text = true,
		-- stdin = true
		--   }
		-- job = vim.system({cmd, flag, pre}, job_opts)
    if job <= 0 then
        vim.notify("starting sapf process failed", vim.log.levels.ERROR)
        return
    end
    vim.api.nvim_buf_set_lines(buffer_id, 0, -1, false, {})
    debug.log("started sapf process with id: " .. job)
end

function _L.stop()
	---@diagnostic disable-next-line: missing-parameter
    _L.eval("stop")
end

function _L.clear()
	---@diagnostic disable-next-line: missing-parameter
    _L.eval("clear")
end
function _L.cleard()
	---@diagnostic disable-next-line: missing-parameter
    _L.eval("cleard")
end

function _L.quit()
    if job then
        vim.fn.jobstop(job)
        job = nil
        if buffer_id and vim.api.nvim_buf_is_valid(buffer_id) then
            vim.api.nvim_buf_delete(buffer_id, { force = true })
            buffer_id = nil
        end
        debug.log("quit sapf process")
    end
end

-- evaluated = {""}
BLOCK = 16
--- @param str string
--- @param stdout_behavior string
--- @return nil
function _L.eval(str, stdout_behavior)
	_L.stdout_behavior = stdout_behavior or 'vanilla'
    if not job then
        vim.notify("sapf process NOT running", vim.log.levels.ERROR)
        return
    end
    open_replwin()
    str = vim.trim(str) .. "\n"
	-- evaluated = vim.split(str, "\n")
    local result, error = pcall(function()
        for i = 1, #str, BLOCK do
            vim.fn.chansend(job, string.sub(str, i, i + BLOCK - 1))
        end
    end)
    if not result then
        vim.notify("chansend failed sending: " .. tostring(error), vim.log.levels.ERROR)
    end
end

return _L
