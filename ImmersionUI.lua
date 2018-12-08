-- MyAddon = {};
-- MyAddon.panel = CreateFrame("Frame", "ImmersionUIPanel", UIParent);
-- -- Register in the Interface Addon Options GUI
-- -- Set the name for the Category for the Options Panel
-- MyAddon.panel.name = "Immersion UI";
-- -- Add the panel to the Interface Options
-- InterfaceOptions_AddCategory(MyAddon.panel);

-- -- Make a child panel
-- MyAddon.childpanel = CreateFrame( "Frame", "MyAddonChild", MyAddon.panel);
-- MyAddon.childpanel.name = "MyChild";
-- -- Specify childness of this panel (this puts it under the little red [+], instead of giving it a normal AddOn category)
-- MyAddon.childpanel.parent = MyAddon.panel.name;
-- -- Add the child to the Interface Options
-- InterfaceOptions_AddCategory(MyAddon.childpanel);


-- fixed bug where ui would fade in an instanced area after leaving combat


local InCombatAlpha = 0.8;
local OutCombatAlpha = 0.4;
local isInstance, instanceType;


CreateFrame("Frame","IMUICompass",UIParent) -- Compass frame


local frame = CreateFrame("FRAME"); -- Need a frame to respond to events
frame:RegisterEvent("ADDON_LOADED"); -- Fired when saved variables are loaded
frame:RegisterEvent("PLAYER_LOGOUT"); -- Fired when about to log out
frame:RegisterEvent("PLAYER_ENTERING_WORLD"); -- Fired when logging into the world, entering an area, instance, etc.
frame:RegisterEvent("PLAYER_REGEN_DISABLED"); -- Fired when player enters combat or takes aggro
frame:RegisterEvent("PLAYER_REGEN_ENABLED"); -- Fired when player leaves combat or loses aggro
frame:RegisterEvent("PLAYER_XP_UPDATE"); -- Fired when the player gains experience points
frame:RegisterEvent("UPDATE_FACTION"); -- Fired when the player gains or loses faction reputation

local imui = nil;

local function alert(message)

	print("|cFFFF0000Immersion UI:|cFFFF9900 " .. message)

end

local function toggleChat(hideit)

	if hideit then
		QuickJoinToastButton:Hide();
		ChatFrameMenuButton:Hide();
	else
		QuickJoinToastButton:Show();
		ChatFrameMenuButton:Show();
	end
	for i=1,NUM_CHAT_WINDOWS do for _,v in pairs{"","Tab"}do local f=_G["ChatFrame"..i..v]if hideit then f.v=f:IsVisible()end f.ORShow=f.ORShow or f.Show f.Show=hideit and f.Hide or f.ORShow if f.v then f:Show()end end end

end

local function toggleCompass(hideit)

	if hideit then
		IMUICompass:Hide();
		IMUICompassBG:Hide();
		IMUICompassDIAL:Hide();
		IMUICompassGLARE:Hide();
		IMUICompassNORTH:Hide();
	else
		IMUICompass:Show();
		IMUICompassBG:Show();
		IMUICompassDIAL:Show();
		IMUICompassGLARE:Show();
		IMUICompassNORTH:Show();
	end

end

local function unfadeFrames()

	MinimapCluster:Show();
	--ObjectiveTrackerFrame.Temphide = "";
	ObjectiveTrackerFrame:Show();
	PlayerFrame:Show();
	TargetFrame:SetAlpha(1);
	VehicleSeatIndicator:Show();
	VehicleSeatIndicator:SetAlpha(1);

	toggleChat(false)


	BuffFrame:SetPoint("TOPRIGHT",-205,-13); --move the buff bar back to the default position

	BuffFrame:SetAlpha(1);
	MainMenuBarArtFrame:SetAlpha(1);
	StanceBarFrame:SetAlpha(1);
	MicroButtonAndBagsBar:SetAlpha(1);
	--MainMenuExpBar:SetAlpha(1);
	StatusTrackingBarManager:SetAlpha(1);
	--ExhaustionTick:SetAlpha(1);
	--ReputationWatchBar:SetAlpha(1);
	StatusTrackingBarManager:SetAlpha(1);
	MultiBarLeft:SetAlpha(1);
	MultiBarRight:SetAlpha(1);
	--ObjectiveTrackerFrame.Temphide = function() ObjectiveTrackerFrame:Hide() end; ObjectiveTrackerFrame:SetScript("OnShow", ObjectiveTrackerFrame.Temphide)
	--ObjectiveTrackerFrame.Temphide = "";
	--ObjectiveTrackerFrame:Show()

