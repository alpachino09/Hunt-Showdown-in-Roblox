--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local folder = Instance.new("Folder")
folder.Name = "GreyOutpostRemotes"
local lobby = Instance.new("RemoteEvent")
lobby.Name = "Lobby"
lobby.Parent = folder
local combat = Instance.new("RemoteEvent")
combat.Name = "Combat"
combat.Parent = folder
folder.Parent = ReplicatedStorage
return table.freeze({ lobby = lobby, combat = combat })
