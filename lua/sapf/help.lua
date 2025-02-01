local _H = {}
local lang = require 'sapf.lang'
-- local debug = require 'sapf.debug'

function _H.all()
	lang.eval(string.format("helpall"), 'helpall')
end

function _H.word()
    local word = vim.fn.expand('<cword>')
    if word and word ~= '' then
		---@diagnostic disable-next-line: missing-parameter
        lang.eval(string.format("`%s help", word), 'help')
    end
end

return _H
