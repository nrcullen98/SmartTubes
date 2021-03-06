CableCore = {};

local CableCore = CableCore;
CableCore.Initalized = false;
local Animated = true;

CableCore.Smashing = false;

function GetConduits()
	return CableCore.CableTypes["Conduits"];
end

local CableConnections;
local Conditions = {};
local CableAmount = 0;
local SourceObject = {};
local DefaultConnections = {{0,1},{0,-1},{-1,0},{1,0}};

Test = {};

--[[function Test.testingfunction()
	return "This is a test!";
end--]]

function IsConnectedTo(ID)
	for i=1,CableAmount do
		if CableCore.CablesFound[i] == ID then
			return true;
		end
	end
	return false;
end

local function vecAdd(a,b)
	return {a[1] + b[1],a[2] + b[2]};
end

local function vecEq(a,b)
	return a[1] == b[1] and a[2] == b[2];
end

local function vecSub(a,b)
	return {a[1] - b[1],a[2] - b[2]};
end

local function tblEq(a,b,count)
	for i=1,count do
		if a[i] ~= b[i] then
			return false;
		end
	end
	return true;
end

local function GetParameterOf(ID,value,defaultValue)
	if SourceObject.Config ~= nil and SourceObject.ID == ID then
		if SourceObject.Config[value] == nil then
			SourceObject.Config[value] = defaultValue;
		end
		return SourceObject.Config[value];
	else
		return world.getObjectParameter(ID,value,defaultValue);
	end
end

function GetCableConnections()
	--sb.logInfo("RETURNING CABLE CONNECTIONS OF " .. sb.print(CableConnections));
	--sb.logInfo("Cable Connection REturning");
	return CableConnections;
end

local function GetCableConnectionsOf(ID)
	if SourceObject.Config ~= nil and SourceObject.ID == ID then
		--sb.logInfo("Returning CONFIG");
		return SourceObject.Config["CableConnections"];
	end

	if world.entityExists(ID) == true then
		--sb.logInfo("Requesting Cable Connections From Entity of " .. sb.print(entity.id()));
		return world.callScriptedEntity(ID,"GetCableConnections");
	end

	--sb.logInfo("Returning VIA WORLD");
	return world.getObjectParameter(ID,"CableConnections",DefaultConnections);
end

local function GetPositionOf(ID)
	if SourceObject.Position ~= nil and SourceObject.ID == ID then
		return SourceObject.Position;
	else
		return world.entityPosition(ID);
	end
end

local function ContainedInSpaces(TestingPos,DestPos,Spaces)
	for i=1,#Spaces do
		if vecEq(TestingPos,vecAdd(DestPos,Spaces[i])) == true then
			return true;
		end	
	end
end

local function GetSpacesOf(ID)
	if SourceObject.Config ~= nil and SourceObject.ID == ID and SourceObject.Config.orientations ~= nil then
		return SourceObject.Config.orientations[1].spaces or {{0,0}};
	end
	return world.objectSpaces(ID);
end

local function TestCondition(Condition,ID)
	if Condition[4] == true then
		return Condition[2](ID);
	else
		return Condition[2](GetParameterOf(ID,Condition[3]));
	end
end

local function SatisfiesConditions(objectID,Index)
	--sb.logInfo("START");
	local InCondition = false;
	for i=1,#Conditions do
		if objectID ~= nil then
			if TestCondition(Conditions[i],objectID) == true      --[[Conditions[i][2](GetParameterOf(objectID,Conditions[i][3])) == true--]] then
				local Valid = false;
				local EntityPosition = entity.position();
				for o,p in ipairs(object.spaces()) do
					local CheckingPosition = vecSub(vecAdd(EntityPosition,p),GetPositionOf(objectID));
					local Connections = GetCableConnectionsOf(objectID);
					if Connections == nil then Valid = true; break; end;
					for m,n in ipairs(Connections) do
						if vecEq(CheckingPosition,n) == true then
									
							Valid = true;
							break;
						end
					end
					if Valid == true then break end;
				end
				if Valid == true then
					if CableCore.CableTypes[Conditions[i][1]] == nil then
						CableCore.CableTypes[Conditions[i][1]] = {};
						for x=1,CableAmount do
							CableCore.CableTypes[Conditions[i][1]][x] = -10;
						end
					end
					local List = CableCore.CableTypes[Conditions[i][1]];
					List[Index] = objectID;
					--sb.logInfo(sb.print(objectID) .. " is part of " .. sb.print(Conditions[i][1]));
					--return objectID;
					InCondition = true;
				end
			end
		else
			if CableCore.CableTypes[Conditions[i][1]] == nil then
				CableCore.CableTypes[Conditions[i][1]] = {};
				for x=1,CableAmount do
					CableCore.CableTypes[Conditions[i][1]][x] = -10;
				end
			end
		end
	end
	--sb.logInfo("END");
	if InCondition == true then
		return objectID;
	end
	return nil;
