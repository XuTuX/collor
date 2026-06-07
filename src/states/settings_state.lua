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

-- 시스템 및 턴 매니저
local Audio = require("systems.audio_system")
local JokerSys = require("systems.joker_system")
local TurnManager = require("gameplay.turn_manager")

local G = nil

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
            love.graphics.setColor(0.08, 0.10, 0.18, 0.4)
            love.graphics.rectangle("fill", sx, sy, sw, boxH, 8, 8)
            love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.25)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", sx, sy, sw, boxH, 8, 8)
            
            Button.txt(stages[i].name, sx + 20, sy + 18, {0.5, 0.5, 0.5, 0.6}, HUD.fM)
            Button.txt("목표 점수: " .. targetScore, sx + 20, sy + 44, {0.5, 0.5, 0.5, 0.5}, HUD.fS)
            Button.pill(sx + sw - 85, sy + 16, 65, 20, "클리어", P.cMono, HUD.fS)
        elseif state == "current" then
            love.graphics.setColor(0.12, 0.16, 0.28, 0.7)
            love.graphics.rectangle("fill", sx, sy, sw, boxH, 8, 8)
            love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], 0.8)
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
            love.graphics.setColor(0.06, 0.08, 0.12, 0.6)
            love.graphics.rectangle("fill", sx, sy, sw, boxH, 8, 8)
            love.graphics.setColor(P.panelBd[1], P.panelBd[2], P.panelBd[3], 0.15)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", sx, sy, sw, boxH, 8, 8)
            
            Button.txt(stages[i].name, sx + 20, sy + 22, {0.4, 0.4, 0.4, 0.5}, HUD.fM)
            Button.txt("목표 점수: " .. targetScore, sx + 20, sy + 48, {0.4, 0.4, 0.4, 0.4}, HUD.fS)
            
            if i == 3 then
                local desc = require("entities/modifier").getBossGimmickDesc(G.bossGimmick)
                Button.txt("특별 규칙: " .. desc, sx + 20, sy + 68, {0.4, 0.3, 0.3, 0.3}, HUD.fS)
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
    Button.pill(rx + rw - 104, ry + 30, 74, 24, "$" .. G.gold, P.gold, HUD.fM)
    
    if G.noticeTimer > 0 then
        local nc = G.noticeKind == "ok" and P.cMono or P.btnR
        local nw = math.min(260, HUD.fS:getWidth(G.noticeText) + 24)
        Button.pill(rx + rw - 118 - nw, ry + 32, nw, 22, G.noticeText, nc, HUD.fS)
    end
    
    love.graphics.setColor(P.panelBd)
    love.graphics.line(rx + 20, ry + 78, rx + rw - 20, ry + 78)
    
    local startX = rx + 30
    local itemW = 160
    local itemH = 260
    local gap = 20
    
    for i = 1, 3 do
        local item = G.shopItems[i]
        if item then
            local ix = startX + (i-1) * (itemW + gap)
            local iy = ry + 110
            
            local bc = P.panelBd
            if item.sold then
                bc = P.dim
            elseif item.type == "joker" then
                bc = P.cMirr
            elseif item.type == "upgrade" then
                bc = P.cMono
            elseif item.type == "deck_add" or item.type == "deck_remove" then
                bc = P.cStep
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
            else
                Button.txtC(item.name, ix + itemW/2, iy + 14, P.text, HUD.fM)
                
                love.graphics.setFont(HUD.fS)
                local typeTxt = "기타"
                if item.type == "deck_add" or item.type == "deck_remove" then typeTxt = "주머니"
                elseif item.type == "joker" then typeTxt = "도우미"
                elseif item.type == "upgrade" then typeTxt = "반짝임" end
                
                Button.pill(ix + 16, iy + 34, 100, 20, typeTxt, bc, HUD.fS)

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
        end
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
    
    -- 보유 도우미 리스트
    love.graphics.setFont(HUD.fS)
    love.graphics.setColor(P.text)
    love.graphics.print("보유 도우미 (" .. #G.jokers .. "/3)", sx + 15, sy + 12)
    
    local jw = 125
    local jh = 85
    for i = 1, 3 do
        local jx = sx + 15 + (i - 1) * (jw + 10)
        local jy = sy + 35
        
        love.graphics.setColor(0.04, 0.05, 0.08, 0.5)
        love.graphics.rectangle("fill", jx, jy, jw, jh, 6, 6)
        love.graphics.setColor(P.panelBd[1], P.panelBd[2], P.panelBd[3], 0.3)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", jx, jy, jw, jh, 6, 6)
        
        local j = G.jokers[i]
        if j then
            love.graphics.setFont(HUD.fS)
            Button.txtC(j.name, jx + jw/2, jy + 10, P.cMirr, HUD.fS)
            
            local lineY = jy + 30
            for line in string.gmatch(j.desc, "[^\n]+") do
                Button.txtC(line, jx + jw/2, lineY, P.dim, HUD.fS)
                lineY = lineY + 15
            end
        else
            love.graphics.setFont(HUD.fS)
            Button.txtC("비어 있음", jx + jw/2, jy + jh/2 - 7, {0.4, 0.4, 0.4, 0.5}, HUD.fS)
        end
    end
    
    -- 주머니 크기
    local dx = sx + 400
    local dy = sy + 12
    local dw = sw - 415
    local dh = sh - 24
    
    love.graphics.setColor(0.04, 0.05, 0.08, 0.5)
    love.graphics.rectangle("fill", dx, dy, dw, dh, 6, 6)
    love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", dx, dy, dw, dh, 6, 6)
    
    love.graphics.setFont(HUD.fS)
    Button.txtC("주머니", dx + dw/2, dy + 12, P.text, HUD.fS)
    
    love.graphics.setFont(HUD.fX)
    local countStr = tostring(#G.deckConfig)
    Button.txtC(countStr, dx + dw/2, dy + 34, P.gold, HUD.fX)
    
    love.graphics.setFont(HUD.fS)
    Button.txtC("개", dx + dw/2, dy + 66, P.dim, HUD.fS)
    
    -- 실시간 배너 애니메이션 그리기
    local AnimSys = require("systems.animation_system")
    local startAnim = AnimSys.getRoundStartAnim()
    if startAnim.active then
        require("states.result_state").drawRoundStartBanner() -- 헬퍼를 경유해 그리거나 settings_state 내에서 직접 렌더링
        SettingsState.drawBanner()
    end
end

-- 라운드 진입 배너 그리기 (S.roundStartAnim 이식)
function SettingsState.drawBanner()
    local AnimSys = require("systems.animation_system")
    local a = AnimSys.getRoundStartAnim()
    if not a or not a.active then return end
    
    local p = a.t / a.dur
    local alpha = 1
    if p < 0.20 then
        alpha = p / 0.20
    elseif p > 0.80 then
        alpha = (1 - p) / 0.20
    end
    
    love.graphics.setColor(0.08, 0.08, 0.12, alpha * 0.90)
    love.graphics.rectangle("fill", 0, C.SH/2 - 90, C.SW, 180)
    
    love.graphics.setColor(P.btnR[1], P.btnR[2], P.btnR[3], alpha * 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, C.SH/2 - 90, C.SW, C.SH/2 - 90)
    love.graphics.line(0, C.SH/2 + 90, C.SW, C.SH/2 + 90)
    
    love.graphics.setFont(HUD.fXX)
    love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], alpha)
    
    local gateTitle = G.stage == 1 and "쉬운 관문" or G.stage == 2 and "도전 관문" or "특별 관문"
    local title = "월드 " .. G.ante .. " - " .. gateTitle
    love.graphics.print(title, (C.SW - HUD.fXX:getWidth(title))/2, C.SH/2 - 60)
    
    love.graphics.setFont(HUD.fL)
    love.graphics.setColor(1, 1, 1, alpha)
    local subText = ""
    if G.stage == 3 then
        local desc = require("entities/modifier").getBossGimmickBannerDesc(G.bossGimmick)
        subText = "특별 규칙: " .. desc
    else
        subText = "목표 점수: " .. G.targetScore
    end
    love.graphics.print(subText, (C.SW - HUD.fL:getWidth(subText))/2, C.SH/2 + 10)
    
    love.graphics.setFont(HUD.fS)
    love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], alpha * 0.7)
    local startTxt = "준비하세요..."
    love.graphics.print(startTxt, (C.SW - HUD.fS:getWidth(startTxt))/2, C.SH/2 + 50)
