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
 
--ChatFrame1:AddMessage(Color("Loaded:",'red').." Auction Scan v1.0.0 - By "..Color("Urutzi-Earthshaker",'blue'))
AsInit()
AsDebugActive = false

ASWaitingForAh = false
ASAuctionHouseWindowOpen = false
ASItemList = _G.ASItemList
if ASItemList == nil then
    ASItemList = {}
end
if AsVendorList == nil then
    AsVendorList = {}
end
if ASLastScan == nil then
    ASLastScan = GetTime()
end