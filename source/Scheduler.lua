local Scheduler = { }

Scheduler.Interface = { }
Scheduler.Prototype = { }

Scheduler.Prototype._className = "Scheduler"

function Scheduler.Prototype:setCycleDelay(value) self._delay = value end
function Scheduler.Prototype:setCycleState(state) self._state = state end
function Scheduler.Prototype:unbindAll() self._bindedFunctions = { } end

function Scheduler.Prototype:bindErrorHandler(callback)
	table.insert(self._bindedFunctions.errorHandlers, callback)

	return function()
		local index = table.find(self._bindedFunctions.errorHandlers, callback)

		if index then
			table.remove(self._bindedFunctions.errorHandlers, index)
		end
	end
end

function Scheduler.Prototype:bindCycleHandler(callback)
	table.insert(self._bindedFunctions.cycleHandlers, callback)

	return function()
		local index = table.find(self._bindedFunctions.cycleHandlers, callback)

		if index then
			table.remove(self._bindedFunctions.cycleHandlers, index)
		end
	end
end

function Scheduler.Prototype:executeCycle(deltaTime)
	for _, callback in self._bindedFunctions.cycleHandlers do
		xpcall(callback, function(exceptionMessage)
			for _, callback in self._bindedFunctions.errorHandlers do
				xpcall(callback, function()
					error("[OutSi-Plugin]: Internal Cycle error in error handler!")
				end, exceptionMessage)
			end
		end, deltaTime)
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

		_bindedFunctions = {
			errorHandlers = { },
			cycleHandlers = { }
		}
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