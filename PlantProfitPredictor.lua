local CurrentPlants = PPPShadowlandsPlants
local CurrentAlchemy = PPPShadowlandsAlchemy
local MAX_NUMBER_MILLING_LIST = 12 -- max number of items displayed on the milling tab
local MAX_NUMBER_PLANTS = 6 -- how many plants can be shown on the plant page at once
local MAX_NUMBER_PIGMENTS = 3 -- how many pigments can be shown at once
local MAX_NUMBER_ALCHEMY_CREATIONS = 3 -- how many alchemy creations can we show per page
local MAX_NUMBER_ALCHEMY_INGREDIENTS = 6 -- how many alchemy ingredients can we show

local list_of_ah_items = {}
for k,v in pairs(PPPPlants) do
	list_of_ah_items[k]=true
end
for k,v in pairs(PPPPigments) do
	list_of_ah_items[k]=true
end
for k,v in pairs(PPPAlchemyCreations) do
	list_of_ah_items[k]=true
end

local function FindXsInBag(list)
	local total = {}
	for k,v in pairs(list) do
		total[k] = 0
	end
	for bag = 0,4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemID = GetContainerItemID(bag, slot)
			if itemID then
				if list[itemID] ~= nil then
					total[itemID] = total[itemID] + select(2, GetContainerItemInfo(bag, slot))
				end
			end
		end
	end
	return total
end

-- PPPMillingHistory = { {id=plant_id, output = {luminous= amount, tranquil=amount, umbral=amount}, mass=was_it_mass } }
local currently_milling = false
local current_milling_info = {}
local last_bag = {}
local current_bag = {}
local function UpdateInventory()
	last_bag = current_bag
	local list_of_items = {}
	for k,v in pairs(PPPPlants) do
		list_of_items[k] = 0
	end
	for k,v in pairs(PPPPigments) do
		list_of_items[k] = 0
	end
	current_bag = FindXsInBag(list_of_items)
	
	-- check for any differences
	if currently_milling then
		for id, count in pairs(current_bag) do
			if last_bag[id] ~= count then
				if current_milling_info.id == nil then
					for k,v in pairs(PPPPlants) do
						if id == k then
							current_milling_info.id=k
							for i=1,#v.pigments do
								current_milling_info.output[v.pigments[i]] = 0
							end
						end
					end
				else
					if current_milling_info.id ~= nil then
						for k,v in pairs(current_milling_info.output) do
							if id == k then
								current_milling_info.output[id] = count - last_bag[id]
							end
						end
					end
				end
			end
		end
	end
end