end

local function fadeFrames()

	MinimapCluster:Hide();
	ObjectiveTrackerFrame:Hide();
	PlayerFrame:Hide();
	TargetFrame:SetAlpha(0);
	VehicleSeatIndicator:Hide();
	VehicleSeatIndicator:SetAlpha(0);

	if imui.hidechat then toggleChat(true) end

	BuffFrame:SetPoint("TOPRIGHT");

	BuffFrame:SetAlpha(OutCombatAlpha);
	MainMenuBarArtFrame:SetAlpha(OutCombatAlpha);
	StanceBarFrame:SetAlpha(OutCombatAlpha);
	MicroButtonAndBagsBar:SetAlpha(OutCombatAlpha);
	--MainMenuExpBar:SetAlpha(OutCombatAlpha);
	StatusTrackingBarManager:SetAlpha(OutCombatAlpha);
	MultiBarLeft:SetAlpha(OutCombatAlpha);
	MultiBarRight:SetAlpha(OutCombatAlpha);
	--ExhaustionTick:SetAlpha(OutCombatAlpha);
	--ReputationWatchBar:SetAlpha(OutCombatAlpha);

	--ObjectiveTrackerFrame.Temphide = function() ObjectiveTrackerFrame:Hide() end; ObjectiveTrackerFrame:SetScript("OnShow", ObjectiveTrackerFrame.Temphide)

end

local function initCompass()

	-- create a frame and texture to show the class icons
	-- this image includes the icons of all player classes, arranged in a 4x4 grid
	
	IMUICompass:SetWidth(128)
	IMUICompass:SetHeight(128)
	IMUICompass:SetPoint("CENTER",0,0)

	IMUICompass:CreateTexture("IMUICompassBG", "BACKGROUND")
	IMUICompassBG:SetAllPoints()
	IMUICompassBG:SetTexture("Interface/Addons/ImmersionUI/compass-bg")
	IMUICompassBG:SetRotation(0)

	IMUICompass:CreateTexture("IMUICompassDIAL", "BORDER")
	IMUICompassDIAL:SetAllPoints()
	IMUICompassDIAL:SetTexture("Interface/Addons/ImmersionUI/compass-dial")

	IMUICompass:CreateTexture("IMUICompassGLARE", "ARTWORK")
	IMUICompassGLARE:SetAllPoints()
	IMUICompassGLARE:SetTexture("Interface/Addons/ImmersionUI/compass-glare")
	IMUICompassGLARE:SetRotation(0)

	IMUICompass:CreateTexture("IMUICompassNORTH", "ARTWORK")
	IMUICompassNORTH:SetAllPoints()
	IMUICompassNORTH:SetTexture("Interface/Addons/ImmersionUI/compass-north")

	IMUICompass:Show();
	IMUICompassBG:Show();
	IMUICompassDIAL:Show();
	IMUICompassGLARE:Show();
	IMUICompassNORTH:Show();


	local function CompassStopMoving()
		IMUICompass:StopMovingOrSizing()
		imui.point, imui.relativeTo, imui.relativePoint, imui.xOfs, imui.yOfs = IMUICompass:GetPoint()
	end

	IMUICompass:SetMovable(true)
	IMUICompass:EnableMouse(true)
	IMUICompass:RegisterForDrag("LeftButton")
	IMUICompass:SetScript("OnDragStart", IMUICompass.StartMoving)
	IMUICompass:SetScript("OnDragStop", CompassStopMoving)

	if imui.point then
		IMUICompass:SetPoint(imui.point, imui.relativeTo, imui.relativePoint, imui.xOfs, imui.yOfs);
	end


	local function onUpdate(self,elapsed)

		-- Force the buff frame to the top right corner, if it's not already there
		if imui.enabled then
			BuffFrame:SetPoint("TOPRIGHT", 0, 0);
		end

		if isInstance then

		--ReloadUI();
			IMUICompass:Hide()

		else
			facing = (GetPlayerFacing()  * -1)
			IMUICompass:Show()
			IMUICompassDIAL:SetRotation(facing)
			IMUICompassNORTH:SetRotation(facing)
		end
	end
	local f = CreateFrame("frame")
	f:SetScript("OnUpdate", onUpdate)

	toggleCompass(imui.hidecompass)

