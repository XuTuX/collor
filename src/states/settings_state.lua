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

            -- 1. Neon Aura Glow for Shop Cards (Behind)
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
            else
                Button.txtC(item.name, ix + itemW/2, iy + 14, P.text, HUD.fM)
                
                love.graphics.setFont(HUD.fS)
                local typeTxt = "기타"
                if item.type == "deck_add" or item.type == "deck_remove" then typeTxt = "주머니"
                elseif item.type == "joker" then typeTxt = "증강체"
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
            if j.id == "time_accelerator" then
                local currentBonus = math.floor((G.timeScoreTimer or 0) / 4) * 2
                desc = "4초 마다 배수 +2\n(현재 배수: +" .. currentBonus .. ")\n실행 시 리셋"
            elseif j.id == "reroll_boost" then
                desc = "바꾸기 시 40% 확률로\n이번 라운드 배수 +3 추가\n(현재 배수: +" .. (G.discardMultBonus or 0) .. ")"
            elseif j.id == "time_fever" then
                local currentProgress = math.floor(G.timeFeverTimer or 0)
                desc = "6초 마다 보유 코인 +$1\n(현재 축적: " .. currentProgress .. "초/6초)"
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
    Button.txtC("주머니", dx + dw/2, dy + 10, P.text, HUD.fS)
    
    love.graphics.setFont(HUD.fX)
    local countStr = tostring(#G.deckConfig)
    Button.txtC(countStr, dx + dw/2, dy + 26, P.gold, HUD.fX)
    
    Button.txtC("개", dx + dw/2, dy + 58, P.dim, HUD.fS)
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
        {type="upgrade", hand="Double Twins", name="쌍둥이 반짝임", desc="쌍둥이 규칙 +1\n(+20 별, +2 콤보)", price=3},
        {type="upgrade", hand="Triple Twins", name="세 쌍둥이 반짝임", desc="세 쌍둥이 규칙 +1\n(+40 별, +3.5 콤보)", price=3},
        {type="upgrade", hand="Mini Zigzag", name="작은 지그재그 반짝임", desc="작은 지그재그 규칙 +1\n(+30 별, +2.5 콤보)", price=3},
        {type="upgrade", hand="Grand Zigzag", name="큰 지그재그 반짝임", desc="큰 지그재그 규칙 +1\n(+60 별, +5 콤보)", price=3},

        -- 증강체
        {type="joker", id="shiny_eye", name="반짝이는 눈", desc="위에 하양이 있으면\n+50 별", price=6},
        {type="joker", id="dark_side", name="밤빛 친구", desc="위에 검정이 있으면\n+5 콤보", price=6},
        {type="joker", id="mirror_shield", name="거울 방패", desc="거울 규칙이 나오면\nx1.8 콤보", price=6},
        {type="joker", id="rainbow", name="무지개", desc="다른 색이 4종류\n이상이면\n+60 별, +6 콤보", price=7},
        {type="joker", id="ladder_master", name="계단 대장", desc="계단 규칙이 나오면\n+100 별", price=5},
        {type="joker", id="gold_rush", name="코인 주머니", desc="관문 종료 시\n+$4 코인 추가", price=5},
        {type="joker", id="chaos", name="혼돈의 카오스", desc="맞는 규칙이 없으면\nx2.2 콤보", price=6},
        {type="joker", id="savings", name="저축왕", desc="보유한 코인 $2 마다\n+1 콤보 추가", price=6},
        {type="joker", id="mono_pride", name="일편단심", desc="보드판 전체가 단 1가지\n색이면 x2.5 콤보", price=8},
        {type="joker", id="burning", name="불타는 열정", desc="보드판 위의 빨강\n카드 1개당 +3 콤보", price=5},
        {type="joker", id="lemonade", name="레몬에이드", desc="보드판 위의 노랑\n카드 1개당 +25 별", price=5},
        {type="joker", id="overload", name="증강 가속기", desc="다른 활성화 증강체\n1개당 +4 콤보 추가", price=7},
        {type="joker", id="eclipse", name="일식 (화이트&블랙)", desc="하양과 검정 증강체\n동시 발동 시 x1.8 배수", price=8},
        {type="joker", id="alchemy", name="금단 연금술", desc="보드판의 빨강 & 노랑\n각 2장 이상 시 별 +80, +$2", price=6},
        {type="joker", id="resonance", name="공명 주파수", desc="거울과 계단 규칙\n동시 발동 시 x2.0 배수", price=7},
        {type="joker", id="time_accelerator", name="시간 가속기", desc="4초 마다 배수 +2\n(현재 배수: +0)\n실행 시 리셋", price=6},
        {type="joker", id="reroll_spark", name="재굴림 스파크", desc="바꾸기 시 35% 확률로\n패의 무작위 카드 1장\n특수 에디션으로 강화", price=6},
        {type="joker", id="reroll_boost", name="재굴림 증폭기", desc="바꾸기 시 40% 확률로\n이번 라운드 배수 +3 추가\n(현재 배수: +0)", price=6},
        {type="joker", id="time_fever", name="시간 피버", desc="6초 마다 보유 코인 +$1\n(현재 축적: 0초/6초)", price=7},

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