end

local AfterFunctions = {};
local ExtractionConduits = {};

AfterFunctions[1] = function()
	for i=1,#ExtractionConduits do
		if world.entityExists(ExtractionConduits[i]) == true then
			world.callScriptedEntity(ExtractionConduits[i],"ResetPathCache");
		end
	end
	ExtractionConduits = {};
	if Animated == true then
		object.setProcessingDirectives("");
		if CableCore.CablesFound[3] ~= nil and CableCore.CablesFound[4] ~= nil and CableCore.CablesFound[1] == nil and CableCore.CablesFound[2] == nil then
			animator.setAnimationState("cable","horizontal");
		elseif CableCore.CablesFound[3] == nil and CableCore.CablesFound[4] == nil and CableCore.CablesFound[1] ~= nil and CableCore.CablesFound[2] ~= nil then
			animator.setAnimationState("cable","vertical");
		elseif CableCore.CablesFound[3] ~= nil and CableCore.CablesFound[4] == nil and CableCore.CablesFound[1] == nil and CableCore.CablesFound[2] ~= nil then
			animator.setAnimationState("cable","corner");
		elseif CableCore.CablesFound[3] ~= nil and CableCore.CablesFound[4] == nil and CableCore.CablesFound[1] ~= nil and CableCore.CablesFound[2] == nil then
			animator.setAnimationState("cable","corner");
			object.setProcessingDirectives("?flipy");
		elseif CableCore.CablesFound[3] == nil and CableCore.CablesFound[4] ~= nil and CableCore.CablesFound[1] ~= nil and CableCore.CablesFound[2] == nil then
			animator.setAnimationState("cable","corner");
			object.setProcessingDirectives("?flipxy");
		elseif CableCore.CablesFound[3] == nil and CableCore.CablesFound[4] ~= nil and CableCore.CablesFound[1] == nil and CableCore.CablesFound[2] ~= nil then
			animator.setAnimationState("cable","corner");
			object.setProcessingDirectives("?flipx");
		elseif CableCore.CablesFound[3] ~= nil and CableCore.CablesFound[4] ~= nil and CableCore.CablesFound[1] == nil and CableCore.CablesFound[2] ~= nil then
			animator.setAnimationState("cable","triplehorizontal");
		elseif CableCore.CablesFound[3] ~= nil and CableCore.CablesFound[4] == nil and CableCore.CablesFound[1] ~= nil and CableCore.CablesFound[2] ~= nil then
			animator.setAnimationState("cable","triplevertical");
			object.setProcessingDirectives("?flipx");
		elseif CableCore.CablesFound[3] ~= nil and CableCore.CablesFound[4] ~= nil and CableCore.CablesFound[1] ~= nil and CableCore.CablesFound[2] == nil then
			animator.setAnimationState("cable","triplehorizontal");
			object.setProcessingDirectives("?flipy");
		elseif CableCore.CablesFound[3] == nil and CableCore.CablesFound[4] ~= nil and CableCore.CablesFound[1] ~= nil and CableCore.CablesFound[2] ~= nil then
			animator.setAnimationState("cable","triplevertical");
		elseif CableCore.CablesFound[3] ~= nil and CableCore.CablesFound[4] ~= nil and CableCore.CablesFound[1] ~= nil and CableCore.CablesFound[2] ~= nil then
			animator.setAnimationState("cable","full");
		elseif CableCore.CablesFound[3] == nil and CableCore.CablesFound[4] == nil and CableCore.CablesFound[1] == nil and CableCore.CablesFound[2] == nil then
			animator.setAnimationState("cable","none");
		elseif CableCore.CablesFound[3] ~= nil and CableCore.CablesFound[4] == nil and CableCore.CablesFound[1] == nil and CableCore.CablesFound[2] == nil then
			animator.setAnimationState("cable","right");
		elseif CableCore.CablesFound[3] == nil and CableCore.CablesFound[4] ~= nil and CableCore.CablesFound[1] == nil and CableCore.CablesFound[2] == nil then
			animator.setAnimationState("cable","right");
			object.setProcessingDirectives("?flipx");
		elseif CableCore.CablesFound[3] == nil and CableCore.CablesFound[4] == nil and CableCore.CablesFound[1] ~= nil and CableCore.CablesFound[2] == nil then
			animator.setAnimationState("cable","up");
			object.setProcessingDirectives("?flipy");
		elseif CableCore.CablesFound[3] == nil and CableCore.CablesFound[4] == nil and CableCore.CablesFound[1] == nil and CableCore.CablesFound[2] ~= nil then
			animator.setAnimationState("cable","up");
		end
	end
