--[[
	PartCache V3.0 by Xan with modifications
	Creating parts is laggy, especially if they are supposed to be there for a split second and/or need to be made frequently.
	This module aims to resolve this lag by pre-creating the parts and CFraming them to a location far away and out of sight.
	When necessary, the user can get one of these parts and CFrame it to where they need, then return it to the cache when they are done with it.
	
	According to Roblox's Technical Director, zeuxcg (https://devforum.roblox.com/u/zeuxcg/summary)...
		>> CFrame is currently the only "fast" property in that you can change it every frame without really heavy code kicking in. Everything else is expensive.
		
		- https://devforum.roblox.com/t/event-that-fires-when-rendering-finishes/32954/19
	
	This alone should ensure the speed granted by this module.
		
		
	HOW TO USE THIS MODULE:
	
	Look at the bottom of my thread for an API! https://devforum.roblox.com/t/partcache-for-all-your-quick-part-creation-needs/246641
--]]

local PartCache = {}
PartCache.__index = PartCache

-----------------------------------------------------------
----------------------- STATIC DATA -----------------------
-----------------------------------------------------------

-- Will warn if PrecreatedParts > this
local EXCESSIVE_PART_AMOUNT = 60						

-- A CFrame that's really far away. Ideally. You are free to change this as needed.
local CF_REALLY_FAR_AWAY = CFrame.new(0, 10e8, 0)

-- Format params: methodName, ctorName
local ERR_NOT_INSTANCE = "Cannot statically invoke method '%s' - It is an instance method. Call it on an instance of this class created via %s"

-- Format params: paramName, expectedType, actualType
local ERR_INVALID_TYPE = "Invalid type for parameter '%s' (Expected %s, got %s)"

-- Format params: N/A
local ERR_OBJECT_DISPOSED = "This PartCache has been disposed. It can no longer be used."

-----------------------------------------------------------
------------------------ UTILITIES ------------------------
-----------------------------------------------------------

-- Alias function to automatically error out for invalid types.
local function MandateType(value, type, paramName, nullable, instanceType)
	if nullable and value == nil then return end
	
	-- New behavior: Special classname based error for instances.
	if type == "Instance" and typeof(value) == type and instanceType ~= nil then
		-- We want our base type to be Instance, value *is* an Instance, and we have defined instanceType, which is the class that we want.
		assert(value:IsA(instanceType), ERR_INVALID_TYPE:format(paramName or "ERR_NO_PARAM_NAME", instanceType, typeof(value)))
	end
	
	assert(typeof(value) == type, ERR_INVALID_TYPE:format(paramName or "ERR_NO_PARAM_NAME", type, typeof(value)))
end

--Similar to assert but warns instead of errors.
local function assertwarn(requirement, messageIfNotMet)
	if not requirement then
		warn(messageIfNotMet)
	end
end

--Dupes a part from the template.
local function MakeFromTemplate(template, currentCacheParent)
	local part = template:Clone()
	part.CFrame = CF_REALLY_FAR_AWAY
	part.Anchored = true
	part.Parent = currentCacheParent
	return part
end

local function ErrorDisposed()
	error(ERR_OBJECT_DISPOSED)
end

