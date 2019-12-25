-----------------------------------------------------------------------
-- Melee Weapons Distribution System
-- by NCrawler
-- Patched by selrahc13 to replace HoningOil and Whetstone items with
-- s13 versions
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- Location Table
-----------------------------------------------------------------------
local weaponspawnlocs = {
	garagestorage = {metal_shelves=.3,crate=.3},
	sportstore = {shelves=1,counter=1},
	sportstorage = {metal_shelves=1,shelves=1,crate=1,counter=1},
	shed = {counter=.4,other=.4},
	hunting = {locker=.6,metal_shelves=.6,other=.6},
	gunstore = {counter=2,displaycase=2,locker=2,metal_shelves=2},
	gunstorestorage = {all=2},
	policestorage = {locker=1,metal_shelves=1},
	bedroom = {wardrobe=.3,sidetable=.3},
	storageunit = {all=.5},
	zippeestore = {counter=.1,crate=.1},
	grocery = {counter=.1},
	fossoil = {counter=.1,crate=.1},
	motelroom = {other=.3},
	motelroomoccupied = {other=.3},	
	all = {inventorymale=.3,inventoryfemale=.3},
	bar = {counter=.5},
}

local miscspawnlocs = {
	kitchen = {counter=5},
	garagestorage = {metal_shelves=1,crate=1},
	sportstore = {shelves=10,counter=10},
	sportstorage = {metal_shelves=3,shelves=3,crate=3,counter=3},
	shed = {counter=5,other=5},
	hunting = {locker=10,metal_shelves=10,other=10},
	gunstore = {counter=15,displaycase=15,locker=15,metal_shelves=15},
	gunstorestorage = {all=15},
	policestorage = {locker=10,metal_shelves=10},
	bedroom = {wardrobe=.5,sidetable=.5},
	storageunit = {all=.5},
	all = {inventorymale=1,inventoryfemale=1},
}

-----------------------------------------------------------------------
-- Main Function
-----------------------------------------------------------------------
local function spawnNCStuff(_roomName, _containerType, _containerFilled)	
	if (weaponspawnlocs[_roomName] == nil) and (miscspawnlocs[_roomName] == nil) then
		return;
	end
	
	if (weaponspawnlocs[_roomName] ~= nil) and (weaponspawnlocs[_roomName][_containerType] ~= nil) then
		if RollPercent(weaponspawnlocs[_roomName][_containerType]) then
			_containerFilled:AddItem(weaponTable[FillContainer(#weaponTable)]);
		end
	end
	
	if (miscspawnlocs[_roomName] ~= nil) and (miscspawnlocs[_roomName][_containerType] ~= nil) then
		if RollPercent(miscspawnlocs[_roomName][_containerType]) then
			_containerFilled:AddItem(maintenanceTable[FillContainer(#maintenanceTable)]);
		end
	end
end

-----------------------------------------------------------------------
-- Tables
-----------------------------------------------------------------------
weaponTable = {
	"NCMeleeWeapons.MetalBaseballBat",
	"NCMeleeWeapons.TacticalAxe",
	"NCMeleeWeapons.TacticalMachete",
	"NCMeleeWeapons.CombatKnife"	
};

maintenanceTable = {
	"s13SharpenBlades.s13Whetstone_Oil_Empty",
	"s13SharpenBlades.s13Mineral_Oil_Full",
  "s13SharpenBlades.s13Whetstone_Oil_Empty",
  "s13SharpenBlades.s13Whetstone_Water_Empty",
};

-----------------------------------------------------------------------
-- Random Gen functions
-----------------------------------------------------------------------
function RollPercent(_percentage)
	if ZombRand(1000)+1 >= (1000 - ((1000 * _percentage) / 100)) then
		return true;
	else
		return false;
	end
end

function FillContainer(_index)
	return ZombRand(_index)+1
end

Events.OnFillContainer.Add(spawnNCStuff)