-----------------------------------------------------------------------
-- s13Compat Sharpen context menu
-- derived in part from
-- Civilian MRE Mod Context Menu
-- by NCrawler
-----------------------------------------------------------------------

UISharpenBlade = {};


-- General mod info
local MOD_ID = "s13SharpenBlades";
local MOD_NAME = "Sharpen all the blades with sharpening stones and honing steel";
local MOD_VERSION = "0.7a";
local MOD_AUTHOR = "selrahc13";
local MOD_DESCRIPTION = "Adds the ability to sharpen bladed weapons using whetstone and honing steel";

local debugItems = false;

-- ------------------------------------------------
-- Functions
-- ------------------------------------------------
---
-- Prints out the mod info on startup.
--
local function info()
	print("Mod Loaded: " .. MOD_NAME .. " by " .. MOD_AUTHOR .. " (v" .. MOD_VERSION .. ")");
end

local function isWhetstoneLube(_type, _item)
  --print("isWhetstoneLube" .. _type .. ": " .. _item:getType() .. " drainable: " .. tostring(instanceof(_item, "DrainableComboItem")) .. " watersource: " .. tostring(_item:isWaterSource()) .. " storewater: " .. tostring(_item:canStoreWater()))
  if _item:getType():contains("s13MineralOil") and instanceof(_item, "DrainableComboItem") then print("uses: " .. _item:getDrainableUsesInt() .. " usedDelta: " .. _item:getUsedDelta() .. " useDelta: " .. _item:getUseDelta()) end
  if _type == "water" then
    if _item:canStoreWater() and _item:isWaterSource() and instanceof(_item, "DrainableComboItem") then
      return true
    end
  else
    if _item:getType():contains("s13MineralOil") or _item:getType():contains("HoningOil") and instanceof(_item, "DrainableComboItem") then
      return true
    end
  end
  
  return false
end