end
CableCore.CablesFound = {};
CableCore.CableTypes = {};

local function ObjectAt(Pos)
	if SourceObject.ID ~= nil and ContainedInSpaces(Pos,SourceObject.Position,GetSpacesOf(SourceObject.ID)) == true then
		if SourceObject.Excluded == true then
			return nil;
		else
			return SourceObject.ID;
		end
	end
	return world.objectAt(Pos);
end

function CableCore.UpdateOthers()
	for i=1,CableAmount do
		if CableCore.CablesFound[i] ~= nil and world.entityExists(CableCore.CablesFound[i]) == true then
			world.sendEntityMessage(CableCore.CablesFound[i],"UpdateConnections",false,entity.id(),object.position(),true);
		end
	end
end

function CableCore.Initialize()
	--sb.logInfo("Started INIT of " .. sb.print(entity.id()));
	--sb.logInfo("Animation = " .. sb.print(config.getParameter("animation")));
	message.setHandler("SmashCableBlockAndSpawnItem",function(_,_,ItemName,Pos,Count,Config)
		--sb.logInfo("A");
		ItemName = ItemName or object.name();
		CableCore.Smashing = true;
		local ConduitType = config.getParameter("conduitType");
		if ConduitType == "extraction" or ConduitType == "io" then
			Config.description = "Color=" .. (Config.SelectedColor or 1) .. "    Speed=" .. (Config.Speed or 0) .. "\nStack=" .. (Config.Stack or 0) .. "    Configs=" .. #(Config.Configs or {});
			if Config.Configs ~= nil and #Config.Configs > 0 then
				Config.description = Config.description .. "\nFirstConfigName=" .. (Config.Configs[1].itemName);
			end
		end
		if ConduitType == "insertion" then
			Config.description = "InsertID=" .. sb.print(config.getParameter("insertID") or "");
		end
		if ConduitType == "io" then
			Config.description = Config.description .. "\nInsertID=" .. sb.print(config.getParameter("insertID") or "");
		end
		object.smash(true);
		--sb.logInfo("Parameters = " .. sb.print(Config));
		if Facaded == true then
			Config.ContainsStoredInfoFor = GetFacadeDropItem();
			world.spawnItem(GetFacadeDropItem(),Pos,nil,Config);
		else
			world.spawnItem(ItemName,Pos,nil,Config);
		end
	end);
	if config.getParameter("animation") ~= "/Animations/Cable.animation" then
		Animated = false;
	end
	if CableConnections == nil then
		CableConnections = config.getParameter("CableConnections",DefaultConnections);
	end
	CableAmount = #CableConnections;
	message.setHandler("UpdateConnections",function(_,_,ToOthers,sourceID,sourcePos,excluded,config)
		--sb.logInfo("Recieving Update");
		--sb.logInfo("Self Connections = " .. sb.print(CableConnections));
		SourceObject = {ID = sourceID,Position = sourcePos,Excluded = excluded,Config = config};
		CableCore.Update();
		if ToOthers == true then 
			for i=1,CableAmount do
				if CableCore.CablesFound[i] ~= nil and world.entityExists(CableCore.CablesFound[i]) == true then
					world.sendEntityMessage(CableCore.CablesFound[i],"UpdateConnections",false);
				end
			end
		end
	end);
	CableCore.Update();
	local SelfConfig = nil;
	for i=1,CableAmount do
		--[[if CableCore.CablesFound[i] ~= nil and world.entityExists(CableCore.CablesFound[i]) == true then
			sb.logInfo("Is Initialized = " .. sb.print(world.getObjectParameter(CableCore.CablesFound[i],"CablesInitialized",false)));
		end--]]
		if CableCore.CablesFound[i] ~= nil and world.entityExists(CableCore.CablesFound[i]) == true--[[ and world.getObjectParameter(CableCore.CablesFound[i],"CablesInitialized",false) == true--]] then
			if SelfConfig == nil then
				SelfConfig = root.itemConfig({name = object.name(),count = 1}).config;
				SelfConfig.CableConnections = CableConnections;
			end
			world.sendEntityMessage(CableCore.CablesFound[i],"UpdateConnections",false,entity.id(),object.position(),false,SelfConfig);
		end
	end
	CableCore.Initalized = true;
	object.setConfigParameter("CablesInitialized",true);
	--sb.logInfo("Ended INIT of " .. sb.print(entity.id()));
