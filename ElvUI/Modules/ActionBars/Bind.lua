local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local AB = E:GetModule("ActionBars");

--Cache global variables
--Lua functions
local _G = _G
local find, format, upper, sub = string.find, string.format, string.upper, string.sub
local floor, mod = math.floor, math.mod
local select, tonumber, pairs, getn = select, tonumber, pairs, getn
--WoW API / Variables
local CreateFrame = CreateFrame
local EnumerateFrames = EnumerateFrames
local GameTooltip_Hide = GameTooltip_Hide
local GetBindingKey = GetBindingKey
local GetCurrentBindingSet = GetCurrentBindingSet
local GetMacroInfo = GetMacroInfo
local hooksecurefunc = hooksecurefunc
local IsAddOnLoaded = IsAddOnLoaded
local IsAltKeyDown = IsAltKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsShiftKeyDown = IsShiftKeyDown
local LoadBindings, SaveBindings = LoadBindings, SaveBindings
local SetBinding = SetBinding
local CHARACTER_SPECIFIC_KEYBINDING_TOOLTIP = CHARACTER_SPECIFIC_KEYBINDING_TOOLTIP
local CHARACTER_SPECIFIC_KEYBINDINGS = CHARACTER_SPECIFIC_KEYBINDINGS

local bind = CreateFrame("Frame", "ElvUI_KeyBinder", E.UIParent)

function AB:ActivateBindMode()
	bind.active = true
	E:StaticPopupSpecial_Show(ElvUIBindPopupWindow)
	AB:RegisterEvent("PLAYER_REGEN_DISABLED", "DeactivateBindMode", false)
end

function AB:DeactivateBindMode(save)
	if save then
		SaveBindings(GetCurrentBindingSet())
		E:Print(L["Binds Saved"])
	else
		LoadBindings(GetCurrentBindingSet())
		E:Print(L["Binds Discarded"])
	end
	bind.active = false
	self:BindHide()
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	E:StaticPopupSpecial_Hide(ElvUIBindPopupWindow)
	AB.bindingsChanged = false
end

function AB:BindHide()
	bind:ClearAllPoints()
	bind:Hide()
	GameTooltip:Hide()
end

function AB:BindListener(key)
	AB.bindingsChanged = true
	if key == "ESCAPE" or key == "RightButton" then
		if bind.button.bindings then
			for i = 1, getn(bind.button.bindings) do
				SetBinding(bind.button.bindings[i])
			end
		end
		E:Print(format(L["All keybindings cleared for |cff00ff00%s|r."], bind.button.name))
		self:BindUpdate(bind.button, bind.spellmacro)
		if bind.spellmacro~="MACRO" then GameTooltip:Hide() end
		return
	end

	if key == "LSHIFT"
	or key == "RSHIFT"
	or key == "LCTRL"
	or key == "RCTRL"
	or key == "LALT"
	or key == "RALT"
	or key == "UNKNOWN"
	or key == "LeftButton"
	then return end

	if key == "MiddleButton" then key = "BUTTON3" end
	if find(key, "Button%d") then
		key = upper(key)
	end

	local alt = IsAltKeyDown() and "ALT-" or ""
	local ctrl = IsControlKeyDown() and "CTRL-" or ""
	local shift = IsShiftKeyDown() and "SHIFT-" or ""
	if not bind.spellmacro or bind.spellmacro == "PET" or bind.spellmacro == "SHAPESHIFT" then
		SetBinding(alt..ctrl..shift..key, bind.button.bindstring)
	else
		SetBinding(alt..ctrl..shift..key, bind.spellmacro.." "..bind.button.name)
	end
	E:Print(alt..ctrl..shift..key..L[" |cff00ff00bound to |r"]..bind.button.name..".")
	self:BindUpdate(bind.button, bind.spellmacro)
	if bind.spellmacro~="MACRO" then GameTooltip:Hide() end
end

