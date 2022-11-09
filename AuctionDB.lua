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
        local minLevel = nil
        local maxLevel = nil
        local invTypeIndex = 0
        local classIndex = 0
        local subclassIndex = 0
        local isUsable = 0
        local qualityIndex = 0
        local newItems = 0
        local page = 0
        local getAll, exactMatch
        if name == "" then
            getAll = true
            exactMatch = false
        else
            getAll = false
            exactMatch = true
        end

        QueryAuctionItems(name, minLevel, maxLevel,
            invTypeIndex, classIndex, subclassIndex,
            page, isUsable, qualityIndex, getAll, exactMatch
        )
    end
end

function AsDebug(msg)
    if AsDebugActive then
        print(msg)
    end
end

SnipList, DBScan, DBTemp, inProgress = {}, {}, {}, {}

function ExtractLink(text)
    return string.match(text, [[|Hitem:%d+:([^:]*):([^|]*)|h([^|]*)|h]]);
end

function GetItemString(link)
    local raw = select(2, ExtractLink(link))
    return select(11, strsplit(":", raw, 11))
end

function ProsessScan()
    DBScan, DBTemp, inProgress = {}, {}, {}
    local newItems, timeUsed, endTime, query, prosessed
    newItems = 0
    batch, listCount = GetNumAuctionItems("list");
    prosessed = 0
    LastScan = time()
    -- print(listCount)
    for i = 1, listCount do
        local name, texture, count, quality, canUse, level, levelColHeader, minBid,
        minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner,
        ownerFullName, saleStatus, itemID, hasAllInfo = GetAuctionItemInfo("list", i)

        local link = GetAuctionItemLink("list", i)

        local vendorPrice = nil
        if AuctionDB.ItemList[itemID] ~= nil then
            vendorPrice = AuctionDB.ItemList[itemID].VendorPrice
        else
            vendorPrice = select(11, GetItemInfo(itemID))
            if name and vendorPrice then
                AuctionDB["ItemList"][itemID] = { ["Name"] = name, ["VendorPrice"] = vendorPrice }
            end
        end

        if buyoutPrice and itemID and quality and type(quality) == "number" and count > 0 and buyoutPrice > 0 and
            itemID > 0 and link then

            local price = buyoutPrice / count
            if vendorPrice and vendorPrice - price > 100 and price > 0 then
                print(name, vendorPrice, price, owner)
                table.insert(SnipList, name)
            end

            DBScan[i] = { ["Price"] = price, ["Amount"] = count, ["ItemID"] = itemID,
                ["ItemLink"] = link, ["Quality"] = quality }
        else
            local item = Item:CreateFromItemID(itemID)
            inProgress[item] = true

            item:ContinueOnItemLoad(function()

                local name, texture, count, quality, canUse, level, levelColHeader, minBid,
                minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner,
                ownerFullName, saleStatus, itemID, hasAllInfo = GetAuctionItemInfo("list", i)
                link                                          = GetAuctionItemLink("list", i)
                inProgress[item]                              = nil

                if vendorPrice == nil then
                    if AuctionDB.ItemList[itemID] ~= nil then
                        vendorPrice = AuctionDB.ItemList[itemID].VendorPrice
                    else
                        vendorPrice = select(11, GetItemInfo(itemID))
                        if name and vendorPrice then
                            AuctionDB["ItemList"][itemID] = { ["Name"] = name, ["VendorPrice"] = vendorPrice }
                        end
                    end
                end

                local price = buyoutPrice / count
                if vendorPrice and vendorPrice - price > 100 and price > 0 then
                    print(name, vendorPrice, price, owner)
                    table.insert(SnipList, name)
                end

                DBScan[i] = { ["Price"] = price, ["Amount"] = count, ["ItemID"] = itemID,
                    ["ItemLink"] = link, ["Quality"] = quality }
                if not next(inProgress) then
                    inProgress = {}
                    EndScan()
                end
            end)
        end

        prosessed = prosessed + 1
        -- Delay(.001)
    end

    if not next(inProgress) then
        EndScan()
    end
    -- print(#DBScan)


end

function EndScan()
    for _, offer in pairs(DBScan) do
        if offer.Quality > 0 then
            local ItemID = offer.ItemID

            local variant = select(2, ExtractLink(offer.ItemLink))
            -- local variant = string.gsub(link, tostring(ItemID), "")
            -- print(variant)
            -- print(ItemID, variant)
            if DBTemp[ItemID] == nil then
                DBTemp[ItemID] = {}
            end
            if DBTemp[ItemID][variant] == nil then
                DBTemp[ItemID][variant] = {}
            end
            table.insert(DBTemp[ItemID][variant], offer)
            -- print(DBTemp[ItemID])
        end
    end

    -- print(#DBTemp)

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
    -- print(#AuctionDB)

    endTime = time()

    AuctionDB["ASLastScan"] = endTime

    Pwc("扫描结束: " .. listCount .. " 件商品")
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

---core


AsInit()
AsDebugActive = true

ASWaitingForAh = false
ASAuctionHouseWindowOpen = false
AuctionDB = _G.AuctionDB


if AuctionDB == nil then
    AuctionDB = {}
    AuctionDB["ASItemList"] = {}
    AuctionDB["ASItemList"][Server] = {}
end
if AuctionDB["ASItemList"] == nil then
    AuctionDB["ASItemList"] = {}
    AuctionDB["ASItemList"][Server] = {}
end
if AuctionDB["ASItemList"][Server] == nil then
    AuctionDB["ASItemList"][Server] = {}
end
if AuctionDB["ItemList"] == nil then
    AuctionDB["ItemList"] = {}
end

if AuctionDB["ASLastScan"] == nil then
    AuctionDB["ASLastScan"] = GetTime()
end




--- event

local function MyAddonCommands(msg, editbox)
    -- pattern matching that skips leading whitespace and whitespace between cmd and args
    -- any whitespace at end of args is retained
    local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
    if cmd == "scan" then
        AsScan()
    end
end

SLASH_AUCTIONSCAN1 = '/as'

SlashCmdList["AUCTIONSCAN"] = MyAddonCommands

local AhClosed = "AUCTION_HOUSE_CLOSED"
local AhOpened = "AUCTION_HOUSE_SHOW"
snip_timer, curr = nil, nil
function OnEvent(self, event, msg, from, ...)
    if (event == AhClosed) then
        ASAuctionHouseWindowOpen = false
        snip_timer:Cancel()
    end
    if (event == AhOpened) then
        ASAuctionHouseWindowOpen = true
        buttonA = ScanButton()
        buttonB = SnipButton()
        buttonB:Disable()
        snip_timer = C_Timer.NewTicker(
            1,
            function()
                if not isScaning then
                    -- print('狙击列表剩余：', #SnipList)
                    if SnipList and #SnipList > 0 and curr == nil then
                        print(SnipList[0])
                        curr = SnipList[0]
                        SnipList[0] = nil
                        Query("")
                        buttonB:Enable()

                    else
                    end


                end

            end
        )
    end

end

local f = CreateFrame("Frame")
f:RegisterEvent(AhClosed)
f:RegisterEvent(AhOpened)
f:SetScript("OnEvent", OnEvent)



-- ui

function ScanButton()
    local b = CreateFrame("Button", "AsScanButton", AuctionFrameBrowse, "UIPanelButtonTemplate")
    b:SetSize(75, 22) -- width, height
    b:SetText("扫描")
    b:SetPoint("BOTTOMLEFT", 25, 43);
    b:SetScript("OnClick", function()
        AsScan()
    end)
    return b
end

function SnipButton()
    local b = CreateFrame("Button", "AsSnipButton", AuctionFrameBrowse, "UIPanelButtonTemplate")
    b:SetSize(75, 22) -- width, height
    b:SetText("狙击")
    b:SetPoint("BOTTOMLEFT", 110, 43);
    b:SetScript("OnClick", function()
        AsSnip()
    end)
    return b
end
