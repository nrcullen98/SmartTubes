if AllItems ~= nil then return nil end;
require("/Core/UICore.lua");

--Declaration
AllItems = {};
local AllItems = AllItems;

--Variables
local AllItemsBackground = "/Blocks/Conduit Terminal/UI/Window/AllItemsArea.png";
local AllItemsBackgroundSize;
local Initialized = false;
local Enabled = false;
local Canvas;
local Size;
local GlideDestination;
local GlideSpeed = 6;
local Position;
local SourceID;
local AllItemsDefaultPosition = {120,-169};
local AllItemsOpenPosition = {120,2};
local BoundElements = {};
local Loading = false;
local SlotsPerRow = 12;
local AllItemsList = "allItemsInventoryArea.itemList";
local SlotRows = {};
local MainLoadingRoutine;
local ConduitContainerUUIDMap = {};
local InternalInventoryItems = {};
local InventoryItemsMeta = {
    __index = function(tbl,k)
        return rawget(InternalInventoryItems,k);
    end,
    __len = function()
        return #InternalInventoryItems;
    end,
    __newindex = function(tbl,k,v)
      --  sb.logInfo("k = " .. sb.print(k));
        --sb.logInfo("v = " .. sb.print(v));
       -- sb.logInfo("START=======");
        local RowNumber = math.ceil(k / SlotsPerRow);
        local SlotAtRow = ((k - 1) % SlotsPerRow) + 1;
        if RowNumber > #SlotRows then
            if RowNumber - 1 ~= 0 then
                for row=#SlotRows,RowNumber - 1 do
                    if SlotRows[row] == nil then
                        local NewSlot = widget.addListItem(AllItemsList);
                        SlotRows[row] = {Name = NewSlot,Full = AllItemsList ..  "." .. NewSlot};
                    end
                    local Top = SlotRows[row].Full;
                    for i=1,SlotsPerRow do
                        widget.setVisible(Top .. ".slot" .. SlotAtRow,true);
                        widget.setVisible(Top .. ".slot" .. SlotAtRow .. "background",true);
                        widget.setData(Top .. ".slot" .. SlotAtRow,((row - 1) * SlotsPerRow) + i);
                    end
                end
            end
            local NewSlot = widget.addListItem(AllItemsList);
            SlotRows[RowNumber] = {Name = NewSlot,Full = AllItemsList ..  "." .. NewSlot};
        end
        local Slot = SlotRows[RowNumber].Full .. ".slot" .. SlotAtRow;
       -- sb.logInfo("Row Number = " .. sb.print(RowNumber));
       -- sb.logInfo("SlotAtRow = " .. sb.print(SlotAtRow));
        --sb.logInfo("Global Slot = " .. sb.print(k));
        --sb.logInfo("Slot = " .. sb.print(Slot));
        widget.setItemSlotItem(Slot,v);
        --sb.logInfo("Set Slot Item = " .. sb.print(widget.itemSlotItem(Slot)));
        rawset(InternalInventoryItems,k,v);
        local IsNil = true;
        for row=#SlotRows,1,-1 do
            local RowPath = SlotRows[row].Full;
            local RowEmpty = true;
            for slot=SlotsPerRow,1,-1 do
                local SlotPath = RowPath .. ".slot" .. slot;
               -- sb.logInfo("SLOTPATH = " .. sb.print(SlotPath));
               -- sb.logInfo("Item = " .. sb.print(widget.itemSlotItem(SlotPath)));
                if IsNil == true then
                    IsNil = widget.itemSlotItem(SlotPath) == nil;
                else
                    if widget.itemSlotItem(SlotPath) ~= nil then
                        break;
                    end
                end
                if RowEmpty == true then
                    RowEmpty = widget.itemSlotItem(SlotPath) == nil;
                end
                widget.setVisible(SlotPath,not IsNil);
                widget.setVisible(SlotPath .. "background",not IsNil);
            end
            if IsNil and RowEmpty then
                table.remove(SlotRows,row);
                widget.removeListItem(AllItemsList,row);
            end
        end
       -- sb.logInfo("END=======");        
    end}
local InventoryItems;
InventoryItems = setmetatable({
    Clear = function() 
        for i=#InternalInventoryItems,1,-1 do 
            InventoryItems[i] = nil 
        end
        SlotRows = {};
        widget.clearListItems(AllItemsList);
    end
},InventoryItemsMeta);

--Functions
local Update;
local AddAllBoundElements;
local BindElement;
local __SlotClick__;
local __RightClickSlot__;
local OnEnable;
local ExecuteScript;
local ExecuteScriptAsync;

