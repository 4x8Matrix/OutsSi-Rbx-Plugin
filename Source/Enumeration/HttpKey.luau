return table.freeze({
	["Body"] = "Body",
	["Headers"] = "Headers",
	["Method"] = "Method",
	["Url"] = "Url",

	["Batch"] = "batch",
	["ActionType"] = "actionType"
}) :: {
	ActionType: string,
	Batch: string,

	Body: string,
	Headers: string,
	Method: string,
	Url: string
}