local SaveService = {}

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ReactorConstants = require(Shared:WaitForChild("ReactorConstants"))

local store
local ok, result = pcall(function()
	return DataStoreService:GetDataStore(Config.Save.DataStoreName)
end)
if ok then
	store = result
end

local cache = {}

local function defaultProfile()
	return {
		XP = 0,
		BestMW = 0,
		FastestStartup = math.huge,
		SuccessfulStartups = 0,
		EmergencyScrams = 0,
		Meltdowns = 0,
		LastSession = 0,
	}
end

local function rankFromXP(xp)
	local title = "Trainee Operator"
	for _, bracket in ipairs(ReactorConstants.RankBrackets) do
		if xp >= bracket.XP then
			title = bracket.Title
		end
	end
	return title
end

function SaveService.Load(player)
	local profile = defaultProfile()
	if store then
		local success, data = pcall(function()
			return store:GetAsync("p_" .. player.UserId)
		end)
		if success and type(data) == "table" then
			for k, v in pairs(data) do
				profile[k] = v
			end
		end
	end
	cache[player] = profile
	return profile
end

function SaveService.Save(player)
	local profile = cache[player]
	if not profile or not store then
		return false
	end
	local ok2, err = pcall(function()
		store:SetAsync("p_" .. player.UserId, profile)
	end)
	if not ok2 then
		warn("[SaveService] Save failed:", err)
	end
	return ok2
end

function SaveService.Get(player)
	return cache[player] or defaultProfile()
end

function SaveService.AddXP(player, amount)
	local profile = cache[player]
	if not profile then return end
	profile.XP = math.max(0, (profile.XP or 0) + amount)
end

function SaveService.RecordRun(player, runData)
	local profile = cache[player]
	if not profile then return end
	if runData.MW and runData.MW > (profile.BestMW or 0) then
		profile.BestMW = runData.MW
	end
	if runData.StartupTime and runData.StartupTime > 0
		and runData.StartupTime < (profile.FastestStartup or math.huge) then
		profile.FastestStartup = runData.StartupTime
	end
	if runData.StartupCompleted then
		profile.SuccessfulStartups = (profile.SuccessfulStartups or 0) + 1
	end
	if runData.Scrammed then
		profile.EmergencyScrams = (profile.EmergencyScrams or 0) + 1
	end
	if runData.Melted then
		profile.Meltdowns = (profile.Meltdowns or 0) + 1
	end
	profile.LastSession = os.time()
end

function SaveService.GetRank(player)
	local profile = cache[player]
	if not profile then return "Trainee Operator" end
	return rankFromXP(profile.XP or 0)
end

function SaveService.Bind()
	Players.PlayerRemoving:Connect(function(player)
		SaveService.Save(player)
		cache[player] = nil
	end)
	game:BindToClose(function()
		for player, _ in pairs(cache) do
			SaveService.Save(player)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.Save.AutosaveInterval)
			for player, _ in pairs(cache) do
				SaveService.Save(player)
			end
		end
	end)
end

return SaveService
