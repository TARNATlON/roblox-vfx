--< Services >--
local Workspace = game:GetService("Workspace")

--< Variables >--
local Camera = Workspace.CurrentCamera

--< Modules >--
local Constants = require(script.Parent.Constants)
local GetValue = require(script.Parent.GetValue)

--< Module >--
local Emitter = {}
Emitter.__index = Emitter

function Emitter.new(description, extendedDescription, createParticle, cleanup)
	local self = setmetatable({}, Emitter)

	extendedDescription = extendedDescription or {}

	self.Tick = 0
	self.DistanceTick = 0
	self.BaseRate = extendedDescription.Rate or 1 / description.Rate
	self.Rate = 1 / self.BaseRate
	self.Enabled = false
	self.Particles = {}
	self.Description = description
    self.ExtendedDescription = extendedDescription
    self.CreateParticle = createParticle
    self.Cleanup = cleanup

	return self
end

function Emitter:Start()
	self.Enabled = true
end

function Emitter:Emit(amount)
	local Distance = (Camera.CFrame.Position - GetValue(self.ExtendedDescription.Position or self.Description.Position)).Magnitude

	if Distance > Constants.RENDER_DISTANCE_START then
		amount = amount / (Distance / 20)
	end

	for _ = 1, amount do
		self.CreateParticle(self)
	end
end

function Emitter:Stop()
	self.Tick = 0
	self.Enabled = false
end

function Emitter:Destroy()
    self.Cleanup(self)

	for _,particle in ipairs(self.Particles) do
		self.Description.Cache:ReturnPart(particle.Actor)
	end
end

return Emitter