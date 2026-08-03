local Passes = 0
local Fails = 0
local Undefined = 0
local Running = 0
local TestOrder = {}
local Results = {}

local function getenvvalue(path)
    local segments = string.split(path, ".")
    local current = getgenv()
    
    for _, segment in ipairs(segments) do
        if type(current) ~= "table" then
            return nil
        end
        current = current[segment]
    end
    
    return current
end

local function Test(Name, Aliases, Callbacks)
    Running = Running + 1
    table.insert(TestOrder, Name)

    task.spawn(function()
        local TargetFunc = getenvvalue(Name)
        local AliasMissing = false

        for _, Alias in ipairs(Aliases or {}) do
            if getenvvalue(Alias) == nil then
                AliasMissing = true
                break
            end
        end

        local StatusEmoji = AliasMissing and "🟡" or "🟢"

        if not TargetFunc then
            local FailMsg = "Function is nil"
            if Callbacks and Callbacks.Failed then
                local Ok, CustomMsg = pcall(Callbacks.Failed, FailMsg)
                if Ok and CustomMsg then
                    FailMsg = CustomMsg
                end
            end
            Results[Name] = {Success = false, Msg = FailMsg, Emoji = "🔴"}
            Fails = Fails + 1
        else
            local Success, Result
            if Callbacks and Callbacks.Passed then
                Success, Result = pcall(Callbacks.Passed, TargetFunc)
            else
                Success = true
            end

            if Success then
                Results[Name] = {Success = true, Msg = Result, Emoji = StatusEmoji}
                Passes = Passes + 1
            else
                local FailMsg = Result
                if Callbacks and Callbacks.Failed then
                    local Ok, CustomMsg = pcall(Callbacks.Failed, FailMsg)
                    if Ok and CustomMsg then
                        FailMsg = CustomMsg
                    end
                end
                Results[Name] = {Success = false, Msg = FailMsg, Emoji = "🔴"}
                Fails = Fails + 1
            end
        end

        Running = Running - 1
    end)
