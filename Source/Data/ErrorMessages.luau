local Enumeration = script.Parent.Parent.Enumeration

local ErrorType = require(Enumeration.ErrorType)

return {
	[ErrorType.SettingVersionMissMatch] = "[OutSi-Plugin]: Settings Version unique - will not set local setting for %s",
	[ErrorType.InternalPluginError] = "[OutSi-Plugin]: Unexpected plugin error:"
}