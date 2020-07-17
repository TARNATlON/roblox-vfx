--< Variables >--
local RNG = Random.new()

--< Module >--
local function GetValue(value)
	local Type = typeof(value)
	
	if Type == "function" then
		return value()
	elseif Type == "NumberRange" then
		return RNG:NextNumber(value.Min, value.Max)
	else
		return value
	end
end

return GetValue