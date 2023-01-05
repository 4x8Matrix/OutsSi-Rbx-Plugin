return function(OutSi)
	local LoggerComponent = OutSi:getComponent("LoggerComponent")
	local HttpComponent = OutSi:getComponent("HttpComponent")
	local SettingsComponent = OutSi:getComponent("SettingsComponent")

	local BatchComponent = { }

	BatchComponent.Interface = { }
	BatchComponent.Prototype = { }

	function BatchComponent.Prototype:instantiateScheduledLoopFunction()
		return function()
			while true do
				if not HttpComponent.isConnected then
					HttpComponent.httpServerConnected:Wait()
				end

				local httpLimitReset = SettingsComponent:getSetting(OutSi.Enumeration.SettingKey.HttpLimitReset)
				local httpLimitPerSecond = SettingsComponent:getSetting(OutSi.Enumeration.SettingKey.HttpLimitPerSecond)
				local httpResourcePercent = SettingsComponent:getSetting(OutSi.Enumeration.SettingKey.HttpResourcePercent)

				HttpComponent:uploadBatch(LoggerComponent:collectLogObjects())

				task.wait(httpLimitReset / (httpLimitPerSecond /httpResourcePercent ))
			end
		end
	end

	function BatchComponent.Interface.new()
		local self = setmetatable({ }, { __index = BatchComponent.Prototype })

		self.scheduleThread = task.spawn(self:instantiateScheduledLoopFunction())

		OutSi.pluginJanitor:Add(function()
			task.cancel(self.scheduleThread)
		end)

		return self
	end

	return BatchComponent.Interface
end