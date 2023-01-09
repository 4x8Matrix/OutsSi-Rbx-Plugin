local ScriptContextService = game:GetService("ScriptContext")
local LogService = game:GetService("LogService")

return function(OutSi)
	local SettingsComponent = OutSi:getComponent("SettingsComponent")

	local LoggerComponent = { }

	LoggerComponent.Interface = { }
	LoggerComponent.Prototype = { }

	LoggerComponent.LastMessageObject = { }

	function LoggerComponent.Prototype:appendMessageObject(messageObject)
		local lastMessage = LoggerComponent.LastMessageObject[OutSi.Enumeration.LogObjectKey.Message]
		local lastMessageType = LoggerComponent.LastMessageObject[OutSi.Enumeration.LogObjectKey.MessageType]

		if
			lastMessage == messageObject[OutSi.Enumeration.LogObjectKey.Message] and
			lastMessageType == messageObject[OutSi.Enumeration.LogObjectKey.MessageType]
		then
			LoggerComponent.LastMessageObject[OutSi.Enumeration.LogObjectKey.RepeatCount] += 1

			return
		end

		if self.instantiatedLogObjectCount + 1 < SettingsComponent:getSetting(OutSi.Enumeration.SettingKey.MaxLogsInMemory) then
			self.instantiatedLogObjectCount += 1
			table.insert(self.instantiatedLogObjects, messageObject)
		else
			table.remove(self.instantiatedLogObjects, 1)
			table.insert(self.instantiatedLogObjects, messageObject)
		end
	end

	function LoggerComponent.Prototype:bindListeners()
		OutSi.pluginJanitor:Add(LogService.MessageOut:Connect(function(message, messageType)
			if not OutSi.Data.MessageTypes[messageType] then
				return
			end

			self:appendMessageObject({
				[OutSi.Enumeration.LogObjectKey.MessageType] = messageType.Value,
				[OutSi.Enumeration.LogObjectKey.Message] = message,
				[OutSi.Enumeration.LogObjectKey.RepeatCount] = 0,
			})
		end))
	end

	function LoggerComponent.Prototype:getAllLogObjects()
		return self.instantiatedLogObjects
	end

	function LoggerComponent.Prototype:clearAllLogObjects()
		LoggerComponent.LastMessageObject = { }

		self.instantiatedLogObjectCount = 0
		self.instantiatedLogObjects = { }
	end

	function LoggerComponent.Prototype:collectLogObjects()
		local logObjects = self:getAllLogObjects()

		self:clearAllLogObjects()

		return logObjects
	end

	function LoggerComponent.Interface.new()
		local self = setmetatable({ }, { __index = LoggerComponent.Prototype })

		self.instantiatedLogObjectCount = 0
		self.instantiatedLogObjects = { }

		self:bindListeners()

		return self
	end

	return LoggerComponent.Interface
end