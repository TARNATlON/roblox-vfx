--< Services >--
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

--< Constants >--
local ZERO_VECTOR = Vector3.new(0, 0, 0)
local RNG = Random.new()

--< Variables >--
local NumberOfParticles = 0
local Emitters = {}
local Descriptions = {}

local ParticleLimit = nil

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

local function CreateParticle(emitter)
	local Description = emitter.Description

	if Description.ParticleLimit and Description.NumberOfParticles >= Description.ParticleLimit then
		return nil
	end

	if ParticleLimit and NumberOfParticles >= ParticleLimit then
		return nil
	end

	local Particle = {}

	Particle.Actor = Description.Actor:Clone()
	Particle.Life = 0
	Particle.Lifetime = GetValue(emitter.ExtendedDescription.Lifetime or Description.Lifetime)
	Particle.Velocity = GetValue(emitter.ExtendedDescription.Velocity or Description.Velocity)
	Particle.Acceleration = GetValue(emitter.ExtendedDescription.Acceleration or Description.Acceleration)
	Particle.Drag = GetValue(emitter.ExtendedDescription.Drag or Description.Drag)
	Particle.RotationVelocity = GetValue(emitter.ExtendedDescription.RotationVelocity or Description.RotationVelocity)
	
	Particle.Motors = Description.Motors
	
	Particle.Actor.CFrame = CFrame.new(GetValue(emitter.ExtendedDescription.Position or Description.Position))
	
	Particle.ActorProps = {}
	for property,value in pairs(Description.ActorProps) do
		local Value = GetValue(value)

		Particle.Actor[property] = Value
		Particle.ActorProps[property] = Value
	end
	
	Particle.OriginalSize = Particle.Actor.Size
	
	Particle.Actor.Parent = Workspace
	
	table.insert(emitter.Particles, Particle)

	emitter.Description.NumberOfParticles += 1
	NumberOfParticles += 1
end

--< Classes >--
local Emitter = {}
Emitter.__index = Emitter

function Emitter.new(descriptionID, extendedDescription)
	if not Descriptions[descriptionID] then
		error("Emitter description `" .. descriptionID .. "` does not exist.")
	end

	local self = setmetatable({}, Emitter)
	
	self.Tick = 0
	self.Enabled = false
	self.Particles = {}
	self.Description = Descriptions[descriptionID]
	self.ExtendedDescription = extendedDescription or {}

	return self
end

function Emitter:Start()
	self.Enabled = true
end

function Emitter:Emit(amount)
	for _ = 1, amount do
		CreateParticle(self)
	end
end

function Emitter:Stop()
	self.Tick = 0
	self.Enabled = false
end

function Emitter:Destroy()
	QuickRemoveFirstOccurence(Emitters, self)

	NumberOfParticles -= #self.Particles

	for _,particle in ipairs(self.Particles) do
		particle.Actor:Destroy()
	end
end

--< Module >--
local VFX = {}

function VFX.SetParticleLimit(amount)
	ParticleLimit = amount
end

function VFX.DescribeEmitter(uniqueID, props)
	local Description = {}
	
	Description.Actor = props.Actor
	Description.Position = props.Position or Vector3.new(0, 0, 0)
	Description.Rate = 1 / props.Rate or 1
	Description.ParticleLimit = props.ParticleLimit
	Description.Velocity = props.Velocity or Vector3.new(0, 1, 0)
	Description.Acceleration = props.Acceleration or Vector3.new(0, 0, 0)
	Description.Drag = props.Drag or 0
	Description.RotationVelocity = props.RotationalVelocity or Vector3.new(0, 0, 0)
	Description.Lifetime = props.Lifetime or 1
	Description.ActorProps = props.ActorProps or {}
	Description.Motors = props.Motors or {}
	Description.NumberOfParticles = 0

	Descriptions[uniqueID] = Description
end

function VFX.CreateEmitter(uniqueID, extendedDescription)
	local NewEmitter = Emitter.new(uniqueID, extendedDescription)

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
				
				CreateParticle(emitter)
			end
		end
		
		for index,particle in ipairs(emitter.Particles) do
			particle.Life = particle.Life + dt
		
			if particle.Life >= particle.Lifetime then
				particle.Actor:Destroy()
				QuickRemove(emitter.Particles, index)

				emitter.Description.NumberOfParticles -= 1
				NumberOfParticles -= 1
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