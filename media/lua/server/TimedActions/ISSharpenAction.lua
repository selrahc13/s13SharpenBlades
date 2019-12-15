require "TimedActions/ISBaseTimedAction"
require "luautils"

ISSharpenBladeAction = ISBaseTimedAction:derive("ISSharpenBladeAction");

local function isWhetstoneLube(_type, _item)
  --print("isWhetstoneLube" .. _type .. ": " .. _item:getType() .. " drainable: " .. tostring(instanceof(_item, "DrainableComboItem")) .. " watersource: " .. tostring(_item:isWaterSource()) .. " storewater: " .. tostring(_item:canStoreWater()))
  --if _item:getType():contains("s13MineralOil") and instanceof(_item, "DrainableComboItem") then print("uses: " .. _item:getDrainableUsesInt() .. " usedDelta: " .. _item:getUsedDelta() .. " useDelta: " .. _item:getUseDelta()) end
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

local function getConsumables(_inventory, _self)
  local _item = nil
  _self.totalOil = 0
  _self.totalWater = 0
  _self.consumablesOil = {}
  _self.consumablesWater = {}
  
  for i = 0, _inventory:getItems():size() -1 do
    local _item = _inventory:getItems():get(i);
    if isWhetstoneLube("water", _item) then
      table.insert(_self.consumablesWater, _item)
      _self.totalWater = _self.totalWater + _item:getDrainableUsesInt()
    elseif isWhetstoneLube("oil", _item) then
      table.insert(_self.consumablesOil, _item)
      _self.totalOil = _self.totalOil + _item:getDrainableUsesInt()
    end
  end
end

local function findFirstRepairItem(_tool, _inventory)
  print("findFirstRepairItem")
  local repairItem
  
  if _tool == "water" then
    repairItem = _inventory:FindAndReturn("s13Waterstone")
  elseif _tool == "oil" then
    repairItem = _inventory:FindAndReturn("s13Oilstone")
    if not repairItem then
      repairItem = _inventory:FindAndReturn("Whetstone")
    end
  elseif _tool == "honing" then
    repairItem = _inventory:FindAndReturn("HoningSteel")
  end
  return repairItem
end

local function getFluidNeeded(_tool, _item)
  if _tool == "oil" then
    if _item:getCategories():contains("SmallBlade") then 
      return 2 
    elseif _item:getCategories():contains("Axe") then
      return 4
    elseif _item:getCategories():contains("LongBlade") then
      return 6
    else
      return 8
    end
  end
  -- waterstone needs to be soaked in 10 units of water
  return 10
end

---
-- This function modifies the chance of sharpening the blade successfully.
-- The higher the chance value, the higher is the chance of success.
-- @param - The character trying to sharpen the blade.
--
local function calculateChance(character)
    local chance = 0
    local maintenance = math.floor(character:getPerkLevel(Perks.Maintenance) * 10)
    local panicMod = character:getStats():getPanic()
    local stressMod = character:getStats():getStress()
    local luckMod = 0
    -- Calculate the panic and stress modifiers. Panic in PZ is stored as a float ranging
    -- from 0 to 100.

    if character:HasTrait('Lucky') then
      luckMod = math.ceil(ZombRand(5, 25) / 2)
    elseif character:HasTrait('Unlucky') then
      luckMod = math.ceil(ZombRand(-10, -50) / 2)
    end

    chance = maintenance - panicMod - stressMod
    
    -- We use luckMod as the floor for our chance of success
    --print("Chance: " .. chance)
    if chance + luckMod >= 100 then 
      chance = 100
    elseif chance + luckMod <= 0 then
      chance = 0
    else
      chance = chance + luckMod
    end
    
    --print("Maintenance: " .. maintenance .. " Panic: " .. panicMod .. " Stress: " .. stressMod .. " Luck: " .. luckMod .. " Chance success: " .. chance)
    return chance

end


function ISSharpenBladeAction:isValid()
  print("ISSharpenBladeAction:isValid()")
  if self.character:isDriving() then return false end
  local inventory = self.character:getInventory()
  local hasOilstoneItem = inventory:FindAndReturn("s13Oilstone")
  local hasHoningItem = inventory:FindAndReturn("s13HoningSteel")
  local hasWaterstoneItem = inventory:FindAndReturn("s13Waterstone")
  local check = false
  getConsumables(inventory, self)  
  
--  for i = 0, inventory:getItems():size() -1 do
--    local zitem = inventory:getItems():get(i);
    -- We need a water source
--    if isWhetstoneLube("water", zitem) then
--      totalWater = totalWater + zitem:getDrainableUsesInt()
--      print("Adding water... " .. totalWater)
--    elseif isWhetstoneLube("oil", zitem) then
--      totalOil = totalOil + zitem:getDrainableUsesInt()
--      print("Adding oil... " .. totalOil)
--    end
--  end
    
  print("totalOil: " .. self.totalOil .. " totalWater: " .. self.totalWater)

  --if self.toolitem1 then print(self.toolitem1:getType()) end
  --if self.toolitem2 then print(self.toolitem2:getType()) end
  
  if self.tool == "oil" then
    print("check for oil tools")
    check = hasOilstoneItem and self.totalOil >= getFluidNeeded(self.tool, self.item)
    print(tostring(check))
  elseif self.tool == "water" then
    print("check for water tools")
    check = hasWaterstoneItem and self.totalWater >= getFluidNeeded(self.tool, self.item)
    print(tostring(check))
  else
    print("check for honing tools")
    check = hasHoningItem
    print(tostring(check))
  end
  return check
