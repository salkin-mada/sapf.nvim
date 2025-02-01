-- Hallais David
-- Thanks :)
-- <3
--

_M = {}
local debug = require 'sapf.debug'

debug.log("creating map factory")

local modules = {
  'editor',
  'lang',
  'sapf',
  'help',
}

local function validate(str)
  local module, fn = unpack(vim.split(str, '.', { plain = true }))
  if not fn then
    error(string.format('"%s" is not a valid input string to map', str), 0)
  end
  local res = vim.tbl_filter(function(m)
    return module == m
  end, modules)
  local valid_module = #res == 1
  if not valid_module then
    error(string.format('"%s" is not a valid module to map', module), 0)
  end
  if module ~= 'sapf' then
    module = 'sapf.' .. module
  end
  return module, fn
end

_M.map = setmetatable({}, {
  __call = function(_, fn, modes, options)
    modes = type(modes) == 'string' and { modes } or modes
    modes = modes or { 'n' }
    options = options or {
      desc = type(fn) == 'string' and ('scnvim: ' .. fn) or 'scnvim keymap',
    }
    if type(fn) == 'string' then
      local module, cmd = validate(fn)
      local wrapper = function()
        if module == 'scnvim.editor' then
          require(module)[cmd](options.callback, options.flash)
        else
          require(module)[cmd]()
        end
      end
      return { modes = modes, fn = wrapper, options = options }
    elseif type(fn) == 'function' then
      return { modes = modes, fn = fn, options = options }
    end
  end,
})

return _M
