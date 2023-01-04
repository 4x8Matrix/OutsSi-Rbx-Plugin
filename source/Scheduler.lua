local Scheduler = { }

Scheduler.Interface = { }
Scheduler.Prototype = { }

Scheduler.Prototype._className = "Scheduler"

function Scheduler.Prototype:setCycleDelay(value) self._delay = value end
function Scheduler.Prototype:setCycleState(state) self._state = state end
function Scheduler.Prototype:unbindAll() self._bindedFunctions = { } end

function Scheduler.Prototype:bind(callback)
	table.insert(self._bindedFunctions, callback)

	return function()
		local index = table.find(self._bindedFunctions, callback)

		if index then
			table.remove(self._bindedFunctions, index)
		end
	end
end

function Scheduler.Prototype:executeCycle(deltaTime)
	for _, callback in self._bindedFunctions do
		callback(deltaTime)
	end
end

function Scheduler.Prototype:destroy()
	self:unbindAll()

	task.cancel(self._cycleThread)
end

function Scheduler.Interface.is(object)
	return object._className == Scheduler.Prototype._className
end

function Scheduler.Interface.new()
	local self = setmetatable({
		_delay = 0,
		_state = false,

		_bindedFunctions = { }
	}, { __index = Scheduler.Prototype })

	self._cycleThread = task.spawn(function()
		while true do
			self._deltaTime = task.wait(self._delay)

			if self._state then
				self:executeCycle(self._deltaTime)
			end
		end
	end)

	return self
end

return Scheduler.Interface