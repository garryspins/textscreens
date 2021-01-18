AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:DrawShadow(false)
	self:SetModel("models/hunter/plates/plate1x1.mdl")
	self:SetMaterial("models/effects/vol_light001")
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end
	self.heldby = 0
end

function ENT:PhysicsUpdate(phys)
	if self.heldby <= 0 then
		phys:Sleep()
	end
end

hook.Add("PhysgunPickup", "TextScreens.IncrementHeldBy", function(ply, ent)
	if IsValid(ent) and ent:GetClass() == "sammyservers_textscreen" then
		ent.heldby = ent.heldby + 1
	end
end)

hook.Add("PhysgunDrop", "TextScreens.DecrementHeldBy", function(ply, ent)
	if IsValid(ent) and ent:GetClass() == "sammyservers_textscreen" then
		ent.heldby = ent.heldby - 1
		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then
			ent:PhysicsUpdate(phys)
		end
	end
end)

util.AddNetworkString("TextScreens.Update")
util.AddNetworkString("TextScreens.Download")

function ENT:SetLine(line, text, color, size, font, rainbow)
	if not text then return end
	if string.sub(text, 1, 1) == "#" then
		text = string.sub(text, 2)
	end
	if string.len(text) > 180 then
		text = string.sub(text, 1, 180) .. "..."
	end

	size = math.Clamp(size, 1, 100)

	font = TextScreens.Fonts[font] ~= nil and font or 1

	rainbow = rainbow or 0

	self.lines = self.lines or {}
	self.lines[tonumber(line)] = {
		["text"] = text,
		["color"] = color,
		["size"] = size,
		["font"] = font,
		["rainbow"] = rainbow
	}
end

net.Receive("TextScreens.Download", function(len, ply)
	if not IsValid(ply) then return end

	local ent = net.ReadEntity()
	if IsValid(ent) and ent:GetClass() == "sammyservers_textscreen" then
		ent.lines = ent.lines or {}
		net.Start("TextScreens.Update")
			net.WriteEntity(ent)
			net.WriteTable(ent.lines)
		net.Send(ply)
	end
end)

function ENT:Broadcast()
	net.Start("TextScreens.Update")
		net.WriteEntity(self)
		net.WriteTable(self.lines)
	net.Broadcast()
end
