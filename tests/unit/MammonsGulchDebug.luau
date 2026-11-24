local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local function characterMock()
    local character = {
        pivots = {},
        HumanoidRootPart = {},
        Humanoid = { Health = 45 },
    }
    function character:PivotTo(frame)
        table.insert(self.pivots, frame.Position)
    end
    function character:FindFirstChildOfClass(className)
        if className == "Humanoid" then
            return self.Humanoid
        end
        return nil
    end
    function character:FindFirstChild(name)
        return self[name]
    end
    return character
end

local function loadService(studio)
    local remote
    local requester = {
        Character = characterMock(),
        attributes = {},
    }
    function requester:SetAttribute(name, value)
        self.attributes[name] = value
    end
    local other = { Character = characterMock() }
    local service = { requester = requester, other = other, remote = nil }
    local replicated = {
        Shared = {},
        FindFirstChild = function(_, name)
            if name == "MammonsGulchDebugTeleport" then
                return remote
            end
            return nil
        end,
    }
    local environment = {
        Vector3 = roblox.Vector3,
        CFrame = roblox.CFrame,
        RunService = {
            IsStudio = function()
                return studio
            end,
        },
        ReplicatedStorage = replicated,
        Players = {
            PlayerRemoving = {
                Connect = function()
                    return nil
                end,
            },
        },
        Instance = {
            new = function(className)
                assert(className == "RemoteEvent", "only one debug remote may be created")
                remote = {
                    IsA = function(_, expectedClass)
                        return expectedClass == "RemoteEvent"
                    end,
                    OnServerEvent = {
                        Connect = function(_, callback)
                            remote.callback = callback
                        end,
                    },
                }
                service.remote = remote
                return remote
            end,
        },
    }
    environment.game = {
        GetService = function(_, name)
            if name == "RunService" then
                return environment.RunService
            end
            if name == "ReplicatedStorage" then
                return replicated
            end
            if name == "Players" then
                return environment.Players
            end
            if name == "Workspace" then
                return {}
            end
            error("unexpected service: " .. name)
        end,
    }
    environment.require = function(target)
        if type(target) == "table" then
            return target
        end
        if target == "CompoundDefinitions" then
            return luau.load(fs.readFile("src/shared/mammons-gulch/CompoundDefinitions.luau"), {
                environment = environment,
            })()
        end
        if target == "DebugConfig" then
            return luau.load(fs.readFile("src/shared/mammons-gulch/DebugConfig.luau"), {
                environment = environment,
            })()
        end
        error("unexpected require: " .. tostring(target))
    end
    replicated.Shared["mammons-gulch"] = {
        CompoundDefinitions = environment.require("CompoundDefinitions"),
        DebugConfig = environment.require("DebugConfig"),
    }
    service.module = luau.load(fs.readFile("places/mammons-gulch/server/DebugService.luau"), {
        debugName = "DebugService",
        environment = environment,
    })()
    return service
end

do
    local service = loadService(false)
    local started = service.module.start()
    assert(started == false, "debug service must not start outside Studio")
    assert(service.remote == nil, "no debug remote outside Studio")
end

do
    local service = loadService(true)
    service.module.start()
    assert(service.remote and service.remote.callback, "Studio remote and handler are required")
    service.remote.callback(service.requester, "com_i")
    assert(#service.requester.Character.pivots == 1, "valid compound should teleport once")
    local position = service.requester.Character.pivots[1]
    assert(math.abs(position.X + 164.352) < 0.01, "La Plata X")
    assert(math.abs(position.Y - 80.24616) < 0.01, "La Plata Y + 6")
    assert(math.abs(position.Z - 272.7936) < 0.01, "La Plata Z")
    assert(service.requester.attributes.DebugCompoundId == "com_i", "server records selected ID")
    assert(#service.other.Character.pivots == 0, "other players must not move")
end

do
    local service = loadService(true)
    service.module.start()
    service.remote.callback(service.requester, "not-a-compound")
    service.remote.callback(service.requester, { 1, 2, 3 })
    assert(
        #service.requester.Character.pivots == 0,
        "unknown IDs and arbitrary payloads are rejected"
    )
end

do
    local service = loadService(true)
    service.module.start()
    service.remote.callback(service.requester, "com_i")
    service.remote.callback(service.requester, "com_j")
    assert(#service.requester.Character.pivots == 1, "second request inside cooldown is rejected")
end

do
    local service = loadService(true)
    service.module.start()
    service.requester.Character.Humanoid.Health = 0
    service.remote.callback(service.requester, "com_i")
    assert(#service.requester.Character.pivots == 0, "dead characters are not teleported")
end

print("mammons-gulch debug: Studio gate, ID validation, throttle and player isolation passed")
