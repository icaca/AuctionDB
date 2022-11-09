ASAuctionHouseWindowOpen = false
RealmString = GetRealmName()
buttonA, buttonB = nil, nil
isScaning = false
FactionGroup = string.sub(select(1, UnitFactionGroup('player')), 1, 1)
Server = RealmString .. '-' .. FactionGroup
table.clone = table.clone or function(t)
    local result = {}
    for i = 1, #t do result[i] = t[i] end
    return result
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

function AsGetVendorSellPrice(itemId)
    sellprice = select(11, GetItemInfo(itemId))
    if sellprice then
        return sellprice
    end
    return false
end

local function Pwc(msg)
    print(msg)
end

function AsInit()
    Pwc("Loaded Auction v1.0.3")
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
            weeks = weeks .. "week and "
        else
            weeks = weeks .. "weeks and "
        end
    end
    if time > 86400 then
        days = math.floor(time / 86400)
        time = time - days * 86400

        if days == 1 then
            days = days .. " day "
        else
            days = days .. " days "
        end
    end
    if weeks == "" then
        if time > 3600 then
            hours = math.floor(time / 3600)
            time = time - hours * 3600
            hours = hours .. "h "
        end
        if time > 59 then
            minutes = math.floor(time / 60)
            time = time - minutes * 60
            minutes = minutes .. "m "
        end
        if time < 60 then
            secounds = math.floor(time) .. "s"
        end
    end
    return weeks .. days .. hours .. minutes .. secounds
end

local function CanQuery()
    canQuery, canQueryAll = CanSendAuctionQuery()
    if (canQueryAll) then
        return true
    end
    theTime = time()
    if AuctionDB["ASLastScan"] == nil then
        AuctionDB["ASLastScan"] = theTime
    end

    timeLeft = AuctionDB["ASLastScan"] + (15 * 60) - theTime
    timeLeft = FormatTime(timeLeft)
    Pwc("查询接口冷却剩余, " .. timeLeft .. " ")
    return false
end

local function IsAtAuctionHouse()
    if ASAuctionHouseWindowOpen then
        return true
    end
    Pwc("请点开拍卖行")
    return false
end

local startTime
local function Query(name)
    if IsAtAuctionHouse() then
        -- name = ""
        minLevel = nil
        maxLevel = nil
        invTypeIndex = 0
        classIndex = 0
        subclassIndex = 0
        isUsable = 0
        qualityIndex = 0
        if name == "" then
            getAll = true
        else
            getAll = false
        end
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

SnipList = {}

function ExtractLink(text)
    return string.match(text, [[|H([^:]*):([^|]*)|h([^|]*)|h]]);
end

function GetItemString(link)
    local raw = select(2, ExtractLink(link))
    return select(11, strsplit(":", raw, 11))
end

