local lang = require 'sapf.lang'

local function add_command(name, fn, desc)
	vim.api.nvim_buf_create_user_command(0, name, fn, { desc = desc })
end


local group = vim.api.nvim_create_augroup("SapfCommands", { clear = true })
vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = lang.quit })
return function()
	-- add_command('APL_start', lang.start, '..')
	add_command("SapfStart", lang.start, 'start sapf')
	add_command("SapfQuit", lang.quit, 'quit sapf')
	end

