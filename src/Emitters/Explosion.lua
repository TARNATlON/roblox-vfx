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
local function Lerp(initial, final, delta)
	return (1 - delta) * initial + delta * final
end

--< Emitter >--
return function(describe)
    describe("Explosion", {
        Actor = Part;
        Position = Vector3.new(0, 5, 0);
        Rate = 10;
        Drag = 1;
        Acceleration = Vector3.new(0, -40, 0);
    
        Velocity = function()
            local Angle = math.rad(math.random(0, 360))
    
            return Vector3.new(math.cos(Angle), 5, math.sin(Angle)).Unit * math.random(25, 40)
        end;
        
        Lifetime = 4;
        
        ActorProps = {
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
                return Lerp(0, 0.25, delta)
            end;
        };
    }, 60)
end