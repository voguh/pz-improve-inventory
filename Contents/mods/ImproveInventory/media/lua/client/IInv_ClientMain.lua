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

local bookCanRead = getTexture("media/ui/book_can_read.png")
local bookRead = getTexture("media/ui/book_read.png")
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
    local xx = self.column2 - (16 + 4)
    local gap = 0

    for i, inv in ipairs(self.itemslist) do
        local item = inv.items[1]
        local yy = (i * self.itemHgt) + gap

        if item:isRecordedMedia() then
            if recordedMedia:hasListenedToAll(playerObj, item:getMediaData()) then
                self:drawTexture(bookRead, xx, yy, 1, 1, 1, 1)
            -- elseif not recordedMedia:hasListenedToAll(playerObj, item:getMediaData()) then
            --     self:drawTexture(bookCanRead, xx, yy, 1, 1, 0.420, 0.420)
            end
        elseif instanceof(item, "Literature") then
            local _type = item:getFullType()
            local teachesRecipes = item:getTeachedRecipes()

            local skillBook = SkillBook[item:getSkillTrained()]
            if skillBook ~= nil then
                local pages = item:getNumberOfPages()
                local readPages = playerObj:getAlreadyReadPages(_type)
                local playerSkillLevel = playerObj:getPerkLevel(skillBook.perk)
                local maxLevel = item:getMaxLevelTrained()

                if playerSkillLevel >= maxLevel or readPages == pages then
                    self:drawTexture(bookRead, xx, yy, 1, 1, 1, 1)
                elseif readPages ~= pages and playerSkillLevel >= maxLevel - 2 then
                    self:drawTexture(bookCanRead, xx, yy, 1, 1, 1, 1)
                end
            elseif teachesRecipes then
                local playerAlreadyRead = playerObj:getAlreadyReadBook()
                local playerKnownRecipes = playerObj:getKnownRecipes()

                if playerAlreadyRead:contains(_type) and playerKnownRecipes:containsAll(teachesRecipes) then
                    self:drawTexture(bookRead, xx, yy, 1, 1, 1, 1)
                elseif not playerKnownRecipes:containsAll(teachesRecipes) then
                    self:drawTexture(bookCanRead, xx, yy, 1, 1, 1, 1)
                elseif not playerAlreadyRead:contains(_type) then
                    self:drawTexture(bookCanRead, xx, yy, 1, 1, 1, 1)
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
    local top = hdrHgt + y * self.itemHgt + yOffset
    local fgBar = {r=ghc:getR(), g=ghc:getG(), b=ghc:getB(), a=1}
    local fgText = {r=0.6, g=0.8, b=0.5, a=0.6}

    if red then
        fgText = {r=0.0, g=0.0, b=0.5, a=0.7}
    end

    if instanceof(item, "HandWeapon") or lightBulbTable[item:getFullType()] or item:getMechanicType() ~= 0 then
        local cond = item:getCondition()
        local condMax = item:getConditionMax()
        local progress = cond / condMax
        local text = string.format("%d / %d (%d%s)", cond, condMax, progress * 100, "%")
        return self:drawTextAndProgressBar(text, progress, xOffset, top, fgText, fgBar)
    elseif instanceof(item, "Drainable") then
        local uses = item:getDrainableUsesInt()
        local delta = math.ceil(1 / item:getUseDelta())
        local progress = item:getUsedDelta()
        local text = string.format("%d / %d (%d%s)", uses, delta, progress * 100, "%")
        return self:drawTextAndProgressBar(text, progress, xOffset, top, fgText, fgBar)
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
