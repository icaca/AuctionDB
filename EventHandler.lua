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
snip_timer = nil
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
                    if SnipList and #SnipList > 0 then
                        -- print(SnipList[0])
                        -- local curr = SnipList[0]
                        -- SnipList[0] = nil
                    else
                    end

                    buttonB:Enable()
                end

            end
        )
    end

end

local f = CreateFrame("Frame")
f:RegisterEvent(AhClosed)
f:RegisterEvent(AhOpened)
f:SetScript("OnEvent", OnEvent)
