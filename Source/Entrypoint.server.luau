local HttpService = game:GetService("HttpService")

local OutSi = { }

OutSi.Interface = { }
OutSi.Prototype = {
	Packages = {
		["Janitor"] = require(script.Parent.Packages.janitor),
		["Signal"] = require(script.Parent.Packages.signal),
		["Promise"] = require(script.Parent.Packages.promise)
	},
	Enumeration = {
		["ContentType"] = require(script.Parent.Enumeration.ContentType),
		["HeaderType"] = require(script.Parent.Enumeration.HeaderType),
		["HttpKey"] = require(script.Parent.Enumeration.HttpKey),
		["ActionType"] = require(script.Parent.Enumeration.ActionType),
		["LogObjectKey"] = require(script.Parent.Enumeration.LogObjectKey),
		["ErrorType"] = require(script.Parent.Enumeration.ErrorType),
		["StorageKey"] = require(script.Parent.Enumeration.StorageKey),
		["SettingKey"] = require(script.Parent.Enumeration.SettingKey),
		["EndpointKey"] = require(script.Parent.Enumeration.EndpointKey),
		["EndpointType"] = require(script.Parent.Enumeration.EndpointType)
	},
	Data = {
		["ErrorMessages"] = require(script.Parent.Data.ErrorMessages),
		["MessageTypes"] = require(script.Parent.Data.MessageTypes),
		["Settings"] = require(script.Parent.Data.Settings),
		["Endpoint"] = require(script.Parent.Data.Endpoint)
	},

	Version = "0.0.1",
	Plugin = plugin;
}

function OutSi.Prototype:initiateComponentObject(componentModule)
	local componentName = componentModule.Name
	local componentCaller = require(componentModule)

	self.componentInstances[componentName] = componentCaller(self).new()
end

function OutSi.Prototype:initiatePlugin()
	local HttpComponent = self:getComponent("HttpComponent")

	HttpComponent:validateConnectionAsync()

	self.pluginActivated:Fire()
	self.pluginJanitor:Add(plugin.Unloading:Connect(function()
		local HttpComponent = self:getComponent("HttpComponent")

		HttpComponent:requestAsync(self.Enumeration.EndpointType.onAction, HttpService:JSONEncode({
			[self.Enumeration.HttpKey.ActionType] = 1
		}))

		self.pluginDeactivated:Fire()
		self.pluginJanitor:Destroy()
	end))
end

function OutSi.Prototype:getComponent(componentName)
	return self.componentInstances[componentName]
end

function OutSi.Interface.new()
	local self = setmetatable({ }, { __index = OutSi.Prototype })

	self.componentInstances = { }

	self.pluginActivated = self.Packages.Signal.new()
	self.pluginDeactivated = self.Packages.Signal.new()

	self.pluginJanitor = self.Packages.Janitor.new()

	self:initiateComponentObject(script.Parent.Components.SettingsComponent)
	self:initiateComponentObject(script.Parent.Components.LoggerComponent)
	self:initiateComponentObject(script.Parent.Components.HttpComponent)
	self:initiateComponentObject(script.Parent.Components.BatchComponent)

	self:initiatePlugin()

	return self
end

return plugin and OutSi.Interface.new()