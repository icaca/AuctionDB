ASAuctionHouseWindowOpen = false

function Color(str, color)
    local c = '';

    if color == 'red' then
        c = '|cFFff0000';
    elseif color == 'gray' then
        c = '|cFFa6a6a6';
    elseif color == 'purple' then
        c = '|cFFB900FF';
    elseif color == 'blue' then
        c = '|cB900FFFF';
    elseif color == 'lightBlue' then
        c = '|cB900FFFF';
    elseif color == 'reputationBlue' then
        c = '|cFF8080ff';
    elseif color == 'yellow' then
        c = '|cFFffff00';
    elseif color == 'orange' then
        c = '|cFFFF6F22';
    elseif color == 'green' then
        c = '|cFF00ff00';
    elseif color == "white" then
        c = '|cFFffffff';
    elseif color == "gold" then
        c = "|cFFffd100" -- this is the default game font
    end

    return c .. str .. "|r"
end

local function AsGetMinBuyoutPrice(itemID)
    local dbminbuyout = nil
    if not (ASItemList[tonumber(itemID)] == nil) then
        dbminbuyout = ASItemList[tonumber(itemID)]["price"]
    end
    
    return dbminbuyout
end

function AsGetPrice(itemID)
    local price = AsGetMinBuyoutPrice(itemID)
    if price then
        return math.floor(price)
    end
    return nil
end

function AsGetVendorPrice(itemID)
    if AsVendorList[itemID] then
        return AsVendorList[itemID]["price"]
    end
    return false 
end

function AsGetVendorSellPrice(itemId)
    sellprice = select(11, GetItemInfo(itemId))
    if sellprice then
        return sellprice
    end
    return false
end

function AsUpdateVendorList()
    local numItems = GetMerchantNumItems();
    for i=1, numItems do

        local name, texture, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(i)
        if name == nil then
            break
        end
        local link = GetMerchantItemLink(i);
        local itemId = tonumber(string.match(link, 'item:*(%d+)'))
        if numAvailable == -1 then
            if not AsVendorList[itemId] then
                AsVendorList[itemId] = {}
            end
            p = price / quantity
            AsVendorList[itemId]["price"] = p
        end
    end
end
function AsFormatPrice(dbmarket, quantity)
    if dbmarket == nil then
        return "Not in db"
    end
    if quantity ~= nil then
        dbmarket = dbmarket * quantity
    end
    local g = math.floor(dbmarket/10000)
    dbmarket = dbmarket - g * 10000
    local s = math.floor(dbmarket/100)
    dbmarket = dbmarket - s * 100
    local c = math.floor(dbmarket)
    
    if(g == 0) then gt = "" else gt = g.."gold " end
    if(s == 0) then st = "" else st = s.."silver " end
    if(c == 0) then ct = "" else ct = c.."copper " end
    local price = gt..st..ct
    return price
end

function AsGetFormatedPrice(itemID)
    return AsFormatPrice()
end

local function GetItemLink(itemID)
    return select(2, GetItemInfo(itemID))
end


local function Pwc(msg)
    modname = Color("<","orange")..Color("AHS",'yellow')..Color(">","orange")
    print(modname.." "..msg)
end

function AsInit()
    Pwc("Loaded v1.0.2 - By Urutzi-Earthshaker")
end

local function FormatTime(time)
    local weeks = ""
    local months = ""
    local days = ""
    local hours = ""
    local minutes = ""
    local secounds = ""
    if time > 604800 then
        weeks = math.floor(time / 604800)
        time = time - weeks * 604800
        if weeks == 1 then
            weeks = weeks.."week and "
        else
            weeks = weeks.."weeks and "
        end
    end
    if time > 86400 then
        days = math.floor(time / 86400)
        time = time - days * 86400
        
        if days == 1 then
            days = days.." day "
        else
            days = days.." days "
        end
    end
    if weeks == "" then
        if time > 3600 then
            hours = math.floor(time / 3600)      
            time = time - hours * 3600
            hours = hours.."h "
        end
        if time > 59 then
            minutes = math.floor(time / 60)
            time = time - minutes * 60
            minutes = minutes.."m "
        end
        if time < 60 then
            secounds = math.floor(time).."s"
        end
    end
    return weeks..days..hours..minutes..secounds
