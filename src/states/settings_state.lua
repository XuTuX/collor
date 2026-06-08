------------------------------------------------------------
-- settings_state.lua · 상점(Shop) 및 모험 맵 진행도 관리 상태 모듈
------------------------------------------------------------
local SettingsState = {}
local C = require("core.constants")
local P = C.P

-- UI 및 엔티티 컴포넌트
local Panel = require("ui.panel")
local Button = require("ui.button")
local HUD = require("ui.hud")
local JokerEntity = require("entities/joker")
local Balance = require("data.balance")
local ShopItems = require("data.shop_items")

-- 시스템 및 턴 매니저
local Audio = require("systems.audio_system")
local TurnManager = require("gameplay.turn_manager")

local G = nil
local ITEM_SLOT_COUNT = 2
local AUGMENT_SLOT_COUNT = 1

local function isAugment(item)
    return item.type == "joker"
end

local function isDeckItem(item)
    return item.type == "deck_add"
        or item.type == "deck_remove"
        or item.type == "deck_remove_color"
        or item.type == "deck_transform"
end

local function shopCardColor(item)
    if item.sold then
        return P.dim
    elseif isAugment(item) then
        return P.cMirr
    elseif item.type == "upgrade" then
        return P.cMono
    elseif isDeckItem(item) then
        return P.cStep
    end
    return P.panelBd
end

local function shopTypeLabel(item)
    if isDeckItem(item) then return "아이템" end
    if isAugment(item) then return "증강체" end
    if item.type == "upgrade" then return "반짝임" end
    return "기타"
end

local function cloneShopEntry(item)
    return {
        type = item.type,
        id = item.id,
        hand = item.hand,
        colorName = item.colorName,
        colorVal = item.colorVal,
        fromColor = item.fromColor,
        toColor = item.toColor,
        toColorVal = item.toColorVal,
        name = item.name,
        desc = item.desc,
        price = item.price,
        sold = false
    }
end

local function shuffle(list)
    for i = #list, 2, -1 do
        local j = love.math.random(1, i)
        list[i], list[j] = list[j], list[i]
    end
end

local function drawShopCard(item, ix, iy, itemW, itemH, mx, my)
    if not item then return end

    local bc = shopCardColor(item)

    if not item.sold then
        for g = 1, 3 do
            love.graphics.setColor(bc[1], bc[2], bc[3], 0.15 / g)
            love.graphics.setLineWidth(1.5 + g * 1.5)
            love.graphics.rectangle("line", ix - g, iy - g, itemW + g*2, itemH + g*2, 8, 8)
        end
    end

    love.graphics.setColor(0.25, 0.32, 0.44, 0.10)
    love.graphics.rectangle("fill", ix + 2, iy + 4, itemW, itemH, 8, 8)
    love.graphics.setColor(item.sold and {0.94,0.94,0.95} or P.panel)
    love.graphics.rectangle("fill", ix, iy, itemW, itemH, 8, 8)
    love.graphics.setColor(1, 1, 1, item.sold and 0.25 or 0.70)
    love.graphics.rectangle("fill", ix + 1, iy + 1, itemW - 2, 50, 7, 7)

    love.graphics.setColor(bc)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", ix, iy, itemW, itemH, 8, 8)
    love.graphics.rectangle("fill", ix, iy, itemW, 5, 4, 4)

    if item.sold then
        love.graphics.setFont(HUD.fL)
        love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.3)
        Button.txtC("품절", ix + itemW/2, iy + itemH/2 - 10, P.dim, HUD.fL)
        return
    end

    Button.txtC(item.name, ix + itemW/2, iy + 14, P.text, HUD.fM)
    Button.pill(ix + 16, iy + 34, 100, 20, shopTypeLabel(item), bc, HUD.fS)

    JokerEntity.drawIcon(item, ix + itemW / 2, iy + 96, bc)

    local descY = iy + 138
    for line in string.gmatch(item.desc, "[^\n]+") do
        Button.txt(line, ix + 16, descY, P.dim, HUD.fS)
        descY = descY + 18
    end

    local bx = ix + 15
    local by = iy + itemH - 50
    local bw = itemW - 30
    local bh = 34
    local hovBuy = mx >= bx and mx <= bx+bw and my >= by and my <= by+bh
    local canAfford = G.gold >= item.price
    Button.draw(bx, by, bw, bh, "$" .. item.price, canAfford, hovBuy, HUD.fM)
