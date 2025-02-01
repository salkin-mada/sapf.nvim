local _D = {}

local config = require 'sapf.config'

function _D.log(msg)
    if config.debug then
        vim.notify("<SAPF> " .. msg, vim.log.levels.DEBUG)
    end
end

return _D
