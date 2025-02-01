local _E = {}

local debug = require 'sapf.debug'
local commands = require 'sapf.commands'
local config = require 'sapf.config'
local lang = require 'sapf.lang'
-- local help = require 'sapf.help'
local action = require 'sapf.action'

--- Applies keymaps from the user configuration.
-- local function apply_keymaps(mappings)
-- 	print("YAYAYAYAY")
-- 	for key, value in pairs(mappings) do
-- 		-- handle list of keymaps to same key
-- 		if value[1] ~= nil then
-- 			for _, v in ipairs(value) do
-- 				vim.keymap.set(v.modes, key, v.fn, { buffer = true, desc = v.desc or "sapf keymap" })
-- 			end
-- 		else
-- 			vim.keymap.set(value.modes, key, value.fn, { buffer = true, desc = value.desc or "sapf keymap" })
-- 		end
-- 	end
-- end
local function apply_keymaps(mappings)
	for key, value in pairs(mappings) do
		-- debug.log(key .. " -> " .. value)
		-- handle list of keymaps to same key
		if value[1] ~= nil then
			for _, v in ipairs(value) do
				local opts = {
					buffer = true,
					desc = v.options.desc,
				}
				vim.keymap.set(v.modes, key, v.fn, opts)
			end
		else
			local opts = {
				buffer = true,
				desc = value.options.desc,
			}
			vim.keymap.set(value.modes, key, value.fn, opts)
		end
	end
end


local function create_hl_group()
	debug.log("creating highlight group")
	local color = config.editor.highlight.color
	if type(color) == 'string' then
		color = string.format('highlight default link SapfEval %s', color)
	elseif type(color) == 'table' then
		color = string.format(
		'highlight default SapfEval guifg=%s guibg=%s ctermfg=%s ctermbg=%s',
		color.guifg or 'black',
		color.guibg or 'white',
		color.ctermfg or 'black',
		color.ctermbg or 'white'
		)
	end
	vim.cmd(color)
	return color
end

local function create_autocmds()
	local id = vim.api.nvim_create_augroup('sapf_editor', { clear = true })
	-- vim.api.nvim_create_autocmd('VimLeavePre', {
	-- 	group = id,
	-- 	desc = 'exit lang on Nvim exit',
	-- 	pattern = '*',
	-- 	callback = lang.quit,
	-- })
	-- api.nvim_create_autocmd({ 'BufEnter', 'BufNewFile', 'BufRead' }, {
	--   group = id,
	--   desc = 'Set the document path in lang',
	--   pattern = { '*.sapf' },
	--   callback = lang.set_current_path,
	-- })
	vim.api.nvim_create_autocmd('FileType', {
		group = id,
		desc = 'Apply commands',
		pattern = 'sapf',
		callback = commands,
	})
	-- vim.api.nvim_create_autocmd('FileType', {
	-- 	group = id,
	-- 	desc = 'Apply settings',
	-- 	pattern = 'sapf',
	-- 	callback = settings,
	-- })
	vim.api.nvim_create_autocmd('FileType', {
		group = id,
		pattern = 'sapf',
		desc = 'Apply keymaps',
		callback = function()
			apply_keymaps(config.keymaps)
		end,
	})
	if config.editor.force_filetype then
		vim.api.nvim_create_autocmd({
			'BufNewFile',
			'BufRead',
			'BufEnter',
			'BufWinEnter',
		}, {
				group = id,
				desc = 'Set *.sapf to filetype sapf',
				pattern = '*.sapf',
				command = 'set filetype=sapf',
			})
	end
	local hl_cmd = create_hl_group()
	vim.api.nvim_create_autocmd('ColorScheme', {
		group = id,
		desc = 'Reapply custom highlight group',
		pattern = '*',
		command = hl_cmd,
	})
end


local function flash_once(start, finish, delay)
	local ns = vim.api.nvim_create_namespace 'SapfFlash'
	vim.highlight.range(0, ns, 'SapfEval', start, finish, { inclusive = true })
	vim.defer_fn(function()
		vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
	end, delay)
