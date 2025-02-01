local sapf = {}
local lang = require 'sapf.lang'
local config = require 'sapf.config'
local editor = require 'sapf.editor'
local debug = require 'sapf.debug'
local help = require 'sapf.help'

function sapf.health()
    local health = require("health")
    health.report_start("sapf")
    if vim.fn.executable(config.lang.executable) == 1 then
        health.report_ok(config.lang.executable .. " is executable")
    else
        health.report_error(config.lang.executable .. " is not executable")
    end
end

local map = require 'sapf.map'
sapf.map = map.map

function sapf.setup(conf)
	debug.log("init setup")
	conf = conf or {}
    if type(conf) ~= "table" and conf ~= nil then
        error("expected table or nil for config - got " .. type(conf))
    end
	config.merge(conf)
	debug.log("configs merged")
	editor.setup()
	help.setup()
    debug.log("done setting up sapf")
end

function sapf.start()
	lang.start()
end
function sapf.quit()
	lang.quit()
end

return sapf
