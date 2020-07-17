--< Constants >--
local RNG = Random.new()

--< Variables >--
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

--< Functions >--
local function QuadOut(initial, final, delta)
	local Change = final - initial
	
	return -Change * delta*(delta-2) + initial
end

--< Emitter >--
return function(describe)
    describe("Fragment", {
        Actor = Part;
        Rate = 10;
        Position = Vector3.new(0, 5, 0);
        
        Acceleration = function()
            return Vector3.new(0, RNG:NextInteger(1, 3), 0)
        end;
        
        Drag = 0.8;
        
        Lifetime = function()
            return RNG:NextNumber(4, 6)
        end;
        
        Velocity = function()
            local Direction = Vector3.new(RNG:NextNumber(-1, 1), RNG:NextNumber(-0.25, 1), RNG:NextNumber(-1, 1)).Unit 
            
            return Direction * RNG:NextNumber(9, 11)
        end;
        
        RotationalVelocity = function()
            return Vector3.new(math.rad(RNG:NextInteger(-180, 180)), math.rad(RNG:NextInteger(-180, 180)), math.rad(RNG:NextInteger(-180, 180)))
        end;
        
        ActorProps = {
            Orientation = function()
                return Vector3.new(RNG:NextInteger(-360, 360), RNG:NextInteger(-360, 360), RNG:NextInteger(-360, 360))
            end;
            
            Size = function()
                local Size = RNG:NextNumber(0.5, 1.25);
                return Vector3.new(Size, 0.05, Size);
            end;
        };
        
        Motors = {
            Size = function(delta, particle)
                return Vector3.new(QuadOut(particle.ActorProps.Size.X, 0, delta), QuadOut(particle.ActorProps.Size.Y, 0, delta), QuadOut(particle.ActorProps.Size.Z, 0, delta))
            end;
        };
    }, 60)
end