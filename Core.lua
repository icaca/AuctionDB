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
if AuctionDB["ASItemList"][Server] ==nil then
    AuctionDB["ASItemList"][Server] = {}
end
if AuctionDB["ItemList"] == nil then
    AuctionDB["ItemList"] = {}
end

if AuctionDB["ASLastScan"] == nil then
    AuctionDB["ASLastScan"] = GetTime()
end

