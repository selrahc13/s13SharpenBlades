-----------------------------------------------------------------------
-- s13SharpenBlades helper functions
-- by selrahc13
-----------------------------------------------------------------------

s13utils = {};

--------------------------------------
-- Constants
--------------------------------------
local s13utils_oils = {"s13Mineral_Oil_Full", "HoningOil"}
local s13utils_smallBlades = {"KitchenKnife", "HuntingKnife", "CombatKnife"}

--------------------------------------
-- Predicate functions
--------------------------------------

-- returns item if it is a usable water source
local function predicateWaterSourceItem(item)
  if item ~= nil then 
   if instanceof(item, "DrainableComboItem") and item:isWaterSource() and item:getDrainableUsesInt() > 0 then
    return true
   end
  end
  
  return false
end

-- returns item if it is a usable honing oil source
local function predicateWhetstoneOilItem(item)
  if item == nil then return nil end
  --print("predicateWhetstoneOilItem("..item:getType()..")")
  for i, _v in ipairs(s13utils_oils) do
    --print("--> ".. _v)
    if tostring(item:getType()) == _v and item:getDrainableUsesInt() > 0 then 
      --print("---> Found: "..item:getType())
      return true 
    end
  end
  
  return false
end

local function predicateDrainableUsesInt(item, count)
	return item:getDrainableUsesInt() >= count
end

--------------------------------------
-- Functions
--------------------------------------

---
-- function injurePlayer
-- randomly determines if a player should receive a hand injury while
-- attempting to use sharpening tools
-- @param Character to possibly injure
-- @param chance of being injured
s13utils.injurePlayer = function(character, injuryChance)
  local lHand = character:getBodyDamage():getBodyPart(BodyPartType.Hand_L) 
  local rHand = character:getBodyDamage():getBodyPart(BodyPartType.Hand_R)
  local panic = character:getStats():getPanic()
  if ZombRand(injuryChance) == 0 then -- chance of getting hurt
    -- 'Tis but a scratch
    local chance = ZombRand(4)
    local isCut = false
    if chance == 0 then
        lHand:SetScratchedWeapon(true);
        character:getStats():setPanic(panic + 5)
        isCut = true
    elseif chance == 1 then
        rHand:SetScratchedWeapon(true);
        character:getStats():setPanic(panic + 5)
        isCut = true
    -- It's just a flesh wound
    elseif chance == 2 then
        lHand:SetCut(true);
        character:getStats():setPanic(panic + 10)
        isCut = true
    elseif chance == 3 then
        rHand:SetCut(true);
        character:getStats():setPanic(panic + 10)
        isCut = true
    end
    if isCut then character:say("Shit! I cut myself!") end
  end
end

---
-- s13utils.repairMax
-- Determines maximum condition that can be repaired to a weapon
-- @param the player object
-- @param the item we want to repair
-- @param the item we are performing the repair with
s13utils.repairMax = function(player, brokenObject, repairItem)
  local conditionMax = 1
  local itemConditionMax = brokenObject:getConditionMax()
  
  if brokenObject then print(brokenObject:getName()) end
  -- We can't use whetstones or honing steels to restore a broken weapon
  if brokenObject:getCondition() == 0 then return 0 end
  
  if repairItem:getType():contains("Whetstone") then
    conditionMax = player:getPerkLevel(Perks.Maintenance)
    -- can't repair an item to be better than full durability
    if conditionMax > itemConditionMax then
      conditionMax = itemConditionMax
    end
  elseif repairItem:getType():contains("Honing") then
    -- a honing steel won't take condition above 2
    if (brokenObject:getCondition() > 1) then
      conditionMax = 0
    else 
      conditionMax = 1
    end
  end
  
  return conditionMax
end

---
-- Determine the chance of repair succeeding
-- @param - The character trying to sharpen the blade.
--
s13utils.calculateChance = function(character)
  local success = 15
  local maintenance = character:getPerkLevel(Perks.Maintenance) * 5
  local panicMod = character:getStats():getPanic()
  local stressMod = character:getStats():getStress()
  local luckMod = 0
  -- Calculate the panic and stress modifiers. Panic in PZ is stored as a float ranging
  -- from 0 to 100.

  if character:HasTrait('Lucky') then
    luckMod = 5
  elseif character:HasTrait('Unlucky') then
    luckMod = -5
  end

  success = success + maintenance - panicMod - stressMod
  
  -- We use luckMod as the floor for our chance of success
  --print("Chance: " .. success)
  success = success + luckMod
  if success > 100 then success = 100 end
  if success < 0 then success = 0 end
  --print("s13utils.calculateChance()")
  --print("--> Maintenance: " .. maintenance .. " Panic: " .. panicMod .. " Stress: " .. stressMod .. " Luck: " .. luckMod .. " Chance success: " .. chance)
  return success
end

---
-- Called to determine if a given fluid can be used to lubricate a whetstone
-- @param the type of whetstone we are using (water or oil)
-- @param the fluid we are checking
s13utils.isWhetstoneFluid = function(_type, _item)
  --print("isWhetstoneFluid" .. _type .. ": " .. _item:getType() .. " drainable: " .. tostring(instanceof(_item, "DrainableComboItem")) .. " watersource: " .. tostring(_item:isWaterSource()) .. " storewater: " .. tostring(_item:canStoreWater()))
  --if _item:getType():contains("s13Mineral_Oil") and instanceof(_item, "DrainableComboItem") then print("uses: " .. _item:getDrainableUsesInt() .. " usedDelta: " .. _item:getUsedDelta() .. " useDelta: " .. _item:getUseDelta()) end
  if _type == "water" then
    return predicateWaterSourceItem(_item)
  elseif _type == "oil"
    return predicateWhetstoneOilItem(_item)
  end
  
  return false