end

function AsHowLongSinceLastScan(itemId)
    local time = time() - ASItemList[itemId]["lastUpdate"]
    return FormatTime(time)
end

local function CanQuery()  
    canQuery,canQueryAll = CanSendAuctionQuery()
    if(canQueryAll)then
        return true
    end
    theTime = time()
    if ASLastScan == nil then
        ASLastScan = theTime
    end

    timeLeft = ASLastScan + (15*60) - theTime
    timeLeft = FormatTime(timeLeft)
    Pwc("You have a scan cooldown, "..timeLeft.." left")
    return false
end

local function IsAtAuctionHouse()
    if ASAuctionHouseWindowOpen then
        return true
    end
    Pwc("You are not at a auction house")
    return false
end

local startTime
local function Query()
    if IsAtAuctionHouse() and CanQuery() then
        name = ""
        minLevel = nil
        maxLevel = nil
        invTypeIndex = 0
        classIndex = 0
        subclassIndex = 0
        isUsable = 0
        qualityIndex = 0
        getAll = true
        newItems = 0
        page = 0
        QueryAuctionItems(name, minLevel, maxLevel, 
              invTypeIndex, classIndex, subclassIndex, 
              page, isUsable, qualityIndex, getAll
            )
    end
end

function AsDebug(msg)
    if AsDebugActive then
        print(msg)
    end
end

local function ProsessScan()
        local newItems, timeUsed, endTime, query, prosessed
        newItems = 0
        batch,listCount = GetNumAuctionItems("list");
        prosessed = 0
        for i=1, listCount do
            local name, texture, count, quality, canUse, level, levelColHeader, minBid,
            minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner,
            ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo("list", i)
            price = buyoutPrice / count
            
            if price ~= 0 then 
                AsDebug(itemId..": "..price)
                if not ASItemList[itemId] then
                    AsDebug("New item")
                    ASItemList[itemId] = {}
                    ASItemList[itemId]["price"] = price
                    ASItemList[itemId]["lastUpdate"] = startTime
                    ASItemList[itemId]["quantity"] = count
                    newItems = newItems + 1
                else
                    if math.floor(ASItemList[itemId]["lastUpdate"]) == math.floor(startTime) then
                        if ASItemList[itemId]["price"] > price then
                            AsDebug("Updated item")
                            ASItemList[itemId]["price"] = price
                            ASItemList[itemId]["lastUpdate"] = startTime
                        end
                        if ASItemList[itemId]["quantity"] == nil then
                            ASItemList[itemId]["quantity"] = count
                        else
                            ASItemList[itemId]["quantity"] = tonumber(ASItemList[itemId]["quantity"]) + count
                        end
                    else
                        AsDebug("First item")
                        ASItemList[itemId]["price"] = price
                        ASItemList[itemId]["lastUpdate"] = startTime
                        ASItemList[itemId]["quantity"] = count
                    end
                    
                end
            end
            prosessed = prosessed + 1
        end
        endTime = time()

        timeUsed = endTime - startTime
        timeUsed = math.floor(timeUsed * 100) / 100
        ASLastScan = endTime
        batch,listCount = GetNumAuctionItems("list");
        if not newItems == 0 then
            newItems = newItems.." new items of "
        else
            newItems = ""
        end
        Pwc("Scan finished: "..newItems..listCount.." auctions scanned in "..timeUsed.." sec")
end

function AsScan()
    if IsAtAuctionHouse() and CanQuery() then
        startTime = time()
        if ASItemList == nil then
            Pwc("Running the first scan")
        else
            Pwc("Started auction house scan")
        end
        Query()
        C_Timer.After(10, ProsessScan)
    end
end