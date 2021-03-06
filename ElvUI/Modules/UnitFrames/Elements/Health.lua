local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule("UnitFrames");

--Cache global variables
--Lua functions
local random = random
--WoW API / Variables
local CreateFrame = CreateFrame
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitReaction = UnitReaction
local UnitIsPlayer = UnitIsPlayer
local UnitClass = UnitClass
local UnitIsDeadOrGhost = UnitIsDeadOrGhost

local ns = oUF
local ElvUF = ns.oUF
assert(ElvUF, "ElvUI was unable to locate oUF.")

function UF:Construct_HealthBar(frame, bg, text, textPos)
	local health = CreateFrame("StatusBar", nil, frame)
	UF["statusbars"][health] = true

	health:SetFrameLevel(10) --Make room for Portrait and Power which should be lower by default
	health.PostUpdate = self.PostUpdateHealth

	CreateStatusBarTexturePointer(health)

	if bg then
		health.bg = health:CreateTexture(nil, "BORDER")
		health.bg:SetAllPoints()
		health.bg:SetTexture(E["media"].blankTex)
		health.bg.multiplier = 0.25
	end

	if text then
		health.value = frame.RaisedElementParent:CreateFontString(nil, "OVERLAY")
		UF:Configure_FontString(health.value)

		local x = -2
		if textPos == "LEFT" then
			x = 2
		end

		health.value:SetPoint(textPos, health, textPos, x, 0)
	end

	health.colorTapping = true
	health.colorDisconnected = true
	E:CreateBackdrop(health, "Default", nil, nil, self.thinBorders, true)

	return health
end