end

--[[function CableCore.Uninitialize()
	object.setConfigParameter("CablesInitialized",false);
	CableCore.Initalized = false;
end--]]

function CableCore.UpdateExtractionConduits()
	for i=1,#ExtractionConduits do
		if world.entityExists(ExtractionConduits[i]) == true then
			world.callScriptedEntity(ExtractionConduits[i],"ResetPathCache");
		end
	end
end

function CableCore.Uninitialize()
	CableCore.UpdateOthers();
	for i=1,#ExtractionConduits do
		if world.entityExists(ExtractionConduits[i]) == true then
			world.callScriptedEntity(ExtractionConduits[i],"ResetPathCache");
		end
	end
end

function AddExtractionConduit(Conduit)
	for i=1,#ExtractionConduits do
		if ExtractionConduits[i] == Conduit then
			return nil;
		end
	end
	ExtractionConduits[#ExtractionConduits + 1] = Conduit;
end

function CableCore.Update()
	local OriginalLayout = {};
	for i=1,CableAmount do
		OriginalLayout[i] = CableCore.CablesFound[i];
	end

	CableCore.CableTypes = {};
	for i=1,CableAmount do
		CableCore.CablesFound[i] = SatisfiesConditions(ObjectAt(vecAdd(object.position(),CableConnections[i])),i);
	end
	local Equals = true;
	for i=1,CableAmount do
		if OriginalLayout[i] ~= CableCore.CablesFound[i] then
			Equals = false;
			break;
		end
	end
	--sb.logInfo("Equals = " .. sb.print(Equals));
	if Equals == false then
		for i=1,#AfterFunctions do
			AfterFunctions[i]();
		end
	end
end

function CableCore.AddCondition(organizingName,configName,func)
	Conditions[#Conditions + 1] = {organizingName,func,configName,false};
end

function CableCore.AddAdvancedCondition(organizingName,func)
	Conditions[#Conditions + 1] = {organizingName,func,"NAN",true};
end

function CableCore.SetAfterFunction(func)
	AfterFunctions[1] = func;
end

function CableCore.SetCableConnections(connections)
	object.setConfigParameter("CableConnections",connections);
	CableConnections = connections;
end

function CableCore.AddAfterFunction(func)
	AfterFunctions[#AfterFunctions + 1] = func;
end