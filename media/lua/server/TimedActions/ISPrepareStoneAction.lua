-----------------------------------------------------------------------
-- s13SharpenBlades whetstone preparation timed action
-- by selrahc13
-----------------------------------------------------------------------

require "TimedActions/ISBaseTimedAction"
require "s13utils"


ISPrepareStoneAction = ISBaseTimedAction:derive("ISPrepareStoneAction");

function ISPrepareStoneAction:isValid()
  --print("ISPrepareStoneAction:isValid()")
  --print("exit ISPrepareStoneAction:isValid()")
  if self.character:isDriving() then return false end
	return true;
end

function ISPrepareStoneAction:update()
  --print("ISPrepareStoneAction:update()")

    if self.itemFrom ~= nil and self.itemTo ~= nil then
        self.itemFrom:setJobDelta(self:getJobDelta());
        self.itemFrom:setUsedDelta(self.itemFromBeginDelta + ((self.itemFromEndingDelta - self.itemFromBeginDelta) * self:getJobDelta()))
        
        self.itemTo:setJobDelta(self:getJobDelta());
        self.itemTo:setUsedDelta(self.itemToBeginDelta + ((self.itemToEndingDelta - self.itemToBeginDelta) * self:getJobDelta()))
    end
  --print("exit ISPrepareStoneAction:update()")
end

function ISPrepareStoneAction:start()
  --print("ISPrepareStoneAction:start()")
    if self.itemFrom ~= nil and self.itemTo ~= nil then
	    self.itemFrom:setJobType(getText("UI_JobType_PourOut"));
	    self.itemTo:setJobType(getText("UI_JobType_PrepareStone"));
	    
	    self.itemFrom:setJobDelta(0.0);
	    self.itemTo:setJobDelta(0.0);
      self:setActionAnim(CharacterActionAnims.Pour);  
    end
  --print("exit ISPrepareStoneAction:perform()")

end

function ISPrepareStoneAction:stop()
  --print("ISPrepareStoneAction:stop()")
    ISBaseTimedAction.stop(self);
    if self.itemFrom ~= nil then
        self.itemFrom:setJobDelta(0.0);
	end
	if self.itemTo ~= nil then
		self.itemTo:setJobDelta(0.0);
	end
  luautils.equipItems(self.character, self.primItem, self.scndItem)
  --print("exit ISPrepareStoneAction:stop()")
end

function ISPrepareStoneAction:perform()
  --print("ISPrepareStoneAction:perform()")
  if self.itemFrom ~= nil and self.itemTo ~= nil then
    self.itemFrom:getContainer():setDrawDirty(true);
    self.itemFrom:setJobDelta(0.0);
    self.itemTo:setJobDelta(0.0);
    if self.itemTo:getContainer() then
      self.itemTo:getContainer():setDrawDirty(true);
    end

    if self.itemFromEndingDelta == 0 then
      self.itemFrom:setUsedDelta(0);
      self.itemFrom:Use();
    else
      self.itemFrom:setUsedDelta(self.itemFromEndingDelta);
    end
    
    self.itemTo:setUsedDelta(self.itemToEndingDelta);
    self.itemTo:updateWeight();

  end
    
  luautils.equipItems(self.character, self.primItem, self.scndItem)    
    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
  --print("exit ISPrepareStoneAction:perform()")
end

function ISPrepareStoneAction:new (character, itemFrom, itemTo, itemFromEndingDelta, itemToEndingDelta)
  --print("ISPrepareStoneAction:new()")
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.itemFrom = itemFrom;
	o.itemFromBeginDelta = itemFrom:getUsedDelta();
	o.itemFromEndingDelta = itemFromEndingDelta;
	o.itemTo = itemTo;
	o.itemToBeginDelta = itemTo:getUsedDelta();
	o.itemToEndingDelta = itemToEndingDelta;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.maxTime = ((itemFrom:getUsedDelta() - itemFromEndingDelta) / itemFrom:getUseDelta()) * 50;
  if itemTo:getType():contains("_Water_") then o.maxTime = o.maxTime * 5 end
  o.primItem, o.scndItem = luautils.equipItems(character, itemFrom, itemTo)
  
  --print("--> maxTime : "..o.maxTime)
  --print("--> itemFrom: "..o.itemFrom:getType())
  --print("--> itemTo  : "..o.itemTo:getType())
  --print("exit ISPrepareStoneAction:new()")
	return o
end