end




function frame:OnEvent(event, arg1)

	if event == "ADDON_LOADED" and arg1 == "ImmersionUI" then
		-- load variables.
		IMUI_SavedVars = IMUI_SavedVars or {};
      	imui = IMUI_SavedVars;
		
		-- set variable defaults if they are unset
		if imui.hidechat == nil then
			imui.hidechat = true
		end
		if imui.enabled == nil then
			imui.enabled = false
		end
		if imui.hidecompass == nil then
			imui.hidecompass = false
		end

		if imui.enabled == false then
			print("Thanks for installing |cFFFF9900Immersion UI|cFFFFFFFF!");
			print("To enable |cFFFF9900Immersion UI|cFFFFFFFF, type |cFF66FF00/imui on");
		end

		initCompass();

	elseif event == "PLAYER_ENTERING_WORLD" then

		-- Check if the player has entered an instanced area (i.e. dungeon, raid, pvp, arena, etc.)
		isInstance, instanceType = IsInInstance()

		if imui.enabled then

			fadeFrames();

			if isInstance then
				if not imui.hidecompass then
					alert("You've just entered an instanced area. The compass has been auto-disabled and will auto-enable when you leave this area.");
					toggleCompass(true);
				end
				--unfadeFrames();
			else
				--fadeFrames();
				--initCompass();
				-- if not imui.hidecompass then 
				-- 	toggleCompass(false);
				-- end
				toggleCompass(imui.hidecompass);
			end

		end

	-- elseif event == "PLAYTIME_CHANGED" then

	-- 	if imui.enabled then

	-- 		BuffFrame:SetPoint("TOPRIGHT");

	-- 	end
	
	elseif event == "PLAYER_REGEN_DISABLED" then
		if imui.enabled and not isInstance then
			MainMenuBarArtFrame:SetAlpha(InCombatAlpha);
			StanceBarFrame:SetAlpha(InCombatAlpha);
			MicroButtonAndBagsBar:SetAlpha(InCombatAlpha);
			--MainMenuExpBar:SetAlpha(InCombatAlpha);
			StatusTrackingBarManager:SetAlpha(InCombatAlpha);
			MultiBarLeft:SetAlpha(InCombatAlpha);
			MultiBarRight:SetAlpha(InCombatAlpha);
			--ExhaustionTick:SetAlpha(InCombatAlpha);
			--ReputationWatchBar:SetAlpha(InCombatAlpha);
			BuffFrame:SetAlpha(InCombatAlpha);
		end
	
	elseif event == "PLAYER_REGEN_ENABLED" then
		if imui.enabled and not isInstance then
			MainMenuBarArtFrame:SetAlpha(OutCombatAlpha);
			StanceBarFrame:SetAlpha(OutCombatAlpha);
			MicroButtonAndBagsBar:SetAlpha(OutCombatAlpha);
			--MainMenuExpBar:SetAlpha(OutCombatAlpha);
			StatusTrackingBarManager:SetAlpha(OutCombatAlpha);
			MultiBarLeft:SetAlpha(OutCombatAlpha);
			MultiBarRight:SetAlpha(OutCombatAlpha);
			--ExhaustionTick:SetAlpha(OutCombatAlpha);
			--ReputationWatchBar:SetAlpha(OutCombatAlpha);
			BuffFrame:SetAlpha(OutCombatAlpha);
		end
	
	elseif event == "PLAYER_XP_UPDATE" or event == "UPDATE_FACTION" then
		if imui.enabled and not isInstance then
			--MainMenuExpBar:SetAlpha(OutCombatAlpha);
			StatusTrackingBarManager:SetAlpha(OutCombatAlpha);
			MultiBarLeft:SetAlpha(OutCombatAlpha);
			MultiBarRight:SetAlpha(OutCombatAlpha);
			--ReputationWatchBar:SetAlpha(OutCombatAlpha);
		end

	end

