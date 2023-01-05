return table.freeze({
	["HttpResourcePercent"] = "HttpResourcePercent",
	["HttpLimitPerSecond"] = "HttpLimitPerSecond",
	["HttpLimitReset"] = "HttpLimitReset",

	["MaxLogsInMemory"] = "MaxLogsInMemory",

	["AttemptDelay"] = "AttemptDelay"
}) :: {
	HttpResourcePercent: string,
	HttpLimitPerSecond: string,
	HttpLimitReset: string,

	MaxLogsInMemory: string,
	AttemptDelay: string
}