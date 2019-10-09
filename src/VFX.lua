--< Services >--
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

--< Variables >--
local Emitters = {}
local Particles = {}

--< Functions >--
local function GetValue(value)
	local Type = typeof(value)
	
	if (Type == "function") then
		return value()
	else
		return value
	end
end

--< Module >--
local VFX = {}

function VFX.CreateEmitter(props) -- actor, position, rate, speed, direction, rotationVel, lifetime, actorProps, motors
	local Emitter = {}
	
	Emitter.Actor = props.Actor
	Emitter.Position = props.Position or Vector3.new(0, 0, 0)
	Emitter.Tick = 0
	Emitter.Rate = props.Rate or 1
	Emitter.Speed = props.Speed or 0.1
	Emitter.Direction = props.Direction or Vector3.new(0, 1, 0)
	Emitter.RotationVelocity = props.RotationalVelocity or Vector3.new(25, 25, 25)
	Emitter.Lifetime = props.Lifetime or 1
	Emitter.ActorProps = props.ActorProps or {}
	Emitter.Motors = props.Motors or {}
	
	table.insert(Emitters, Emitter)
	
	return Emitter
end

function VFX.CreateParticle(emitter)
	local Particle = {}
	
	Particle.Actor = emitter.Actor:Clone()
	Particle.Life = 0
	Particle.Lifetime = GetValue(emitter.Lifetime)
	Particle.Speed = GetValue(emitter.Speed)
	Particle.Direction = GetValue(emitter.Direction).Unit
	Particle.RotationVelocity = GetValue(emitter.RotationVelocity)
	
	Particle.Motors = emitter.Motors
	
	Particle.Actor.CFrame = CFrame.new(emitter.Position)
	
	Particle.ActorProps = {}
	for property,value in pairs(emitter.ActorProps) do
		local Value = GetValue(value)
		emitter.Actor[property] = Value
		Particle.ActorProps[property] = Value
	end
	
	Particle.Actor.Parent = Workspace
	
	table.insert(Particles, Particle)
	
	return Particle
end

--< Start >--
RunService.Heartbeat:Connect(function(dt)
	for _,emitter in pairs(Emitters) do
		emitter.Tick = emitter.Tick + dt
		
		if (emitter.Tick > emitter.Rate) then
			emitter.Tick = 0
			
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
			
			Actor.CFrame = Actor.CFrame * CFrame.Angles(particle.RotationVelocity.X*dt, particle.RotationVelocity.Y*dt, particle.RotationVelocity.Z*dt) + particle.Direction * particle.Speed*dt
			
			for property,motor in pairs(particle.Motors) do
				Actor[property] = motor(particle.Life / particle.Lifetime, particle)
			end
		end
	end
end)

return VFX