local function UpdatePlantCountFrame()
	UpdateInventory()
	
	-- hide everything in case not needed
	for i=1,MAX_NUMBER_PLANTS do
		-- hide pigments too in case they're not needed
		for j=1,MAX_NUMBER_PIGMENTS do
			_G["PPPBaseFrameMillingFrameMainPlant" .. i .. "PigmentButton" .. j]:Hide()
		end
		_G["PPPBaseFrameMillingFrameMainPlant" .. i]:Hide()
	end
	
	-- update plant count
	for i=1,#CurrentPlants do
		if i <= MAX_NUMBER_PLANTS then
			local frame_name = "PPPBaseFrameMillingFrameMainPlant" .. i .. "Name"
			frame = _G[frame_name]
			if frame then
				local possible_millings = math.floor(current_bag[CurrentPlants[i]] / 5)
				_G["PPPBaseFrameMillingFrameMainPlant" .. i]:Show()
				_G["PPPBaseFrameMillingFrameMainPlant" .. i .. "PlantButton"]:SetNormalTexture(PPPPlants[CurrentPlants[i]].file)
				_G["PPPBaseFrameMillingFrameMainPlant" .. i .. "PlantButton"]:SetText(PPPPlants[CurrentPlants[i]].name)
				_G["PPPBaseFrameMillingFrameMainPlant" .. i .. "TimesCanMill"]:SetText("x" .. possible_millings)
				frame:SetText(PPPPlants[CurrentPlants[i]].name .. ": " .. current_bag[CurrentPlants[i]])
				
				-- clear arrow text
				_G["PPPBaseFrameMillingFrameMainPlant" .. i .. "Arrow"]:SetText("|cffffff00Per milling of 5 plants:|r|cffffffff")
				
				-- set texture and text of pigment buttons
				for j=1,#PPPPlants[CurrentPlants[i]].pigments do
					if j<=MAX_NUMBER_PIGMENTS then
						local current_text = _G["PPPBaseFrameMillingFrameMainPlant" .. i .. "Arrow"]:GetText()
						if current_text ~= nil then
							_G["PPPBaseFrameMillingFrameMainPlant" .. i .. "Arrow"]:SetText(current_text .. "\n" .. PPPPigments[PPPPlants[CurrentPlants[i]].pigments[j]].name)
						else
							_G["PPPBaseFrameMillingFrameMainPlant" .. i .. "Arrow"]:SetText(PPPPigments[PPPPlants[CurrentPlants[i]].pigments[j]].name)
						end
						pigment_frame_name = "PPPBaseFrameMillingFrameMainPlant" .. i .. "PigmentButton" .. j
						pigment_frame = _G[pigment_frame_name]
						if pigment_frame then
							pigment_frame:Show()
							pigment_frame:SetText(PPPPigments[PPPPlants[CurrentPlants[i]].pigments[j]].name)
							pigment_frame:SetNormalTexture(PPPPigments[PPPPlants[CurrentPlants[i]].pigments[j]].file)
							
							-- update pigment estimate
							local total_milled = 0
							local times_milled = 0
							if PPPMillingHistory ~= nil then
								for k,v in pairs(PPPMillingHistory) do
									if v.id == CurrentPlants[i] then
										total_milled = total_milled + v.output[PPPPlants[CurrentPlants[i]].pigments[j]]
										if v.mass_milled then
											times_milled = times_milled + 4
										else
											times_milled = times_milled + 1
										end
									end
								end
							end
							local current_text = _G["PPPBaseFrameMillingFrameMainPlant" .. i .. "Arrow"]:GetText()
							if total_milled ~= 0 then
								local estimation_per_milling = (total_milled/times_milled)
								_G[pigment_frame_name .. "Count"]:SetText(string.format("%.1f",estimation_per_milling*possible_millings))
								_G["PPPBaseFrameMillingFrameMainPlant" .. i .. "Arrow"]:SetText(current_text .. ": " .. string.format("%.1f",estimation_per_milling))
							else
								_G["PPPBaseFrameMillingFrameMainPlant" .. i .. "Arrow"]:SetText(current_text .. ": 0")
								_G[pigment_frame_name .. "Count"]:SetText("0")
							end
						else
							print("[PlantProfitPredictor.lua:172] Could not locate frame " .. pigment_frame_name)
						end
					else
						print("[PlantProfitPredictor] Too many pigments!")
					end
				end
				local current_text = _G["PPPBaseFrameMillingFrameMainPlant" .. i .. "Arrow"]:GetText()
				_G["PPPBaseFrameMillingFrameMainPlant" .. i .. "Arrow"]:SetText(current_text .. "|r")
			else
				print("[PlantProfitPredictor.lua:193] Could not locate frame " .. frame_name)
			end
		else
			print("[PlantProfitPredictor] NEED NEW PAGE!!!")
		end
	end
end

local function FinishedMillLooting()
	if currently_milling then
		table.insert(PPPMillingHistory, 1, current_milling_info)
		currently_milling = false
		current_milling_info = {}
		PPPScrollBarUpdate()
		if PPPBaseFrameMillingFrame:IsVisible() then
			UpdatePlantCountFrame()
		end
	end
end

local function UpdateAlchemyPage()
	UpdateInventory()
	for i=1,#CurrentAlchemy do
		if i<= MAX_NUMBER_ALCHEMY_CREATIONS then
			local frame_name = "PPPBaseFrameAlchemyFrameMainCreation" .. i
			local frame = _G[frame_name]
			if frame then
				frame:Show()
				_G[frame_name .. "PlantButton"]:SetNormalTexture(PPPAlchemyCreations[CurrentAlchemy[i]].file)
				_G[frame_name .. "PlantButton"]:SetText(PPPAlchemyCreations[CurrentAlchemy[i]].name)
				_G[frame_name .. "Name"]:SetText(PPPAlchemyCreations[CurrentAlchemy[i]].name)
				
				-- run through each ingredient
				local ingredient_number = 1
				local max_can_create = 0
				for k,v in pairs(PPPAlchemyCreations[CurrentAlchemy[i]].ingredients) do
					local can_create_with_this_ingredient = math.floor(current_bag[k] / v)
					if ingredient_number == 1 or can_create_with_this_ingredient < max_can_create then
						max_can_create = can_create_with_this_ingredient
					end
					if ingredient_number <= MAX_NUMBER_ALCHEMY_INGREDIENTS then
						local ingredient_frame_name = frame_name .. "IngredientButton" .. ingredient_number
						ingredient_frame = _G[ingredient_frame_name]
						if ingredient_frame then
							ingredient_frame:Show()
							ingredient_frame:SetNormalTexture(PPPPlants[k].file)
							ingredient_frame:SetText(PPPPlants[k].name .. "\n|cffffffffTotal in bags: " .. current_bag[k] .. "|r")
							_G[ingredient_frame_name .. "Count"]:SetText(v)
							_G[ingredient_frame_name .. "TimesCanCreate"]:SetText(can_create_with_this_ingredient)
						else
							print("[PlantProfitPredictor] Could not locate frame " .. frame_name .. "IngredientButton" .. ingredient_number)
						end
						ingredient_number = ingredient_number + 1
					else
						print("[PlantProfitPredictor] I'm not equipped to handle that many ingredients!")
					end
				end
				can_create_frame = _G[frame_name .. "TimesCanCreate"]:SetText("x" .. max_can_create)
			else
				print("[PlantProfitPredictor] Could not locate frame " .. frame_name)
			end
		else
			print("[PlantProfitPredictor] Too many recipes! I need more pages!")
		end
	end
