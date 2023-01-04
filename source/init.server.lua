local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local RunService = game:GetService("RunService")

local MESSAGE_KEY = "message"
local MESSAGE_TYPE_KEY = "messageType"

local HTTP_LIMIT_THROTTLE_PERCENT = 35

local HTTP_LIMIT_PER_SECOND = 500
local HTTP_LIMIT_RESET = 1

local CYCLE_DELIVERY_TIME = HTTP_LIMIT_RESET / (HTTP_LIMIT_PER_SECOND / HTTP_LIMIT_THROTTLE_PERCENT)

local BASE_NETWORK_URL = "http://127.0.0.1:3012"

local REPORT_API_BASE = "/api/report"
local ACTION_API_BASE = "/api/action"
local IDENTIFY_API_BASE = "/api/identify"

local NETWORK_URL_PATTERN = "%s%s"

local Scheduler = require(script.Scheduler)

local OutSi = { }

OutSi.Interface = { }
OutSi.Prototype = { }

OutSi.ActionTypes = {
	["RunModeChanged"] = 0
}

function OutSi.Prototype:postAsync(...)
	local success, exceptionMessage = pcall(HttpService.RequestAsync, HttpService, {
		Url = select(1, ...),
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = select(2, ...)
	})

	if not success or (exceptionMessage and not exceptionMessage.Success) then
		warn("[OutSi-Plugin]: Error when transmitting request:", exceptionMessage)
		warn("[OutSi-Plugin]: Attempting to re-establish VSCode connection")

		self._vscPluginConnected = false

		self:connectToVscServer()
	end
end

function OutSi.Prototype:pushRemoteLogs()
	if not self._vscPluginConnected then
		return
	end

	local localbatchStore = self.batch
	self.batch = { }

	return self:postAsync(
		string.format(NETWORK_URL_PATTERN, BASE_NETWORK_URL, REPORT_API_BASE),
		HttpService:JSONEncode({
			["batch"] = localbatchStore
		})
	)
end

function OutSi.Prototype:pushRemoteAction(actiionType)
	if not self._vscPluginConnected then
		return
	end

	return self:postAsync(
		string.format(NETWORK_URL_PATTERN, BASE_NETWORK_URL, ACTION_API_BASE),
		HttpService:JSONEncode({
			["action"] = actiionType
		})
	)
end

function OutSi.Prototype:destroy()
	for _, connectionInstance in self.connections do
		connectionInstance:Disconnect()
	end

	self._destroyed = true
end

function OutSi.Prototype:connectToVscServer()
	self._vscPluginConnected = false

	while task.wait(0.5) do
		local success, response = pcall(HttpService.PostAsync, HttpService, string.format(NETWORK_URL_PATTERN, BASE_NETWORK_URL, IDENTIFY_API_BASE), { })
		local responseJson = success and HttpService:JSONDecode(response)

		if self._destroyed then
			return
		end

		if not success then
			continue
		end

		self._vscPluginVersion = responseJson.version
		self._vscPluginConnected = true

		return
	end
end

function OutSi.Prototype:instantiate()
	local runModeState = RunService:IsRunMode()

	self:connectToVscServer()

	table.insert(self.connections, RunService.Stepped:Connect(function()
		local localRunModeState = RunService:IsRunMode()

		if localRunModeState ~= runModeState then
			runModeState = localRunModeState

			self:pushRemoteAction(
				OutSi.ActionTypes.RunModeChanged
			)
		end
	end))

	---

	table.insert(self.connections, plugin.Unloading:Connect(function()
		self:destroy()
	end))

	table.insert(self.connections, LogService.MessageOut:Connect(function(message, messageType)
		table.insert(self.batch, {
			[MESSAGE_KEY] = message,
			[MESSAGE_TYPE_KEY] = messageType.Value
		})
	end))
end

function OutSi.Interface.new()
	local self = setmetatable({
		Scheduler = Scheduler.new(),

		batch = { },
		connections = { },

		_vscPluginConnected = false
	}, { __index = OutSi.Prototype })

	self.Scheduler:setCycleDelay(CYCLE_DELIVERY_TIME)
	self.Scheduler:setCycleState(true)

	self:instantiate()

	self.Scheduler:bindCycleHandler(function()
		if not self._vscPluginConnected then
			return
		end

		if #self.batch <= 0 then
			return
		end

		self:pushRemoteLogs()
	end)

	return self
end

return OutSi.Interface.new()