end

-- 상점 아이템 랜덤 구성 생성 (G.enterShop 이식)
function SettingsState.enterShop(gameInstance)
    local pool = {
        -- 색 규칙 강화 반짝임
        {type="upgrade", hand="Mini Mono", name="세 친구 반짝임", desc="세 친구 규칙 +1\n(+20 별, +2 콤보)", price=3},
        {type="upgrade", hand="Half Mono", name="네 친구 반짝임", desc="네 친구 규칙 +1\n(+30 별, +2.5 콤보)", price=3},
        {type="upgrade", hand="Tower", name="색 탑 반짝임", desc="색 탑 규칙 +1\n(+50 별, +4 콤보)", price=3},
        {type="upgrade", hand="Half Mirror", name="작은 거울 반짝임", desc="작은 거울 규칙 +1\n(+40 별, +3 콤보)", price=3},
        {type="upgrade", hand="Grand Mirror", name="큰 거울 반짝임", desc="큰 거울 규칙 +1\n(+100 별, +10 콤보)", price=3},
        {type="upgrade", hand="Half Step", name="작은 계단 반짝임", desc="작은 계단 규칙 +1\n(+45 별, +4 콤보)", price=3},
        {type="upgrade", hand="Perfect Ladder", name="무지개 계단 반짝임", desc="무지개 계단 규칙 +1\n(+80 별, +6 콤보)", price=3},

        -- 도우미 조커
        {type="joker", id="shiny_eye", name="반짝이는 눈", desc="위에 하양이 있으면\n+50 별", price=6},
        {type="joker", id="dark_side", name="밤빛 친구", desc="위에 검정이 있으면\n+5 콤보", price=6},
        {type="joker", id="mirror_shield", name="거울 방패", desc="거울 규칙이 나오면\nx1.8 콤보", price=6},
        {type="joker", id="rainbow", name="무지개", desc="다른 색이 4종류\n이상이면\n+60 별, +6 콤보", price=7},
        {type="joker", id="ladder_master", name="계단 대장", desc="계단 규칙이 나오면\n+100 별", price=5},
        {type="joker", id="gold_rush", name="코인 주머니", desc="관문 종료 시\n+$4 코인 추가", price=5},

        -- 색친구 주머니 추가 및 삭제
        {type="deck_add", colorName="Red", colorVal={0.92,0.22,0.25}, name="빨강 추가", desc="빨강 색친구 1개를\n주머니에 계속 추가", price=2},
        {type="deck_add", colorName="Black", colorVal={0.12,0.12,0.16}, name="검정 추가", desc="검정 색친구 1개를\n주머니에 계속 추가", price=2},
        {type="deck_remove", name="색친구 줄이기", desc="무작위 색친구 1개를\n주머니에서 줄이기", price=3},
    }
    
    -- 보유 조커 필터링
    local temp = {}
    for _, item in ipairs(pool) do
        local owned = false
        if item.type == "joker" then
            for _, ownedJ in ipairs(gameInstance.jokers) do
                if ownedJ.id == item.id then 
                    owned = true 
                    break 
                end
            end
        end
        if not owned then 
            table.insert(temp, item) 
        end
    end
    
    -- 임의 셔플 후 3개 판매 지정
    for i = #temp, 2, -1 do
        local j = love.math.random(1, i)
        temp[i], temp[j] = temp[j], temp[i]
    end
    
    gameInstance.shopItems = {}
    for i = 1, math.min(3, #temp) do
        gameInstance.shopItems[i] = {
            type = temp[i].type,
            id = temp[i].id,
            hand = temp[i].hand,
            colorName = temp[i].colorName,
            colorVal = temp[i].colorVal,
            name = temp[i].name,
            desc = temp[i].desc,
            price = temp[i].price,
            sold = false
        }
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
    local itemH = 260
    local gap = 20
    
    for i = 1, 3 do
        local ix = startX + (i - 1) * (itemW + gap)
        local iy = ry + 110
        local bx = ix + 15
        local by = iy + itemH - 50
        local bw = itemW - 30
        local bh = 34
        
        if x >= bx and x <= bx + bw and y >= by and y <= by + bh then
            G.buyItem(i)
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