--Initializes the All Items Area
function AllItems.Initialize()
    if Initialized == true then return nil end;
    SourceID = pane.sourceEntity();
    Initialized = true;
        AllItemsBackgroundSize = root.imageSize(AllItemsBackground);
    local OldUpdate = update;
    update = function(dt)
        if OldUpdate ~= nil then
            OldUpdate(dt);
        end
        Update(dt);
    end
    --sb.logInfo("For Loop Test");
    widget.registerMemberCallback("allItemsInventoryArea.itemList","__SlotClick__",__SlotClick__);
    widget.registerMemberCallback("allItemsInventoryArea.itemList","__SlotRightClick__",__SlotRightClick__);
    --[[for i=1,1 do
        sb.logInfo("I of A = " .. sb.print(i));
    end
    for i=1,2 do
        sb.logInfo("I of B = " .. sb.print(i));
    end--]]
    --[[for i=1,50 do
        InventoryItems[i] = {name = "perfectlygenericitem",count = i % 1000};
    end--]]
   -- InventoryItems[500] = {name = "perfectlygenericitem",count = 1};
    Canvas = widget.bindCanvas("allItemsCanvas");
    GlideDestination = AllItemsDefaultPosition;
    widget.setPosition("allItemsCanvas",GlideDestination);
    Position = {GlideDestination[1],GlideDestination[2]};
    Size = Canvas:size();
    Canvas:drawImageRect(AllItemsBackground,{0,0,AllItemsBackgroundSize[1],AllItemsBackgroundSize[2]},{0,0,Size[1],Size[2]});
   -- Canvas:drawRect({0,0,Canvas:size()[1],Canvas:size()[2]},{0,0,255});
   AddAllBoundElements();
   --TEST FUNCTIONS
   --[[ widget.registerMemberCallback("allItemsInventoryArea.itemList","__SlotClick__",__SlotClick__);
   widget.registerMemberCallback("allItemsInventoryArea.itemList","__SlotRightClick__",__SlotRightClick__);
   local Item = widget.addListItem("allItemsInventoryArea.itemList");
   local FullLink = "allItemsInventoryArea.itemList." .. Item .. ".";
   for i=1,12 do
        local SlotName = FullLink .. "slot" .. i;
       -- sb.logInfo("SlotName = " .. sb.print(SlotName));
        widget.setVisible(SlotName,true);
        widget.setVisible(SlotName .. "background",true);
    end--]]
end

--Adds any bound elements
AddAllBoundElements = function()
    BindElement("allItemsInventoryArea");
end

