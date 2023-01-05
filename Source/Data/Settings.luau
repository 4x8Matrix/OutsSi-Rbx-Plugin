local Enumeration = script.Parent.Parent.Enumeration

local SettingKey = require(Enumeration.SettingKey)

return {
	[SettingKey.HttpLimitPerSecond] = 500,
	[SettingKey.HttpLimitReset] = 1,

	[SettingKey.HttpResourcePercent] = 25,
	[SettingKey.MaxLogsInMemory] = 50000,

	[SettingKey.AttemptDelay] = 2
}