require ("/Core/Math.lua");
require ("/Core/CanvasCore/ElementBase.lua");
local vec = vec;
CanvasCore = {};
local ElementCreators = {};

local Canvases = {};

local Core = {};

function Core.AddElement(CanvasName,Element)
	Canvases[CanvasName].Elements[#Canvases[CanvasName].Elements + 1] = Element;
end

function CanvasCore.CreateElement(Type,CanvasAlias,...)
	if ElementCreators[Type] ~= nil then
		local Controller,Element = ElementCreators[Type](CanvasAlias,...);
		Core.AddElement(CanvasAlias,Element);
		sb.logInfo("Element = " .. sb.print(Element));
		return Controller;
	else
		error("Element Type of " .. sb.print(Type) .. "doesn't exist");
	end
end

function CanvasCore.AddCanvas(CanvasName,AliasName)
	for k,i in pairs(Canvases) do
		if i.Name == CanvasName then
			error(sb.print(CanvasName) .. " is already Added under the Alias Name : " .. sb.print(k));
		end
	end
	local Binding = widget.bindCanvas(CanvasName);
	Canvases[AliasName] = {Canvas = Binding,Name = CanvasName,Elements = {}};
	return Binding;
end

function CanvasCore.GetCanvas(CanvasAlias)
	if Canvases[CanvasAlias] == nil then
		error(sb.print(CanvasAlias) .. " is not a valid Canvas Alias");
	end
	return Canvases[CanvasAlias].Canvas;
end

local function DeleteElement(Element)
	for k,i in ipairs(Canvases[Element.CanvasName].Elements) do
		if i.ID == Element.ID then
			table.remove(Canvases[Element.CanvasName].Elements,k);
		end
	end
end

function CanvasCore.Init()
	local ElementJson = root.assetJson("/Core/CanvasCore/Elements.json").Elements;
	for k,i in ipairs(ElementJson) do
		if i.Name ~= nil then
			require(i.Script);
			if Creator ~= nil and Creator.Create ~= nil then
				ElementCreators[i.Name] = Creator.Create;
				Creator = nil;
			else
				error(sb.print(i.Script) .. " is either not a valid lua file or doesn't implement Creator.Create()");
			end
		end
	end
end

function CanvasCore.Update(dt)
	for k,i in pairs(Canvases) do
		i.Canvas:clear();
		for m,n in ipairs(i.Elements) do
			if n.Update ~= nil then
				n.Update(dt);
			end
			n.Draw();
		end
	end
end