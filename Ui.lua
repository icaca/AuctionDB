function ScanButton()
	local b = CreateFrame("Button", "AsScanButton", AuctionFrameBrowse, "UIPanelButtonTemplate")
	b:SetSize(50 ,22) -- width, height
	b:SetText("扫描")
	b:SetPoint("BOTTOMLEFT", 25, 43);
	b:SetScript("OnClick", function()
	    AsScan()
	end)
	return b
end

function SnipButton()
	local b = CreateFrame("Button", "AsSnipButton", AuctionFrameBrowse, "UIPanelButtonTemplate")
	b:SetSize(50 ,22) -- width, height
	b:SetText("狙击")
	b:SetPoint("BOTTOMLEFT", 80, 43);
	b:SetScript("OnClick", function()
	    AsSnip()
	end)
	return b
end