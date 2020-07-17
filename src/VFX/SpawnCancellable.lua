--< Functions >--
local function FastSpawn(fn, ...)
	local Arguments = {...}
	local Count = select("#", ...)
	
	local Bindable = Instance.new("BindableEvent")
	Bindable.Event:Connect(function()
		fn(unpack(Arguments, 1, Count))
	end)
	
	Bindable:Fire()
	Bindable:Destroy()
end

--< Module>--
local function SpawnCancellable(fn, ...)
    local Spawn = {
        Canceled = false;
    }
    
    local Co = coroutine.create(fn)
    
    local Args = {...}

    local function StepCoroutine(ok, callback, ...)
        if not ok then
            error(callback)
        end
        
        if Spawn.Canceled then
            return
        end
        
        if coroutine.status(Co) == "suspended" and typeof(callback) == "function" then
			local Resolution = table.pack(callback(...))
			
			if Spawn.Canceled then
				return
			end
			
			StepCoroutine(coroutine.resume(Co, unpack(Resolution, 1, Resolution.n)))
        end
    end
    
    FastSpawn(function()
        StepCoroutine(coroutine.resume(Co, unpack(Args)))
    end)
    
    return Spawn
end

return SpawnCancellable