end

local function drawJokerWatermark(jx, jy, jw, jh, accentColor)
    local cx, cy = jx + jw/2, jy + jh/2
    local rad = 22
    
    -- Ears/Horns
    love.graphics.setColor(accentColor[1]*0.6, accentColor[2]*0.6, accentColor[3]*0.6, 0.12)
    love.graphics.polygon("fill", cx - 20, cy - 8, cx - 28, cy - 24, cx - 12, cy - 18)
    love.graphics.polygon("fill", cx + 20, cy - 8, cx + 28, cy - 24, cx + 12, cy - 18)
    
    -- Body
    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.10)
    love.graphics.circle("fill", cx, cy, rad)
    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.15)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", cx, cy, rad)
    
    -- Eyes
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.ellipse("fill", cx - 7, cy - 3, 3, 5)
    love.graphics.ellipse("fill", cx + 7, cy - 3, 3, 5)
end

local function drawBagWatermark(dx, dy, dw, dh)
    local cx, cy = dx + dw/2, dy + dh/2
    local w, h = 32, 42
    
    love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], 0.08)
    -- Back card
    love.graphics.rectangle("fill", cx - w/2 + 4, cy - h/2 - 4, w, h, 4, 4)
    -- Front card
    love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], 0.10)
    love.graphics.rectangle("fill", cx - w/2, cy - h/2, w, h, 4, 4)
    love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], 0.15)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", cx - w/2, cy - h/2, w, h, 4, 4)
end

function SettingsState.enter(gameInstance)
    G = gameInstance
end

function SettingsState.exit()
end

function SettingsState.update(dt)
end

