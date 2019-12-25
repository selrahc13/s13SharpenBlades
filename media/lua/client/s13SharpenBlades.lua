-----------------------------------------------------------------------
-- s13SharpenBlades context menu module
-- by selrahc13
-----------------------------------------------------------------------

UISharpenBlades = {};

require "ISUI/ISToolTip"
require "s13utils"

-- General mod info
local MOD_ID = "s13SharpenBlades";
local MOD_NAME = "Sharpen all the blades with sharpening stones and honing steel";
local MOD_VERSION = "1.0b";
local MOD_AUTHOR = "selrahc13";
local MOD_DESCRIPTION = "Adds the ability to sharpen bladed weapons using whetstone and honing steel";

local debugItems = false;

-- ------------------------------------------------
-- Functions
-- ------------------------------------------------
---
-- --prints out the mod info on startup.
--
local function info()
	print("Mod Loaded: " .. MOD_NAME .. " by " .. MOD_AUTHOR .. " (v" .. MOD_VERSION .. ")");
end

function UISharpenBlades.createMenu(_player, _context, _items)
	local player = getSpecificPlayer(_player)
	local clickedItems = _items
  local inventory = player:getInventory()

  --print ("UISharpenBlades.createMenu()")
  -- Will store the clicked stuff.
  local item
  local stack = {}

  -- stop function if player has selected multiple item stacks
  if #clickedItems > 1 then
    --print("Selected multiple item stacks, exiting")
    return
  end

  --print (#clickedItems .. " entries")
  -- Iterate through all clicked items
  for i, entry in ipairs(clickedItems) do
    --print("Type: " .. type(entry))
    if type(entry) == "table" then
      for i = 2, #entry.items do
        -- if we have a stack, stick all items into a new table
        table.insert(stack, entry.items[i])
      end
    else
      -- we just have a single item in a table
      stack = clickedItems
      --print("createMenu: isItem")
    end
  end
      
  -- Add context option for sharpening the blade  
  for i, item in ipairs(stack) do
    --print("createMenu: item: " .. item:getName())
    -- Check if it is a bladed weapon
    -- Adds context menu entry for single items.
    if s13utils.isWhetstone(item) then
      local fluid = s13utils.getFirstWhetstoneFluid(player, item)
      local pctAvail = 0
      if not item:getType():contains("_Empty") then pctAvail = math.floor(item:getUsedDelta() * 100) end
      local _addtext = " ("..pctAvail..getText("ContextMenu_FullPercent") .. ")"
      local fixOption = _context:addOption("Prepare " .. item:getName() .. _addtext, _items, UISharpenBlades.onPrepStone, item, player)
      if not fluid or pctAvail == 100 then fixOption.notAvailable = true end
    end -- s13utils.isWhetstone()
    if s13utils.isBladed(item) then
      local fixers = {instanceItem("s13SharpenBlades.s13Whetstone_Oil_Full"), instanceItem("s13SharpenBlades.s13Whetstone_Water_Full"), instanceItem("s13SharpenBlades.s13Honing_Steel")}
      if item:getCondition() < item:getConditionMax() then
        local fixOption = _context:addOption("Repair " .. item:getType() .. " blade", clickedItems, nil);
        local subMenuFix = ISContextMenu:getNew(_context);
        _context:addSubMenu(fixOption, subMenuFix);
        UISharpenBlades.buildFixingMenu(item, player, fixers, fixOption, subMenuFix)
      end
    end -- s13utils.isBladed()
  end -- stack iteration loop
end

UISharpenBlades.addToolTip = function()
	local toolTip = ISToolTip:new();
	toolTip:initialise();
	toolTip:setVisible(false);
	return toolTip;
end

UISharpenBlades.buildFixingMenu = function(brokenObject, player, fixers, fixOption, subMenuFix)
  --print("buildFixingMenu()")
  local tooltip = UISharpenBlades.addToolTip()
  
  tooltip.description = ""
  tooltip.texture = brokenObject:getTex()
  tooltip:setName(brokenObject:getName())
  -- fetch all the fixer item to build the sub menu and tooltip
  for i, fixer in ipairs(fixers) do
    --print(fixer:getType())
    -- if you have this item in your main inventory
    --print(type(player:getInventory()))
    local fixerItem = s13utils.findFirstRepairItem(fixer, brokenObject, player)
    --if fixerItem then print("hasValidFixer: " .. fixerItem:getType()) else --print("no valid fixer in inventory") end
    -- now test the required skill if needed
    local skillDescription = " ";
    local subOption = UISharpenBlades.addFixerSubOption(brokenObject, player, fixer, subMenuFix);
    local add = "="

    if fixerItem then
        tooltip.description = tooltip.description .. " <LINE> " .. fixerItem:getName() .. add .. skillDescription
    else
        tooltip.description = tooltip.description .. " <LINE> <RGB:1,0,0> " .. fixer:getName() .. add .. skillDescription
        subOption.notAvailable = true
    end
  end
end

UISharpenBlades.addFixerSubOption = function(brokenObject, player, fixer, subMenuFix)
  local usedItem = fixer --InventoryItemFactory.CreateItem(fixer:getName());
  local fixOption = null;
  local tooltip = UISharpenBlades.addToolTip();
  local itemName
  local oilNeeded, waterNeeded = s13utils.getUsesNeeded(brokenObject)
  local totalOil, totalWater = s13utils.getWhetstoneFluidCount(player:getInventory())
  local uses
  local total
  local fixerType = fixer:getType()
  local notAvailable = false
  if fixerType:contains("_Oil_") then
    uses = oilNeeded
    total = totalOil
  elseif fixerType:contains("_Water_") then
    uses = waterNeeded
    total = totalWater
  elseif fixerType:contains("Honing_") then
    uses = 1
    total = fixer:getDrainableUsesInt()
    -- A honing steel won't fix a broken weapon
    if brokenObject:getCondition() == 0 or brokenObject:getCategories():contains("Axe") then notAvailable = true end
  end
  --print(fixer:getName() .. " uses " .. uses .. " of " .. total)
  if usedItem then
      tooltip.texture = usedItem:getTex();
      itemName = getItemNameFromFullType(usedItem:getFullType())
      fixOption = subMenuFix:addOption(itemName, brokenObject, UISharpenBlades.onSharpenBlade, player, fixer);
  else
      --print("addFixerSubOption using generated fixer")
      usedItem = s13utils.getFixerWithUses(player, uses, fixer)
      itemName = fixer:getName()
      fixOption = subMenuFix:addOption(itemName, brokenObject, UISharpenBlades.onSharpenBlade, player, fixer);
  end
  tooltip:setName(itemName);
  local condPercentRepaired = (s13utils.repairMax(player, brokenObject, fixer) / brokenObject:getConditionMax()) * 100
  local color1 = "<RED>";
  if condPercentRepaired > 15 and condPercentRepaired <= 25 then
      color1 = "<ORANGE>";
  elseif condPercentRepaired > 25 then
      color1 = "<GREEN>";
  end
  local chanceOfSucess = s13utils.calculateChance(player)
  local color2 = "<RED>";
  if chanceOfSucess > 15 and chanceOfSucess <= 40 then
      color2 = "<ORANGE>";
  elseif chanceOfSucess > 40 then
      color2 = "<GREEN>";
  end
  tooltip.description = " " .. color1 .. " " .. getText("Tooltip_potentialRepair") .. " " .. math.ceil(condPercentRepaired) .. "%";
  tooltip.description = tooltip.description .. " <LINE> " .. color2 .. " " .. getText("Tooltip_chanceSuccess") .. " " .. math.ceil(chanceOfSucess) .. "%";

	tooltip.description = tooltip.description .. " <LINE> <LINE> <RGB:1,1,1> " .. getText("Tooltip_craft_Needs") .. ": <LINE> "
  local add = "";
	if uses <= fixer:getDrainableUsesInt() and condPercentRepaired > 0 then color1 = " <RGB:1,1,1> " else color1 = " <RED> "; notAvailable = true end
	tooltip.description = tooltip.description .. color1 .. itemName .. " " .. uses .. "/" .. fixer:getDrainableUsesInt(); fixOption.notAvailable = notAvailable

  fixOption.toolTip = tooltip;
  return fixOption
end

function UISharpenBlades.onSharpenBlade(_brokenObject, _player, _fixer)
  --print("UISharpenBlades.onSharpenBlade()")
  _fixer = s13utils.findFirstRepairItem(_fixer, _brokenObject, _player)
  --print("--> fixer: " .. _fixer:getType())
  --print("----> fixer: " .. tostring(_fixer))
  --print("------> Container:")
  --local _cont = _fixer:getContainer()
  --print("------> ".. _cont:getType())
  local _time = 300
  UISharpenBlades.transferIfNeeded(_player, {_fixer, _brokenObject}, true)
  if _fixer:getType():contains("Whetstone") then _time = 660 end
  ISTimedActionQueue.add(ISSharpenBladeAction:new(_player, _brokenObject, _time, _fixer));
  --print("exit UISharpenBlades.onSharpenBlade()")
end

function UISharpenBlades.onPrepStone(items, itemTo, playerObj)
  --print("UISharpenBlades.onPrepStone()")
 
  local totalOil, totalWater = s13utils.getWhetstoneFluidCount(playerObj:getInventory())
  local uses
  local total
  local itemFrom = s13utils.getFirstWhetstoneFluid(playerObj, itemTo)

  if not itemFrom then return end
  
  -- NCrawler Melee Weapons compat
  
  if itemTo:getType():contains("_Oil_") then
    uses = oilNeeded
    total = totalOil
    --itemFrom = s13utils.getFirstWhetstoneFluid(playerObj, itemTo)
  elseif itemTo:getType():contains("_Water_") then
    uses = waterNeeded
    total = totalWater
    --itemFrom = s13utils.getFirstWhetstoneFluid(playerObj, itemTo)
  end
  
  --print("--> prep item : " .. itemFrom:getType())
  --print("--> fixer item: " .. itemTo:getType())
 
	if itemTo:getType():contains("_Empty") then
		local newItemType = itemTo:getReplaceOnUseOn();
		--newItemType = string.sub(newItemType,13);
    newItemType = luautils.split(newItemType, "-")[2]
    --print("replace "..itemTo:getType().." with "..newItemType)
		newItemType = itemTo:getModule() .. "." .. newItemType;

    local newItem = InventoryItemFactory.CreateItem(newItemType,0);
    playerObj:getInventory():AddItem(newItem);
		if playerObj:getPrimaryHandItem() == itemTo then
			playerObj:setPrimaryHandItem(newItem)
		end
		if playerObj:getSecondaryHandItem() == itemTo then
			playerObj:setSecondaryHandItem(newItem)
		end
		playerObj:getInventory():Remove(itemTo);

        itemTo = newItem;
   end

	local waterStorageAvailable = (1 - itemTo:getUsedDelta()) / itemTo:getUseDelta();
	local waterStorageNeeded = itemFrom:getUsedDelta() / itemFrom:getUseDelta();

	local itemFromEndingDelta = 0;
	local itemToEndingDelta = nil;
--
	if waterStorageAvailable >= waterStorageNeeded then
		--Transfer all water to the the second container.
		local waterInA = itemTo:getUsedDelta() / itemTo:getUseDelta();
		local waterInB = itemFrom:getUsedDelta() / itemFrom:getUseDelta();
		local totalWater = waterInA + waterInB;

		itemToEndingDelta = totalWater * itemTo:getUseDelta();
		itemFromEndingDelta = 0;
	end

	if waterStorageAvailable < waterStorageNeeded then
		--Transfer what we can. Leave the rest in the container.
		local waterInB = itemFrom:getUsedDelta() / itemFrom:getUseDelta();
		local waterRemainInB = waterInB - waterStorageAvailable;

		itemFromEndingDelta = waterRemainInB * itemFrom:getUseDelta();
		itemToEndingDelta = 1;
	end

	UISharpenBlades.transferIfNeeded(playerObj, itemFrom)

  --print("--> to: "..itemTo:getType() .. " from: "..itemFrom:getType().." fromD: "..itemFromEndingDelta.." toD: "..itemToEndingDelta)
  
--/Crowley
  ISTimedActionQueue.add(ISPrepareStoneAction:new(playerObj, itemFrom, itemTo, itemFromEndingDelta, itemToEndingDelta))
end

function UISharpenBlades.transferIfNeeded(playerObj, item, dontwalk)
  --print("UISharpenBlades.transferIfNeeded()")
  --print(">type: "..type(item))
	if instanceof(item, "InventoryItem") then
    --print("-> Transfer single item")
    local _cont = item:getContainer()
  	--if luautils.haveToBeTransfered(playerObj, item, dontwalk) then
    if _cont then 
      --print("--> container: ".. _cont:getType())
      --print("--->     type: ".. tostring(_cont))
      --print("---->    item: ".. tostring(item))
      if _cont:getType() ~= "none" and instanceof(_cont, "ItemContainer") then
        --print("------> Transferring")
        --print("--------> IsInventoryContainer " .. tostring(instanceof(_cont, "InventoryContainer")))
        ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, _cont, playerObj:getInventory()))
      end
    else
      --print("--> Not in a container")
    end
	elseif instanceof(item, "table") then
    --print("-> Transfer multiple items")
		local items = item
		for i, item in ipairs(items) do
			--local item = items:get(i-1)
      local _cont = item:getContainer()
			--if luautils.haveToBeTransfered(playerObj, item, dontwalk) then
      if _cont then 
        --print("--> container: ".. _cont:getType())
        --print("--->     type: ".. tostring(_cont))
        --print("---->    item: ".. tostring(item))
        if _cont:getType() ~= "none" and instanceof(_cont, "ItemContainer") then
          --print("------> Transferring")
          --print("--------> IsInventoryContainer " .. tostring(instanceof(_cont, "InventoryContainer")))
          ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), playerObj:getInventory()))
        end
      else
        --print("--> Not in a container")
      end
		end
	end
end

-- ------------------------------------------------
-- Game hooks
-- ------------------------------------------------
Events.OnGameBoot.Add(info);
Events.OnPreFillInventoryObjectContextMenu.Add(UISharpenBlades.createMenu);
