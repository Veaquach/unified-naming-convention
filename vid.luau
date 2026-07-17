local function isCClosure(func)
	if type(func) ~= "function" then
		return false, "Not a function"
	end
	if isexecutorclosure and isexecutorclosure(func) then
		return false
	end
	if (islclosure and islclosure(func)) or (iscclosure and not iscclosure(func)) then
		return false
	end
	local source, line = debug.info(func, "sl")
	if source ~= "[C]" or line ~= -1 then
		return false
	end
	if getfunctionhash and clonefunction then
		local s, clone = pcall(clonefunction, func)
		if s and type(clone) == "function" then
			local hs, match = pcall(function()
				return getfunctionhash(func) == getfunctionhash(clone)
			end)
			if hs and not match then
				return false
			end
		end
	end
	local s, trace = pcall(debug.traceback)
	if s and trace then
		local t = trace:lower()
		if t:find("hook") or t:find("solara") then
			return false
		end
	end
	return true
end
local setthreadidentitypass = false
local originalidentity = getthreadidentity()

setthreadidentity(3)
local pass3 = (getthreadidentity() == 3)

setthreadidentity(6)
local pass6 = (getthreadidentity() == 6)

setthreadidentity(8)
local pass8 = (getthreadidentity() == 8)

if pass3 and pass6 and pass8 then
	setthreadidentitypass = true
end
setthreadidentity(originalidentity)
local internality = false
local internal_success = pcall(function(...)
	local a = setmetatable({}, {
		__index = function()
			return 1
		end,
	})
	pcall(function()
		hookmetamethod(a, "__index", function()
			return "GG"
		end)
	end)
	if a.b == "GG" then
		internality = true
	else
		internality = false
	end
end)
local ExecutorName = identifyexecutor()
local PassedCount = 0
local FailedCount = 0
local GoodExecutors = {
	["Potassium"] = true,
	["Volt"] = true,
	["Synapse Z"] = true,
} -- this isnt full but yes these are good 100%
-- setthreadidentity check
print("\n\n\n            Is " .. ExecutorName .. " faking its identity level? Let's find out.")
print("\n            vID Test made by @veaquach on Discord.")

print("\n            Executor: " .. ExecutorName .. "\n")

if GoodExecutors[ExecutorName] then
	warn("this is a good executor idk why you need to test it but ok")
end
print("✅ = Pass, ⛔ = Fail\n")
if not getthreadidentity() then
	warn("⛔ Identity check failed :(")
	FailedCount += 1
else
	print("✅ Identity check passed - Identity: " .. getthreadidentity())
	PassedCount += 1
end
if not setthreadidentitypass then
	print("⛔ Set Identity check failed :( (identity was not set to the correct number)")
	FailedCount += 1
else
	print("✅ Set Identity check passed - Identities set: 3, 6, 8, " .. originalidentity)
	PassedCount += 1
end
if internality == false then
	print("⛔ Internal check failed :( (executor is not internal)")
	FailedCount += 1
else
	print('✅ Internal check passed - hookmetamethod returned "GG" -' .. " i love " .. ExecutorName:lower())
	PassedCount += 1
end
local function randomstringgen(length)
	math.randomseed(os.time() ^ math.random())

	local characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>/?"
	local result = ""

	for i = 1, length do
		local randomIndex = math.random(1, #characters)
		result = result .. characters:sub(randomIndex, randomIndex)
	end

	return result
end

local leakedenv = false
local generatedstring = randomstringgen(100)
getgenv().SolaraDetectionKey = generatedstring

local renv = getrenv()
if renv.SolaraDetectionKey == generatedstring or renv._G.SolaraDetectionKey == generatedstring then
	leakedenv = true
end

if leakedenv then
	print("⛔ REnv leak test failed :( (REnv string was found in GEnv)")
	FailedCount += 1
else
	print("✅ REnv leak test passed - REnv string was not found in GEnv")
	PassedCount += 1
end
local cclosuretest = true
local function normfunc()
	print("<3")
end
local normalfunctest = isCClosure(normfunc)
if not normalfunctest then
	cclosuretest = false
else
	cclosuretest = true
end
if cclosuretest then
	print("⛔ Closure test failed - executor said a normal function is a C function.")
	FailedCount += 1
else
	print("✅ Closure test passed - executor identified a Luau function as Luau.")
	PassedCount += 1
end
local islarp = false
local isgoodlarp = false
if internality == false and getthreadidentity() > 3 then
	islarp = true
elseif internality == true and getthreadidentity() < 7 then
	isgoodlarp = true
else
	islarp = false
end

if islarp then
	print(
		"Unfortunately,\n            "
			.. ExecutorName
			.. " is FAKING it's identity!\n            Supposed identity: "
			.. getthreadidentity()
			.. ", real identity: 2-3"
	)
elseif isgoodlarp then
	print(
		"For some reason,\n            "
			.. ExecutorName
			.. " is LOWERING it's identity!\n            Supposed identity: "
			.. getthreadidentity()
			.. ", real identity: 7-9"
	)
else
	print(
		"Fortunately,\n            "
			.. ExecutorName
			.. " is NOT faking it's identity!\n            Identity level: "
			.. getthreadidentity()
	)
end

print(
	"✅ Tested with a "
		.. string.format("%.2f", (PassedCount / 5) * 100)
		.. "% success rate ("
		.. PassedCount
		.. " out of 5)"
)
if FailedCount == 0 then
	print("⛔ NO tests failed!")
else
	print("⛔ Failed " .. FailedCount .. " tests.")
end
