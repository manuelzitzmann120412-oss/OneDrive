-- Globale Bestenliste (meiste Münzen aller Zeiten) auf einer Tafel in der Lobby.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)

local LeaderboardService = {}

local UPDATE_INTERVAL = 60
local TOP_COUNT = 10

local function formatNumber(n: number): string
	if n >= 1e9 then
		return ("%.1fB"):format(n / 1e9)
	elseif n >= 1e6 then
		return ("%.1fM"):format(n / 1e6)
	elseif n >= 1e3 then
		return ("%.1fK"):format(n / 1e3)
	end
	return tostring(n)
end

local nameCache: { [number]: string } = {}
local function getName(userId: number): string
	if nameCache[userId] then
		return nameCache[userId]
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	local result = ok and name or ("Spieler " .. userId)
	nameCache[userId] = result
	return result
end

function LeaderboardService.Init(world)
	local label: TextLabel = world.LeaderboardLabel

	local ok, store = pcall(function()
		return DataStoreService:GetOrderedDataStore(Config.LeaderboardStoreName)
	end)
	if not ok then
		label.Text = "🏆 Top Münzen\n\n(DataStore in Studio\nnicht aktiviert)"
		return
	end

	task.spawn(function()
		while true do
			-- Eigene Werte hochladen
			for _, player in Players:GetPlayers() do
				local data = DataService.Get(player)
				if data then
					pcall(function()
						store:SetAsync(tostring(player.UserId), math.floor(data.TotalCoins))
					end)
				end
			end

			-- Top-Liste abrufen
			local success, pages = pcall(function()
				return store:GetSortedAsync(false, TOP_COUNT)
			end)
			if success then
				local lines = { "🏆 Top Münzen" }
				for rank, entry in pages:GetCurrentPage() do
					local medal = rank == 1 and "🥇" or rank == 2 and "🥈" or rank == 3 and "🥉" or ("#" .. rank)
					table.insert(
						lines,
						("%s %s  –  %s"):format(medal, getName(tonumber(entry.key) or 0), formatNumber(entry.value))
					)
				end
				label.Text = table.concat(lines, "\n")
			else
				label.Text = "🏆 Top Münzen\n\n(DataStore nicht verfügbar)"
			end

			task.wait(UPDATE_INTERVAL)
		end
	end)
end

return LeaderboardService
