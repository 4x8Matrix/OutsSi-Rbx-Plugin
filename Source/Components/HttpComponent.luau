local HttpService = game:GetService("HttpService")

return function(OutSi)
	local SettingsComponent = OutSi:getComponent("SettingsComponent")

	local ServerUid = HttpService:GenerateGUID(false)

	local HttpComponent = { }

	HttpComponent.Interface = { }
	HttpComponent.Prototype = { }

	HttpComponent.ActionEnums = {
		[OutSi.Enumeration.ActionType.RunModeChanged] = 0
	}

	function HttpComponent.Prototype:getUniqueServerId()
		if game.PlaceId ~= 0 then
			return game.Name
		else
			if game.Name == "" then
				return ServerUid
			else
				local gameName = game.Name

				gameName = string.gsub(gameName, ".rbxl", "")
				gameName = string.gsub(gameName, ".rbxlx", "")

				return gameName
			end
		end
	end

	function HttpComponent.Prototype:generateRequestHeaders()
		return {
			[OutSi.Enumeration.HeaderType.ContentType] = OutSi.Enumeration.ContentType.ApplicationJson,
			[OutSi.Enumeration.HeaderType.UniqueId] = self:getUniqueServerId()
		}
	end

	function HttpComponent.Prototype:requestAsync(endpointType, body)
		return OutSi.Packages.Promise.new(function(resolve, reject)
			local headers = self:generateRequestHeaders()
			local method = OutSi.Data.Endpoint[OutSi.Enumeration.EndpointKey.EndpointRequestType][endpointType]
			local url = string.format(
				OutSi.Data.Endpoint[OutSi.Enumeration.EndpointKey.EndpointStructure],
				OutSi.Data.Endpoint[OutSi.Enumeration.EndpointKey.EndpointUrl],
				OutSi.Data.Endpoint[OutSi.Enumeration.EndpointKey.EndpointPaths][endpointType]
			)

			xpcall(function()
				resolve(HttpService:RequestAsync({
					[OutSi.Enumeration.HttpKey.Body] = body,
					[OutSi.Enumeration.HttpKey.Headers] = headers,
					[OutSi.Enumeration.HttpKey.Method] = method,
					[OutSi.Enumeration.HttpKey.Url] = url
				}))
			end, function(exception)
				reject(exception)
			end)
		end)
	end

	function HttpComponent.Prototype:validateConnectionAsync()
		return OutSi.Packages.Promise.new(function(resolve, reject)
			local success, response = self:requestAsync(OutSi.Enumeration.EndpointType.identify):await()
			if not success or not response then
				return reject(response or "Server Response: <NULL>")
			end

			if not response.Success then
				return reject(response.Message)
			end

			if not self.isConnected then
				self.httpServerConnected:Fire()

				self.isConnected = true
			end

			resolve(true)
		end):catch(function(exception)
			warn(string.format(OutSi.Data.ErrorMessages[OutSi.Enumeration.ErrorType.InternalPluginError]), exception)

			task.delay(SettingsComponent:getSetting(OutSi.Enumeration.SettingKey.AttemptDelay), function()
				self:validateConnectionAsync():await()
			end)

			if self.isConnected then
				self.httpServerDisconnected:Fire()

				self.isConnected = false
			end

			return false
		end)
	end

	function HttpComponent.Prototype:uploadBatch(logObjects)
		local success, isConnected = self:validateConnectionAsync():await()

		if success and not isConnected then
			self.httpServerConnected:Wait()
		end

		return self:requestAsync(OutSi.Enumeration.EndpointType.onUpload, HttpService:JSONEncode({
			[OutSi.Enumeration.HttpKey.Batch] = logObjects
		}))
	end

	function HttpComponent.Prototype:uploadAction(actionType, actionData)
		local success, isConnected = self:validateConnection():await()

		if success and not isConnected then
			self.httpServerConnected:Wait()
		end

		return self:requestAsync(OutSi.Enumeration.EndpointType.onAction, HttpService:JSONEncode({
			[OutSi.Enumeration.HttpKey.ActionType] = HttpComponent.ActionEnums[actionType]
		})):catch(function()
			self:validateConnection()
		end)
	end

	function HttpComponent.Interface.new()
		local self = setmetatable({ }, { __index = HttpComponent.Prototype })

		self.isConnected = false

		self.httpServerConnected = OutSi.Packages.Signal.new()
		self.httpServerDisconnected = OutSi.Packages.Signal.new()

		return self
	end

	return HttpComponent.Interface
end