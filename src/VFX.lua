--< Services >--
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

--< Constants >--
local ZERO_VECTOR = Vector3.new(0, 0, 0)
local RNG = Random.new()

--< Variables >--
local Emitters = {}

--< Functions >--
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

local function QuickRemove(tbl, index)
	local Last = #tbl
	tbl[index] = tbl[Last]
	tbl[Last] = nil
end

local function QuickRemoveFirstOccurence(tbl, value)
	local Index = table.find(tbl, value)

	if Index then
		QuickRemove(tbl, Index)
	end
end

local function CreateParticle(description)
	local Particle = {}

	Particle.Actor = description.Actor:Clone()
	Particle.Life = 0
	Particle.Lifetime = GetValue(description.Lifetime)
	Particle.Velocity = GetValue(description.Velocity)
	Particle.Acceleration = GetValue(description.Acceleration)
	Particle.Drag = GetValue(description.Drag)
	Particle.RotationVelocity = GetValue(description.RotationVelocity)
	
	Particle.Motors = description.Motors
	
	Particle.Actor.CFrame = CFrame.new(GetValue(description.Position))
	
	Particle.ActorProps = {}
	for property,value in pairs(description.ActorProps) do
		local Value = GetValue(value)
		description.Actor[property] = Value
		Particle.ActorProps[property] = Value
	end
	
	Particle.OriginalSize = Particle.Actor.Size
	
	Particle.Actor.Parent = Workspace
	
	return Particle
end

--< Classes >--
local Emitter = {}
Emitter.__index = Emitter

function Emitter.new(description)
	local self = setmetatable({}, Emitter)
	
	self.Tick = 0
	self.Enabled = false
	self.Particles = {}
	self.Description = description
	
	return self
end

function Emitter:Start()
	self.Enabled = true
end

function Emitter:Emit(amount)
	for _ = 1, amount do
		table.insert(self.Particles, CreateParticle(self.Description))
	end
end

function Emitter:Stop()
	self.Tick = 0
	self.Enabled = false
end

function Emitter:Destroy()
	QuickRemoveFirstOccurence(Emitters, self)

	for _,particle in ipairs(self.Particles) do
		particle.Actor:Destroy()
	end
end

--< Module >--
local VFX = {}

function VFX.DescribeEmitter(props)
	local Description = {}
	
	Description.Actor = props.Actor
	Description.Position = props.Position or Vector3.new(0, 0, 0)
	Description.Rate = 1 / props.Rate or 1
	Description.Velocity = props.Velocity or Vector3.new(0, 1, 0)
	Description.Acceleration = props.Acceleration or Vector3.new(0, 0, 0)
	Description.Drag = props.Drag or 0
	Description.RotationVelocity = props.RotationalVelocity or Vector3.new(0, 0, 0)
	Description.Lifetime = props.Lifetime or 1
	Description.ActorProps = props.ActorProps or {}
	Description.Motors = props.Motors or {}
	
	return Description
end

function VFX.CreateEmitter(description)
	local NewEmitter = Emitter.new(description)

	table.insert(Emitters, NewEmitter)

	return NewEmitter
end

--< Start >--
RunService.Heartbeat:Connect(function(dt)
	for _,emitter in ipairs(Emitters) do
		if emitter.Enabled then
			emitter.Tick = emitter.Tick + dt

			while emitter.Tick > emitter.Description.Rate do
				emitter.Tick = emitter.Tick - emitter.Description.Rate
				
				table.insert(emitter.Particles, CreateParticle(emitter.Description))
			end
		end
		
		for index,particle in ipairs(emitter.Particles) do
			particle.Life = particle.Life + dt
		
			if particle.Life >= particle.Lifetime then
				particle.Actor:Destroy()
				QuickRemove(emitter.Particles, index)
			else
				local Actor = particle.Actor
				
				particle.Velocity = particle.Velocity:Lerp(ZERO_VECTOR, particle.Drag*dt) + particle.Acceleration*dt
				
				Actor.CFrame = Actor.CFrame * CFrame.Angles(particle.RotationVelocity.X*dt, particle.RotationVelocity.Y*dt, particle.RotationVelocity.Z*dt) + particle.Velocity*dt
				
				for property,motor in pairs(particle.Motors) do
					Actor[property] = motor(particle.Life / particle.Lifetime, particle)
				end
			end
		end
	end
end)

return VFX