end

function ISSharpenBladeAction:update()
  print("ISSharpenBladeAction:update()")

	self.item:setJobDelta(self:getJobDelta());

  self.character:setMetabolicTarget(Metabolics.UsingTools);
end

function ISSharpenBladeAction:start()
  print("ISSharpenBladeAction:start()")
  self.item:setJobDelta(0.0);  
  if self.sound then self.sound:stop() end
  -- need to localize this
	--self.item:setJobType(getText("IGUI_JobType_Repair"));
  self.item:setJobType(self.soundName)
  self:setActionAnim(CharacterActionAnims.Craft);  
  self.character:getEmitter():playSound(self.soundName);
end

function ISSharpenBladeAction:stop()
  print("ISSharpenBladeAction:stop()")
  self.item:setJobDelta(0.0);

  -- Re-equip the previous items
  luautils.equipItems(self.character, self.primItem, self.scndItem)
  ISBaseTimedAction.stop(self);
end

function ISSharpenBladeAction:perform()
  print("ISSharpenBladeAction:perform()")
	local perklvl = self.character:getPerkLevel(Perks.Maintenance);
  local character = self.character;
  local item = self.item;
  local itemCondition = item:getCondition()
  local itemConditionMax = item:getConditionMax()
  local itemConditionPercent = (itemCondition / itemConditionMax) * 100
  local conditionMax = 1 -- maximum durability that can be restored
  local sharpenItem = nil 
  
  --local useLeft = waterContainer:getUsedDelta() / waterContainer:getUseDelta();  --local prim = character:getPrimaryHandItem();
  --local scnd = character:getSecondaryHandItem();
  local chance = calculateChance(character);
  print("Success chance: " .. chance .. "%")
  
	if self.item:getContainer() then
    self.item:getContainer():setDrawDirty(true);
	end    

  if self.craftSound and self.craftSound:isPlaying() then
      self.craftSound:stop();
  end
  --print("s13SharpenBlades chance " .. chance)

  sharpenItem = findFirstRepairItem(self.tool, character:getInventory())
  if sharpenItem then print(sharpenItem:getName()) end
  if self.tool == "oil" or self.tool == "water" then
    conditionMax = 2 + player:getPerkLevel(Perks.Maintenance)
    conditionMax = ZombRand(2, conditionMax + 2)
    -- cannot restore less than 2 durability with sharpening stones
    if conditionMax > 0 and conditionMax < 2 then
      conditionMax = 2;
    end      
    -- with luck and skill, can restore up to full durability
    if conditionMax > itemConditionMax then
      conditionMax = itemConditionMax
    end
  end
  
  -- Calculate the chance for successfully sharpening the blade
--  if ZombRand(chance) == 0 then
    -- Break the blade
--    item:setCondition(tool:getCondition() - 1);
    -- TODO choose appropriate sound for blunting the blade
    --getSoundManager():PlayWorldSound("doorlocked", door:getSquare(), 0, 12, 1, true);
--  else
    -- 
    --getSoundManager():PlayWorldSound("unlockDoor", door:getSquare(), 0, 6, 1, true);
--  end

--  if ZombRand(chance) == 0 then
--    character:Say(getText("UI_Text_BladeBroken"));
    --character:setSecondaryHandItem(nil); -- Remove Item from hand.
    --scnd:getContainer():Remove(scnd); -- Remove Item from inventory.
--    getSoundManager():PlayWorldSound("PZ_MetalSnap", character:getSquare(), 0, 10, 1, true);
--    item:setCondition(0)
--  elseif ZombRand(100) <= 30 - (perklvl * 2) then
--    character:Say(getText("UI_Text_BladeBlunted"));
--    item:setCondition(-1)
    --character:setSecondaryHandItem(nil);
    --scnd:getContainer():Remove(scnd);
--  elseif (ZombRand(100) <= chance) then
    -- Total success
--    character:getXp():AddXP(Perks.Maintenance, 2)
--  end

  -- remove Timed Action from stack
  -- needed to remove from queue / start next.
  self.item:setJobDelta(0.0);

  -- Re-equip the previous items
  luautils.equipItems(self.character, self.primItem, self.scndItem)
  
	ISBaseTimedAction.perform(self);
  print("exit ISSharpenBladeAction:perform()") 
end

function ISSharpenBladeAction:new(_character, _item, _time, _items, _tool, _toolitem1, _toolitem2)
  print("enter ISSharpenBladeAction:new()")

	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = _character;
  o.item = _item;
  o.items = _items;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.maxTime = _time;
  o.caloriesModifier = 4;
  o.tool = _tool;
  o.toolitem1 = _toolitem1;
  o.toolitem2 = _toolitem2;
  o.consumablesOil = {}
  o.consumablesWater = {}
  o.totalOil = 0
  o.totalWater = 0
  o.primItem = nil
  o.scndItem = nil
  if _tool == "oil" or _tool == "water" then o.soundName = "Sharpening" else o.soundName = "Honing" end
  if _character:isTimedActionInstant() then
      o.maxTime = 1;
  end
  o.primItem, o.scndItem = luautils.equipItems(o.character, o.item, findFirstRepairItem(o.tool, o.character:getInventory()))
  
  print("exit ISSharpenBladeAction:new()")
	return o;
end
