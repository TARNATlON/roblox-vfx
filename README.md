# roblox-vfx

For now, you can only create a 3D particle emitter with the VFX module.

```lua
local VFX = require(...)

local props = {

}

VFX.CreateEmitter(props)
```

This will not work however because at the very minimum, you need an actor prop!

```lua
local props = {
  Actor = Instance.new("Part");
}
```

Other properties include:

``Position (Vector3): Position of the emitter``

``Rate (Number): How many seconds it takes to spawn a particle``

``Speed (Number): The speed in studs per second that the particle travels in its direction``

``Direction (Vector3): The direction that the particles travel in``

``RotationalVelocity (Vector3): The rotational velocity which gets converted to CFrame.Angles()``

``Lifetime (Number): How long each particle stays alive in seconds``

``ActorProps (Dictionary): Used to change the particle's actor on creation. Example:``
```lua
props.ActorProps = {
  Size = Vector3.new(1, 2, 1);
}
```

``Motors (Dictionary): Used to modify the particle's actor's properties during animation. Example:``
```lua
local function Lerp(initial, finish, delta)
  return (1 - delta) * initial + delta * final
end

props.Motors = {
  Transparency = function(delta, particle)
    return Lerp(0, 1, delta)
  end;
}
```