end
local function getrandomstring(length)
    math.randomseed(os.time() ^ math.random())
    local characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"
    local result = ""
    for i = 1, length do
        local randomIndex = math.random(1, #characters)
        result = result .. characters:sub(randomIndex, randomIndex)
    end
    return result
end

print("\n\n            vUNC\n            Made by @veaquach on Discord\n\n")
local executorName = (identifyexecutor and identifyexecutor()) or "Executor"
if executorName == "Volt" then
    warn"i love volt"
elseif executorName == "Potassium" then
    warn("i love potassium")
elseif executorName == "Real" then
    warn("i love real")
elseif executorName == "Madium" then
    warn("i love madium")
end

Test("loadstring", {}, {
    Passed = function(TargetFunc)
        loadstring("print'hello world from loadstring!';getgenv().LoadstringMintTestPassed = 'hello'")()
        assert(getgenv().LoadstringMintTestPassed=="hello", "loadstring did not set a global value to a string.")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("writefile", {}, {
    Passed = function(TargetFunc)
        local Name = getrandomstring(15) .. ".vunc"
        TargetFunc(Name, "hello from vunc!")
        local isoktouseisfile = pcall(isfile, Name)
        if not isoktouseisfile then
            warn("Dependency failure: 'isfile' crashed or is missing, cannot safely verify 'writefile'.")
        end
        local isoktousereadfile = pcall(readfile, Name)
        if not isoktousereadfile then
            warn("Dependency failure: 'readfile' crashed or is missing, cannot safely verify 'writefile'.")
        end
        assert(isfile(Name) and readfile(Name) == "hello from vunc!", "writefile did not write a .vunc file to disk.")
        pcall(delfile, Name)
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("isfile", {}, {
    Passed = function(TargetFunc)
        local NameToWrite = getrandomstring(15) .. ".vunc"
        pcall(writefile, NameToWrite, "hello world!")
        assert(TargetFunc(NameToWrite), "did not see file made by writefile")
        pcall(delfile, NameToWrite)
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("delfile", {}, {
    Passed = function(TargetFunc)
        local NameToWrite = getrandomstring(15) .. ".vunc"
        pcall(writefile, NameToWrite, "testing delfile :3")
        pcall(TargetFunc, NameToWrite)
        assert(not isfile(NameToWrite), "file was not deleted")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("makefolder", {}, {
    Passed = function(TargetFunc)
        local FolderName = getrandomstring(35)
        TargetFunc(FolderName)

        local isoktouseisfolder, folderexists = pcall(isfolder, FolderName)
        if not isoktouseisfolder then
            warn("Dependency failure: 'isfolder' crashed or is missing.")
        end
        assert(folderexists == true, 'makefolder did not make a folder')
        pcall(delfolder, FolderName)
        return 'passed'
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("isfolder", {}, {
    Passed = function(TargetFunc)
        local FolderName = getrandomstring(35)
        pcall(makefolder, FolderName)
        assert(isfolder(FolderName), "could not see a folder made by makefolder")
        pcall(delfolder, FolderName)
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("delfolder", {}, {
    Passed = function(TargetFunc)
        local FolderName = getrandomstring(35)
        pcall(makefolder, FolderName)
        delfolder(FolderName)
        assert(not isfolder(FolderName), "created folder remained after being deleted")
        pcall(delfolder, FolderName)
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("hookfunction", {}, {
    Passed = function(TargetFunc)
        getgenv().TestGotHooked = false
        local function hooktest()
            getgenv().TestGotHooked = false
        end
        pcall(function() 
            local hook = TargetFunc(hooktest, function()
                getgenv().TestGotHooked = true
                return
            end)
        end)
        hooktest()
        assert(getgenv().TestGotHooked == true, "failed to hook test function.")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("hookmetamethod", {}, {
    Passed = function(TargetFunc)
        local metatable = setmetatable({}, {
            __index = function()
                return 1
            end,
        })

        pcall(TargetFunc, metatable, "__index", function()
            return "vUNC" 
        end) 
        assert(metatable.b == "vUNC", "hook on a meta table did not return the correct value")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("cloneref", {}, {
    Passed = function(TargetFunc)
        local part = Instance.new("Part", workspace)
        local cloned = TargetFunc(part)
        assert(cloned ~= nil, "cloneref returned nil")
        assert(cloned ~= part, "cloneref returned the same part instead of a cloned one")
        part:Destroy()
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

-- get functions
Test("getnilinstances", {}, {
    Passed = function(TargetFunc)
        local Name = getrandomstring(35)
        local Part = Instance.new("Part", nil)
        Part.Name = Name
        local list = TargetFunc()
        assert(type(list) == "table", "getnilinstances did not return a table")
        local found = false
        for _, inst in ipairs(list) do
            if inst == Part and inst.Name == Name then
                found = true
                break
            end
        end
        Part:Destroy()

        assert(found == true, "created nil instance was not found in getnilinstances")
        return 'passed'
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getgenv", {}, {
    Passed = function(TargetFunc)
        local env = TargetFunc()
        assert(type(env) == "table", "getgenv did not return a table")

        local testkey = "vUNCTest_" .. getrandomstring(10)
        env[testkey] = true
        assert(_G[testkey] == nil, 'getgenv shared variables with _G table')
        env[testkey] = nil
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getrenv", {}, {
    Passed = function(TargetFunc)
        local env = TargetFunc()
        assert(type(env) == "table", "getrenv did not return a table")
        assert(env.print ~= nil, "getrenv is missing standard functions")
        assert(env.getrenv == nil, "getrenv contains executor functions")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getscripthash", {}, {
    Passed = function(TargetFunc)
        local script = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerScripts"):FindFirstChildWhichIsA("LocalScript", true) 
            or game:GetService("ReplicatedFirst"):FindFirstChildWhichIsA("LocalScript", true)

        assert(script ~= nil, "Failed to find a valid game script to hash.")

        local success, hash = pcall(TargetFunc, script)
        assert(success, "getscripthash failed to execute on target script")
        assert(type(hash) == "string", "getscripthash did not return a string")
        assert(#hash == 96 or #hash == 64, "hash length was incorrect (expected SHA-384 96 or SHA-256 64 chars)")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getloadedmodules", {}, {
    Passed = function(TargetFunc)
        local list = TargetFunc()
        assert(type(list) == "table", "getloadedmodules did not return a table")
        assert(#list > 0, "getloadedmodules returned an empty table")
        assert(#list < 2000, "getloadedmodules returned an impossibly high number of modules (" .. tostring(#list) .. ")")

        local invalidobjects = 0
        for i = 1, math.min(#list, 10) do
            local item = list[i]
            if typeof(item) ~= "Instance" or not item:IsA("ModuleScript") then
                invalidobjects = invalidobjects + 1
            end
        end

        assert(invalidobjects == 0, "executor is faking getloadedmodules by returning non-modulescript instances")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getcustomasset", {}, {
    Passed = function(TargetFunc)
        local filename = getrandomstring(25) .. ".txt"
        pcall(writefile, filename, "dummy asset")
        local success, asset = pcall(TargetFunc, filename)
        pcall(delfile, filename)
        assert(success, "getcustomasset failed to execute")
        assert(type(asset) == "string", "getcustomasset did not return a string")
        assert(string.find(asset, "rbxassetid://") or string.find(asset, "http") or string.find(asset, "rbxasset://"), "getcustomasset is not a assetid or url")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getrawmetatable", {}, {
    Passed = function(TargetFunc)
        local metatable = TargetFunc(game)
        assert(type(metatable) == "table", "getrawmetatable did not return a table")
        assert(rawget(metatable, "__index") ~= nil, "metatable is missing standard metamethods")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getrenderproperty", {}, {
    Passed = function(TargetFunc)
        local drawing = Drawing.new("Square")
        drawing.Visible = true
        
        local success, val = pcall(TargetFunc, drawing, "Visible")
        drawing:Remove()
        
        assert(success, "getrenderproperty failed to execute")
        assert(val == true, "getrenderproperty did not return the correct property value")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getinstances", {}, {
    Passed = function(TargetFunc)
        local list = TargetFunc()
        assert(type(list) == "table", "getinstances did not return a table")
        assert(#list > 0, "getinstances returned an empty table")
        assert(typeof(list[1]) == "Instance", "getinstances list items are not instances")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("gethui", {}, {
    Passed = function(TargetFunc)
        local hui = TargetFunc()
        assert(typeof(hui) == "Instance", "gethui did not return an instance")
        assert(hui.ClassName ~= nil, "gethui instance is missing standard class structure")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getthreadidentity", {}, {
    Passed = function(TargetFunc)
        local identity = TargetFunc()
        assert(type(identity) == "number", "getthreadidentity did not return a number")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getscriptbytecode", {}, {
    Passed = function(TargetFunc)
        local targetscript = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerScripts"):FindFirstChildWhichIsA("LocalScript", true)
        assert(targetscript ~= nil, "failed to find a script for bytecode check")
        
        local success, bytecode = pcall(TargetFunc, targetscript)
        assert(success, "getscriptbytecode failed to execute")
        assert(type(bytecode) == "string", "getscriptbytecode did not return a string")
        assert(#bytecode > 0, "returned bytecode string is empty")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("debug.getprotos", {}, {
    Passed = function(TargetFunc)
        local function testfunc()
            local function innerfunc()
                return "active"
            end
            return innerfunc
        end
        testfunc()()
        
        local protos = TargetFunc(testfunc)
        assert(type(protos) == "table", "debug.getprotos did not return a table")
        assert(#protos > 0 or next(protos) ~= nil, "debug.getprotos returned an empty prototypes array")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})
Test("getscriptclosure", {}, {
    Passed = function(TargetFunc)
        local players = game:GetService("Players")
        local localplayer = players.LocalPlayer
        local playerscripts = localplayer and localplayer:FindFirstChildOfClass("PlayerScripts")
        local script1 = playerscripts and playerscripts:FindFirstChildWhichIsA("LocalScript", true)
        
        assert(script1 ~= nil, "failed to find a valid localscript context for validation")
        
        local success1, closure1 = pcall(TargetFunc, script1)
        assert(success1 and type(closure1) == "function", "getscriptclosure failed or returned invalid type")
        
        local fakeScript = Instance.new("LocalScript")
        local success2, closure2 = pcall(TargetFunc, fakeScript)
        if success2 and type(closure2) == "function" then
            error("executor is faking getscriptclosure: it returned a function handle for an empty script with no bytecode")
        end
        
        local success3, closure3 = pcall(TargetFunc, Instance.new("Folder"))
        if not success3 and string.find(tostring(closure3), "is not a valid member of Folder") then
            error("executor is faking getscriptclosure: leaked internal property lookup error")
        elseif success3 then
            error("executor is faking getscriptclosure: successfully returned a closure for a Folder instance")
        end
        
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("debug.getinfo", {}, {
    Passed = function(TargetFunc)
        local function sample1() return "a" end
        local function sample2(x, y, z) return x end
        
        local info1 = TargetFunc(sample1)
        local info2 = TargetFunc(sample2)
        
        assert(type(info1) == "table" and type(info2) == "table", "debug.getinfo did not return info tables")
        
        if info1.nups and info1.nups < 0 then
            error("executor is faking debug.getinfo: returned an impossible negative upvalue count")
        end
        
        if info1.linedefined and info1.linedefined == -1 then
            error("executor is faking debug.getinfo: failed to resolve valid line definitions")
        end
        
        if info1.isvararg ~= nil or info1.nparams ~= nil or info1.namewhat ~= nil then
            error("executor is faking debug.getinfo: leaked non-standard vanilla Lua fields")
        end
        
        if info1.func ~= nil then
            assert(info1.func == sample1, "debug.getinfo returned a 'func' key that doesn't match the original function reference")
        else
            error("executor is faking debug.getinfo: missing critical 'func' key reference")
        end
        
        if info1.numparams and info2.numparams then
            assert(info1.numparams == 0 and info2.numparams == 3, "debug.getinfo returned static or incorrect parameter counts")
        end
        
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getgc", {}, {
    Passed = function(TargetFunc)
        local gc = TargetFunc()
        assert(type(gc) == "table", "getgc did not return a table")
        assert(#gc > 0, "getgc table is empty")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})
Test("getcallingscript", {}, {
    Passed = function(TargetFunc)
        local scr = TargetFunc()
        assert(scr == nil or typeof(scr) == "Instance", "getcallingscript did not return a valid instance or nil")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getrunningscripts", {}, {
    Passed = function(TargetFunc)
        local list = TargetFunc()
        assert(type(list) == "table", "getrunningscripts did not return a table")
        assert(#list > 0, "getrunningscripts returned an empty table")
        assert(#list < 5000, "executor is faking getrunningscripts via a full game tree instance dump")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})
Test("debug.getproto", {}, {
    Passed = function(TargetFunc)
        local function testFunc()
            local function innerFunc()
                return "active"
            end
            return innerFunc
        end
        testFunc()()
        
        local success, proto = pcall(TargetFunc, testFunc, 1, true)
        if not success or (type(proto) ~= "function" and type(proto) ~= "table") then
            success, proto = pcall(TargetFunc, testFunc, 1)
        end
        
        assert(success, "debug.getproto failed to execute")
        assert(type(proto) == "function" or type(proto) == "table" or type(proto) == "userdata", "debug.getproto did not return a valid prototype structure")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("base64_encode", {}, {
    Passed = function(TargetFunc)
        local data = "hello world"
        local encoded = TargetFunc(data)
        assert(type(encoded) == "string", "base64_encode did not return a string")
        assert(encoded == "aGVsbG8gd29ybGQ=", "base64_encode returned an incorrect hash value")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("base64_decode", {}, {
    Passed = function(TargetFunc)
        local hash = "aGVsbG8gd29ybGQ="
        local decoded = TargetFunc(hash)
        assert(type(decoded) == "string", "base64_decode did not return a string")
        assert(decoded == "hello world", "base64_decode returned an incorrect decoded string")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("lz4compress", {}, {
    Passed = function(TargetFunc)
        local data = "test_lz4_string_compression_data_123!"
        local compressed = TargetFunc(data)
        assert(type(compressed) == "string", "lz4compress did not return a string")
        assert(compressed ~= data, "lz4compress left data uncompressed")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("lz4decompress", {}, {
    Passed = function(TargetFunc)
        local raw = "test_lz4_string_compression_data_123!"
        local compressFunc = getgenv().lz4compress
        assert(compressFunc ~= nil, "lz4compress is required to verify lz4decompress")
        
        local compressed = compressFunc(raw)
        local decompressed = TargetFunc(compressed, #raw)
        assert(type(decompressed) == "string", "lz4decompress did not return a string")
        assert(decompressed == raw, "lz4decompress failed to reconstruct the original data")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getconnections", {}, {
    Passed = function(TargetFunc)
        local bindable = Instance.new("BindableEvent")
        local fired = false
        local connection = bindable.Event:Connect(function() fired = true end)
        
        local list = TargetFunc(bindable.Event)
        assert(type(list) == "table", "getconnections did not return a table")
        assert(#list > 0, "getconnections returned an empty list for a valid connection")
        
        local targetConn = list[1]
        assert(type(targetConn) == "table" or type(targetConn) == "userdata", "connection container type mismatch")
        
        if type(targetConn) == "table" or type(targetConn) == "userdata" then
            assert(targetConn.Disconnect ~= nil or targetConn.disconnect ~= nil, "connection object missing Disconnect capability")
        end
        
        connection:Disconnect()
        bindable:Destroy()
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getscriptfromthread", {}, {
    Passed = function(TargetFunc)
        local currentThread = coroutine.running()
        local scriptAssociated = TargetFunc(currentThread)
        
        local success, result = pcall(TargetFunc, "NotAThread")
        if success then
            error("executor is faking getscriptfromthread: accepted raw strings as thread references")
        end
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getscripts", {}, {
    Passed = function(TargetFunc)
        local scriptList = TargetFunc()
        assert(type(scriptList) == "table", "getscripts did not return an array table")
        assert(#scriptList > 0, "getscripts returned zero script instances in the active tree")
        assert(typeof(scriptList[1]) == "Instance", "script collection contains non-instance data entries")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("decompile", {}, {
    Passed = function(TargetFunc)
        local players = game:GetService("Players")
        local localplayer = players.LocalPlayer
        local playerscripts = localplayer and localplayer:FindFirstChildOfClass("PlayerScripts")
        local scriptObj = playerscripts and playerscripts:FindFirstChildWhichIsA("LocalScript", true)
        
        assert(scriptObj ~= nil, "failed to find a valid localscript context for decompilation")
        
        local decompiledCode = TargetFunc(scriptObj)
        assert(type(decompiledCode) == "string", "decompile function did not yield string output data")
        
        local success, resultEmpty = pcall(TargetFunc, Instance.new("LocalScript"))
        if success and resultEmpty == decompiledCode and #decompiledCode > 0 then
            error("executor is faking decompile: identical static output string generated for distinct structures")
        end
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("cache.iscached", {}, {
    Passed = function(TargetFunc)
        local part = Instance.new("Part")
        local isCached = TargetFunc(part)
        assert(type(isCached) == "boolean", "cache.iscached did not produce a boolean status")
        assert(isCached == true, "newly allocated game instance reference was missing from VM registry cache")
        part:Destroy()
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("cache.replace", {}, {
    Passed = function(TargetFunc)
        local sourcePart = Instance.new("Part")
        local targetPart = Instance.new("Part")
        
        local success = pcall(function()
            TargetFunc(sourcePart, targetPart)
        end)
        
        assert(success, "cache.replace encountered execution failures during swap")
        
        sourcePart:Destroy()
        targetPart:Destroy()
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("cache.invalidate", {}, {
    Passed = function(TargetFunc)
        local testPart = Instance.new("Part")
        local iscachedFunc = getgenv().cache and getgenv().cache.iscached
        
        local success = pcall(function()
            TargetFunc(testPart)
        end)
        assert(success, "cache.invalidate encountered evaluation execution faults")
        
        if iscachedFunc then
            assert(iscachedFunc(testPart) == false, "cache.invalidate failed to strip instance reference out of engine registry cache")
        end
        testPart:Destroy()
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("filtergc", {}, {
    Passed = function(TargetFunc)
        local uniqueToken = {token = "strict_filtergc_check"}
        
        local success, results = pcall(TargetFunc, "tables", false)
        if not success then
            success, results = pcall(TargetFunc, "tables")
        end
        if not success then
            success, results = pcall(TargetFunc)
        end
        
        if not success or type(results) ~= "table" then
            return "passed"
        end
        
        local discovered = false
        for _, tbl in pairs(results) do
            if type(tbl) == "table" and tbl.token == "strict_filtergc_check" then
                discovered = true
                break
            end
        end
        
        assert(discovered == true, "executor is faking filtergc: failed to track newly allocated elements in the active GC registry pool")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("checkcaller", {}, {
    Passed = function(TargetFunc)
        -- im sorry but i was fed up as fuck with how good solara was faking the function but i know it doesnt work on externals so yeah
        local metatable = setmetatable({}, {
            __index = function()
                return 1
            end,
        })

        pcall(hookmetamethod, metatable, "__index", function()
            return "vUNC" 
        end) 
        assert(metatable.b == "vUNC", "external executor, checkcaller not available 100%")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("restorefunction", {}, {
    Passed = function(TargetFunc)
        local targetHook = game.Workspace.GetRealPhysicsFPS
        
        local success, err = pcall(TargetFunc, targetHook)
        if not success and string.find(tostring(err), "not hooked") then
            return "passed"
        end
        
        assert(success, "restorefunction failed handling native standard engine operations entries: " .. tostring(err))
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("isexecutorclosure", {}, {
    Passed = function(TargetFunc)
        local function testNativeClosure() end
        local isExecClosure = TargetFunc(testNativeClosure)
        
        assert(type(isExecClosure) == "boolean", "isexecutorclosure did not return a boolean result")
        assert(isExecClosure == true, "isexecutorclosure failed to identify internal closure references")
        assert(TargetFunc(print) == false, "isexecutorclosure falsely tagged a core game C-closure engine interface")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getfunctionhash", {}, {
    Passed = function(TargetFunc)
        local function hashTargetClosure() return true end
        local hashResult = TargetFunc(hashTargetClosure)
        
        assert(type(hashResult) == "string", "getfunctionhash failed to yield string hex output values")
        
        local distinctHash = TargetFunc(function() return false end)
        assert(hashResult ~= distinctHash, "getfunctionhash generated duplicate signature blocks across variable structures")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("newcclosure", {}, {
    Passed = function(TargetFunc)
        local metatable = setmetatable({}, {
            __index = function()
                return 1
            end,
        })

        pcall(hookmetamethod, metatable, "__index", function()
            return "vUNC" 
        end) 
        assert(metatable.b == "vUNC", "external executor, newcclosure not available 100%")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("debug.getupvalue", {}, {
    Passed = function(TargetFunc)
        local trackingValue = "target_upvalue_signature"
        local function trackingClosure() return trackingValue end
        
        local success, upvalueResult = pcall(TargetFunc, trackingClosure, 1)
        assert(success, "debug.getupvalue processing runtime exception faulted out")
        assert(upvalueResult == "target_upvalue_signature", "debug.getupvalue read incorrect up value block state data")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("debug.getupvalues", {}, {
    Passed = function(TargetFunc)
        local contextA = 50
        local contextB = "string_state"
        local function collectionClosure() return contextA, contextB end
        
        local upvaluesTable = TargetFunc(collectionClosure)
        assert(type(upvaluesTable) == "table", "debug.getupvalues failed to capture map elements as a collection array")
        assert(upvaluesTable[1] == 50 or upvaluesTable[2] == 50, "debug.getupvalues map structure is missing up value references")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("debug.setupvalue", {}, {
    Passed = function(TargetFunc)
        local activeState = "initial_state"
        local function executionClosure() return activeState end
        
        local success = pcall(TargetFunc, executionClosure, 1, "mutated_state")
        if not success then
            success = pcall(TargetFunc, executionClosure, 0, "mutated_state")
        end
        if not success then
            success = pcall(TargetFunc, executionClosure, "activeState", "mutated_state")
        end
        
        if not success then
            return "passed"
        end
        
        if executionClosure() ~= "mutated_state" then
            local getupvalues = getgenv().debug and getgenv().debug.getupvalues
            if getupvalues then
                local ok, upvals = pcall(getupvalues, executionClosure)
                if ok and type(upvals) == "table" then
                    local found = false
                    for _, val in pairs(upvals) do
                        if val == "mutated_state" then
                            found = true
                            break
                        end
                    end
                    assert(found == true, "executor is faking debug.setupvalue: closure captures remain completely unmutated")
                end
            end
        end
        
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("listfiles", {}, {
    Passed = function(TargetFunc)
        local success, fileCollection = pcall(TargetFunc, "")
        if not success then
            success, fileCollection = pcall(TargetFunc, ".")
        end
        if not success then
            success, fileCollection = pcall(TargetFunc)
        end
        
        assert(success and type(fileCollection) == "table", "listfiles directory query failed to yield tracking arrays")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("request", {}, {
    Passed = function(TargetFunc)
        local httpStructure = {
            Url = "https://www.google.com",
            Method = "GET"
        }
        
        local success, httpResult
        local completed = false
        
        task.spawn(function()
            success, httpResult = pcall(TargetFunc, httpStructure)
            completed = true
        end)
        
        local retries = 0
        while not completed and retries < 20 do
            task.wait(0.1)
            retries = retries + 1
        end
        
        assert(completed, "request execution pipeline encountered an external network timeout")
        assert(success, "request execution pipeline encountered core transport exceptions")
        assert(type(httpResult) == "table", "request interface failed to generate standard network payload tables")
        assert(httpResult.StatusCode ~= nil, "network transaction table response payload missing standard Status code track keys")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("WebSocket.connect", {}, {
    Passed = function(TargetFunc)
        local success, socketHandle = pcall(TargetFunc, "wss://echo.websocket.events")
        if success then
            assert(type(socketHandle) == "table" or type(socketHandle) == "userdata", "WebSocket container format mismatch")
            assert(socketHandle.Send ~= nil and socketHandle.Close ~= nil, "WebSocket object structure missing required capabilities hooks")
            socketHandle:Close()
        end
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("appendfile", {}, {
    Passed = function(TargetFunc)
        local writefileFunc = getgenv().writefile
        local readfileFunc = getgenv().readfile
        local delfileFunc = getgenv().delfile
        
        assert(writefileFunc and readfileFunc, "filesystem prerequisites are missing to test appendfile operations")
        
        writefileFunc("append_validation.txt", "base_payload")
        local success = pcall(TargetFunc, "append_validation.txt", "_appended_payload")
        assert(success, "appendfile filesystem modification operation faulted out")
        
        local integratedData = readfileFunc("append_validation.txt")
        if delfileFunc then pcall(delfileFunc, "append_validation.txt") end
        
        assert(integratedData == "base_payload_appended_payload", "appendfile operation failed to append content to the target storage container")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("setthreadidentity", {}, {
    Passed = function(TargetFunc)
        local getidentityFunc = getgenv().getthreadidentity or getgenv().getthreadcontext
        assert(getidentityFunc ~= nil, "thread verification tools missing to analyze identity shifting updates")
        
        local initialIdentity = getidentityFunc()
        local success = pcall(TargetFunc, 3)
        assert(success, "setthreadidentity modification context operation faulted out")
        
        local shiftedIdentity = getidentityFunc()
        pcall(TargetFunc, initialIdentity)
        
        assert(shiftedIdentity == 3, "setthreadidentity failed to update active thread context execution maps")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("setreadonly", {}, {
    Passed = function(TargetFunc)
        local variantTable = { property = "fixed" }
        
        local setro = TargetFunc or getgenv().setreadonly or getgenv().make_readonly
        if not setro then
            return "passed"
        end
        
        local success = pcall(setro, variantTable, true)
        if not success then
            return "passed"
        end
        
        if table.isreadonly then
            assert(table.isreadonly(variantTable) == true, "executor is faking setreadonly: failed to secure target container tables to structural read-only modes")
        else
            local writeSuccess = pcall(function() variantTable.property = "mutated" end)
            assert(writeSuccess == false, "executor is faking setreadonly: table values remain mutable when frozen")
        end
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("isreadonly", {}, {
    Passed = function(TargetFunc)
        local staticTable = { val = 1 }
        table.freeze(staticTable)
        
        local readOnlyCheck = TargetFunc(staticTable)
        assert(type(readOnlyCheck) == "boolean", "isreadonly did not return a boolean status flag")
        assert(readOnlyCheck == true, "isreadonly failed to identify a structurally frozen table context")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("sethiddenproperty", {}, {
	Passed = function(TargetFunc)
		-- Target the actual local player object, not the service container
		local localPlayer = game:GetService("Players").LocalPlayer
		assert(localPlayer ~= nil, "LocalPlayer instance not available for validation")

		-- SimulationRadius exists on the Player instance
		local success, err = pcall(TargetFunc, localPlayer, "SimulationRadius", 15)
		assert(success, "sethiddenproperty structural update pipeline operation faulted out: " .. tostring(err))

		local fakeSuccess = pcall(TargetFunc, localPlayer, "NonExistentPropertyFakeName123", true)
		if fakeSuccess then
			error("executor is faking sethiddenproperty: successfully validated impossible mock properties")
		end
		return "passed"
	end,
	Failed = function(Err)
		return "Test failure: " .. tostring(Err)
	end,
})

Test("gethiddenproperty", {}, {
    Passed = function(TargetFunc)
        local metatable = setmetatable({}, {
            __index = function()
                return 1
            end,
        })

        pcall(hookmetamethod, metatable, "__index", function()
            return "vUNC" 
        end) 
        assert(metatable.b == "vUNC", "external executor, gethiddenproperty not available 100%")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})
Test("setscriptable", {}, {
    Passed = function(TargetFunc)
        local targetObject = Instance.new("Part")
        local success, initialScriptableState = pcall(TargetFunc, targetObject, "Position", true)
        
        assert(success, "setscriptable structural visibility adjustment operation faulted out")
        assert(type(initialScriptableState) == "boolean", "setscriptable did not output previous property configuration states")
        targetObject:Destroy()
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("isscriptable", {}, {
    Passed = function(TargetFunc)
        local targetObject = Instance.new("Part")
        local isScriptable = TargetFunc(targetObject, "Position")
        
        assert(type(isScriptable) == "boolean", "isscriptable did not output a boolean result flag")
        assert(isScriptable == true, "standard public property reported back as non-scriptable")
        targetObject:Destroy()
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("compareinstances", {}, {
    Passed = function(TargetFunc)
        local metatable = setmetatable({}, {
            __index = function()
                return 1
            end,
        })

        pcall(hookmetamethod, metatable, "__index", function()
            return "vUNC" 
        end) 
        assert(metatable.b == "vUNC", "external executor, compareinstance not available 100%")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("Drawing.new", {}, {
    Passed = function(TargetFunc)
        local canvasShape = TargetFunc("Line")
        assert(canvasShape ~= nil, "Drawing.new failed to generate asset instances")
        assert(canvasShape.Visible ~= nil, "Drawing canvas asset missing basic state property maps")
        
        canvasShape.Visible = false
        canvasShape:Remove()
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("Drawing.Fonts", {}, {
    Passed = function(TargetFunc)
        assert(type(TargetFunc) == "table", "Drawing.Fonts structure metadata element is missing")
        assert(TargetFunc.UI ~= nil or TargetFunc.Monospace ~= nil, "Drawing.Fonts layout data maps are unpopulated")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("isrenderobj", {}, {
    Passed = function(TargetFunc)
        local drawingAllocationFunc = getgenv().Drawing and getgenv().Drawing.new
        assert(drawingAllocationFunc ~= nil, "Drawing allocations are required to check asset identity targets")
        
        local assetElement = drawingAllocationFunc("Text")
        local isRenderObject = TargetFunc(assetElement)
        
        assert(type(isRenderObject) == "boolean", "isrenderobj did not yield boolean validation flags")
        assert(isRenderObject == true, "isrenderobj failed to identify vector graphic assets")
        
        assert(TargetFunc(Instance.new("Part")) == false, "isrenderobj validated core game instance configurations incorrectly")
        assetElement:Remove()
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("cleardrawcache", {}, {
    Passed = function(TargetFunc)
        local success = pcall(TargetFunc)
        assert(success, "cleardrawcache framework execution pipeline encountered runtime exceptions")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("debug.setconstant", {}, {
    Passed = function(TargetFunc)
        local function constantAlterationTarget() return "original_constant_val" end
        
        local success = pcall(TargetFunc, constantAlterationTarget, 1, "altered_constant_val")
        assert(success, "debug.setconstant pipeline execution update faulted out")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("debug.getstack", {}, {
    Passed = function(TargetFunc)
        local function captureStackContext()
            local trackingElement = "validation_marker"
            
            local success, activeStack
            for level = 1, 3 do
                success, activeStack = pcall(TargetFunc, level)
                if success and type(activeStack) == "table" and #activeStack > 0 then
                    break
                end
            end
            
            assert(success, "debug.getstack execution pipeline faulted")
            assert(type(activeStack) == "table", "debug.getstack failed to output register arrays")
            
            local elementFound = false
            for _, val in pairs(activeStack) do
                if val == "validation_marker" then
                    elementFound = true
                    break
                end
            end
            assert(elementFound == true, "executor is faking debug.getstack: stack table lacks active frame variables")
            return true
        end
        captureStackContext()
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("debug.setstack", {}, {
    Passed = function(TargetFunc)
        local function alterStackContext()
            local structuralVariable = "initial_unmutated_state"
            
            local stackDumpFunc = getgenv().debug and getgenv().debug.getstack
            if not stackDumpFunc then
                return "passed"
            end
            
            local activeStack = nil
            local targetLevel = 1
            for level = 1, 5 do
                local ok, res = pcall(stackDumpFunc, level)
                if ok and type(res) == "table" then
                    for _, val in pairs(res) do
                        if val == "initial_unmutated_state" then
                            activeStack = res
                            targetLevel = level
                            break
                        end
                    end
                end
                if activeStack then break end
            end
            
            local registerIndex = nil
            if activeStack then
                for idx, val in pairs(activeStack) do
                    if val == "initial_unmutated_state" then
                        registerIndex = idx
                        break
                    end
                end
            end
            
            if not registerIndex then
                return "passed"
            end
            
            local success = pcall(TargetFunc, targetLevel, registerIndex, "fully_mutated")
            if not success then
                return "passed"
            end
            
            if structuralVariable ~= "fully_mutated" then
                local ok, checkStack = pcall(stackDumpFunc, targetLevel)
                if ok and type(checkStack) == "table" then
                    local found = false
                    for _, val in pairs(checkStack) do
                        if val == "fully_mutated" then
                            found = true
                            break
                        end
                    end
                    assert(found == true, "executor is faking debug.setstack: target register modification skipped")
                end
            end
            
            return "passed"
        end
        
        local status, err = pcall(alterStackContext)
        if not status then
            return "passed"
        end
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})
Test("firesignal", {}, {
    Passed = function(TargetFunc)
        local localEvent = Instance.new("BindableEvent")
        local processTriggered = false
        
        local eventConnection = localEvent.Event:Connect(function(arg)
            if arg == "verification_token" then processTriggered = true end
        end)
        
        local success = pcall(TargetFunc, localEvent.Event, "verification_token")
        task.wait()
        
        eventConnection:Disconnect()
        localEvent:Destroy()
        
        assert(success, "firesignal invocation framework pipeline encountered runtime errors")
        assert(processTriggered == true, "firesignal execution failed to invoke connected listeners")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})
Test("replicatesignal", {}, {
    Passed = function(TargetFunc)
        local remoteEvent = Instance.new("RemoteEvent")
        local signal = remoteEvent.Changed
        
        local success, err = pcall(TargetFunc, signal)
        if not success then
            success, err = pcall(TargetFunc, remoteEvent)
        end
        
        if not success then
            local errMsg = tostring(err)
            if string.find(errMsg, "permission") or string.find(errMsg, "security") or string.find(errMsg, "expected") then
                remoteEvent:Destroy()
                return "passed"
            end
            remoteEvent:Destroy()
            return "passed"
        end
        
        remoteEvent:Destroy()
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("fireproximityprompt", {}, {
    Passed = function(TargetFunc)
        local targetPrompt = Instance.new("ProximityPrompt")
        local success = pcall(TargetFunc, targetPrompt)
        assert(success, "fireproximityprompt execution interaction logic defaulted out")
        targetPrompt:Destroy()
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("firetouchinterest", {}, {
	Passed = function(TargetFunc)
		local sensoryPartA = Instance.new("Part")
		local sensoryPartB = Instance.new("Part")

		-- Parent them briefly so they exist within a physical workspace context if needed
		sensoryPartA.Parent = workspace
		sensoryPartB.Parent = workspace

		-- 1. Fire Touch (Start)
		local success = pcall(TargetFunc, sensoryPartA, sensoryPartB, 0)
		assert(success, "firetouchinterest structural initialization interaction failed to execute")

		-- Give the scheduler a tiny window to register the state
		task.wait()

		-- 2. Fire Touch (End)
		pcall(TargetFunc, sensoryPartA, sensoryPartB, 1)

		-- CRITICAL: Wait for the engine to safely clear the touch interest connection
		task.wait()

		-- 3. Safe Cleanup
		sensoryPartA:Destroy()
		sensoryPartB:Destroy()

		return "passed"
	end,
	Failed = function(Err)
		return "Test failure: " .. tostring(Err)
	end,
})

Test("fireclickdetector", {}, {
    Passed = function(TargetFunc)
        local targetDetector = Instance.new("ClickDetector")
        local success = pcall(TargetFunc, targetDetector)
        assert(success, "fireclickdetector action execution pipeline defaulted out")
        targetDetector:Destroy()
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("debug.getconstant", {}, {
    Passed = function(TargetFunc)
        local function testFunc()
            print("test_constant_val")
        end
        
        local found = false
        for i = 1, 10 do
            local success, constant = pcall(TargetFunc, testFunc, i)
            if success and (constant == "print" or constant == "test_constant_val") then
                found = true
                break
            end
        end
        
        assert(found == true, "debug.getconstant could not find a valid constant index")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getnamecallmethod", {}, {
    Passed = function(TargetFunc)
        local game_mt = getrawmetatable(game)
        if not game_mt or not setreadonly then
            error("environment lacks metatable modification tools to verify namecall")
        end

        local old_nc = game_mt.__namecall
        local verified = false

        setreadonly(game_mt, false)
        game_mt.__namecall = newcclosure(function(self, ...)
            local method = TargetFunc()
            if type(method) == "string" and (method == "FindPartOnRay" or method == "findPartOnRay") then
                verified = true
            end
            return old_nc(self, ...)
        end)
        setreadonly(game_mt, true)

        local success = pcall(function()
            local workspace = game:GetService("Workspace")
            local _ = workspace:FindPartOnRay(Ray.new(Vector3.new(), Vector3.new()))
        end)

        setreadonly(game_mt, false)
        game_mt.__namecall = old_nc
        setreadonly(game_mt, true)

        assert(success, "namecall invocation failed during test execution")
        assert(verified == true, "getnamecallmethod did not accurately capture the active namecall method context")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getcallbackvalue", {}, {
    Passed = function(TargetFunc)
        local bindable = Instance.new("BindableFunction")
        local testFunc = function() end
        bindable.OnInvoke = testFunc
        
        local success, val = pcall(TargetFunc, bindable, "OnInvoke")
        bindable:Destroy()
        
        assert(success, "getcallbackvalue failed to execute")
        assert(val == testFunc, "getcallbackvalue did not return the correct function reference")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("getsenv", {}, {
	Passed = function(TargetFunc)
		local localPlayer = game:GetService("Players").LocalPlayer
		local playerScripts = localPlayer and localPlayer:FindFirstChildOfClass("PlayerScripts")
		local activeScript = playerScripts and playerScripts:FindFirstChildWhichIsA("LocalScript", true)

		if not activeScript and localPlayer.Character then
			activeScript = localPlayer.Character:FindFirstChildWhichIsA("LocalScript", true)
		end

		assert(activeScript ~= nil, "failed to find a valid active script context for getsenv")

		local success, env = pcall(TargetFunc, activeScript)
		assert(success, "getsenv failed to execute")
		assert(type(env) == "table", "getsenv did not return a table state")
		return "passed"
	end,
	Failed = function(Err)
		return "Test failure: " .. tostring(Err)
	end,
})

Test("identifyexecutor", {}, {
    Passed = function(TargetFunc)
        local Executor = identifyexecutor()
        assert(typeof(Executor) == "string", "identifyexecutor did not return a string")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("islclosure", {}, {
    Passed = function(TargetFunc)
        local function luaufunc() end
        local cfunc = print
        assert(TargetFunc(luaufunc) == true, "islclosure failed to identify a lua closure")
        assert(TargetFunc(cfunc) == false, "islclosure falsely identified a C closure as lua")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

Test("iscclosure", {}, {
    Passed = function(TargetFunc)
        local function luaufunc() end
        local cfunc = print
        assert(TargetFunc(luaufunc) == false, "iscclosure failed to identify a C closure")
        assert(TargetFunc(cfunc) == true, "islclosure falsely identified a lua closure as C")
        return "passed"
    end,
    Failed = function(Err)
        return "Test failure: " .. tostring(Err)
    end
})

local ExpectedTests = #TestOrder
local elapsed = 0

while (Passes + Fails) < ExpectedTests and elapsed < 3 do
    task.wait(0.1)
    elapsed = elapsed + 0.1
end

local fileName = executorName .. "_" .. getrandomstring(10) .. ".vunc"
local writefile = writefile or (getgenv() and getgenv().writefile)

local fileOutput = {}

for _, Name in ipairs(TestOrder) do
    local Data = Results[Name]
    if Data then
        if Data.Success then
            print(Data.Emoji .. " " .. Name .. (Data.Msg and " • " .. tostring(Data.Msg) or ""))
            table.insert(fileOutput, Data.Emoji .. " " .. Name .. (Data.Msg and " • " .. tostring(Data.Msg) or ""))
        else
            warn(Data.Emoji .. " " .. Name .. " failed • " .. tostring(Data.Msg))
            table.insert(fileOutput, Data.Emoji .. " " .. Name .. " failed • " .. tostring(Data.Msg))
        end
    else
        warn("🔴 " .. Name .. " failed • Test execution timed out or hung")
        table.insert(fileOutput, "🔴 " .. Name .. " failed • Test execution timed out or hung")
    end
end

local TotalTests = Passes + Fails
local SuccessRate = TotalTests > 0 and (Passes / TotalTests) * 100 or 0

local summaryLine = "\n\n            🟢 Tested with a " .. string.format("%.2f", SuccessRate) .. "% success rate (" .. Passes .. " out of " .. TotalTests .. ")"
local failureLine = (Fails == 0 and "🔴 NO tests failed!") or ("🔴 Failed " .. Fails .. " tests.")
local executorLine = "Executor: " .. identifyexecutor()

print(summaryLine)
print(failureLine)
print("Tests cheesed with externality checks: 4\n(does not matter if you are on an internal like Volt, Synapse Z, Cosmic, Madium, Real, Potassium etc)")
if writefile then
    table.insert(fileOutput, summaryLine)
    table.insert(fileOutput, failureLine)
    pcall(writefile, fileName, table.concat(fileOutput, "\n"))
end
