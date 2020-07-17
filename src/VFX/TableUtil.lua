--< Module >--
local TableUtil = {}

function TableUtil.QuickRemove(tbl, index)
	local Removed = tbl[index]

	local Last = #tbl
	tbl[index] = tbl[Last]
	tbl[Last] = nil

	return Removed
end

function TableUtil.QuickRemoveFirstOccurence(tbl, value)
	local Index = table.find(tbl, value)

	if Index then
		TableUtil.QuickRemove(tbl, Index)
	end
end

return TableUtil