function UF:Configure_HealthBar(frame)
	if not frame.VARIABLES_SET then return end
	local db = frame.db
	local health = frame.Health

	health.Smooth = self.db.smoothbars
	health.SmoothSpeed = self.db.smoothSpeed * 10

	--Text
	if db.health and health.value then
		local attachPoint = self:GetObjectAnchorPoint(frame, db.health.attachTextTo)
		health.value:ClearAllPoints()
		health.value:SetPoint(db.health.position, attachPoint, db.health.position, db.health.xOffset, db.health.yOffset)
		frame:Tag(health.value, db.health.text_format)
	end

	--Colors
	health.colorSmooth = nil
	health.colorHealth = nil
	health.colorClass = nil
	health.colorReaction = nil

	if db.colorOverride and db.colorOverride == "FORCE_ON" then
		health.colorClass = true
		health.colorReaction = true
	elseif db.colorOverride and db.colorOverride == "FORCE_OFF" then
		if self.db["colors"].colorhealthbyvalue == true then
			health.colorSmooth = true
		else
			health.colorHealth = true
		end
	else
		if self.db.colors.healthclass ~= true then
			if self.db.colors.colorhealthbyvalue == true then
				health.colorSmooth = true
			else
				health.colorHealth = true
			end
		else
			health.colorClass = (not self.db.colors.forcehealthreaction)
			health.colorReaction = true
		end
	end

	--Position
	health:ClearAllPoints()
	if frame.ORIENTATION == "LEFT" then
		health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -frame.BORDER - frame.SPACING, -frame.BORDER - frame.SPACING - frame.CLASSBAR_YOFFSET)

		if frame.USE_POWERBAR_OFFSET then
			health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -frame.BORDER - frame.SPACING - frame.POWERBAR_OFFSET, -frame.BORDER - frame.SPACING - frame.CLASSBAR_YOFFSET)
			health:SetWidth(frame.UNIT_WIDTH - (frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING) - (frame.BORDER + frame.SPACING + frame.POWERBAR_OFFSET))
			health:SetHeight(frame.UNIT_HEIGHT - (frame.BORDER + frame.SPACING + frame.POWERBAR_OFFSET) - (frame.BORDER + frame.SPACING + frame.CLASSBAR_YOFFSET))
		elseif frame.POWERBAR_DETACHED or not frame.USE_POWERBAR or frame.USE_INSET_POWERBAR then
			health:SetWidth(frame.UNIT_WIDTH - (frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING) - (frame.BORDER + frame.SPACING))
			health:SetHeight(frame.UNIT_HEIGHT - (frame.BORDER + frame.SPACING + frame.CLASSBAR_YOFFSET) - (frame.BORDER + frame.SPACING + frame.BOTTOM_OFFSET))
		elseif frame.USE_MINI_POWERBAR then
			health:SetWidth(frame.UNIT_WIDTH - (frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING) - (frame.BORDER + frame.SPACING))
			health:SetHeight(frame.UNIT_HEIGHT - (frame.BORDER + frame.SPACING + frame.CLASSBAR_YOFFSET) - (frame.SPACING + (frame.POWERBAR_HEIGHT/2)))
		else
			health:SetWidth(frame.UNIT_WIDTH - (frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING) - (frame.BORDER + frame.SPACING))
			health:SetHeight(frame.UNIT_HEIGHT - (frame.BORDER + frame.SPACING + frame.CLASSBAR_YOFFSET) - (frame.BORDER + frame.SPACING + frame.BOTTOM_OFFSET))
		end
	elseif frame.ORIENTATION == "RIGHT" then
		health:SetPoint("TOPLEFT", frame, "TOPLEFT", frame.BORDER + frame.SPACING, -frame.BORDER - frame.SPACING - frame.CLASSBAR_YOFFSET)

		if frame.USE_POWERBAR_OFFSET then
			health:SetPoint("TOPLEFT", frame, "TOPLEFT", frame.BORDER + frame.SPACING + frame.POWERBAR_OFFSET, -frame.BORDER - frame.SPACING - frame.CLASSBAR_YOFFSET)
			health:SetWidth(frame.UNIT_WIDTH - (frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING) - (frame.BORDER + frame.SPACING + frame.POWERBAR_OFFSET))
			health:SetHeight(frame.UNIT_HEIGHT - (frame.BORDER + frame.SPACING + frame.POWERBAR_OFFSET) - (frame.BORDER + frame.SPACING + frame.CLASSBAR_YOFFSET))
		elseif frame.POWERBAR_DETACHED or not frame.USE_POWERBAR or frame.USE_INSET_POWERBAR then
			health:SetWidth(frame.UNIT_WIDTH - (frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING) - (frame.BORDER + frame.SPACING))
			health:SetHeight(frame.UNIT_HEIGHT - (frame.BORDER + frame.SPACING + frame.CLASSBAR_YOFFSET) - (frame.BORDER + frame.SPACING + frame.BOTTOM_OFFSET))
		elseif frame.USE_MINI_POWERBAR then
			health:SetWidth(frame.UNIT_WIDTH - (frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING) - (frame.BORDER + frame.SPACING))
			health:SetHeight(frame.UNIT_HEIGHT - (frame.BORDER + frame.SPACING + frame.CLASSBAR_YOFFSET) - (frame.SPACING + (frame.POWERBAR_HEIGHT/2)))
		else
			health:SetWidth(frame.UNIT_WIDTH - (frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING) - (frame.BORDER + frame.SPACING))
			health:SetHeight(frame.UNIT_HEIGHT - (frame.BORDER + frame.SPACING + frame.CLASSBAR_YOFFSET) - (frame.BORDER + frame.SPACING + frame.BOTTOM_OFFSET))
		end
	elseif frame.ORIENTATION == "MIDDLE" then
		health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -frame.BORDER - frame.SPACING, -frame.BORDER - frame.SPACING - frame.CLASSBAR_YOFFSET)

		if frame.USE_POWERBAR_OFFSET then
			health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -frame.BORDER - frame.SPACING - frame.POWERBAR_OFFSET, -frame.BORDER - frame.SPACING - frame.CLASSBAR_YOFFSET)
			health:SetWidth(frame.UNIT_WIDTH - (frame.BORDER + frame.SPACING) - (frame.BORDER + frame.SPACING + (frame.POWERBAR_OFFSET*2)))
			health:SetHeight(frame.UNIT_HEIGHT - (frame.BORDER + frame.SPACING + frame.POWERBAR_OFFSET) - (frame.BORDER + frame.SPACING + frame.CLASSBAR_YOFFSET))
		elseif frame.POWERBAR_DETACHED or not frame.USE_POWERBAR or frame.USE_INSET_POWERBAR then
			health:SetWidth(frame.UNIT_WIDTH - (frame.BORDER + frame.SPACING) - (frame.BORDER + frame.SPACING))
			health:SetHeight(frame.UNIT_HEIGHT - (frame.BORDER + frame.SPACING + frame.CLASSBAR_YOFFSET) - (frame.BORDER + frame.SPACING + frame.BOTTOM_OFFSET))
		elseif frame.USE_MINI_POWERBAR then
			health:SetWidth(frame.UNIT_WIDTH - (frame.BORDER + frame.SPACING) - (frame.BORDER + frame.SPACING))
			health:SetHeight(frame.UNIT_HEIGHT - (frame.BORDER + frame.SPACING + frame.CLASSBAR_YOFFSET) - (frame.SPACING + (frame.POWERBAR_HEIGHT/2)))
		else
			health:SetWidth(frame.UNIT_WIDTH - (frame.PORTRAIT_WIDTH + frame.BORDER + frame.SPACING) - (frame.BORDER + frame.SPACING))
			health:SetHeight(frame.UNIT_HEIGHT - (frame.BORDER + frame.SPACING + frame.CLASSBAR_YOFFSET) - (frame.BORDER + frame.SPACING + frame.BOTTOM_OFFSET))
		end
	end

	health.bg:ClearAllPoints()
	if not frame.USE_PORTRAIT_OVERLAY then
		health.bg:SetParent(health)
		health.bg:SetAllPoints()
	else
		health.bg:SetPoint("BOTTOMLEFT", health.texturePointer, "BOTTOMRIGHT")
		health.bg:SetPoint("TOPRIGHT", health)
		health.bg:SetParent(frame.Portrait.overlay)
	end

	if db.health then
		--Party/Raid Frames allow to change statusbar orientation
		if db.health.orientation then
			health:SetOrientation(db.health.orientation)
		end

		--Party/Raid Frames can toggle frequent updates
		if db.health.frequentUpdates then
			health.frequentUpdates = db.health.frequentUpdates
		end
	end

	--Transparency Settings
	UF:ToggleTransparentStatusBar(UF.db.colors.transparentHealth, frame.Health, frame.Health.bg, (frame.USE_PORTRAIT and frame.USE_PORTRAIT_OVERLAY) ~= true)

	--Highlight Texture
	UF:Configure_HighlightGlow(frame)

	frame:UpdateElement("Health")