end

---
-- Return the total number of oil and water fluids available in the player inventory
-- @param Player object
s13utils.getWhetstoneFluidCount = function(_inventory)
  local _item = nil
  local totalOil = 0
  local totalWater = 0
  
  for i = 0, _inventory:getItems():size() -1 do
    local _item = _inventory:getItems():get(i);
--    print(_item:getType())
    if predicateWaterSourceItem(_item) then
      totalWater = totalWater + _item:getDrainableUsesInt()
    elseif predicateWhetstoneOilItem(_item) then
      totalOil = totalOil + _item:getDrainableUsesInt()
    end
  end
  return totalOil, totalWater
end

---
-- Find the first valid item that can repair our broken object
-- @param The repair object
-- @param The object to repair
-- @param The player object
s13utils.findFirstRepairItem = function(_tool, _brokenObject, _player)
  --print("s13utils.findFirstRepairItem()")
  local toRepair
  local _inventory = _player:getInventory()
  local _oil, _water = s13utils.getUsesNeeded(_brokenObject)
  if _tool:getType():contains("_Oil_") then 
    toRepair = _oil
  elseif _tool:getType():contains("_Water_") then
    toRepair = _water
  else
    toRepair = 1
  end
  return s13utils.getFixerWithUses(_player, toRepair, _tool)
end

---
-- Find the first repair object that has at least the specified number of uses remaining
-- @param player object
-- @param number of required uses
-- @param the repair object we are looking for
s13utils.getFixerWithUses = function(_player, uses, fixer)
  local _inventory = _player:getInventory()
  print("s13utils.getFixerWithUses()")
  --print(_inventory:getType() .. ", ")
  --print(uses ..", ")
  --print(fixer:getFullType()..")")
  local _temp = _inventory:getAllTypeRecurse(fixer:getFullType())
  if _temp then
    for i = 1, _temp:size() do
      local _item = _temp:get(i-1)
      --print("--> item: ".._item:getType())
      if _item:getDrainableUsesInt() >= uses then 
        --print("----> isValidFixer")
        --print("----> item: " .. tostring(_item))
        --print("------> Container:")
        local _cont = _item:getContainer()
        --print("--------> ".. _cont:getType())
        return _item 
      end
    end
  end
  return nil
  --return _inventory:getFirstTypeEvalArgRecurse(tostring(fixer:getFullType()), predicateDrainableUsesInt, uses)
end

---
-- Return first valid fluid container that can lubricate the whetstone
-- @param The player object
-- @param The whetstone we want to hydrate
s13utils.getFirstWhetstoneFluid = function(_player, whetstone)
  local _inventory = _player:getInventory()
  --print("s13utils.getFirstWhetstoneFluid()")
  --print(_inventory:getType() .. ", ")
  --print(uses ..", ")
  --print(fixer:getFullType()..")")
  if whetstone:getType():contains("_Water_") then 
    local _item = _inventory:getFirstEvalRecurse(predicateWaterSourceItem)
    --print("---> got item: "..tostring(_item))
    return _item
  elseif whetstone:getType():contains("_Oil_") then 
    local _item = _inventory:getFirstEvalRecurse(predicateWhetstoneOilItem)
    --print("---> got item: "..tostring(_item))
    return _item
  end
  
  return nil
end

---
-- Check if item is a valid whetstone
-- @param The item to check
s13utils.isWhetstone = function(_item)
  local _result = s13utils.isOilstone(_item) or s13utils.isWaterstone(_item)
  --print("isWhetstone(): " .. _item:getType() .. " " .. tostring(_result))
  if _result then 
    return true 
  end
  return false
end

s13utils.isOilstone = function(_item)
  return _item ~= nil and _item:getType():contains("Whetstone") --and _item:getType():contains("_Oil_")
end

s13utils.isWaterstone = function(_item)
  return _item ~= nil and _item:getType():contains("Whetstone_") and _item:getType():contains("_Water_")
end

---
-- Determine how many oil or water uses are needed for repair
-- depending on item to be repaired
-- @param The item we want to repair
s13utils.getUsesNeeded = function(_item)
  --Returns oil needed, water needed in whetstone for repair
  if _item:getCategories():contains("SmallBlade") then 
    return 2, 10
  elseif _item:getCategories():contains("Axe") then
    return 4, 10
  elseif _item:getCategories():contains("LongBlade") then
    return 6, 10
  else
    return 8, 10
  end
end

---
-- Is the item a bladed weapon that we can sharpen with these tools?
-- @param item
s13utils.isBladed = function(item)
  --print("isBladed()")
  if item == nil then
    return false
  end
  if instanceof(item, "HandWeapon") then
    local weapon = item:getScriptItem()
    local weaponCategories = weapon:getCategories()
    --print(weapon:getCategories())
    if weaponCategories:contains("Axe") or weaponCategories:contains("LongBlade") then
      return true
    elseif weaponCategories:contains("SmallBlade") then
      for i, _v in ipairs(s13utils_smallBlades) do
        if weapon:getName():contains(_v) then return true end
      end
      return false
    end
  else
    return false
  end
end