function UISharpenBlade.createMenu(_player, _context, _items)
	local player = getSpecificPlayer(_player);
	local clickedItems = _items;
  local inventory = player:getInventory();
  local hasOilTools = false
  local hasWaterTools = false
  local hasHoningTools = false

	 -- Will store the clicked stuff.
    local item;
    local stack;

    -- stop function if player has selected multiple item stacks
    if #clickedItems > 1 then
        return;
    end

    -- Iterate through all clicked items
    for i, entry in ipairs(clickedItems) do
		-- test if we have a single item
		if instanceof(entry, "HandWeapon") then
      if entry.getCondition() < entry.getConditionMax() then
        item = entry; -- store in local variable
        --print("createMenu: isItem")
        break;
      end
      elseif type(entry) == "table" then
        --print("createMenu: isStack")
        stack = entry;
        break;
      end
    end

    if item ~= nil then print("createMenu: item: " .. item.getName()) end
    
    -- Add context option for sharpening the blade
    local hasOilstoneItem = inventory:FindAndReturn("s13Oilstone")
    local hasHoningItem = inventory:FindAndReturn("s13HoningSteel")
    local hasWaterstoneItem = inventory:FindAndReturn("s13Waterstone")
    local hasWaterItem = nil
    local hasOilItem = nil
    local totalOil = 0
    local totalWater = 0
    local totalHoning = 0

		for i = 0, inventory:getItems():size() -1 do
			local zitem = inventory:getItems():get(i);
      -- We need a water source
      if isWhetstoneLube("water", zitem) then
				totalWater = totalWater + zitem:getDrainableUsesInt()
        --print("Adding water... " .. totalWater)
      elseif isWhetstoneLube("oil", zitem) then
        totalOil = totalOil + zitem:getDrainableUsesInt()
        --print("Adding oil... " .. totalOil)
      end
		end
    
    --print("totalOil: " .. totalOil .. " totalWater: " .. totalWater)
    
    if hasOilItem and hasOilstoneItem then
      hasOilTools = true
    else
      hasOilTools = false
    end

    if totalWater >= 10 and hasWaterstoneItem then
      hasWaterTools = true
    else
      hasWaterTools = false
    end

    if hasHoningItem then
      hasHoningTools = true
    else
      hasHoningTools = false
    end
    
    --print("oil: " .. tostring(hasOilTools) .. " water: " .. tostring(hasWaterTools) .. " honing: " .. tostring(hasHoningTools))

    -- Adds context menu entry for single items.
    local neededWater = 10
    local neededOil = 8
    	-- Check if it is a bladed weapon
    if isBladed(item) then
      if item:getCategories():contains("SmallBlade") then 
        neededOil=2 
      elseif item:getCategories():contains("Axe") then
        neededOil=4
      elseif item:getCategories():contains("LongBlade") then
        neededOil=6
      end
      --print("CreateMenu: hasOilTools: " .. tostring(hasOilTools) .. " hasWaterTools: " .. tostring(hasWaterTools) .. " hasHoningTools: " .. tostring(hasHoningTools))
      --local fixOption = context:addOption("Sharpen " .. getItemNameFromFullType(item:getFullType()), items, nil);
      --local subMenuFix = ISContextMenu:getNew(_context);
      --_context:addSubMenu(fixOption, subMenuFix);
      --for i=0,fixingList:size()-1 do
          --ISInventoryPaneContextMenu.buildFixingMenu(brokenObject, player, fixingList:get(i), fixOption, subMenuFix)
      --   if item:getCondition() < item:getConditionMax() and hasOilstoneItem and totalOil >= neededOil then
      --      _context:addOption("Sharpen " .. item:getType() .. " with whetstone (oil)", clickedItems, UISharpenBlade.onSharpenBladeOil, player, item, hasOilItem, hasOilstoneItem);
      --      ISInventoryPaneContextMenu.buildFixingMenu(item, player, )
      --    end
          
      --end
      
    	if item:getCondition() < item:getConditionMax() and hasOilstoneItem and totalOil >= neededOil then
        _context:addOption("Sharpen " .. item:getType() .. " with whetstone (oil)", clickedItems, UISharpenBlade.onSharpenBladeOil, player, item, hasOilItem, hasOilstoneItem);
      end
    	if item:getCondition() < item:getConditionMax() and hasWaterstoneItem and totalWater >= neededWater then
        _context:addOption("Sharpen " .. item:getType() .. " with whetstone (water)", clickedItems, UISharpenBlade.onSharpenBladeWater, player, item, hasWaterItem, hasWaterstoneItem);
      end
      if item:getCondition() / item:getConditionMax() < 0.75 and hasHoningTools then
        _context:addOption("Hone " .. item:getType() .. " with honing steel", clickedItems, UISharpenBlade.onHoneBlade, player, item, hasHoningItem);
      end
    end

    -- Adds context menu entries for multiple bladed weapons.
    if stack then
      -- We start to iterate at the second index to jump over the dummy
      -- item that is contained in the item-table.
      for i = 2, #stack.items do
        local item = stack.items[i];
        -- Check if it is a bladed weapon
        -- Adds context menu entry for single items.
        if isBladed(item) then
          if item:getCategories():contains("SmallBlade") then 
            neededOil=2 
          elseif item:getCategories():contains("Axe") then
            neededOil=4
          elseif item:getCategories():contains("LongBlade") then
            neededOil=6
          end
            
          -- Check if it is a bladed weapon
          --print("CreateMenu: hasOilTools: " .. tostring(hasOilTools) .. " hasWaterTools: " .. tostring(hasWaterTools) .. " hasHoningTools: " .. tostring(hasHoningTools))
          if item:getCondition() < item:getConditionMax() and hasOilstoneItem and totalOil >= neededOil then
            _context:addOption("Sharpen " .. item:getType() .. " with whetstone (oil)", clickedItems, UISharpenBlade.onSharpenBladeOil, player, item, hasOilItem, hasOilstoneItem);
          end
          if item:getCondition() < item:getConditionMax() and hasWaterstoneItem and totalWater >= neededWater then
            _context:addOption("Sharpen " .. item:getType() .. " with whetstone (water)", clickedItems, UISharpenBlade.onSharpenBladeWater, player, item, hasWaterItem, hasWaterstoneItem);
          end
          if item:getCondition() / item:getConditionMax() < 0.75 and hasHoningTools then
            _context:addOption("Hone " .. item:getType() .. " with honing steel", clickedItems, UISharpenBlade.onHoneBlade, player, item, hasHoningItem);
          end
        else
          return;
        end
      end
    end
end

function isBladed(item)
  if item == nil then
    return false
  end
  if instanceof(item, "HandWeapon") then
    local weapon = item:getScriptItem()
    local weaponCategories = weapon:getCategories()
    if weaponCategories:contains("Axe") or weaponCategories:contains("SmallBlade") or weaponCategories:contains("LongBlade") then
      return true
    else
      return false
    end
  else
    return false
  end
end

function UISharpenBlade.onSharpenBladeOil(_items, _player, _item, _hasOilItem, _hasOilstoneItem)
  print("UISharpenBlade.onSharpenBladeOil()")
  ISTimedActionQueue.add(ISSharpenBladeAction:new(_player, _item, 660, _items, "oil", _hasOilItem, _hasOilstoneItem));
  print("exit UISharpenBlade.onSharpenBladeOil()")
end

function UISharpenBlade.onSharpenBladeWater(_items, _player, _item, _hasWaterItem, _hasWaterstoneItem)
  print("UISharpenBlade.onSharpenBladeWater()")
  ISTimedActionQueue.add(ISSharpenBladeAction:new(_player, _item, 660, _items, "water", _hasWaterItem, _hasWaterstoneItem));
  print("exit UISharpenBlade.onSharpenBladeWater()")
end

function UISharpenBlade.onHoneBlade(_items, _player, _item, _hasHoningItem)
  print("UISharpenBlade.onHoneBlade()")
  ISTimedActionQueue.add(ISSharpenBladeAction:new(_player, _item, 120, _items, "hone", _hasHoningItem));
  print("exit UISharpenBlade.onHoneBlade()")
end

-- ------------------------------------------------
-- Game hooks
-- ------------------------------------------------
Events.OnGameBoot.Add(info);
Events.OnPreFillInventoryObjectContextMenu.Add(UISharpenBlade.createMenu);
