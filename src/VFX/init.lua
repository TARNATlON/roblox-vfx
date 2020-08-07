--< Services >--
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

--< Modules >--
local TableUtil = require(script.TableUtil)
local GetValue = require(script.GetValue)
local PartCache = require(script.PartCache)
local Emitter = require(script.Emitter)
local Constants = require(script.Constants)
local SpawnCancellable = require(script.SpawnCancellable)

--< Constants >--
local RNG = Random.new()
local ZERO_VECTOR = Vector3.new(0, 0, 0)

--< Variables >--
local NumberOfParticles = 0
local Emitters = {}
local Descriptions = {}
local Effects = {}
local Camera = Workspace.CurrentCamera

local ParticleCache = {}

local ParticleLimit = nil

--< Functions >--
local function CleanEmitter(emitter)
	TableUtil.QuickRemoveFirstOccurence(Emitters, emitter)

	NumberOfParticles -= #emitter.Particles
end

local function Wait(length)
	coroutine.yield(wait, length)
end

local function WaitOnEvent(event)
	coroutine.yield(function()
		event:Wait()
	end)
end

--< Classes >--
local Effect = {}
Effect.__index = Effect

function Effect.new(effectId)
	local self = setmetatable({}, Effect)
	
	self.PlayFunction = Effects[effectId].Play
	self.StopFunction = Effects[effectId].Stop
	self.CancelFunction = Effects[effectId].Cancel
	self.Memory = {}

	self.Finished = function()
		if self.Thread then
			self.Thread.Canceled = true
		end

		self.StopFunction(self.Memory)
		self.Memory = {}
	end

	return self
end

function Effect:Play(...)
	self.Thread = SpawnCancellable(self.PlayFunction, self.Finished, Wait, WaitOnEvent, self.Memory, ...)
end

function Effect:Stop()
	if self.Thread then
		self.Thread.Canceled = true
	end

	if self.CancelFunction then
		self.CancelFunction(self.Memory)
	end
	
	self.StopFunction(self.Memory)
	self.Memory = {}
end

--< Module >--
local VFX = {}

function VFX.RegisterEmittersIn(folder)
	for _,descendant in ipairs(folder:GetDescendants()) do
		if descendant:IsA("ModuleScript") then
			require(descendant)(VFX.DescribeEmitter)
		end
	end
end

function VFX.RegisterEffectsIn(folder)
	for _,descendant in ipairs(folder:GetDescendants()) do
		if descendant:IsA("ModuleScript") then
			require(descendant)(VFX.DescribeEffect)
		end
	end
end

function VFX.CreateParticle(emitter)
	local Description = emitter.Description

	if Description.ParticleLimit and Description.NumberOfParticles >= Description.ParticleLimit then
		return nil
	end

	if ParticleLimit and NumberOfParticles >= ParticleLimit then
		return nil
	end

	local Particle = {}

	local Actor = nil
	if typeof(Description.Actor) == "table" then
		Actor = Description.Actor[RNG:NextInteger(1, #Description.Actor)]
	else
		Actor = Description.Actor
	end

	Particle.BaseActor = Actor
	Particle.Actor = ParticleCache[Actor]:GetPart()
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

function VFX.DescribeEffect(uniqueId, effect)
	if Effects[uniqueId] then
		error("Attempted to describe effect `" .. uniqueId .. "` more than once.")
	end

	Effects[uniqueId] = {
		Play = effect.Play;
		Cancel = effect.Cancel;
		Stop = effect.Stop;
	}
end

function VFX.CreateEffect(uniqueId)
	return Effect.new(uniqueId)
end

function VFX.SetParticleLimit(amount)
	ParticleLimit = amount
end

function VFX.DescribeEmitter(uniqueId, props, precreatedParts)
	if Descriptions[uniqueId] then
		error("Attempted to describe emitter `" .. uniqueId .. "` more than once.")
	end

	local Description = {}
	
	if typeof(props.Actor) == "table" then
		for _,actor in ipairs(props.Actor) do
			if not ParticleCache[actor] then
				ParticleCache[actor] = PartCache.new(actor, precreatedParts)
			end
		end
	else
		if not ParticleCache[props.Actor] then
			ParticleCache[props.Actor] = PartCache.new(props.Actor, precreatedParts)
		end
	end

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

	Descriptions[uniqueId] = Description
end

function VFX.CreateEmitter(descriptionID, extendedDescription)
	if not Descriptions[descriptionID] then
		error("Emitter `" .. descriptionID .. "` does not exist.")
	end

	local NewEmitter = Emitter.new(Descriptions[descriptionID], extendedDescription, VFX.CreateParticle, CleanEmitter, ParticleCache)

	table.insert(Emitters, NewEmitter)

	return NewEmitter
end

--< Start >--
RunService.Heartbeat:Connect(function(dt)
	local CFrames = {}
	local Actors = {}

	for _,emitter in ipairs(Emitters) do
		if emitter.Enabled then
			emitter.Tick = emitter.Tick + dt
			emitter.DistanceTick = emitter.DistanceTick + dt

			if emitter.DistanceTick > 4 then
				emitter.DistanceTick = 0

				local Distance = (Camera.CFrame.Position - GetValue(emitter.ExtendedDescription.Position or emitter.Description.Position)).Magnitude

				if Distance > Constants.RENDER_DISTANCE_START then
					emitter.Rate = 1 / (emitter.BaseRate / (math.clamp(Distance / (emitter.BaseRate * 8), 1, 100)))
				else
					emitter.Rate = 1 / emitter.BaseRate
				end
			end

			while emitter.Tick > emitter.Rate do
				emitter.Tick = emitter.Tick - emitter.Rate
				
				VFX.CreateParticle(emitter)
			end
		end
		
		for index,particle in ipairs(emitter.Particles) do
			particle.Life = particle.Life + dt
			
			if particle.Life >= particle.Lifetime then
				ParticleCache[particle.BaseActor]:ReturnPart(particle.Actor)
				TableUtil.QuickRemove(emitter.Particles, index)

				emitter.Description.NumberOfParticles -= 1
				NumberOfParticles -= 1
			else
				local Actor = particle.Actor
				
				particle.Velocity = particle.Velocity:Lerp(ZERO_VECTOR, particle.Drag*dt) + particle.Acceleration*dt
				
				Actors[#Actors+1] = particle.Actor
				CFrames[#CFrames+1] = Actor.CFrame * CFrame.Angles(particle.RotationVelocity.X*dt, particle.RotationVelocity.Y*dt, particle.RotationVelocity.Z*dt) + particle.Velocity*dt
				
				for property,motor in pairs(particle.Motors) do
					Actor[property] = motor(particle.Life / particle.Lifetime, particle)
				end
			end
		end
	end
	
	Workspace:BulkMoveTo(Actors, CFrames, Enum.BulkMoveMode.FireCFrameChanged)
end)

return VFX