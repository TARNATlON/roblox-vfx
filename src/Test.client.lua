local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VFX = require(ReplicatedStorage.VFX)

VFX.RegisterEmittersIn(ReplicatedStorage.Emitters)

--VFX.SetParticleLimit(2000)

--[[
for _ = 1, 50 do
    VFX.CreateEmitter("Embers", {
        Position = Vector3.new(math.random(-300, 300), 5, math.random(-300, 300));
    }):Start()
end
--]]

--[[
local Emitter = VFX.CreateEmitter("Explosion")

wait(4)

while true do
	Emitter:Emit(20)
	wait(0.5)
	Emitter:Emit(20)
	wait(0.5)
	Emitter:Emit(20)
	wait(5)
end
--]]

--[[
local Emitters = {}

for _ = 1, 20 do
    Emitters[#Emitters+1] = VFX.CreateEmitter("Fragment", {
        Position = Vector3.new(math.random(-100, 100), 5, math.random(-100, 100));
    })
end

while true do
	for _,emitter in ipairs(Emitters) do
		emitter:Emit(100)
	end

	wait(7)
end
--]]

local function Play(finished, wait, _, memory)
	print("playing effect")

	wait(3)

	print("doing particle")

	local Emitter = VFX.CreateEmitter("Fragment")
	Emitter:Start()

	memory.Emitter = Emitter

	wait(3)

	finished()
end

local function Stop(memory)
	if memory.Emitter then
		memory.Emitter:Destroy()
	end
end

VFX.DescribeEffect("Yum", {
	Play = Play;
	Stop = Stop;
})

wait(5)

local EffectInstance = VFX.CreateEffect("Yum")
EffectInstance:Play()