-- Hallais David
-- Thanks :)
-- <3
--
local debug = require 'sapf.debug'
debug.log("action factory load")

local action = {}

local _id = 1000
local function get_next_id()
	local next = _id
	_id = _id + 1
	return next
end

function action.new(fn)
	debug.log("new action")
	local self = setmetatable({}, {
		__index = action,
		__call = function(tbl, ...)
			tbl.default_fn(...)
			for _, obj in ipairs(tbl.appended) do
				obj.fn(...)
			end
		end,
	})
	self._default = fn
	self.default_fn = fn
	self.appended = {}
	debug.log("new action done")
	return self
end

function action:replace(fn)
	debug.log("action replace")
	self.default_fn = fn
end

function action:restore()
	debug.log("action restore")
	self.default_fn = self._default
end

function action:append(fn)
	debug.log("action append")
	local id = get_next_id()
	self.appended[#self.appended + 1] = {
		id = id,
		fn = fn,
	}
	return id
end

function action:remove(id)
	debug.log("action remove")
	for i, obj in ipairs(self.appended) do
		if obj.id == id then
			table.remove(self.appended, i)
			return
		end
	end
	error('could not find action with id: ' .. id)
end

return action