function PartCache.new(template, numPrecreatedParts, currentCacheParent)
	numPrecreatedParts = numPrecreatedParts or 5
	currentCacheParent = currentCacheParent or workspace
	
	--Catch cases for incorrect input.
	MandateType(template, "Instance", "template", false, "BasePart")
	MandateType(numPrecreatedParts, "number", "numPrecreatedParts", false, nil)
	
	--PrecreatedParts value.
	--Same thing. Ensure it's a number, ensure it's not negative, warn if it's really huge or 0.
	assert(numPrecreatedParts > 0, "PrecreatedParts can not be negative!")
	assertwarn(numPrecreatedParts ~= 0, "PrecreatedParts is 0! This may have adverse effects when initially using the cache.")
	assertwarn(numPrecreatedParts <= EXCESSIVE_PART_AMOUNT, "It is not advised to set PrecreatedParts > " .. EXCESSIVE_PART_AMOUNT .. " as this can cause lag on creation.")
	assertwarn(template.Archivable, "The template's Archivable property has been set to false, which prevents it from being cloned. It will temporarily be set to true.")
	
	local oldArchivable = template.Archivable
	template.Archivable = true
	local newTemplate = template:Clone() --If they destroy it, we'll have a reference here to keep.
	template.Archivable = oldArchivable
	template = newTemplate
	
	local object = setmetatable({
		Open = {},
		InUse = {},
		CurrentCacheParent = currentCacheParent,
		Template = template
	}, PartCache)
	
	for _ = 1, numPrecreatedParts do
		table.insert(object.Open, MakeFromTemplate(template, object.CurrentCacheParent))
	end
	object.Template.Parent = nil
	
	return object
end

-- Gets a part from the cache, or creates one if no more are available.
function PartCache:GetPart()
	assert(getmetatable(self) == PartCache, ERR_NOT_INSTANCE:format("GetPart", "PartCache.new"))
	
	if #self.Open == 0 then
		table.insert(self.Open, MakeFromTemplate(self.Template, self.CurrentCacheParent))
	end
	local part = self.Open[#self.Open]
	self.Open[#self.Open] = nil
	table.insert(self.InUse, part)
	return part
end

local function keyOf(tbl, value)
	for index, obj in pairs(tbl) do
		if obj == value then
			return index
		end
	end
	return nil
end

local function indexOf(tbl, value)
	local fromFind = table.find(tbl, value)
	if fromFind then return fromFind end
	
	return keyOf(tbl, value)
end

-- Returns the key of the specified value, or nil if it could not be found. Unlike IndexOf, this searches every key in the table, not just ordinal indices (arrays)
-- This is inherently slower due to how lookups work, so if your table is structured like an array, use table.find


-- Returns a part to the cache.
function PartCache:ReturnPart(part)
	assert(getmetatable(self) == PartCache, ERR_NOT_INSTANCE:format("ReturnPart", "PartCache.new"))
	MandateType(part, "Instance", "part", false, "BasePart")
	
	local index = indexOf(self.InUse, part)
	if index ~= nil then
		table.remove(self.InUse, index)
		table.insert(self.Open, part)
		part.CFrame = CF_REALLY_FAR_AWAY
		part.Anchored = true
	else
		error("Attempted to return part \"" .. part.Name .. "\" (" .. part:GetFullName() .. ") to the cache, but it's not in-use! Did you call this on the wrong part?")
	end
end

-- Sets the parent of all cached parts.
function PartCache:SetCacheParent(newParent)
	assert(getmetatable(self) == PartCache, ERR_NOT_INSTANCE:format("SetCacheParent", "PartCache.new"))
	MandateType(newParent, "Instance", "newParent", false, nil)
	assert(newParent:IsDescendantOf(workspace) or newParent == workspace, "Cache parent is not a descendant of Workspace! Parts should be kept where they will remain in the visible world.")
	
	self.CurrentCacheParent = newParent
	for i = 1, #self.Open do
		self.Open[i].Parent = newParent
	end
	for i = 1, #self.InUse do
		self.InUse[i].Parent = newParent
	end
end

-- Destroys this cache entirely. Use this when you don't need this cache object anymore.
function PartCache:Dispose()
	assert(getmetatable(self) == PartCache, ERR_NOT_INSTANCE:format("Dispose", "PartCache.new"))
	for i = 1, #self.Open do
		self.Open[i]:Destroy()
	end
	for i = 1, #self.InUse do
		self.InUse[i]:Destroy()
	end
	self.Template:Destroy()
	self.Open = nil
	self.InUse = nil
	self.CurrentCacheParent = nil
	self.Template = nil	
	
	self.GetPart = ErrorDisposed
	self.ReturnPart = ErrorDisposed
	self.SetCacheParent = ErrorDisposed
	self.Dispose = ErrorDisposed
end

return PartCache