-- 상점 화면 렌더링 (S.shop 이식)
function SettingsState.draw()
    if not G then return end
    
    love.graphics.setColor(0.04, 0.05, 0.08, 0.88)
    love.graphics.rectangle("fill", 0, 0, C.SW, C.SH)
    
    local mx, my = love.mouse.getPosition()
    
    -- 1. 왼쪽 패널 (모험 관문 진행도)
    local lx, ly, lw, lh = 80, 80, 500, 560
    Panel.draw(lx, ly, lw, lh, 14)
    Button.txt("모험 관문", lx + 30, ly + 24, P.text, HUD.fX)
    Button.txt("현재 월드: " .. G.ante, lx + 30, ly + 58, P.dim, HUD.fS)
    love.graphics.setColor(P.panelBd)
    love.graphics.line(lx + 20, ly + 78, lx + lw - 20, ly + 78)
    
    local stages = {
        {name="쉬운 관문 (Small Stage)"},
        {name="도전 관문 (Big Stage)"},
        {name="특별 관문 (Boss Stage)"}
    }
    
    local startY = ly + 95
    local boxH = 95
    local gapY = 15
    
    for i = 1, 3 do
        local sy = startY + (i - 1) * (boxH + gapY)
        local sx = lx + 30
        local sw = lw - 60
        
        local targetScore = Balance.getTargetScore(G.ante, i, G.bossGimmick)
        local state = "locked"
        if i < G.stage then
            state = "cleared"
        elseif i == G.stage then
            state = "current"
        end
        
        if state == "cleared" then
            love.graphics.setColor(0.95, 0.96, 0.95)
            love.graphics.rectangle("fill", sx, sy, sw, boxH, 8, 8)
            love.graphics.setColor(0.80, 0.88, 0.80)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", sx, sy, sw, boxH, 8, 8)
            
            Button.txt(stages[i].name, sx + 20, sy + 18, P.dim, HUD.fM)
            Button.txt("목표 점수: " .. targetScore, sx + 20, sy + 44, P.dim, HUD.fS)
            Button.pill(sx + sw - 85, sy + 16, 65, 20, "클리어", P.cMono, HUD.fS)
        elseif state == "current" then
            love.graphics.setColor(0.93, 0.95, 1.00)
            love.graphics.rectangle("fill", sx, sy, sw, boxH, 8, 8)
            love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], 0.9)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", sx, sy, sw, boxH, 8, 8)
            
            Button.txt(stages[i].name, sx + 20, sy + 18, P.text, HUD.fM)
            Button.txt("목표 점수: " .. targetScore, sx + 20, sy + 44, P.gold, HUD.fS)
            
            if i == 3 then
                local desc = require("entities/modifier").getBossGimmickDesc(G.bossGimmick)
                Button.txt("특별 규칙: " .. desc, sx + 20, sy + 66, P.mult, HUD.fS)
            end
            
            Button.pill(sx + sw - 85, sy + 16, 65, 20, "도전 중", P.btnR, HUD.fS)
        else
            love.graphics.setColor(0.97, 0.97, 0.98)
            love.graphics.rectangle("fill", sx, sy, sw, boxH, 8, 8)
            love.graphics.setColor(P.panelBd[1], P.panelBd[2], P.panelBd[3], 0.25)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", sx, sy, sw, boxH, 8, 8)
            
            Button.txt(stages[i].name, sx + 20, sy + 22, {0.62, 0.65, 0.70}, HUD.fM)
            Button.txt("목표 점수: " .. targetScore, sx + 20, sy + 48, {0.62, 0.65, 0.70}, HUD.fS)
            
            if i == 3 then
                local desc = require("entities/modifier").getBossGimmickDesc(G.bossGimmick)
                Button.txt("특별 규칙: " .. desc, sx + 20, sy + 68, {0.72, 0.75, 0.80}, HUD.fS)
            end
            Button.pill(sx + sw - 85, sy + 16, 65, 20, "대기 중", P.btnG, HUD.fS)
        end
    end
    
    local nW, nH = lw - 60, 50
    local nX = lx + 30
    local nY = ly + lh - 80
    local hovNext = mx >= nX and mx <= nX+nW and my >= nY and my <= nY+nH
    Button.draw(nX, nY, nW, nH, "관문 시작!", true, hovNext, HUD.fL)
    Button.txtC("Enter / Space", lx + lw / 2, nY + nH + 6, P.dim, HUD.fS)
    
    -- 2. 오른쪽 패널 (상점)
    local rx, ry, rw, rh = 620, 80, 580, 560
    Panel.draw(rx, ry, rw, rh, 14)
    Button.txt("컬러 상점", rx + 30, ry + 24, P.text, HUD.fX)
    Button.txt("코인으로 능력과 주머니를 강화하세요.", rx + 30, ry + 58, P.dim, HUD.fS)
    Button.pill(rx + rw - 104, ry + 24, 74, 24, "$" .. G.gold, P.gold, HUD.fM)
    
    if G.noticeTimer > 0 then
        local nc = G.noticeKind == "ok" and P.cMono or P.btnR
        local nw = math.min(260, HUD.fS:getWidth(G.noticeText) + 24)
        Button.pill(rx + rw - 118 - nw, ry + 25, nw, 22, G.noticeText, nc, HUD.fS)
    end
    
    love.graphics.setColor(P.panelBd)
    love.graphics.line(rx + 20, ry + 78, rx + rw - 20, ry + 78)
    
    local startX = rx + 30
    local itemW = 160
    local itemH = 245
    local gap = 20

    Button.txt("아이템 / 반짝임", startX, ry + 92, P.text, HUD.fS)
    for i = 1, ITEM_SLOT_COUNT do
        local ix = startX + (i-1) * (itemW + gap)
        drawShopCard(G.shopItems[i], ix, ry + 120, itemW, itemH, mx, my)
    end

    local augmentX = startX + ITEM_SLOT_COUNT * (itemW + gap)
    Button.txt("증강체", augmentX, ry + 92, P.text, HUD.fS)
    for i = 1, AUGMENT_SLOT_COUNT do
        local ix = augmentX + (i-1) * (itemW + gap)
        drawShopCard(G.shopAugments[i], ix, ry + 120, itemW, itemH, mx, my)
    end
    
    -- 보유 현황 패널 (도우미 + 주머니 개수)
    local sx = rx + 30
    local sy = ry + 390
    local sw = rw - 60
    local sh = 135
    
    love.graphics.setColor(0.08, 0.10, 0.18, 0.4)
    love.graphics.rectangle("fill", sx, sy, sw, sh, 8, 8)
    love.graphics.setColor(P.panelBd)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", sx, sy, sw, sh, 8, 8)
    
    -- 보유 증강체 리스트
    love.graphics.setFont(HUD.fS)
    love.graphics.setColor(P.text)
    love.graphics.print("보유 증강체 (" .. #G.jokers .. "/3)", sx + 15, sy + 12)
    
    local jw = 110
    local jh = 84
    local jy = sy + 36
    
    for i = 1, 3 do
        local jx = sx + 15 + (i - 1) * (jw + 12)
        
        local j = G.jokers[i]
        if j then
            -- 워터마크 그리기
            drawJokerWatermark(jx, jy, jw, jh, P.cMirr)
            
            love.graphics.setColor(P.cMirr[1], P.cMirr[2], P.cMirr[3], 0.06)
            love.graphics.rectangle("fill", jx, jy, jw, jh, 6, 6)
            love.graphics.setColor(P.cMirr[1], P.cMirr[2], P.cMirr[3], 0.4)
            love.graphics.setLineWidth(1.5)
            love.graphics.rectangle("line", jx, jy, jw, jh, 6, 6)
            
            love.graphics.setFont(HUD.fS)
            Button.txtC(j.name, jx + jw/2, jy + 10, P.white, HUD.fS)
            
            local desc = j.desc
            if j.id == "reroll_boost" then
                desc = "바꾸기 시 40% 확률로\n이번 라운드 배수 +3 추가\n(현재 배수: +" .. (G.discardMultBonus or 0) .. ")"
            end
            
            local lineY = jy + 30
            for line in string.gmatch(desc, "[^\n]+") do
                Button.txtC(line, jx + jw/2, lineY, P.dim, HUD.fS)
                lineY = lineY + 15
            end
        else
            love.graphics.setColor(0.04, 0.05, 0.08, 0.5)
            love.graphics.rectangle("fill", jx, jy, jw, jh, 6, 6)
            love.graphics.setColor(P.panelBd[1], P.panelBd[2], P.panelBd[3], 0.2)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", jx, jy, jw, jh, 6, 6)
            
            love.graphics.setFont(HUD.fS)
            Button.txtC("비어 있음", jx + jw/2, jy + jh/2 - 7, {0.4, 0.4, 0.4, 0.5}, HUD.fS)
        end
    end
    
    -- 주머니 크기
    local dx = sx + 395
    local dy = jy
    local dw = sw - 410
    local dh = jh
    
    -- 워터마크 그리기
    drawBagWatermark(dx, dy, dw, dh)
    
    love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], 0.05)
    love.graphics.rectangle("fill", dx, dy, dw, dh, 6, 6)
    love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], 0.4)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", dx, dy, dw, dh, 6, 6)
    
    love.graphics.setFont(HUD.fS)
    Button.txtC("주머니 크기", dx + dw/2, dy + 16, P.text, HUD.fS)
    
    love.graphics.setFont(HUD.fL)
    local countStr = tostring(#G.deckConfig)
    Button.txtC(countStr .. " 명", dx + dw/2, dy + 42, P.gold, HUD.fL)
end

-- 상점 아이템 랜덤 구성 생성 (G.enterShop 이식)
function SettingsState.enterShop(gameInstance)
    local pool = ShopItems.buildPool()

    local function deckHasColor(colorName)
        for _, card in ipairs(gameInstance.deckConfig or {}) do
            if card.name == colorName then
                return true
            end
        end
        return false
    end
    
    -- 보유 증강체와 현재 주머니 상태에 맞지 않는 상품 필터링
    local itemCandidates = {}
    local augmentCandidates = {}
    for _, item in ipairs(pool) do
        local owned = false
        if isAugment(item) then
            for _, ownedJ in ipairs(gameInstance.jokers) do
                if ownedJ.id == item.id then 
                    owned = true 
                    break 
                end
            end
        end
        local usable = true
        if item.type == "deck_remove" then
            usable = #(gameInstance.deckConfig or {}) > 7
        elseif item.type == "deck_remove_color" then
            usable = #(gameInstance.deckConfig or {}) > 7 and deckHasColor(item.colorName)
        elseif item.type == "deck_transform" then
            usable = deckHasColor(item.fromColor)
        end
        if not owned and usable then
            if isAugment(item) then
                table.insert(augmentCandidates, item)
            else
                table.insert(itemCandidates, item)
            end
        end
    end
    
    shuffle(itemCandidates)
    shuffle(augmentCandidates)

    gameInstance.shopItems = {}
    for i = 1, math.min(ITEM_SLOT_COUNT, #itemCandidates) do
        gameInstance.shopItems[i] = cloneShopEntry(itemCandidates[i])
    end

    gameInstance.shopAugments = {}
    for i = 1, math.min(AUGMENT_SLOT_COUNT, #augmentCandidates) do
        gameInstance.shopAugments[i] = cloneShopEntry(augmentCandidates[i])
    end
end

-- 상점 나가기 및 다음 라운드 준비 (G.exitShop 이식)
local function exitShop()
    if not G then return end
    
    TurnManager.newRound(G)
    G.stateMachine:change("play", G)
end

-- ── 마우스 입력 ──
function SettingsState.mousepressed(x, y, btn)
    if btn ~= 1 or not G then return end
    
    -- 1. 상점 물품 구매 버튼 클릭 체크
    local rx = 620
    local ry = 80
    local startX = rx + 30
    local itemW = 160
    local itemH = 245
    local gap = 20
    
    for i = 1, ITEM_SLOT_COUNT do
        local ix = startX + (i - 1) * (itemW + gap)
        local iy = ry + 120
        local bx = ix + 15
        local by = iy + itemH - 50
        local bw = itemW - 30
        local bh = 34
        
        if G.shopItems[i] and x >= bx and x <= bx + bw and y >= by and y <= by + bh then
            G.buyItem(i)
            return
        end
    end

    local augmentX = startX + ITEM_SLOT_COUNT * (itemW + gap)
    for i = 1, AUGMENT_SLOT_COUNT do
        local ix = augmentX + (i - 1) * (itemW + gap)
        local iy = ry + 120
        local bx = ix + 15
        local by = iy + itemH - 50
        local bw = itemW - 30
        local bh = 34

        if G.shopAugments[i] and x >= bx and x <= bx + bw and y >= by and y <= by + bh then
            G.buyAugment(i)
            return
        end
    end
    
    -- 2. 관문 시작 버튼 클릭 체크
    local lx = 80
    local ly = 80
    local lw = 500
    local lh = 560
    local btnW = lw - 60
    local btnH = 50
    local btnX = lx + 30
    local btnY = ly + lh - 80
    if x >= btnX and x <= btnX + btnW and y >= btnY and y <= btnY + btnH then
        exitShop()
        return
    end
end

function SettingsState.mousereleased(x, y, btn)
end

-- ── 키보드 입력 ──
function SettingsState.keypressed(key)
    if not G then return end
    
    if key == "return" or key == "space" then
        exitShop()
    end
end

return SettingsState
