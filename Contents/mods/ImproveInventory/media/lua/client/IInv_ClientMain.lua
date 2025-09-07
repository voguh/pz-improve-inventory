--[[
/*!******************************************************************************
 * Improve Inventory
 * Copyright (C) 2025 Voguh <voguhofc@protonmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * This Source Code Form is "Incompatible With Secondary Licenses", as
 * defined by the Mozilla Public License, v. 2.0.
 ******************************************************************************/
]]

local readDot = getTexture("media/ui/read_dot.png")
local ghc = getCore():getGoodHighlitedColor()
local bhc = getCore():getBadHighlitedColor()
local lightBulbTable = {
    ["Base.LightBulb"] = true,
    ["Base.LightBulbRed"] = true,
    ["Base.LightBulbGreen"] = true,
    ["Base.LightBulbBlue"] = true,
    ["Base.LightBulbYellow"] = true,
    ["Base.LightBulbCyan"] = true,
    ["Base.LightBulbMagenta"] = true,
    ["Base.LightBulbOrange"] = true,
    ["Base.LightBulbPurple"] = true,
    ["Base.LightBulbPink"] = true
}

--****************************************************************************--

local ISInventoryPane = ISInventoryPane

local originalRender = ISInventoryPane.render
function ISInventoryPane:render()
    local recordedMedia = getZomboidRadio():getRecordedMedia()
    local playerObj = getSpecificPlayer(self.player)
    local xx = self.column2 - 16
    local gap = 0

    for i, inv in ipairs(self.itemslist) do
        local item = inv.items[1]
        local yy = (i * self.itemHgt) + gap

        if item:isRecordedMedia() then
            if recordedMedia:hasListenedToAll(playerObj, item:getMediaData()) then
                self:drawTexture(readDot, xx, yy, 1, 0.318, 0.812, 0.400) -- rgb(81, 207, 102)
            -- elseif not recordedMedia:hasListenedToAll(playerObj, item:getMediaData()) then
            --     self:drawTexture(readDot, xx, yy, 1, 1, 0.420, 0.420) -- rgb(255, 107, 107)
            end
        elseif instanceof(item, "Literature") then
            local _type = item:getFullType()
            local teachesRecipes = item:getTeachedRecipes()

            if SkillBook[item:getSkillTrained()] then
                local pages = item:getNumberOfPages()
                if pages > 0 then
                    if playerObj:getAlreadyReadPages(_type) == pages then
                        self:drawTexture(readDot, xx, yy, 1, 0.318, 0.812, 0.400) -- rgb(81, 207, 102)
                    elseif playerObj:getAlreadyReadPages(_type) ~= pages then
                        self:drawTexture(readDot, xx, yy, 1, 1, 0.420, 0.420) -- rgb(255, 107, 107)
                    end
                end
            elseif teachesRecipes then
                if playerObj:getAlreadyReadBook():contains(_type) and playerObj:getKnownRecipes():containsAll(teachesRecipes) then
                    self:drawTexture(readDot, xx, yy, 1, 0.318, 0.812, 0.400) -- rgb(81, 207, 102)
                elseif not playerObj:getKnownRecipes():containsAll(teachesRecipes) then
                    self:drawTexture(readDot, xx, yy, 1, 1, 0.573, 0.169) -- rgb(255, 146, 43)
                elseif not playerObj:getAlreadyReadBook():contains(_type) then
                    self:drawTexture(readDot, xx, yy, 1, 1, 0.420, 0.420) -- rgb(255, 107, 107)
                end
            end
        end

        if not self.collapsed[item:getName()] then
            gap = gap + self.itemHgt*(#inv.items-1)
        end
    end

    originalRender(self)
end

local originalDrawItemDetails = ISInventoryPane.drawItemDetails
function ISInventoryPane:drawItemDetails(item, y, xOffset, yOffset, red)
    if item == nil then
        return;
    end

    local hdrHgt = self.headerHgt
    local top = hdrHgt + y * self.itemHgt + xOffset
    local fgBar = {r=ghc:getR(), g=ghc:getG(), b=ghc:getB(), a=1}
    local fgText = {r=0.6, g=0.8, b=0.5, a=0.6}

    if red then
        fgText = {r=0.0, g=0.0, b=0.5, a=0.7}
    end

    if instanceof(item, "HandWeapon") or lightBulbTable[item:getFullType()] then
        local progress = item:getCondition() / item:getConditionMax()
        local text = getText("IGUI_invpanel_Condition") .. ": " .. round(progress * 100) .. "%"
        return self:drawTextAndProgressBar(text, progress, xOffset, top, fgText, fgBar)
    elseif instanceof(item, "Drainable") then
        local progress = item:getUsedDelta()
        local text = getText("IGUI_invpanel_Remaining") .. ": " .. round(progress * 100) .. "%"
        return self:drawTextAndProgressBar(text, item:getUsedDelta(), xOffset, top, fgText, fgBar)
    elseif item:getMeltingTime() > 0 then
        local progress = item:getMeltingTime() / 100
        local text = getText("IGUI_invpanel_Melting") .. ": " .. round(progress * 100) .. "%"
        return self:drawTextAndProgressBar(text, progress, xOffset, top, fgText, fgBar)
    elseif instanceof(item, "Food") then
        if item:isIsCookable() and not item:isFrozen() and item:getHeat() > 1.6 then
            local xx = 40 + 30 + xOffset
            local yy = top + (self.itemHgt - self.fontHgt) / 2
            local ct = item:getCookingTime()
            local mtc = item:getMinutesToCook()
            local mtb = item:getMinutesToBurn()
            local progress = ct / mtc

            local text = getText("IGUI_invpanel_Cooking") .. ": " .. round(progress * 100) .. "%"
            if ct > mtb then
                text = getText("IGUI_invpanel_Burnt")
            elseif ct > mtc then
                progress = (ct - mtc) / (mtb - mtc)
                text = getText("IGUI_invpanel_Burning") .. ": " .. round(progress * 100) .. "%"
                fgBar.r = bhc:getR()
                fgBar.g = bhc:getG()
                fgBar.b = bhc:getB()
            end

            if item:isBurnt() then
                return self:drawText(text, xx, yy, fgText.a, fgText.r, fgText.g, fgText.b, self.font)
            else
                return self:drawTextAndProgressBar(text, progress, xOffset, top, fgText, fgBar)
            end
        elseif item:getFreezingTime() > 0 then
            local progress = item:getFreezingTime() / 100
            local text = getText("IGUI_invpanel_FreezingTime") .. ": " .. round(progress * 100) .. "%"
            return self:drawTextAndProgressBar(text, progress, xOffset, top, fgText, fgBar)
        else
            local hunger = item:getHungerChange()
            if (hunger ~= 0) then
                local progress = (-hunger) / 1.0
                local text = getText("IGUI_invpanel_Nutrition") .. ": " .. round(progress * 100) .. "%"
                return self:drawTextAndProgressBar(text, progress, xOffset, top, fgText, fgBar)
            end
        end
    end

    originalDrawItemDetails(self, item, y, xOffset, yOffset, red)
end
