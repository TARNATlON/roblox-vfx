--< Services >--
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

--< Constants >--
local ZERO_VECTOR = Vector3.new(0, 0, 0)

--< Variables >--
local Emitters = {}
local Particles = {}

local RNG = Random.new(tick())

--< Functions >--
local function GetValue(value)
	local Type = typeof(value)
	
	if (Type == "function") then
		return value()
	elseif (Type == "NumberRange") then
		return RNG:NextNumber(value.Min, value.Max)
	else
		return value
	end
end

--< Module >--
local VFX = {}

function VFX.CreateEmitter(props)
	local Emitter = {}
	
	Emitter.Actor = props.Actor
	Emitter.Position = props.Position or Vector3.new(0, 0, 0)
	Emitter.Tick = 0
	Emitter.Rate = 1 / props.Rate or 1
	Emitter.Velocity = props.Velocity or Vector3.new(0, 1, 0)
	Emitter.Acceleration = props.Acceleration or Vector3.new(0, 0, 0)
	Emitter.Drag = props.Drag or 0
	Emitter.RotationVelocity = props.RotationalVelocity or Vector3.new(0, 0, 0)
	Emitter.Lifetime = props.Lifetime or 1
	Emitter.ActorProps = props.ActorProps or {}
	Emitter.Motors = props.Motors or {}
	
	table.insert(Emitters, Emitter)
	
	return Emitter
end

function VFX.DestroyEmitter(emitter)
	local Index = table.find(Emitters, emitter)
	if (Index) then
		table.remove(Emitters, Index)	
	end
end

function VFX.CreateParticle(emitter)
	local Particle = {}
	
	Particle.Actor = emitter.Actor:Clone()
	Particle.Life = 0
	Particle.Lifetime = GetValue(emitter.Lifetime)
	Particle.Velocity = GetValue(emitter.Velocity)
	Particle.Acceleration = GetValue(emitter.Acceleration)
	Particle.Drag = GetValue(emitter.Drag)
	Particle.RotationVelocity = GetValue(emitter.RotationVelocity)
	
	Particle.Motors = emitter.Motors
	
	Particle.Actor.CFrame = CFrame.new(GetValue(emitter.Position))
	
	Particle.ActorProps = {}
	for property,value in pairs(emitter.ActorProps) do
		local Value = GetValue(value)
		emitter.Actor[property] = Value
		Particle.ActorProps[property] = Value
	end
	
	Particle.OriginalSize = Particle.Actor.Size
	
	Particle.Actor.Parent = Workspace
	
	table.insert(Particles, Particle)
	
	return Particle
end

--< Start >--
RunService.Heartbeat:Connect(function(dt)
	for _,emitter in pairs(Emitters) do
		emitter.Tick = emitter.Tick + dt
		
		while (emitter.Tick > emitter.Rate) do
			emitter.Tick = emitter.Tick - emitter.Rate
			
			VFX.CreateParticle(emitter)
		end
	end
	
	for index,particle in pairs(Particles) do
		particle.Life = particle.Life + dt
		
		if (particle.Life >= particle.Lifetime) then
			particle.Actor:Destroy()
			Particles[index] = nil
		else
			local Actor = particle.Actor
			
			particle.Velocity = particle.Velocity:Lerp(ZERO_VECTOR, particle.Drag*dt) + particle.Acceleration*dt
			
			Actor.CFrame = Actor.CFrame * CFrame.Angles(particle.RotationVelocity.X*dt, particle.RotationVelocity.Y*dt, particle.RotationVelocity.Z*dt) + particle.Velocity*dt
			
			for property,motor in pairs(particle.Motors) do
				Actor[property] = motor(particle.Life / particle.Lifetime, particle)
			end
		end
	end
end)

return VFX