end

local function flash_region(start, finish)
	-- debug.log("region flash")
	local duration = config.editor.highlight.flash.duration
	local repeats = config.editor.highlight.flash.repeats
	if duration == 0 or repeats == 0 then
		return
	end
	local delta = duration / repeats
	flash_once(start, finish, delta)
	if repeats > 1 then
		local count = 0
		local timer = vim.uv.new_timer()
		timer:start(
			duration,
			duration,
			vim.schedule_wrap(function()
				-- debug.log("gonna flash")
				flash_once(start, finish, delta)
				count = count + 1
				if count == repeats - 1 then
					timer:stop()
				end
			end)
		)
	end
end

local function get_range(lstart, lend)
	return vim.api.nvim_buf_get_lines(0, lstart - 1, lend, false)
end

-- _E.on_highlight = action.new(function(start, finish) end)

_E.on_send = action.new(function(lines, callback)
	if callback then
		lines = callback(lines)
	end
	---@diagnostic disable-next-line: missing-parameter
	lang.eval(table.concat(lines, '\n'))
end)

function _E.send_line(cb, flash)
	flash = flash == nil and true or flash
	local linenr = vim.api.nvim_win_get_cursor(0)[1]
	local line = get_range(linenr, linenr)
	debug.log (string.format('line -> %s', line))
	table.insert(line, "\n")
	_E.on_send(line, cb)
	if flash then
		local start = { linenr - 1, 0 }
		local finish = { linenr - 1, #line[1] }
		-- _E.on_highlight(start, finish)
		flash_region(start, finish)
	end
end

vim.api.nvim_set_hl(0, 'SapfEval', {
    fg = '#dcd7ba',
    bg = '#2d4f67',
    default = true,
  })

-- function _E.evaluate(type)
-- 	if type == "block" then
-- 		_E.send_block
-- 	elseif type == "selection" then
-- 	else
-- end

function _E.send_block(cb, flash)
	flash = flash == nil and true or flash
	local lstart, lend = unpack(vim.fn['sapf#editor#get_block']())
	-- debug.log(lstart.." "..lend)
	if lstart == 0 or lend == 0 then
		_E.send_line(cb, flash)
		return
	end
	local lines = get_range(lstart, lend)
	-- local last_line = lines[#lines]
	-- local block_end = string.find(last_line, ')')
	-- lines[#lines] = last_line:sub(1, block_end)

	-- remove parens before sending
	table.remove(lines, 1)
	table.remove(lines, #lines)

	-- if config.debug then
	-- 	for _, line in ipairs(lines) do
	-- 		debug.log(string.format('block -> %s', line))
	-- 	end
	-- end
	-- table.insert(lines, "\n")
	_E.on_send(lines, cb)
	if flash then
		debug.log("flash eval")
		local start = { lstart - 1, 0 }
		local finish = { lend - 1, 0 }
		debug.log(lstart .." ".. lend)
		-- _E.on_highlight(start, finish)
		flash_region(start, finish)
	end
end

function _E.send_selection(cb, flash)
  flash = flash == nil and true or flash
  local ret = vim.fn['scnvim#editor#get_visual_selection']()
  _E.on_send(ret.lines, cb)
  if flash then
    local start = { ret.line_start - 1, ret.col_start - 1 }
    local finish = { ret.line_end - 1, ret.col_end - 1 }
    -- M.on_highlight(start, finish)
	flash_region(start, finish)
  end
end

function _E.setup()
	debug.log("editor setup")
	create_autocmds()
	-- local highlight = config.editor.highlight
	-- if highlight.type == 'flash' then
	-- 	debug.log("setup for flash eval")
	-- 	_E.on_highlight:replace(flash_region)
	-- else -- none
	-- 	_E.on_highlight:replace(function() end)
	-- end
end

return _E
