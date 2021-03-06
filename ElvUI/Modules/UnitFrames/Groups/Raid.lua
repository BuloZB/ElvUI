local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule("UnitFrames");

--Cache global variables
--Lua functions
--WoW API / Variables
local CreateFrame = CreateFrame

local ns = oUF
local ElvUF = ns.oUF
assert(ElvUF, "ElvUI was unable to locate oUF.")

function UF:Construct_RaidFrames()
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self.RaisedElementParent = CreateFrame("Frame", nil, self)
	self.RaisedElementParent:SetFrameLevel(self:GetFrameLevel() + 100)
	self.RaisedElementParent.TextureParent = CreateFrame("Frame", nil, self.RaisedElementParent)
	self.RaisedElementParent.TextureParent:SetFrameLevel(self.RaisedElementParent:GetFrameLevel() + 1)

	self.Health = UF:Construct_HealthBar(self, true, true, "RIGHT")
	self.Power = UF:Construct_PowerBar(self, true, true, "LEFT")
	self.Power.frequentUpdates = false
	self.Portrait3D = UF:Construct_Portrait(self, "model")
	self.Portrait2D = UF:Construct_Portrait(self, "texture")
	self.Name = UF:Construct_NameText(self)
	self.RaidRoleFramesAnchor = UF:Construct_RaidRoleFrames(self)
	self.RaidTargetIndicator = UF:Construct_RaidIcon(self)
	self.MouseGlow = UF:Construct_MouseGlow(self)
 	self.TargetGlow = UF:Construct_TargetGlow(self)

	self.GPS = UF:Construct_GPS(self)
	self.InfoPanel = UF:Construct_InfoPanel(self)
	UF:Update_StatusBars()
	UF:Update_FontStrings()
	self.unitframeType = "raid"

	UF:Update_RaidFrames(self, UF.db["units"]["raid"])

	return self
end

function UF:Update_RaidHeader(header)
	if not header.positioned then
		header:ClearAllPoints()
		header:SetPoint("BOTTOMLEFT", E.UIParent, "BOTTOMLEFT", 4, 195)

		E:CreateMover(header, header:GetName().."Mover", L["Raid Frames"], nil, nil, nil, "ALL,RAID")
		header.positioned = true
	end
end

function UF:Update_RaidFrames(frame, db)
	frame.db = db

	frame.Portrait = frame.Portrait or (db.portrait.style == "2D" and frame.Portrait2D or frame.Portrait3D)
	frame.colors = ElvUF.colors
	frame:RegisterForClicks(self.db.targetOnMouseDown and "LeftButtonDown" or "LeftButtonUp", self.db.targetOnMouseDown and "RightButtonDown" or "RightButtonUp")

	do
		if self.thinBorders then
			frame.SPACING = 0
			frame.BORDER = E.mult
		else
			frame.BORDER = E.Border
			frame.SPACING = E.Spacing
		end

		frame.SHADOW_SPACING = 3
		frame.ORIENTATION = db.orientation

		frame.UNIT_WIDTH = db.width
		frame.UNIT_HEIGHT = db.infoPanel.enable and (db.height + db.infoPanel.height) or db.height

		frame.USE_POWERBAR = db.power.enable
		frame.POWERBAR_DETACHED = db.power.detachFromFrame
		frame.USE_INSET_POWERBAR = not frame.POWERBAR_DETACHED and db.power.width == "inset" and frame.USE_POWERBAR
		frame.USE_MINI_POWERBAR = (not frame.POWERBAR_DETACHED and db.power.width == "spaced" and frame.USE_POWERBAR)
		frame.USE_POWERBAR_OFFSET = db.power.offset ~= 0 and frame.USE_POWERBAR and not frame.POWERBAR_DETACHED
		frame.POWERBAR_OFFSET = frame.USE_POWERBAR_OFFSET and db.power.offset or 0

		frame.POWERBAR_HEIGHT = not frame.USE_POWERBAR and 0 or db.power.height
		frame.POWERBAR_WIDTH = frame.USE_MINI_POWERBAR and (frame.UNIT_WIDTH - (frame.BORDER*2))/2 or (frame.POWERBAR_DETACHED and db.power.detachedWidth or (frame.UNIT_WIDTH - ((frame.BORDER+frame.SPACING)*2)))

		frame.USE_PORTRAIT = db.portrait and db.portrait.enable
		frame.USE_PORTRAIT_OVERLAY = frame.USE_PORTRAIT and (db.portrait.overlay or frame.ORIENTATION == "MIDDLE")
		frame.PORTRAIT_WIDTH = (frame.USE_PORTRAIT_OVERLAY or not frame.USE_PORTRAIT) and 0 or db.portrait.width

		frame.CLASSBAR_WIDTH = 0
		frame.CLASSBAR_YOFFSET = 0

		frame.USE_INFO_PANEL = not frame.USE_MINI_POWERBAR and not frame.USE_POWERBAR_OFFSET and db.infoPanel.enable
		frame.INFO_PANEL_HEIGHT = frame.USE_INFO_PANEL and db.infoPanel.height or 0

		frame.BOTTOM_OFFSET = UF:GetHealthBottomOffset(frame)

		frame.VARIABLES_SET = true
	end

	frame:SetWidth(frame.UNIT_WIDTH)
	frame:SetHeight(frame.UNIT_HEIGHT)

	UF:Configure_InfoPanel(frame)

	UF:Configure_HealthBar(frame)

	UF:UpdateNameSettings(frame)

	UF:Configure_Power(frame)

	UF:Configure_Portrait(frame)

	UF:Configure_GPS(frame)

	UF:Configure_RaidIcon(frame)

	UF:Configure_RaidRoleIcons(frame)

	frame:UpdateAllElements("ElvUI_UpdateAllElements")
end

UF["headerstoload"]["raid"] = true