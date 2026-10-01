-- Lädt und speichert Spielerdaten sicher per DataStore.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {}

local profiles: { [Player]: any } = {}
local loadedSignals: { [Player]: BindableEvent } = {}
local changedCallbacks: { (Player, any) -> () } = {}
-- Spieler, deren Daten nicht geladen werden konnten: niemals speichern,
-- sonst würden echte Daten mit leeren Standardwerten überschrieben.
local doNotSave: { [Player]: boolean } = {}

local store
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStore nicht verfügbar (in Studio API-Zugriff aktivieren). Daten werden nicht gespeichert.")
	end
end

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value do
		copy[k] = deepCopy(v)
	end
	return copy
end

-- Fehlende Felder mit Standardwerten auffüllen (wichtig bei Updates)
local function reconcile(data, template)
	for k, v in template do
		if data[k] == nil then
			data[k] = deepCopy(v)
		end
	end
	return data
end

local function withRetries(fn: () -> any, attempts: number?)
	local tries = attempts or 3
	local lastErr
	for i = 1, tries do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		task.wait(i)
	end
	return false, lastErr
end

local function keyFor(player: Player): string
	return "Player_" .. player.UserId
end

function DataService.Get(player: Player)
	return profiles[player]
end

-- Wartet bis die Daten eines Spielers geladen sind
function DataService.WaitFor(player: Player)
	if profiles[player] then
		return profiles[player]
	end
	local signal = loadedSignals[player]
	if not signal then
		return nil
	end
	signal.Event:Wait()
	return profiles[player]
end

function DataService.OnChanged(callback: (Player, any) -> ())
	table.insert(changedCallbacks, callback)
end

-- Nach jeder Änderung aufrufen, damit UI & Leaderstats aktualisiert werden
function DataService.MarkChanged(player: Player)
	local data = profiles[player]
	if not data then
		return
	end
	for _, cb in changedCallbacks do
		task.spawn(cb, player, data)
	end
end

function DataService.Load(player: Player)
	local signal = Instance.new("BindableEvent")
	loadedSignals[player] = signal

	local data
	if store then
		local ok, result = withRetries(function()
			return store:GetAsync(keyFor(player))
		end)
		if ok then
			data = result
		else
			warn("[DataService] Laden fehlgeschlagen für", player.Name, result)
			doNotSave[player] = true
		end
	end

	if type(data) ~= "table" then
		data = deepCopy(Config.DefaultData)
	end
	reconcile(data, Config.DefaultData)

	if not player.Parent then
		doNotSave[player] = nil
		return nil
	end

	profiles[player] = data
	signal:Fire()
	loadedSignals[player] = nil
	signal:Destroy()
	return data
end

function DataService.Save(player: Player)
	local data = profiles[player]
	if not data or not store or doNotSave[player] then
		return
	end
	local ok, err = withRetries(function()
		store:UpdateAsync(keyFor(player), function()
			return data
		end)
	end)
	if not ok then
		warn("[DataService] Speichern fehlgeschlagen für", player.Name, err)
	end
end

function DataService.Release(player: Player)
	DataService.Save(player)
	profiles[player] = nil
	doNotSave[player] = nil
end

function DataService.Init()
	Players.PlayerRemoving:Connect(function(player)
		DataService.Release(player)
	end)

	game:BindToClose(function()
		if RunService:IsStudio() and not store then
			return
		end
		for _, player in Players:GetPlayers() do
			task.spawn(DataService.Save, player)
		end
		task.wait(3)
	end)

	task.spawn(function()
		while true do
			task.wait(Config.AutoSaveInterval)
			for _, player in Players:GetPlayers() do
				task.spawn(DataService.Save, player)
			end
		end
	end)
end

return DataService