end

frame:SetScript("OnEvent", frame.OnEvent);


-- Known issue. Since, time() returns an integer (not a floating point number),
-- the threshold for double-clicking ranges from 0.0000000000001 to 1 second.
-- I tried using GetTime(), but I couldn't seem to get it to work.

-- double click compass toggles the fade
IMUICompass.timer = 0
IMUICompass:SetScript("OnMouseUp", function(...)
    if IMUICompass.timer < time() then
        IMUICompass.startTimer = false
    end
    if IMUICompass.timer == time() and IMUICompass.startTimer then
        IMUICompass.startTimer = false

		if not imui.enabled then
			alert("IMUI is now enabled.")
			imui.enabled = true;
			fadeFrames()
			--initCompass()
		else
			alert("IMUI is now disabled.")
			imui.enabled = false;
			unfadeFrames()
			--killCompass()
		end
    else
        IMUICompass.startTimer = true
        IMUICompass.timer = time()
    end
end)



-- SLASH COMMANDS

SLASH_IMMERSIONUI1 = "/immersionui"
SLASH_IMMERSIONUI2 = "/imui"
SlashCmdList["IMMERSIONUI"] = function(msg)

	if msg == "on" then

		-- if isInstance == true then
		-- 	print("|cFFFF0000Immersion UI:|cFFFF9900You are currently in an instanced area. You can enable the addon again when you leave this area.")
		-- else
			if not imui.enabled then
				alert("IMUI is now enabled.")
				imui.enabled = true;
				fadeFrames()
				initCompass()
			end
		-- end

	elseif msg == "off" then
		
		if imui.enabled then
			alert("IMUI is now disabled.")
			imui.enabled = false;
			unfadeFrames()
			toggleCompass(true);
		end

	elseif msg == "hidechat" then

		if not imui.hidechat then
			imui.hidechat = true;
			alert("Chat will now be hidden.")
			toggleChat(true);
		end

	elseif msg == "showchat" then

		if imui.hidechat then
			imui.hidechat = false;
			alert("Chat will now be shown.")
			toggleChat(false);
		end

	elseif msg == "showcompass" then

		if imui.hidecompass then
			imui.hidecompass = false;
			alert("Compass will now be shown.")
			toggleCompass(false);
		end

	elseif msg == "hidecompass" then

		if not imui.hidecompass then
			imui.hidecompass = true;
			alert("Compass will now be hidden.")
			toggleCompass(true);
		end
	
	elseif msg == "help" then

		print("Immersion UI commands:");
		print("/imui on – Enables the addon");
		print("/imui off – Disables the addon");
		print("/imui hidechat – Hides the chat frames");
		print("/imui showchat – Shows the chat frames");
		print("/imui hidecompass – Hides the compass");
		print("/imui showcompass – Shows the compass");
		print("/imui help – Displays this list");
	
	else

		print("|cFFFF0000Immersion UI:|cFFFF9900 Whoops! I didn't recognise that command. Try typing |cFFFFFFFF/imui help|cFFFF9900 for a commands list.")

	end
	
end 