end

function PPPGotoPlantPage()
	UpdatePlantCountFrame()
end
function PPPGotoMillingPage()
	-- update information when going to milling page
	PPPScrollBarUpdate()
end
function PPPGotoAlchemyPage()
	-- stuff to do when going to alchemy page
	UpdateAlchemyPage()
end
function PPPGotoDebugPage()
	-- stuff to do when going to debug page
	
	-- update last ah scan
	if PPPAuctionHistory.time_of_query ~= nil then
		PPPBaseFrameDebugFrameMainLastAHScanTime:SetText("Last Auction House scan: " .. PPPAuctionHistory.time_of_query)
	else
		PPPBaseFrameDebugFrameMainLastAHScanTime:SetText("Last Auction House scan: N/A")
	end
	PPPBaseFrameDebugFrameMainLastAHScanCount:SetText("Number of replicate items stored: " .. C_AuctionHouse.GetNumReplicateItems())
	
	local ah_items_checked_text = "Items checked for on the AH:\n"
	for k,v in pairs(list_of_ah_items) do
		ah_items_checked_text = ah_items_checked_text .. "[" .. k .. "]\n"
	end
	PPPBaseFrameDebugFrameMainAHItemsChecked:SetText(ah_items_checked_text)
	
	local count_of_found_items = 0
	local ah_items_found_text = "Items found on the AH:\n"
	for k,v in pairs(PPPAuctionHistory.items) do
		ah_items_found_text = ah_items_found_text .. "[" .. k .. "] for " .. v .. "\n"
		count_of_found_items = count_of_found_items + 1
	end
	PPPBaseFrameDebugFrameMainSavedItemsCount:SetText("Number of items stored in PPPAuctionHistory: " .. count_of_found_items)
	PPPBaseFrameDebugFrameMainAHItemsFound:SetText(ah_items_found_text)
end

local function ToggleFrame()
	if PPPBaseFrame:IsVisible() then
		PPPBaseFrame:Hide()
	else
		UpdatePlantCountFrame()
		PPPBaseFrame:Show()
	end
end

