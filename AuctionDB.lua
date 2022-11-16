FactionGroup = string.sub(select(1, UnitFactionGroup('player')), 1, 1)
RealmString = GetRealmName()
ASAuctionHouseWindowOpen = false
Server = RealmString .. '-' .. FactionGroup
SLASH_ADB_Commands1 = "/ahdb"
AsDebugActive = true
ASWaitingForAh = false

local StartFlag = false

table.clone = table.clone or function(t)
    local result = {}
    for i = 1, #t do result[i] = t[i] end
    return result
end

-- buttonA, buttonB = nil, nil

SlashCmdList["ADB_Commands"] = function(msg)
    AsScan()
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
    if AHDB == nil then
        AHDB = {}
    end
    if AHDB[Server] == nil then
        AHDB[Server] = {}
    end
    if AHDB["Items"] == nil then
        AHDB["Items"] = {}
    end

    if AHDB["LastScan"] == nil then
        AHDB["LastScan"] = GetTime()
    end
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
    if AHDB["ASLastScan"] == nil then
        AHDB["ASLastScan"] = theTime
    end

    timeLeft = AHDB["ASLastScan"] + (15 * 60) - theTime
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

function Query(name, page)
    if IsAtAuctionHouse() and CanSendAuctionQuery() then
        local minLevel = nil
        local maxLevel = nil
        local isUsable = 0
        local qualityIndex = 0
        local getAll = false
        local exactMatch = false
        SortAuctionClearSort("list")
        QueryAuctionItems(name, minLevel, maxLevel,
            page, isUsable, qualityIndex, getAll, exactMatch)
    end
end

function QueryAll()
    if IsAtAuctionHouse() then
        local name = ""
        local minLevel = nil
        local maxLevel = nil
        local isUsable = 0
        local qualityIndex = 0
        local page = 0
        local getAll = true
        local exactMatch = false

        QueryAuctionItems(name, minLevel, maxLevel,
            page, isUsable, qualityIndex, getAll, exactMatch)
    end
end

function AsDebug(msg)
    if AsDebugActive then
        print(msg)
    end
end

DBScan, DBTemp = {}, {}

-- function ExtractLink(text)
--     return string.match(text, [[|Hitem:%d+:([^:]*):([^|]*)|h([^|]*)|h]]);
-- end

-- function GetItemString(link)
--     local raw = select(2, ExtractLink(link))
--     return select(11, strsplit(":", raw, 11))
-- end

function ProsessScan()
    ASWaitingForAh   = true
    local inProgress = {}
    local prosessed  = 1

    local batch, listCount = GetNumAuctionItems("list");

    LastScan = time()
    for i = 1, listCount do
        local name, texture, count, quality, canUse, level, levelColHeader, minBid,
        minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner,
        ownerFullName, saleStatus, itemID, hasAllInfo = GetAuctionItemInfo("list", i)

        local link = GetAuctionItemLink("list", i)

        local vendorPrice = AsGetVendorSellPrice(itemID)
        -- print(name, vendorPrice, owner)

        if buyoutPrice and itemID and quality and type(quality) == "number" and count > 0 and buyoutPrice > 0 and
            itemID > 0 and link then

            local price = buyoutPrice / count
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

                local price = buyoutPrice / count

                DBScan[i] = { ["Price"] = price, ["Amount"] = count, ["ItemID"] = itemID,
                    ["ItemLink"] = link, ["Quality"] = quality }
                if not next(inProgress) and prosessed >= listCount then
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
end

function EndScan()
    for _, offer in pairs(DBScan) do
        if offer.Quality > 0 then
            local ItemID = offer.ItemID

            if DBTemp[ItemID] == nil then
                DBTemp[ItemID] = {}
            end

            table.insert(DBTemp[ItemID], offer)
        end

    end

    if AHDB[Server] == nil then
        AHDB[Server] = {}
    end

    for itemID, _ in pairs(DBTemp) do
        local price, amount, minBuyout = analyze(DBTemp[itemID])
        if amount > 3 then
            if AHDB[Server][itemID] == nil then
                AHDB[Server][itemID] = {}
            end
            AHDB[Server][itemID] = { ["Price"] = price, ["Amount"] = amount, ["MinBuyout"] = minBuyout,
                ["LastSeen"] = LastScan,
            }
        end
    end

    endTime = time()
    AHDB["LastScan"] = endTime
    ASWaitingForAh = false
    Pwc("扫描结束")
    buttonC:Enable()
end