function AB:BindUpdate(button, spellmacro)
	if not bind.active then return end

	bind.button = button
	bind.spellmacro = spellmacro

	bind:ClearAllPoints()
	bind:SetAllPoints(button)
	bind:Show()

	ShoppingTooltip1:Hide()

	if not bind:IsMouseEnabled() then
		bind:EnableMouse(true)
	end

	if spellmacro == "MACRO" then
		bind.button.id = bind.button:GetID()

		if floor(.5 + select(2,MacroFrameTab1Text:GetTextColor()) * 10) / 10 == .8 then bind.button.id = bind.button.id + MAX_MACROS end

		bind.button.name = GetMacroInfo(bind.button.id)

		GameTooltip:SetOwner(bind, "ANCHOR_TOP")
		E:Point(GameTooltip, "BOTTOM", bind, "TOP", 0, 1)
		GameTooltip:AddLine(bind.button.name, 1, 1, 1)

		bind.button.bindings = {GetBindingKey(spellmacro.." "..bind.button.name)}
			if getn(bind.button.bindings == 0) then
				GameTooltip:AddLine(L["No bindings set."], .6, .6, .6)
			else
				GameTooltip:AddDoubleLine(L["Binding"], L["Key"], .6, .6, .6, .6, .6, .6)
				for i = 1, getn(bind.button.bindings) do
					GameTooltip:AddDoubleLine(L["Binding"]..i, bind.button.bindings[i], 1, 1, 1)
				end
			end
		GameTooltip:Show()
	elseif spellmacro=="SHAPESHIFT" or spellmacro=="PET" then
		bind.button.id = tonumber(button:GetID())
		bind.button.name = button:GetName()

		if not bind.button.name then return end

		if not bind.button.id or bind.button.id < 1 or bind.button.id > (spellmacro=="SHAPESHIFT" and 10 or 12) then
			bind.button.bindstring = "CLICK "..bind.button.name..":LeftButton"
		else
			bind.button.bindstring = (spellmacro=="SHAPESHIFT" and "SHAPESHIFTBUTTON" or "BONUSACTIONBUTTON")..bind.button.id
		end

		GameTooltip:AddLine(L["Trigger"])
		GameTooltip:Show()
		GameTooltip:SetScript("OnHide", function()
			this:SetOwner(bind, "ANCHOR_NONE")
			E:Point(this, "BOTTOM", bind, "TOP", 0, 1)
			this:AddLine(bind.button.name, 1, 1, 1)
			bind.button.bindings = {GetBindingKey(bind.button.bindstring)}
			if getn(bind.button.bindings) == 0 then
				this:AddLine(L["No bindings set."], .6, .6, .6)
			else
				this:AddDoubleLine(L["Binding"], L["Key"], .6, .6, .6, .6, .6, .6)
				for i = 1, getn(bind.button.bindings) do
					this:AddDoubleLine(i, bind.button.bindings[i])
				end
			end
			this:Show()
			this:SetScript("OnHide", nil)
		end)
	else
		bind.button.name = button:GetName()

		bind.button.bindstring = bind.button.buttonType
		if not bind.button.bindstring and (find(bind.button.name, "BonusActionButton") or find(bind.button.name, "ActionButton")) then
			bind.button.bindstring = "ACTIONBUTTON"
		end

		if tonumber(sub(bind.button.name, -2)) then
			bind.button.bindstring = bind.button.bindstring .. sub(bind.button.name, -2)
		elseif tonumber(sub(bind.button.name, -1)) then
			bind.button.bindstring = bind.button.bindstring .. sub(bind.button.name, -1)
		end

		GameTooltip:AddLine(L["Trigger"])
		GameTooltip:Show()
		GameTooltip:SetScript("OnHide", function()
			this:SetOwner(bind, "ANCHOR_TOP")
			E:Point(this, "BOTTOM", bind, "TOP", 0, 4)
			this:AddLine(bind.button.name, 1, 1, 1)
			bind.button.bindings = {GetBindingKey(bind.button.bindstring)}
			if getn(bind.button.bindings) == 0 then
				this:AddLine(L["No bindings set."], .6, .6, .6)
			else
				this:AddDoubleLine(L["Binding"], L["Key"], .6, .6, .6, .6, .6, .6)
				for i = 1, getn(bind.button.bindings) do
					this:AddDoubleLine(i, bind.button.bindings[i])
				end
			end
			this:Show()
			this:SetScript("OnHide", nil)
		end)
	end
end

local script
local shapeshift = ShapeshiftButton1:GetScript("OnClick")
local pet = PetActionButton1:GetScript("OnClick")

function AB:RegisterButton(b, override)
	if b.IsObjectType and b.GetScript and b:IsObjectType("CheckButton") then
		local buttonName = b:GetName()
		if buttonName then
			if find(buttonName, "MultiBarLeftButton")
			or find(buttonName, "MultiBarRightButton")
			or find(buttonName, "MultiBarBottomLeftButton")
			or find(buttonName, "MultiBarBottomRightButton")
			or find(buttonName, "BonusActionButton")
			or find(buttonName, "ActionButton") or override then
				HookScript(b, "OnEnter", function() self:BindUpdate(b) end)
				script = b:GetScript("OnClick")
				if script == shapeshift then
					HookScript(b, "OnEnter", function() self:BindUpdate(b, "SHAPESHIFT") end)
				elseif script == pet then
					HookScript(b, "OnEnter", function() self:BindUpdate(b, "PET") end)
				end
			end
		end
	end
end

function AB:RegisterMacro(addon)
	if addon == "Blizzard_MacroUI" then
		for i = 1, MAX_MACROS do
			local b = _G["MacroButton"..i]
			HookScript(b, "OnEnter", function() AB:BindUpdate(this, "MACRO") end)
		end
	end
end

function AB:ChangeBindingProfile()
	if ElvUIBindPopupWindowCheckButton:GetChecked() then
		LoadBindings(2)
		SaveBindings(2)
	else
		LoadBindings(1)
		SaveBindings(1)
	end
end

