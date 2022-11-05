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
local MerchantOpened = "MERCHANT_SHOW"

function OnEvent(self, event, msg, from, ...)
    if(event == AhClosed) then
        ASAuctionHouseWindowOpen = false
    end
    if(event == AhOpened) then
        ASAuctionHouseWindowOpen = true
        ScanButton()
    end
    if(event == MerchantOpened) then
        AsDebug("Merchant open")
        AsUpdateVendorList()
    end
end




local f = CreateFrame("Frame")
f:RegisterEvent(AhClosed)
f:RegisterEvent(AhOpened)
f:RegisterEvent(MerchantOpened)
f:SetScript("OnEvent", OnEvent)