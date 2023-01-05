return function(OutSi)
	local SettingsComponent = { }

	SettingsComponent.Interface = { }
	SettingsComponent.Prototype = { }

	SettingsComponent.Settings = {
		Storage = { },
		Remote = { },
	}

	function SettingsComponent.Prototype:setRemoteSetting(settingKey, settingValue)
		self:setStorageSetting(settingKey, settingValue)

		SettingsComponent.Settings.Remote[settingKey] = settingValue
	end

	function SettingsComponent.Prototype:setStorageSetting(settingKey, settingValue)
		SettingsComponent.Settings.Storage[settingKey] = settingValue

		OutSi.Plugin:SetSetting(settingKey, {
			[OutSi.Enumeration.StorageKey.Version] = OutSi.Version,
			[OutSi.Enumeration.StorageKey.Value] = settingValue
		})
	end

	function SettingsComponent.Prototype:getRemoteSetting(settingKey)
		return SettingsComponent.Settings.Remote[settingKey]
	end

	function SettingsComponent.Prototype:getStorageSetting(settingKey)
		return SettingsComponent.Settings.Storage[settingKey]
	end

	function SettingsComponent.Prototype:getDefaultSetting(settingKey)
		return OutSi.Data.Settings[settingKey]
	end

	function SettingsComponent.Prototype:getSetting(...)
		return self:getRemoteSetting(...)
			or self:getStorageSetting(...)
			or self:getDefaultSetting(...)
	end

	function SettingsComponent.Interface.new()
		local self = setmetatable({ }, { __index = SettingsComponent.Prototype })

		for settingKey in OutSi.Enumeration.SettingKey do
			local settingsObject = OutSi.Plugin:GetSetting(settingKey)

			if not settingsObject then
				continue
			end

			if settingsObject[OutSi.Enumeration.StorageKey.Version] ~= OutSi.Version then
				warn(string.format(OutSi.Data.ErrorMessages[OutSi.Enumeration.ErrorType.SettingVersionMissMatch], settingKey))
				OutSi.Plugin:SetSetting(settingKey, nil)

				continue
			end

			SettingsComponent.Settings.Storage[settingKey] = settingsObject[OutSi.Enumeration.StorageKey.Value]
		end

		return self
	end

	return SettingsComponent.Interface
end