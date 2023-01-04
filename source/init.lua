local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local RunService = game:GetService("RunService")

local MESSAGE_KEY = "message"
local MESSAGE_TYPE_KEY = "messageType"

local HTTP_LIMIT_THROTTLE_PERCENT = 35

local HTTP_LIMIT_PER_SECOND = 500
local HTTP_LIMIT_RESET = 1

local CYCLE_DELIVERY_TIME = HTTP_LIMIT_RESET / (HTTP_LIMIT_PER_SECOND / HTTP_LIMIT_THROTTLE_PERCENT)

local BASE_NETWORK_URL = "https://localhost:3012"

local REPORT_API_BASE = "/api/report"
local ACTION_API_BASE = "/api/action"

local NETWORK_URL_PATTERN = "%s%s"

local Scheduler = require(script.Scheduler)

local OutSi = { }

OutSi.Interface = { }
OutSi.Prototype = { }

OutSi.ActionTypes = {
	["RunModeChanged"] = 0
}

function OutSi.Prototype:pushRemoteLogs()
	local localBatchStore = self.Batch
	self.Batch = { }

	return HttpService:PostAsync(
		string.format(NETWORK_URL_PATTERN, BASE_NETWORK_URL, REPORT_API_BASE),
		HttpService:JSONEncode({
			["batch"] = localBatchStore
		}),
		Enum.HttpContentType.ApplicationJson
	)
end

function OutSi.Prototype:pushRemoteAction(actiionType)
	return HttpService:PostAsync(
		string.format(NETWORK_URL_PATTERN, BASE_NETWORK_URL, ACTION_API_BASE),
		HttpService:JSONEncode({
			["action"] = actiionType
		}),
		Enum.HttpContentType.ApplicationJson
	)
end

function OutSi.Prototype:destroy()
	for _, connectionInstance in self.Connections do
		connectionInstance:Disconnect()
	end
end

function OutSi.Prototype:instantiate()
	local runModeState = RunService:IsRunMode()

	table.insert(self.Connections, RunService.RenderStepped:Connect(function()
		local localRunModeState = RunService:IsRunMode()

		if localRunModeState ~= runModeState then
			runModeState = localRunModeState

			self:pushRemoteAction(
				OutSi.ActionTypes.RunModeChanged
			)
		end
	end))

	---

	table.insert(self.Connections, plugin.Unloading:Connect(function()
		self:destroy()
	end))

	table.insert(self.Connections, LogService.MessageOut:Connect(function(message, messageType)
		table.insert(self.Batch, {
			[MESSAGE_KEY] = message,
			[MESSAGE_TYPE_KEY] = messageType.Name
		})
	end))
end

function OutSi.Interface.new()
	local self = setmetatable({
		Scheduler = Scheduler.new(),
		Connections = { }, Batch = { }
	}, { __index = OutSi.Prototype })

	self.Scheduler:setCycleDelay(CYCLE_DELIVERY_TIME)
	self.Scheduler:setCycleState(true)

	for key, value in LogService:GetLogHistory() do
		self.Batch[key] = {
			[MESSAGE_KEY] = value.message,
			[MESSAGE_TYPE_KEY] = value.messageType.Name
		}
	end

	self:instantiate()

	self.Scheduler:bind(function()
		self:pushRemoteLogs()
	end)

	return self
end

return OutSi.Interface.new()