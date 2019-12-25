-----------------------------------------------------------------------
-- s13SharpenBlades blade maintenance timed action
-- by selrahc13
-----------------------------------------------------------------------

require "TimedActions/ISBaseTimedAction"
require "luautils"
require "s13utils"

ISSharpenBladeAction = ISBaseTimedAction:derive("ISSharpenBladeAction");

function ISSharpenBladeAction:isValid()
  --print("ISSharpenBladeAction:isValid()")
  if self.character:isDriving() then return false end
  self.totalOil, self.totalWater = s13utils.getWhetstoneFluidCount(self.character:getInventory())  
  
  --print("totalOil: " .. self.totalOil .. " totalWater: " .. self.totalWater)
  
  local fixerType = self.fixer:getType()
  if fixerType:contains("Whetstone_") then
    if fixerType:contains("_Oil_") then 
      self.usesNeeded = self.oilNeeded
    elseif fixerType:contains("_Water_") then
      self.usesNeeded = self.waterNeeded
    end
  elseif fixerType:contains("Honing_") then
    return true
  end

  if self.usesNeeded <= self.fixer:getDrainableUsesInt() then
    return true
  end
  
  return false
end

function ISSharpenBladeAction:update()
  --print("ISSharpenBladeAction:update()")

	self.brokenObject:setJobDelta(self:getJobDelta());
	self.fixer:setJobDelta(self:getJobDelta());

  self.character:setMetabolicTarget(Metabolics.UsingTools);
end

function ISSharpenBladeAction:start()
  --print("ISSharpenBladeAction:start()")
  self.brokenObject:setJobDelta(0.0);
  self.fixer:setJobDelta(0.0)
  if self.sound then self.sound:stop() end
  -- need to localize this
	--self.brokenObject:setJobType(getText("IGUI_JobType_Repair"));
  self.brokenObject:setJobType(getText(self.jobType))
  self:setActionAnim(CharacterActionAnims.Craft);  
  self.character:getEmitter():playSound(self.soundName);
end

function ISSharpenBladeAction:stop()
  --print("ISSharpenBladeAction:stop()")
  self.brokenObject:setJobDelta(0.0);

  -- Re-equip the previous items
  luautils.equipItems(self.character, self.primItem, self.scndItem)
  ISBaseTimedAction.stop(self);
end