end

function UF:GetHealthBottomOffset(frame)
	local bottomOffset = 0
	if frame.USE_POWERBAR and not frame.POWERBAR_DETACHED and not frame.USE_INSET_POWERBAR then
		bottomOffset = bottomOffset + frame.POWERBAR_HEIGHT - (frame.BORDER-frame.SPACING)
	end
	if frame.USE_INFO_PANEL then
		bottomOffset = bottomOffset + frame.INFO_PANEL_HEIGHT - (frame.BORDER-frame.SPACING)
	end

	return bottomOffset
end

function UF:PostUpdateHealth(unit, min, max)
	local parent = self:GetParent()
	if parent.isForced then
		min = random(1, max)
		self:SetValue(min)
	end

	local r, g, b = self:GetStatusBarColor()
	local colors = E.db["unitframe"]["colors"]
	if ((colors.healthclass == true and colors.colorhealthbyvalue == true) or (colors.colorhealthbyvalue and parent.isForced)) and not (UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) then
		local newr, newg, newb = ElvUF.ColorGradient(min, max, 1, 0, 0, 1, 1, 0, r, g, b)

		self:SetStatusBarColor(newr, newg, newb)
		if self.bg and self.bg.multiplier then
			local mu = self.bg.multiplier
			self.bg:SetVertexColor(newr * mu, newg * mu, newb * mu)
		end
	end

	if colors.classbackdrop then
		local reaction = UnitReaction(unit, "player")
		local t
		if UnitIsPlayer(unit) then
			local _, class = UnitClass(unit)
			t = parent.colors.class[class]
		elseif(reaction) then
			t = parent.colors.reaction[reaction]
		end

		if t then
			self.bg:SetVertexColor(t[1], t[2], t[3])
		end
	end

	--Backdrop
	if colors.customhealthbackdrop then
		local backdrop = colors.health_backdrop
		self.bg:SetVertexColor(backdrop.r, backdrop.g, backdrop.b)
	end

	if colors.useDeadBackdrop and UnitIsDeadOrGhost(unit) then
		local backdrop = colors.health_backdrop_dead
		self.bg:SetVertexColor(backdrop.r, backdrop.g, backdrop.b)
	end
end