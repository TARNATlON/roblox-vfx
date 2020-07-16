local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VFX = require(ReplicatedStorage.VFX)

local Part = Instance.new("Part")
Part.Material = Enum.Material.SmoothPlastic
Part.Color = Color3.fromRGB(0, 0, 0)
Part.Size = Vector3.new(1, 1, 1)
Part.CanCollide = false
Part.Anchored = true
Part.CastShadow = false
Part.BackSurface = Enum.SurfaceType.SmoothNoOutlines
Part.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
Part.FrontSurface = Enum.SurfaceType.SmoothNoOutlines
Part.LeftSurface = Enum.SurfaceType.SmoothNoOutlines
Part.RightSurface = Enum.SurfaceType.SmoothNoOutlines
Part.TopSurface = Enum.SurfaceType.SmoothNoOutlines

local function Lerp(initial, final, delta)
	return (1 - delta) * initial + delta * final
end

VFX.DescribeEmitter("TestParticles", {
    Actor = Part;
	Position = Vector3.new(0, 5, 0);
	Rate = 1;
	Acceleration = Vector3.new(0, -1, 0);
    ParticleLimit = 1;

	Velocity = function()
		return Vector3.new(math.random(-5, 5)/2.5, math.random(5, 10), math.random(-5, 5)/2.5)
	end;
	
	RotationalVelocity = function()
		return Vector3.new(math.random(-4, 4), math.random(-4, 4), math.random(4, 4))
	end;
	
	Lifetime = 2;
	
	ActorProps = {
		Orientation = function()
			return Vector3.new(math.random(-360, 360), math.random(-360, 360), math.random(-360, 360))
		end;
		
		Color = function()
			return Color3.fromRGB(255, math.random(100, 200), 0)
		end;
		
		Size = function()
			local S = math.random(5, 10)/20
			return Vector3.new(S, S, S)
		end;
	};
	
	Motors = {
		Size = function(delta, particle)
			return Vector3.new(Lerp(particle.ActorProps.Size.X, 0, delta), Lerp(particle.ActorProps.Size.Y, 0, delta), Lerp(particle.ActorProps.Size.Z, 0, delta))
		end;
		
		Transparency = function(delta)
			return Lerp(0, 0.75, delta)
		end;
	};
})

VFX.SetParticleLimit(500)

local Emitter = VFX.CreateEmitter("TestParticles")
local Emitter2 = VFX.CreateEmitter("TestParticles", {
    Position = Vector3.new(15, 5, 0);
})

wait(4)

print("Enabling...")

Emitter:Start()
--Emitter2:Start()