function analyze(data)
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
    local sum, count, c, minprice = 0, 0, nil, nil
    for k, item in pairs(t) do --归一化,范围-1.5 —— 1.5 之间
        v = item.Price
        c = (v - avg) / b
        if c >= -1.5 and c <= 1.5 then
            if minprice == nil or minprice < item.Amount then
                minprice = item.Amount
            end
            sum = sum + v * item.Amount
            count = count + item.Amount
            -- print(5,k,v,c,b,item.Amount)
        end
    end
    -- print(6,sum/count,count,time(),Amount)
    -- _his = table.clone(his)
    -- table.insert(_his, { ["Price"] = math.floor(sum / count), ["Amount"] = Amount, ["LastSeen"] = date })
    return math.floor(sum / count), count, minprice
    -- return calcMarketPriceByMultipleVals(_his),Amount
end

function AsScan()
    if IsAtAuctionHouse() and CanQuery() then
        Pwc("扫描开始")
        buttonC:Disable()
        QueryAll()
        C_Timer.After(1, ProsessScan)
    end
end

function AsSnip()
    -- print("狙击！")
    -- buttonB:Disable()
    local batch, listCount = GetNumAuctionItems("list");

    -- print(batch, listCount)
    -- for i = #list, 1, -1 do
    for i = batch, 1, -1 do
        local name, texture, count, quality, canUse, level, levelColHeader, minBid,
        minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner,
        ownerFullName, saleStatus, itemID, hasAllInfo = GetAuctionItemInfo("list", i)
        -- local link = GetAuctionItemLink("list", i)

        -- print(i, name, buyoutPrice, vendorPrice)
        -- local price = buyoutPrice / count
        if buyoutPrice and buyoutPrice > 0 then
            local snipprice = DB.SNIP[itemID]
            if snipprice and snipprice > 0 then
                snipprice = snipprice * count * 10000
                if snipprice and snipprice - buyoutPrice >= 0 then
                    print(i, name, buyoutPrice, vendorPrice)
                    PlaceAuctionBid("list", i, buyoutPrice)
                    return
                end
            end

            local vendorPrice = AsGetVendorSellPrice(itemID) * count
            if vendorPrice and vendorPrice - buyoutPrice >= 0 then
                print(i, name, buyoutPrice, vendorPrice)
                PlaceAuctionBid("list", i, buyoutPrice)
                return
            end
        end
    end
end

---core

AsInit()

--- event

local function MyAddonCommands(msg, editbox)
    local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
    if cmd == "scan" then
        AsScan()
    end
end

SLASH_AUCTIONSCAN1 = '/as'

SlashCmdList["AUCTIONSCAN"] = MyAddonCommands
local Inited = false
local AhClosed = "AUCTION_HOUSE_CLOSED"
local AhOpened = "AUCTION_HOUSE_SHOW"
local snip_timer, PAGE = nil, 1
function OnEvent(self, event, msg, from, ...)
    if (event == AhClosed) then
        if Inited == false then
            Inited = true
        end
        ASAuctionHouseWindowOpen = false

        snip_timer:Cancel()
    end
    if (event == AhOpened) then
        ASAuctionHouseWindowOpen = true
        if not Inited then
            buttonA = ScanButton()
            buttonB = SnipButton()
            buttonC = StartButton()
        end
        buttonB:Disable()
        snip_timer = C_Timer.NewTicker(
            .3,
            function()
                if StartFlag and not ASWaitingForAh then
                    PAGE = max(ceil(select(2, GetNumAuctionItems("list")) / NUM_AUCTION_ITEMS_PER_PAGE) - 1, 0)
                    Query("", PAGE)
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
    b:SetSize(55, 22) -- width, height
    b:SetText("扫描")
    b:SetPoint("BOTTOMLEFT", 70, 43);
    b:SetScript("OnClick", function()
        AsScan()
    end)
    return b
end

function SnipButton()
    local b = CreateFrame("Button", "AsSnipButton", AuctionFrameBrowse, "UIPanelButtonTemplate")
    b:SetSize(55, 22) -- width, height
    b:SetText("狙击")
    b:SetPoint("BOTTOMLEFT", 130, 43);
    b:SetScript("OnClick", function()
        AsSnip()
    end)
    return b
end

function StartButton()
    local b = CreateFrame("Button", "AsStartButton", AuctionFrameBrowse, "UIPanelButtonTemplate")
    b:SetSize(55, 22) -- width, height
    b:SetText("自动")
    b:SetPoint("BOTTOMLEFT", 10, 43);
    b:SetScript("OnClick", function()
        if StartFlag then
            b:SetText("自动")
            buttonA:Enable()
            buttonB:Disable()
            StartFlag = not StartFlag
        else
            b:SetText("停止")
            buttonA:Disable()
            buttonB:Enable()
            StartFlag = not StartFlag
        end
    end)
    return b
end
