local async = LibStub("LibAsync")
local task = async:Create("FurnitureCatalogue_Tooltip")

local p 		= FurC.DebugOut -- debug function calling zo_strformat with up to 10 args

local function tryColorize(text)
	if not (text and FurC.GetColouredTooltips()) then return text end
	return text:gsub("cannot craft", "|cFF0000cannot craft|r"):gsub("Can be crafted", "|c00FF00Can be crafted|r")
end

local defaultDebugString = "[<<1>>] = <<2>>, -- <<3>>"
local function tryCreateDebugOutput(itemId, itemLink)
    if not (FurC.DevDebug and FurCGui:IsHidden()) then return end
    itemId = itemId or FurC.GetItemId(itemLink)
    local price = 0
    local control = moc()
    local debugString = defaultDebugString
    if control and control.dataEntry then
        local data = control.dataEntry.data or {}
        if 0 == data.currencyQuantity1 then
            price = data.stackBuyPrice
            debugString = "[<<1>>] = { -- <<3>>\n\titemPrice = <<2>>,\n\t--achievement = 0, \n},"
        else
            price = data.currencyQuantity1
        end
    end
    d(zo_strformat(debugString, itemId, price, GetItemLinkName(itemLink)))
end

local function addTooltipData(control, itemLink)

	if FurC.GetDisableTooltips() then return end
	local itemId, recipeArray = nil
	if nil == itemLink or FURC_EMPTY_STRING == itemLink then return end
	local isRecipe = IsItemLinkFurnitureRecipe(itemLink)

    tryCreateDebugOutput(itemId, itemLink)

	itemLink = (isRecipe and GetItemLinkRecipeResultItemLink(itemLink)) or itemLink

    if not (isRecipe or IsItemLinkPlaceableFurniture(itemLink)) then return end
	itemId 		= FurC.GetItemId(itemLink)
	recipeArray = FurC.Find(itemLink)

	-- |H0:item:118206:5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h

	if not recipeArray then return end


	local unknown 	= not FurC.CanCraft(itemId, recipeArray)
	local stringTable = {}


	local function add(t, arg)
		if nil ~= arg then t[#t + 1] = arg end
		return t
	end

	-- if craftable:
	if isRecipe or recipeArray.origin == FURC_CRAFTING then
		if unknown and not FurC.GetHideUnknown() or not FurC.GetHideKnowledge() then
			local crafterList = FurC.GetCrafterList(itemLink, recipeArray)
			if crafterList then
				stringTable = add(stringTable, tryColorize(crafterList))
			end
		end
		if not isRecipe and (not FurC.GetHideCraftingStation()) then
			stringTable = add(stringTable, FurC.PrintCraftingStation(itemId, recipeArray))
		end
		if isRecipe then
			stringTable = add(stringTable, FurC.getRecipeSource(itemId, recipeArray))
		end
		-- check if we should show mats
		if not (FurC.GetHideMats() or isRecipe) then
			stringTable = add(stringTable, FurC.GetMats(itemLink, recipeArray, true):gsub(", ", "\n"))
		end
	else
		if not FurC.GetHideSource() then
			stringTable = add(stringTable, FurC.GetItemDescription(itemId, recipeArray))
		end
		stringTable = add(stringTable, recipeArray.achievement)
	end

	if #stringTable == 0 then return end

	control:AddVerticalPadding(8)
	ZO_Tooltip_AddDivider(control)

	for i = 1, #stringTable do
		control:AddLine(zo_strformat("<<C:1>>", stringTable[i]))
	end

end

local function TooltipHook(tooltipControl, method, linkFunc)
	local origMethod = tooltipControl[method]

	tooltipControl[method] = function(self, ...)
		origMethod(self, ...)
		addTooltipData(self, linkFunc(...))
	end
end

local function ReturnItemLink(itemLink)
	return FurC.GetItemLink(itemLink)
end

do
	local identifier = FurC.name .. "Tooltips"
	-- hook real late
	local function HookToolTips()
		EVENT_MANAGER:UnregisterForUpdate(identifier)
		TooltipHook(ItemTooltip, 	"SetBagItem", 				GetItemLink)
		TooltipHook(ItemTooltip, 	"SetTradeItem", 			GetTradeItemLink)
		TooltipHook(ItemTooltip, 	"SetBuybackItem",			GetBuybackItemLink)
		TooltipHook(ItemTooltip, 	"SetStoreItem", 			GetStoreItemLink)
		TooltipHook(ItemTooltip, 	"SetAttachedMailItem", 		GetAttachedItemLink)
		TooltipHook(ItemTooltip, 	"SetLootItem", 				GetLootItemLink)
		TooltipHook(ItemTooltip, 	"SetTradingHouseItem", 		GetTradingHouseSearchResultItemLink)
		TooltipHook(ItemTooltip, 	"SetTradingHouseListing", 	GetTradingHouseListingItemLink)
		TooltipHook(ItemTooltip, 	"SetLink", 					ReturnItemLink)
		TooltipHook(PopupTooltip, 	"SetLink", 					ReturnItemLink)
	end
	-- hook late
	local function DeferHookToolTips()
		EVENT_MANAGER:UnregisterForEvent(identifier, EVENT_PLAYER_ACTIVATED)
		EVENT_MANAGER:RegisterForUpdate(identifier, 100, HookToolTips)
	end
	function FurC.CreateTooltips()
		EVENT_MANAGER:RegisterForEvent(identifier, EVENT_PLAYER_ACTIVATED, DeferHookToolTips)
	end
end