local function ProsessScan()
    local DBScan, DBTemp = {}, {}
    local newItems, timeUsed, endTime, query, prosessed
    newItems = 0
    batch, listCount = GetNumAuctionItems("list");
    prosessed = 0
    LastScan = time()
    for i = 1, listCount do
        local name, texture, count, quality, canUse, level, levelColHeader, minBid,
        minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner,
        ownerFullName, saleStatus, itemID, hasAllInfo = GetAuctionItemInfo("list", i)
        local link = GetAuctionItemLink("list", i)
        
        if buyoutPrice and itemID and quality and type(quality) == "number" and count > 0 and buyoutPrice > 0 and
            itemID > 0 and link then
            -- AsDebug(itemID .. ": " .. buyoutPrice)
            local vendorPrice = select(11, GetItemInfo(link))
            local name        = GetItemInfo(itemID)
            local price       = buyoutPrice / count
            if vendorPrice > price then
                print(name, vendorPrice, price)
                table.insert(SnipList, name)
            end
            AuctionDB["ItemList"][itemID] = name
            local itemLevel = GetDetailedItemLevelInfo(link)
            DBScan[i] = { ["Price"] = price, ["Amount"] = count, ["ItemID"] = itemID,
                ["Level"] = itemLevel,
                ["ItemLink"] = link, ["Quality"] = quality }
        end
        prosessed = prosessed + 1
    end

    print(#DBScan)

    for _, offer in pairs(DBScan) do
        -- print(offer)
        if offer.Quality > 0 then
            local variant
            link = select(2, ExtractLink(offer.ItemLink))
            variant = string.gsub(link, tostring(offer.ItemID), "")
            print(offer.ItemID,variant)
            if DBTemp[offer.ItemID] == nil then
                DBTemp[offer.ItemID] = {}
            end
            if DBTemp[offer.ItemID][variant] == nil then
                DBTemp[offer.ItemID][variant] = {}
            end
            table.insert(DBTemp[offer.ItemID][variant], offer)
            print(DBTemp)
        end
    end

    print(#DBTemp)
    for itemID, _ in pairs(DBTemp) do
        if AuctionDB["ASItemList"][Server][itemID] == nil then
            AuctionDB["ASItemList"][Server][itemID] = {}
        end
        for variant, _ in pairs(DBTemp[itemID]) do

            local Price, Amount = analyze(DBTemp[itemID][variant], nil, LastScan)

            AuctionDB["ASItemList"][Server][itemID][variant] = { ["Price"] = Price, ["Amount"] = Amount,
                ["LastSeen"] = LastScan,
            }
        end
    end
    print(#AuctionDB)

    endTime = time()

    timeUsed = endTime - startTime
    timeUsed = math.floor(timeUsed * 100) / 100
    AuctionDB["ASLastScan"] = endTime
    batch, listCount = GetNumAuctionItems("list");
    if not newItems == 0 then
        newItems = newItems .. " / "
    else
        newItems = ""
    end
    Pwc("扫描结束: " .. newItems .. listCount .. " 件商品，耗时 " .. timeUsed .. " 秒")
    isScaning = false
end

function analyze(data, his, date)
    -- print("Start")
    if data == nil or #data == 0 then
        return nil
    end
    local Amount, Min30, tmpcnt, Total = 0, 0, 0, 0

    table.sort(data,
        function(a, b) return a.Price < b.Price end)

    for _, item in pairs(data) do
        Amount = Amount + item.Amount
    end
    Min30 = math.floor(Amount * 0.3)
    if Min30 < 1 then Min30 = 1 end

    -- print(1,Amount , Min30)
    local t, Count = {}, 0

    for _, item in pairs(data) do
        if Count >= Min30 then
            break
        end
        if tmpcnt + item.Amount > Min30 then
            item.Amount = (Min30 - Count)
        end
        table.insert(t, item)

        Total = Total + item.Price * item.Amount
        Count = Count + item.Amount
        -- print(2,item.Price , item.Amount, Min30)
    end

    avg = Total / Min30

    -- print(3,Total,Min30,avg)

    local p = 2
    local b = 0
    for k, item in pairs(t) do --计算方差
        v = item.Price
        for i = 1, item.Amount do
            b = b + ((v - avg) ^ p)
        end
    end
    b = (b / Min30) ^ 0.5 --总体标准偏差
    -- print(4,b,#t)
    local sum, count, c = 0, 0, nil
    for k, item in pairs(t) do --归一化,范围-1.5 —— 1.5 之间
        v = item.Price
        c = (v - avg) / b
        if c >= -1.5 and c <= 1.5 then
            sum = sum + v * item.Amount
            count = count + item.Amount
            -- print(5,k,v,c,b,item.Amount)
        end
    end
    -- print(6,sum/count,count,time(),Amount)
    -- _his = table.clone(his)
    -- table.insert(_his, { ["Price"] = math.floor(sum / count), ["Amount"] = Amount, ["LastSeen"] = date })
    return math.floor(sum / count), Amount
    -- return calcMarketPriceByMultipleVals(_his),Amount
end

function AsScan()
    if IsAtAuctionHouse() and CanQuery() then
        snipping = true
        startTime = time()
        if ASItemList == nil then
            Pwc("运行首次扫描")
        else
            Pwc("开始扫描")
        end
        Query("")
        C_Timer.After(1, ProsessScan)
    end
end

function AsSnip()
    print("狙击！")
    buttonB:Disable()
    -- QueryAuctionItems('', nil, nil, snippage, false, 0, nil, false, nil)
end
