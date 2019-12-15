
-- ------------------------------------------------
-- Local Functions
-- ------------------------------------------------

---
-- This function performs the actual blad repair action
-- get the blade, increase its condition according to maintenance perk level
-- adjust chance of success based on lucky/unlucky/nimble fingers
-- @param - items used by recipe
-- @param - resulting created item (we discard this)
-- @param - the player doing the repair
-- @param - selectedItem - the weapon being sharpened
--
function s13SharpenBlade_OnCreate(items, result, player, selectedItem)
    local conditionMax = 1 -- maximum durability that can be restored
    local sharpenItem = nil 

    local itemCondition = selectedItem:getCondition()
    local itemConditionMax = selectedItem:getConditionMax()
    local itemConditionPercent = (itemCondition / itemConditionMax) * 100

    local maintenance = math.floor(player:getPerkLevel(Perks.Maintenance) * 10)
    local chance = 0
    local panicMod = player:getStats():getPanic()
    local stressMod = player:getStats():getStress()
    local luckMod = 0

    -- Don't do anything if a weapon wasn't selected
    if not instanceof(selectedItem, "HandWeapon") then
      print("HandWeapon not selected for sharpening")
      return
    end

    -- calculcate conditionMax, automatically set to 1 if Honing Steel used
    -- this determines the maximum condition repair that we can do
    for i=0, items:size()-1 do
      local thisItem = items:get(i)
      if thisItem:getType() == "s13Oilstone" or thisItem:getType() == "s13Waterstone" then
        sharpenItem = thisItem
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
      elseif thisItem:getType() == "s13HoningSteel" then
        sharpenItem = thisItem
      end
    end
    
    print("cond: " .. itemCondition .. " maxcond: " .. itemConditionMax)
    -- can't improve condition beyond 75% with honing steel
    if sharpenItem:getType() == "s13HoningSteel" and itemConditionPercent > 75 then
      player:Say("I don't think a honing steel will improve the edge.")
      return
    end
    
    -- Calculate the panic and stress modifiers. Panic in PZ is stored as a float ranging
    -- from 0 to 100.

    if player:HasTrait('Lucky') then
      luckMod = ZombRand(5, 100)
    elseif player:HasTrait('Unlucky') then
      luckMod = ZombRand(-10, -100)
    end

    chance = maintenance - panicMod - stressMod
    
    -- We use luckMod as the floor for our chance of success
    print("Chance: " .. chance)
    chance = ZombRand(chance) + luckMod
    
    print("Maintenance: " .. maintenance .. " Panic: " .. panicMod .. " Stress: " .. stressMod .. " Luck: " .. luckMod .. " Chance success: " .. chance)
        
    print("Restoring " .. conditionMax .. " durability to " .. selectedItem:getName() .. " with " .. sharpenItem:getName() .. " chance of success " .. chance)
    player:Say("Restoring " .. conditionMax .. " durability to " .. selectedItem:getName() .. " with " .. sharpenItem:getName() .. " chance of success " .. chance)

    if sharpenItem:getType() == "s13HoningSteel" then
      -- honing steel
      if chance < 25 then
        player:Say("I think I made it worse.")
        selectedItem:setCondition(-1)
      elseif chance > 60 then
        player:Say("Not too shabby.")
        selectedItem:setCondition(itemCondition + 1)
      else
        player:Say("I don't think it helped.")
      end
    else
      -- sharpening stones
      if conditionMax == 0 and chance <= 0 then
        player:Say("Fuck, I broke it")
        --selectedItem:setCondition(0)
      elseif chance > 0 and chance < 20 then
        player:Say("Ugh, I think I made it worse")
        --selectedItem:setCondition(-1)
      elseif chance >= 20 and chance < 75 then
        player:Say("This seems a little sharper now")
        --selectedItem:setCondition(ZombRand(1, conditionMax))
      elseif chance >= 75 and chance < 100 then
        player:Say("Ah! Much sharper than it was before")
        --selectedItem:setCondition(conditionMax)
      else
        player:Say("As sharp as a new blade!")
        --selectedItem:setCondition(itemConditionMax)
      end
    end
end

---
-- This function determines whether the recipe can be executed
-- @param - The recipe item
-- @param - Recipe result? - not sure what this does
function s13SharpenBlade_TestIsValid(sourceItem, result)
    --print(sourceItem)
    if instanceof(sourceItem, "HandWeapon") then
        return sourceItem:getCondition() < sourceItem:getConditionMax() and not sourceItem:isBroken()
    else
        return true;
    end
end