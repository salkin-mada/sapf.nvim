local _C = {}

local defaults = {
    lang = {
		executable = "sapf",
		prelude = ""
	},
	editor = {
		force_filetype = true,
		highlight = {
			-- color = 'TermCursor',
			color = 'yellow',
			type = 'flash',
			flash = {
				duration = 135,
				repeats = 4,
			}
		}
	},
	keymaps = {
	},
    window = {
        size = 0.35,
        position = "bottom",
        border = "double",
		wrap = false,
		buffer = {
			name = "sapf repl",
		}
    },
    debug = false,
}

setmetatable(_C, {
  __index = function(self, key)
    local config = rawget(self, 'config')
    if config then
      return config[key]
    end
    return defaults[key]
  end,
})

function _C.merge(config)
  config = config or {}
  _C.config = vim.tbl_deep_extend('keep', config, defaults)
end

return _C
