local Enumeration = script.Parent.Parent.Enumeration

local EndpointType = require(Enumeration.EndpointType)
local EndpointKey = require(Enumeration.EndpointKey)

return {
	[EndpointKey.EndpointStructure] = "http://%s%s",
	[EndpointKey.EndpointUrl] = "127.0.0.1:3012",

	[EndpointKey.EndpointPaths] = {
		[EndpointType.identify] = "/api/v1/identify",
		[EndpointType.settings] = "/api/v1/settings",

		[EndpointType.onAction] = "/api/v1/event/action",
		[EndpointType.onUpload] = "/api/v1/event/upload"
	},

	[EndpointKey.EndpointRequestType] = {
		[EndpointType.identify] = "GET",
		[EndpointType.settings] = "GET",

		[EndpointType.onAction] = "POST",
		[EndpointType.onUpload] = "POST"
	}
}