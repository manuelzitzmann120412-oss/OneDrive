-- Startpunkt des Servers: baut die Welt und startet alle Services.
local Players = game:GetService("Players")

local Services = script.Parent.Services
local DataService = require(Services.DataService)
local PlayerService = require(Services.PlayerService)
local WorldBuilder = require(Services.WorldBuilder)
local ObbyService = require(Services.ObbyService)
local CoinService = require(Services.CoinService)
local PetService = require(Services.PetService)
local ShopService = require(Services.ShopService)
local LeaderboardService = require(Services.LeaderboardService)

local world = WorldBuilder.Build()

DataService.Init()
PlayerService.Init()
ObbyService.Init(world)
CoinService.Init(world)
PetService.Init(world)
ShopService.Init()
LeaderboardService.Init(world)

local function onPlayerAdded(player: Player)
	local data = DataService.Load(player)
	if not data then
		return
	end
	PlayerService.SetupPlayer(player, data)
	ObbyService.SetupPlayer(player)
	PetService.SetupPlayer(player)
	ShopService.SetupPlayer(player)
	PlayerService.Notify(player, "Willkommen bei Mega Obby Simulator! 🎉", "success")
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