function ISSharpenBladeAction:perform()
  --print("ISSharpenBladeAction:perform()")
  local character = self.character;
  local itemCondition = self.brokenObject:getCondition()
  local itemConditionMax = self.brokenObject:getConditionMax()
  local itemConditionPercent = (itemCondition / itemConditionMax) * 100
  local conditionMax = 0 -- maximum durability that can be restored
  
  -- calculate chance of success
  local success = s13utils.calculateChance(character);
  local rolled = ZombRand(50) + character:getPerkLevel(Perks.Maintenance) * 5
  --print("--> Success chance: " .. success .. "%")
  --print("--> rolledChance  : " .. rolled)
  
	if self.brokenObject:getContainer() then
    self.brokenObject:getContainer():setDrawDirty(true);
	end    

  if self.craftSound and self.craftSound:isPlaying() then
      self.craftSound:stop();
  end
  
  --print("--> Fixer: " .. self.fixer:getName())
  conditionMax = s13utils.repairMax(self.character, self.brokenObject, self.fixer)
  --print("--> max condition restored: "..conditionMax)

  -- enable for testing --
  --if true then return end
  
  local fixerUseDelta = self.fixer:getUseDelta()
  self.fixer:setUseDelta(self.usesNeeded * fixerUseDelta)
  self.fixer:Use()
  self.fixer:setUseDelta(fixerUseDelta)
      
  if not s13utils.isWhetstone(self.fixer) and itemCondition == 1 then
    -- honing steel
    -- botching it carries a chance of self-inflicted injury
    if rolled < success then
      player:Say("This ".. self.brokenObject:getName() .." should hold for a while longer.")
      self.brokenObject:setCondition(itemCondition + 1)
      character:getStats():setStress(character:getStats():getStress() - 2)
      self.addXP = self.addXP + 3
    elseif rolled <= success + 35 then
      player:Say("This ".. self.brokenObject:getName() .." isn't better but at least it's not worse...")
      self.addXP = self.addXP + 1
    else
      player:Say("*sigh* I totally botched the ".. self.brokenObject:getName() ..".")
      self.brokenObject:setCondition(itemCondition-1)
      character:getStats():setStress(character:getStats():getStress() + 10)
      s13utils.injurePlayer(self.character, self.injuryChance)
    end
  else
    -- sharpening stones
    if rolled == 0 then 
      -- nat20, weapon gets a max condition increase in addition to full condition restoration
      player:Say("Amazing! I could shave with this ".. self.brokenObject:getName() .."!")
      character:getStats():setStress(character:getStats():getStress() - 50)
      self.brokenObject:setConditionMax(itemConditionMax + 1)
      self.brokenObject:setCondition(itemConditionMax + 1)
      self.addXP = self.addXP + 7
    elseif rolled == 99 then
      -- Break the weapon, high probability of self-inflicted injury, makes player stressed
      player:Say("Fuck, I broke the ".. self.brokenObject:getName() .."!")
      self.brokenObject:setCondition(0)
      s13utils.injurePlayer(self.character, self.injuryChance / 2)
      character:getStats():setStress(character:getStats():getStress() + 50)
    elseif rolled <= success + 15 then
      -- Restore 2 condition at minimum
      player:Say("This ".. self.brokenObject:getName() .. " is definitely sharper!")
      local toRestore = ZombRand(2, conditionMax) + 1
      if toRestore > itemConditionMax then toRestore = conditionMax end
      character:getStats():setStress(character:getStats():getStress() - 15)
      self.brokenObject:setCondition(toRestore)
      self.addXP = self.addXP + 5
    elseif rolled <= success + 40 then
      -- Restore 1 condition at minimum
      player:Say("This ".. self.brokenObject:getName() .." seems a little sharper now.")
      local toRestore = ZombRand(1, conditionMax - 2) + 1
      if toRestore > itemConditionMax then toRestore = conditionMax end
      if toRestore < 1 then toRestore = 1 end
      character:getStats():setStress(character:getStats():getStress() - 5)
      self.brokenObject:setCondition(toRestore)
      self.addXP = self.addXP + 3
    elseif rolled <= success + 60 then 
      -- Damage the weapon, chance of self-inflicted injury
      player:Say("Damn it, I dulled the ".. self.brokenObject:getName())
      self.brokenObject:setCondition(itemCondition-1)
      self.addXP = self.addXP + 1
      s13utils.injurePlayer(self.character, self.injuryChance)
      character:getStats():setStress(character:getStats():getStress() + 10)
    end
  end

  -- give earned XP
  self.character:getXp():AddXP(Perks.Maintenance, self.addXP)

  -- remove Timed Action from stack
  -- needed to remove from queue / start next.
  self.brokenObject:setJobDelta(0.0);

  -- Re-equip the previous items
  luautils.equipItems(self.character, self.primItem, self.scndItem)
  
	ISBaseTimedAction.perform(self);
  --print("exit ISSharpenBladeAction:perform()") 
end

function ISSharpenBladeAction:new(_character, _brokenObject, _time, _fixer)
  --print("enter ISSharpenBladeAction:new()")

	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = _character
  o.brokenObject = _brokenObject
	o.stopOnWalk = true
	o.stopOnRun = true
	o.maxTime = _time
  o.caloriesModifier = 4
  --o.fixer = s13utils.findFirstRepairItem(_fixer, _brokenObject, _character);
  o.fixer = _fixer
  o.totalOil, o.totalWater = s13utils.getWhetstoneFluidCount(_character:getInventory())
  o.oilNeeded, o.waterNeeded = s13utils.getUsesNeeded(_brokenObject)
  o.usesNeeded = 1
  o.jobType = "UI_JobType_Sharpen"
  o.addXP = 0
  if _fixer:getType():contains("_Oil_") then
    o.usesNeeded = o.oilNeeded
  elseif _fixer:getType():contains("_Water_") then
    o.usesNeeded = o.waterNeeded
  end
  if _fixer:getType():contains("Whetstone_") then 
    o.soundName = "Sharpening"
    o.jobType = "UI_JobType_Sharpen"
  else 
    o.soundName = "Honing_" 
    o.jobType = "UI_JobType_Hone"
  end
  if _character:isTimedActionInstant() then
      o.maxTime = 1
  end
  o.primItem, o.scndItem = luautils.equipItems(_character, _brokenObject, o.fixer)
  o.injuryChance = ZombRand(_character:getPerkLevel(Perks.Maintenance) + 1)
  --print("--> Fixing ".. _brokenObject:getType() .. " with: ".. _fixer:getType())
  
  --print("exit ISSharpenBladeAction:new()")
	return o;
end