function PPPScrollBarUpdate()
	local line, lineplusoffset
	FauxScrollFrame_Update(PPPBaseFrameMillingFrameLogScrollFrame,#PPPMillingHistory,12,25) -- (frame, total number, number shown, height)
	for line=1,12 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(PPPBaseFrameMillingFrameLogScrollFrame)
		if lineplusoffset <= #PPPMillingHistory then
			local plant_name = nil
			local plant_file, plant_id
			for k,v in pairs(PPPPlants) do
				if k == PPPMillingHistory[lineplusoffset].id then
					_G["PPPBaseFrameMillingFrameLogEntry" .. line .. "PlantButton"]:SetText(v.name)
					_G["PPPBaseFrameMillingFrameLogEntry" .. line .. "PlantButton"]:SetNormalTexture(v.file)
					if PPPMillingHistory[lineplusoffset].mass_milled then
						_G["PPPBaseFrameMillingFrameLogEntry" .. line .. "Name"]:SetText(v.name .. " x20")
					else
						_G["PPPBaseFrameMillingFrameLogEntry" .. line .. "Name"]:SetText(v.name .. " x5")
					end
				end
			end
			
			local pigment_int = 1
			for k,v in pairs(PPPMillingHistory[lineplusoffset].output) do
				_G["PPPBaseFrameMillingFrameLogEntry" .. line .. "PigmentButton" .. pigment_int .. "Count"]:SetText(v)
				_G["PPPBaseFrameMillingFrameLogEntry" .. line .. "PigmentButton" .. pigment_int]:SetNormalTexture(PPPPigments[k].file)
				_G["PPPBaseFrameMillingFrameLogEntry" .. line .. "PigmentButton" .. pigment_int]:SetText(PPPPigments[k].name)
				pigment_int = pigment_int + 1
			end
			_G["PPPBaseFrameMillingFrameLogEntry" .. line]:Show()
		else
			_G["PPPBaseFrameMillingFrameLogEntry" .. line]:Hide()
		end
	end
end

local function ScanNewAHList()
	if C_AuctionHouse.GetNumReplicateItems()-1 ~= -1 then
		print("[PlantProfitPredictor] About to scan " .. C_AuctionHouse.GetNumReplicateItems()-1 .. " items.")
		PPPAuctionHistory.time_of_query = date()
		PPPAuctionHistory.items = {}
		local relevant_item_count = 0
		for i = 0, C_AuctionHouse.GetNumReplicateItems()-1 do
			local item_name, _, count, _, _, _, _, min_bid, _, buyout_price, _, _, _, _, _, _, item_id, _ = C_AuctionHouse.GetReplicateItemInfo(i)
			if list_of_ah_items[item_id] then
				PPPAuctionHistory.items[item_id] = {C_AuctionHouse.GetReplicateItemInfo(i)}
				relevant_item_count = relevant_item_count + 1
			end
		end		
		print("[PlantProfitPredictor] Finished scanning and found " .. relevant_item_count .. " relevant listings!")
	else
		print("[PlantProfitPredictor] No Auction House data to scan!")
	end
end

function PPPDebugButtonScanNewAHList()
	ScanNewAHList()
end

local first_query = false
local delayed_yet = false
local milled_waited_for_delay_yet = false
-- PPPAuctionHistory = { 
function PPPEventHandler(self, event, arg1, arg2, arg3)
	if event == "ADDON_LOADED" and arg1 == "PlantProfitPredictor" then
		-- check if saved variable exists
		if PPPMillingHistory == nil then
			PPPMillingHistory = {}
		end
		-- print(type(date()))
		if PPPAuctionHistory == nil then
			print("[PlantProfitPredictor] Open up the Auction House to store plant prices!")
			PPPAuctionHistory = {time_of_query=nil, items={}}
		else
			print("[PlantProfitPredictor] Open up the Auction House to store plant prices!")
		end
		
		if PPPBaseFrame:IsVisible() then
			UpdatePlantCountFrame() -- run this in case client starts with window open & code ran before saved variables loaded
		end
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
		if arg3==51005 then
			milled_waited_for_delay_yet = false
			current_milling_info = {id=nil, output={},mass_milled=false}
			currently_milling = true
		elseif PPPMillingSpells[arg3] ~= nil then
			milled_waited_for_delay_yet = true
			current_milling_info = {id=PPPMillingSpells[arg3], output={},mass_milled=true}
			for i=1,#PPPPlants[PPPMillingSpells[arg3]].pigments do
				current_milling_info.output[PPPPlants[PPPMillingSpells[arg3]].pigments[i]] = 0
			end
			currently_milling = true
		end
	elseif event=="BAG_UPDATE" then
		if delayed_yet then
			UpdateInventory()
			if PPPBaseFrame:IsVisible() then
				UpdatePlantCountFrame()
			end
		end
	elseif event=="BAG_UPDATE_DELAYED" then
		delayed_yet = true
		if milled_waited_for_delay_yet == true then
			FinishedMillLooting()
		end
	elseif event == "LOOT_CLOSED" then
		-- FinishedMillLooting()
		milled_waited_for_delay_yet = true
	elseif event == "AUCTION_HOUSE_SHOW" then
		-- scan auction house
		print("[PlantProfitPredictor] Scanning Auction House if possible!")
		C_AuctionHouse.ReplicateItems()
		first_query = true		
	elseif event == "REPLICATE_ITEM_LIST_UPDATE" then
		-- list update
		if first_query then
			-- first time AH data updated
			--print(C_AuctionHouse.GetNumReplicateItems())
			print("[PlantProfitPredictor] Updating PPPAuctionHistory!")
			ScanNewAHList()
		end
		first_query = false
	end
end

function PlantProfitPredictor_OnLoad()
	PPPBaseFrame:RegisterEvent("ADDON_LOADED")
	PPPBaseFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	PPPBaseFrame:RegisterEvent("BAG_UPDATE")
	PPPBaseFrame:RegisterEvent("BAG_UPDATE_DELAYED")
	PPPBaseFrame:RegisterEvent("LOOT_CLOSED")
	PPPBaseFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
	PPPBaseFrame:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
	PPPBaseFrame:SetScript("OnEvent", PPPEventHandler)
end

local function PlantProfitPredictor_SlashCommand(msg, editbox)
	ToggleFrame();
end

SLASH_PPP1 = "/ppp";
SLASH_PPP2 = "/plantprofitpredictor";
SlashCmdList["PPP"] = PlantProfitPredictor_SlashCommand;