--Binds an element to move with the All Items Canvas
BindElement = function(elementName)
    --BoundElements[#BoundElements + 1] = elementName;
    local RelativePosition = widget.getPosition(elementName);
    widget.setPosition(elementName,{AllItemsDefaultPosition[1] + RelativePosition[1],AllItemsDefaultPosition[2] + RelativePosition[2]});
    widget.setVisible(elementName,true);
    BoundElements[#BoundElements + 1] = {Name = elementName,RelativePosition = RelativePosition};
end


--Enables the All Items Area
function AllItems.Enable(bool)
    if bool == nil then
        bool = true;
    end
    if Enabled ~= bool then
        Enabled = bool;
        if Enabled == true then
            GlideDestination = AllItemsOpenPosition;
        else
            GlideDestination = AllItemsDefaultPosition;
        end
        OnEnable(bool);
    end

end

--TEST TEST TEST
local Counter = 0;

--The Update Loop for the All Items Area
Update = function(dt)
   --[[ Counter = Counter + dt;
   -- sb.logInfo("Counter = " .. sb.print(Counter));
    if Counter > 5 and Counter < 6 then
        Counter = 6;
       -- sb.logInfo("Setting");
        InventoryItems[500] = nil;
    end--]]
  --[[  for i=1,5 do
        InventoryItems[#InventoryItems + 1] = {name = "perfectlygenericitem",count = (#InventoryItems % 1000) + 1};
    end--]]
    --InventoryItems[500] = {name = "perfectlygenericitem",count = 1};
    --local CurrentPosition = widget.getPosition("allItemsCanvas");
    Position = {(GlideDestination[1] - Position[1]) / GlideSpeed + Position[1],(GlideDestination[2] - Position[2]) / GlideSpeed + Position[2]};
   -- sb.logInfo("Position = " .. sb.print(Position));
    widget.setPosition("allItemsCanvas",Position);
    for i=1,#BoundElements do
        local Element = BoundElements[i];
        widget.setPosition(Element.Name,{Element.RelativePosition[1] + Position[1],Element.RelativePosition[2] + Position[2]});
    end
    if GlideDestination[1] ~= Position[1] and math.abs(GlideDestination[1] - Position[1]) < 0.3 then
        --GlideDestination[1] = Position[1];
        Position[1] = GlideDestination[1];
    end
    if GlideDestination[2] ~= Position[2] and math.abs(GlideDestination[2] - Position[2]) < 0.3 then
       -- GlideDestination[2] = Position[2];
       Position[2] = GlideDestination[2];
    end
end

--Called when the AllItemsArea is clicked
function __AllItemsAreaClick__(position,buttonType,isDown)
    if buttonType == 0 and isDown == true then
        AllItems.Enable(not Enabled);
    end
end

__SlotClick__ = function(name,data)
    sb.logInfo("Clicked on slot = " .. sb.print(data));
end

__SlotRightClick__ = function(name,data)

end

--Called when the Enable Variable is changed
OnEnable = function(enabled)
    if enabled == true then
        if MainLoadingRoutine ~= nil then
            UICore.CancelCoroutine(MainLoadingRoutine);
            MainLoadingRoutine = nil;
        end
        MainLoadingRoutine = UICore.AddAsyncCoroutine(function()
            InventoryItems.Clear();
            local Network = TerminalUI.GetNetwork();
            local Info = TerminalUI.GetNetworkInfo();
            for _,conduit in ipairs(Network) do
                local ConduitInfo = Info[tostring(conduit)];
                local Contents;
                --if ConduitInfo.ConduitType == "extraction" or ConduitInfo.ConduitType == "io" then
                  --[[  local Promise = world.sendEntityMessage(SourceID,"ExecuteScript",conduit,"Extraction.QueryContainers",ConduitContainerUUIDMap[tostring(conduit)]);
                    while not Promise:finished() do
                        coroutine.yield();
                    end
                    local Value = Promise:result();--]]
                    local ID;
                    if ConduitContainerUUIDMap[tostring(conduit)] ~= nil then
                        ID = ConduitContainerUUIDMap[tostring(conduit)].ID;
                    end
                    local Value;
                    if ConduitInfo.ConduitType == "extraction" or ConduitInfo.ConduitType == "io" then
                        Value = ExecuteScriptAsync(conduit,"Extraction.QueryContainers",ID,true);
                    elseif ConduitInfo.ConduitType == "insertion" then
                        Value = ExecuteScriptAsync(conduit,"Insertion.QueryContainers",ID,true);
                    end         
                    if Value == false then
                        Contents = ConduitContainerUUIDMap[tostring(conduit)].Contents;
                        sb.logInfo("A");                        
                    elseif Value ~= nil then
                        ConduitContainerUUIDMap[tostring(conduit)] = {ID = Value[2],Contents = Value[1]};
                        Contents = Value[1];
                        sb.logInfo("B");
                    end
                    sb.logInfo("Contents for " .. sb.print(conduit) .. " = " .. sb.print(Contents));
               -- elseif ConduitInfo.ConduitType == "insertion" then
                    --TODO
                 --   Contents = {};
                 --   sb.logInfo("C");
               -- end
                sb.logInfo("Contents = " .. sb.print(Contents));
                -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO 
                --Track Containers to avoid duplicates and to allow taking out of them
                if Contents ~= nil then
                    for stringContainer,ContainerItems in pairs(Contents) do
                        local Container = tonumber(stringContainer);
                        for _,item in ipairs(ContainerItems) do
                            --Add items to the all items list
                            if type(item) == "table" then
                                InventoryItems[#InventoryItems + 1] = item;
                            else
                                InventoryItems[#InventoryItems + 1] = nil;
                            end
                        end
                    end
                end
                ::Continue::
            end
        end);
    end
end

--Calls a script on the passed in object on the server side
--Returns a promise to that call
ExecuteScript = function(object,functionName,...)
    return world.sendEntityMessage(SourceID,"ExecuteScript",object,functionName,...);
end

--Calls a script on the passed in object on the server side
--Returns the value that was returns from the server function
--THIS MUST BE USED IN A COUROUTINE
ExecuteScriptAsync = function(object,functionName,...)
    local Promise = ExecuteScript(object,functionName,...);
    while not Promise:finished() do
        coroutine.yield();
    end
    return Promise:result();
end



