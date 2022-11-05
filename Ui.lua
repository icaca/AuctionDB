function ScanButton()
	local b = CreateFrame("Button", "AsScanButton", AuctionFrameBrowse, "UIPanelButtonTemplate")
	b:SetSize(150 ,22) -- width, height
	b:SetText("Auction House Scan")
	b:SetPoint("BOTTOMLEFT", 25, 43);
	b:SetScript("OnClick", function()
	    AsScan()
	end)
end