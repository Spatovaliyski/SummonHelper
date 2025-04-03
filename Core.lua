-- Core.lua
SummonHelper = {}
SummonHelper.__index = SummonHelper

function SummonHelper:New()
    local self = setmetatable({}, SummonHelper)
    self.playerResponses = {}
    self:InitializeEvents()
    return self
end

function SummonHelper:InitializeEvents()
    self.frame = CreateFrame("Frame")
    self.frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    self.frame:RegisterEvent("CHAT_MSG_PARTY")
    self.frame:RegisterEvent("CHAT_MSG_RAID")
    self.frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
    self.frame:RegisterEvent("CHAT_MSG_RAID_WARNING")
    
    self.frame:SetScript("OnEvent", function(_, event, ...)
        if event == "GROUP_ROSTER_UPDATE" then
            self:UpdateRaidList()
        elseif event:match("CHAT_MSG_") then
            self:CheckForSummonRequest(event, ...)
        end
    end)
end

function SummonHelper:ResetResponses()
    wipe(self.playerResponses)
    self:UpdateRaidList()
end

-- Define a placeholder UpdateRaidList method
function SummonHelper:UpdateRaidList()
  -- Will be overridden by RaidList.lua
  if SummonHelperRaidList and SummonHelperRaidList.UpdateList then
      SummonHelperRaidList:UpdateList(self.playerResponses)
  end
end

function SummonHelper:CheckForSummonRequest(event, msg, sender)
    -- Move existing code here, adjusted for class structure
    local playerName = SummonHelperTextUtils:GetPlayerNameWithoutRealm(sender)
    if self:IsSummonRequest(msg, event) then
        if self.playerResponses[playerName] then
            return  -- Ignore if already responded
        end
        
        print("|cFF33FF33SummonHelper:|r " .. playerName .. " requested a summon: \"" .. msg .. "\"")
        self.playerResponses[playerName] = true
        PlaySound(SOUNDKIT.READY_CHECK, "Master")
        self:UpdateRaidList()
    end
end

function SummonHelper:IsSummonRequest(msg, event)
    -- Logic to determine if a message is a summon request
    local lowerMsg = string.lower(msg)
    
    if lowerMsg:match("^summonhelper: summoning") then
        return false
    end
    
    -- Also ignore other patterns that might indicate a summon is already happening
    if lowerMsg:match("^attempting to summon") or lowerMsg:match("^summoning ") then
        return false
    end
    
    for _, phrase in ipairs(SummonHelperConfig.SummonPhrases) do
        if lowerMsg == phrase then
            return true
        end
    end
    
    return false
end

-- Global initialization
local function InitializeAddon()
  -- Create our global addon instance
  _G.SummonHelperCore = SummonHelper:New()
  print("|cFF33FF33SummonHelper:|r Core initialized")
  
  -- Delay the UI initialization and first update
  C_Timer.After(0.5, function()
      if SummonHelperUI and SummonHelperUI.Initialize then
          SummonHelperUI:Initialize()
          print("|cFF33FF33SummonHelper:|r UI initialized")
          
          if _G.SummonHelperCore and _G.SummonHelperCore.UpdateRaidList then
            _G.SummonHelperCore:UpdateRaidList()
            print("|cFF33FF33SummonHelper:|r Initial raid list updated")
          end
      else
          print("|cFFFF3333SummonHelper:|r Error: UI module not found")
      end
  end)
end

-- Register slash commands
SLASH_SUMMONHELPER1 = "/sh"
SLASH_SUMMONHELPER2 = "/summonhelper"
SlashCmdList["SUMMONHELPER"] = function()
    SummonHelperUI:ToggleMainFrame()
end

-- Call initialization when addon loads
InitializeAddon()