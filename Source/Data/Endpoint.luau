local Enumeration = script.Parent.Parent.Enumeration

local EndpointType = require(Enumeration.EndpointType)
local EndpointKey = require(Enumeration.EndpointKey)

return {
	[EndpointKey.EndpointStructure] = "http://%s%s",
	[EndpointKey.EndpointUrl] = "127.0.0.1:3017",

	[EndpointKey.EndpointPaths] = {
		[EndpointType.identify] = "/api/identify",
		[EndpointType.settings] = "/api/settings",

		[EndpointType.onAction] = "/api/event/action",
		[EndpointType.onUpload] = "/api/event/upload"
	},

	[EndpointKey.EndpointRequestType] = {
		[EndpointType.identify] = "GET",
		[EndpointType.settings] = "GET",

		[EndpointType.onAction] = "POST",
		[EndpointType.onUpload] = "POST"
	}
}