function AB:LoadKeyBinder()
	bind:SetFrameStrata("DIALOG")
	bind:SetFrameLevel(99)
	bind:EnableMouse(true)
	bind:EnableKeyboard(true)
	bind:EnableMouseWheel(true)
	bind.texture = bind:CreateTexture()
	bind.texture:SetAllPoints(bind)
	bind.texture:SetTexture(0, 0, 0, .25)
	bind:Hide()

	bind:SetScript("OnEnter", function() local db = this.button:GetParent().db if db and db.mouseover then AB:Button_OnEnter(this.button) end end)
	bind:SetScript("OnLeave", function() AB:BindHide() local db = this.button:GetParent().db if db and db.mouseover then AB:Button_OnLeave(this.button) end end)
	bind:SetScript("OnKeyUp", function() self:BindListener(arg1) end)
	bind:SetScript("OnMouseUp", function() self:BindListener(arg1) end)
	bind:SetScript("OnMouseWheel", function() if arg1 > 0 then self:BindListener("MOUSEWHEELUP") else self:BindListener("MOUSEWHEELDOWN") end end)

	local b = EnumerateFrames()
	while b do
		self:RegisterButton(b)
		b = EnumerateFrames(b)
	end

	for b, _ in pairs(self["handledButtons"]) do
		self:RegisterButton(b, true)
	end

	if not IsAddOnLoaded("Blizzard_MacroUI") then
		self:SecureHook("LoadAddOn", "RegisterMacro")
	else
		self:RegisterMacro("Blizzard_MacroUI")
	end

	--Special Popup
	local f = CreateFrame("Frame", "ElvUIBindPopupWindow", UIParent)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetFrameLevel(99)
	f:SetClampedToScreen(true)
	E:Size(f, 360, 130)
	E:SetTemplate(f, "Transparent")
	f:Hide()

	local header = CreateFrame("Button", nil, f)
	E:SetTemplate(header, "Default", true)
	E:Size(header, 100, 25)
	E:Point(header, "CENTER", f, "TOP")
	header:SetFrameLevel(header:GetFrameLevel() + 2)
	header:EnableMouse(true)
	header:RegisterForClicks("AnyUp", "AnyDown")
	header:SetScript("OnMouseDown", function() f:StartMoving() end)
	header:SetScript("OnMouseUp", function() f:StopMovingOrSizing() end)

	local title = header:CreateFontString("OVERLAY")
	E:FontTemplate(title)
	E:Point(title, "CENTER", header, "CENTER")
	title:SetText("Key Binds")

	local desc = f:CreateFontString("ARTWORK")
	desc:SetFontObject("GameFontHighlight")
	desc:SetJustifyV("TOP")
	desc:SetJustifyH("LEFT")
	E:Point(desc, "TOPLEFT", 18, -32)
	E:Point(desc, "BOTTOMRIGHT", -18, 48)
	desc:SetText(L["Hover your mouse over any actionbutton or spellbook button to bind it. Press the escape key or right click to clear the current actionbutton's keybinding."])

	local perCharCheck = CreateFrame("CheckButton", f:GetName().."CheckButton", f, "OptionsCheckButtonTemplate")
	_G[perCharCheck:GetName() .. "Text"]:SetText(CHARACTER_SPECIFIC_KEYBINDINGS)

	perCharCheck:SetScript("OnShow", function()
		perCharCheck:SetChecked(GetCurrentBindingSet() == 2)
	end)

	perCharCheck:SetScript("OnClick", function()
		if AB.bindingsChanged then
			E:StaticPopup_Show("CONFIRM_LOSE_BINDING_CHANGES")
		else
			AB:ChangeBindingProfile()
		end
	end)

	perCharCheck:SetScript("OnEnter", function()
		GameTooltip:SetOwner(perCharCheck, "ANCHOR_RIGHT")
		GameTooltip:SetText(CHARACTER_SPECIFIC_KEYBINDING_TOOLTIP, nil, nil, nil, nil, 1)
	end)

	perCharCheck:SetScript("OnLeave", GameTooltip_Hide)

	local save = CreateFrame("Button", f:GetName().."SaveButton", f, "OptionsButtonTemplate")
	_G[save:GetName() .. "Text"]:SetText(L["Save"])
	E:Width(save, 150)
	save:SetScript("OnClick", function()
		AB:DeactivateBindMode(true)
	end)

	local discard = CreateFrame("Button", f:GetName().."DiscardButton", f, "OptionsButtonTemplate")
	E:Width(discard, 150)
	_G[discard:GetName() .. "Text"]:SetText(L["Discard"])

	discard:SetScript("OnClick", function()
		AB:DeactivateBindMode(false)
	end)

	--position buttons
	E:Point(perCharCheck, "BOTTOMLEFT", discard, "TOPLEFT", 0, 2)
	E:Point(save, "BOTTOMRIGHT", -14, 10)
	E:Point(discard, "BOTTOMLEFT", 14, 10)

	local S = E:GetModule("Skins")
	S:HandleCheckBox(perCharCheck)
	S:HandleButton(save)
	S:HandleButton(discard)
end
