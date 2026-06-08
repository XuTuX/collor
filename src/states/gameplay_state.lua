------------------------------------------------------------
-- gameplay_state.lua · 인게임 플레이 상태 및 입력 처리 모듈
------------------------------------------------------------
local GameplayState = {}
local C = require("core.constants")
local P = C.P

-- UI 및 엔티티 컴포넌트
local Panel = require("ui.panel")
local Button = require("ui.button")
local CardSlot = require("ui.card_slot")
local HUD = require("ui.hud")
local CharacterEntity = require("entities/character")
local Drag = require("ui.drag_handler")

-- 시스템 의존성
local Audio = require("systems.audio_system")
local Effect = require("systems.effect_system")
local Anim = require("systems.animation_system")
local ScoreSys = require("systems.score_system")
local TurnManager = require("gameplay.turn_manager")
local Tile = require("gameplay.tile")
local MathUtils = require("utils.math")

local G = nil

function GameplayState.enter(gameInstance)
    G = gameInstance
end

function GameplayState.exit()
end

function GameplayState.update(dt)
end

-- ── 렌더링 ──
function GameplayState.draw()
    if not G then return end

    -- 1. 네오 브루탈리즘 격자 무늬 배경
    love.graphics.setColor(P.bg)
    love.graphics.rectangle("fill", 0, 0, C.SW, C.SH)
    
    local gridSize = 40
    
    -- 미세 가로세로 그리드 라인 (Charcoal Black 3.5% 투명도)
    love.graphics.setColor(0.102, 0.102, 0.102, 0.035)
    love.graphics.setLineWidth(1)
    for x = 0, C.SW, gridSize do
        love.graphics.line(x, 0, x, C.SH)
    end
    for y = 0, C.SH, gridSize do
        love.graphics.line(0, y, C.SW, y)
    end
    
    -- 레트로 감성 파스텔 블록 포인트
    love.graphics.setColor(0.976, 0.847, 0.427, 0.08) -- 파스텔 옐로우 8%
    love.graphics.rectangle("fill", gridSize * 2 + 4, gridSize * 3 + 4, 32, 32, 8, 8)
    
    love.graphics.setColor(0.063, 0.725, 0.506, 0.05) -- 파스텔 그린 5%
    love.graphics.rectangle("fill", gridSize * 12 + 4, gridSize * 8 + 4, 32, 32, 8, 8)
    
    love.graphics.setColor(0.000, 0.584, 1.000, 0.05) -- 파스텔 블루 5%
    love.graphics.rectangle("fill", gridSize * 20 + 4, gridSize * 2 + 4, 32, 32, 8, 8)

    -- 2. 게임 득점 흔들림 연출 적용
    love.graphics.push()
    if G.shake > 0 then
        local dx = (love.math.random() * 2 - 1) * G.shake
        local dy = (love.math.random() * 2 - 1) * G.shake
        love.graphics.translate(dx, dy)
    end

    -- 3. HUD 및 보드 드로우
    HUD.drawTopUI(G)
    CardSlot.drawBoard(G, G.board, G.slotAnim, ScoreSys.getState())
    GameplayState.drawHand()
    GameplayState.drawDeckUI()
    HUD.drawCheatSheet(G)
    GameplayState.drawJokers()
    Effect.draw()
    
    love.graphics.pop()

    -- 4. 오버레이 및 상위 모달 그리기
    HUD.drawBagOverlay(G)
    GameplayState.drawGameOver()
    
    -- 5. 라운드 진입 배너 애니메이션 그리기
    GameplayState.drawBanner()
end

-- 내 손패 카드 렌더링 (하단 패널 내에 예쁘게 안착)
function GameplayState.drawHand()
    if G.phase ~= "play" then return end
    local n = #G.hand
    local time = love.timer.getTime()

    -- 하단 보유 캐릭터 패널
    Panel.draw(C.HX, C.HY, C.HW, C.HH, 14)
    Button.txt("내 색친구", C.HX + 20, C.HY + 16, P.text, HUD.fM)

    if n == 0 then return end
    
    local mid = (n + 1) / 2
    local order = {}
    for i = 1, n do
        local bx = G.hand[i].visX or (C.HCX_HAND + (i - mid) * C.HSPC)
        local by = C.HY_HAND
        local sel = G.hand[i].sel
        local hov = (G.hCard == i)
        local dy = 0
        if sel then dy = -18 end
        if hov then dy = dy - 6 end
        
        local rx, ry = bx, by + dy
        local bob = math.sin(time*2.0 + i*0.7) * 1.5
        local sc = G.hand[i].hovScale or 1.0
        local tilt = G.hand[i].hovTilt or 0.0
        
        if G.dragIndex == i then
            rx = G.dragX
            ry = G.dragY
            bob = 0
            sc = 1.15
            tilt = 0.0
        else
            local age = time - (G.hand[i].spawnT or 0)
            if age < 0.25 then 
                local birthSc = MathUtils.easeBack(age/0.25)
                sc = sc * birthSc
            end
        end
        
        table.insert(order, {
            i=i, x=rx, y=ry, bob=bob, sc=sc, tilt=tilt, hov=hov, sel=sel, card=G.hand[i],
            pri=(G.dragIndex == i and 5 or (sel and 1 or 0)+(hov and 2 or 0))
        })
    end
    table.sort(order, function(a, b) return a.pri < b.pri end)

    for _, o in ipairs(order) do
        love.graphics.push()
        love.graphics.translate(o.x, o.y)
        love.graphics.scale(o.sc, o.sc)
        if o.tilt and o.tilt ~= 0 then
            love.graphics.rotate(o.tilt)
        end
        love.graphics.translate(-o.x, -o.y)
        CharacterEntity.draw(o.x, o.y, C.HCR, o.card, { selected = o.sel, bob = o.bob })
        
        if G.dragIndex ~= o.i then
            love.graphics.setFont(HUD.fS)
            love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.7)
            local kname = HUD.getColorKoreanName(o.card.name)
            local nw = HUD.fS:getWidth(kname)
            love.graphics.print(kname, o.x - nw/2, o.y + C.HCR + 5 + o.bob)
        end
        love.graphics.pop()
    end
end

-- 우측 및 하단 액션 버튼 통합 렌더링
function GameplayState.drawDeckUI()
    if G.phase ~= "play" then return end

    local mx, my = love.mouse.getPosition()
    local nCards = #G.hand

    -- 1. 우측 패널 위쪽 주머니 카드더미
    local bx0, by0, bw0, bh0 = C.RX + 20, C.RY + 20, C.RW - 40, 110
    G.hBag = mx >= bx0 and mx <= bx0 + bw0 and my >= by0 and my <= by0 + bh0
    CardSlot.drawDeckStack(bx0, by0, bw0, bh0, #G.deck, G.hBag)

    -- 2. 하단 패널 우측 영역의 실행 및 바꾸기 버튼
    local runW, runH = 130, 48
    local runX, runY = C.HX + C.HW - 150, C.HY + 30
    local canRun = nCards > 0
    G.hRun = mx >= runX and mx <= runX + runW and my >= runY and my <= runY + runH
    Button.draw(runX, runY, runW, runH, "실행!", canRun, G.hRun, HUD.fM)

    local bw, bh = 130, 40
    local bx, by = C.HX + C.HW - 150, C.HY + 95
    local canDiscard = Tile.getSelectionCount(G.hand) > 0 and G.discLeft > 0
    G.hDiscard = mx >= bx and mx <= bx + bw and my >= by and my <= by + bh
    Button.draw(bx, by, bw, bh, "바꾸기", canDiscard, G.hDiscard, HUD.fM)

    -- 바꾸기 잔여 횟수 가이드 텍스트
    love.graphics.setFont(HUD.fS)
    love.graphics.setColor(canDiscard and P.gold or P.dim)
    local rtxt = "바꾸기 " .. G.discLeft .. "/" .. C.MAXDISC
    love.graphics.print(rtxt, bx + (bw - HUD.fS:getWidth(rtxt))/2, by + 44)

    -- 출전 인원 표시
    love.graphics.setFont(HUD.fS)
    love.graphics.setColor(canRun and P.gold or P.dim)
    local selCount = Tile.getSelectionCount(G.hand)
    local pickTxt = ""
    if selCount > 0 then
        pickTxt = selCount .. "명 출전"
    else
        local toExec = math.min(C.BN, nCards)
        pickTxt = toExec .. "명 모두 출전"
    end
    love.graphics.print(pickTxt, runX + (runW - HUD.fS:getWidth(pickTxt))/2, runY - 18)

    -- 알림 토스트 배너 피드백
    if G.noticeTimer > 0 then
        local nc = G.noticeKind == "ok" and P.cMono or P.mult
        local nw = math.min(280, HUD.fS:getWidth(G.noticeText) + 24)
        Button.pill(C.HCX - nw / 2, C.BY + C.BSH + 20, nw, 24, G.noticeText, nc, HUD.fS)
    end
end

local function drawJokerWatermark(jx, jy, jw, jh, accentColor)
    local cx, cy = jx + jw/2, jy + jh/2
    local rad = 20
    
    -- Ears/Horns
    love.graphics.setColor(accentColor[1]*0.8, accentColor[2]*0.8, accentColor[3]*0.8, 0.08)
    love.graphics.polygon("fill", cx - 18, cy - 6, cx - 25, cy - 20, cx - 10, cy - 15)
    love.graphics.polygon("fill", cx + 18, cy - 6, cx + 25, cy - 20, cx + 10, cy - 15)
    
    -- Body
    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.06)
    love.graphics.circle("fill", cx, cy, rad)
    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.12)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", cx, cy, rad)
end

-- 상단 중앙 증강체 패널 그리기
function GameplayState.drawJokers()
    Panel.draw(C.JX, C.JY, C.JW, C.JH, 12)
    Button.txt("증강체", C.JX + 16, C.JY + 12, P.text, HUD.fM)
    Button.pill(C.JX + C.JW - 68, C.JY + 14, 48, 20, #G.jokers .. " / 3", P.cMirr, HUD.fS)
    
    local jw = (C.JW - 40) / 3
    local jh = C.JH - 48
    local sx = C.JX + 10
    local sy = C.JY + 38
    
    local mx, my = love.mouse.getPosition()
    
    for i = 1, 3 do
        local cx = sx + (i - 1) * (jw + 10)
        local cy = sy
        
        local j = G.jokers[i]
        if j then
            -- 증강체 아이콘 + 이름
            drawJokerWatermark(cx, cy, jw, jh, P.cMirr)
            
            love.graphics.setColor(P.cMirr[1], P.cMirr[2], P.cMirr[3], 0.05)
            love.graphics.rectangle("fill", cx, cy, jw, jh, 6, 6)
            love.graphics.setColor(P.cMirr[1], P.cMirr[2], P.cMirr[3], 0.35)
            love.graphics.setLineWidth(1.2)
            love.graphics.rectangle("line", cx, cy, jw, jh, 6, 6)
            
            love.graphics.setFont(HUD.fS)
            Button.txtC(j.name, cx + jw/2, cy + jh/2 - 7, P.text, HUD.fS)
            
            -- 호버 시 툴팁(상세 설명) 렌더링
            if mx >= cx and mx <= cx + jw and my >= cy and my <= cy + jh then
                local desc = j.desc
                if j.id == "reroll_boost" then
                    desc = "바꾸기 시 40% 확률로\n이번 라운드 배수 +3 추가\n(현재 배수: +" .. (G.discardMultBonus or 0) .. ")"
                end
                
                -- 화면 중앙 상단 또는 알맞은 마우스 근처에 상세 툴팁 출력
                local tW = 220
                local tH = 68
                local tx = math.min(C.SW - tW - 10, math.max(10, mx - tW/2))
                local ty = cy + jh + 8
                
                love.graphics.push()
                love.graphics.origin()
                Panel.draw(tx, ty, tW, tH, 8)
                love.graphics.setColor(P.text)
                love.graphics.setFont(HUD.fS)
                local lineY = ty + 10
                for line in string.gmatch(desc, "[^\n]+") do
                    Button.txtC(line, tx + tW/2, lineY, P.dim, HUD.fS)
                    lineY = lineY + 16
                end
                love.graphics.pop()
            end
        else
            -- 빈 슬롯 그리기
            love.graphics.setColor(P.bg[1], P.bg[2], P.bg[3], 0.5)
            love.graphics.rectangle("fill", cx, cy, jw, jh, 6, 6)
            love.graphics.setColor(P.panelBd[1], P.panelBd[2], P.panelBd[3], 0.3)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", cx, cy, jw, jh, 6, 6)
            
            love.graphics.setFont(HUD.fS)
            Button.txtC("비어 있음", cx + jw/2, cy + jh/2 - 7, P.dim, HUD.fS)
        end
    end
end

-- 게임오버 오버레이 카드 그리기 (밝은 모던 테마 맞춤)
function GameplayState.drawGameOver()
    if G.phase ~= "gameover" then return end
    
    love.graphics.setColor(P.bg[1], P.bg[2], P.bg[3], 0.9)
    love.graphics.rectangle("fill", 0, 0, C.SW, C.SH)

    local pw, ph = 400, 340
    local px, py = C.HCX - pw/2, C.SH/2 - ph/2
    
    Panel.draw(px, py, pw, ph, 14)

    Button.txtC("게임 오버", px + pw/2, py + 26, P.mult, HUD.fXX)
    love.graphics.setColor(P.panelBd)
    love.graphics.line(px + 30, py + 78, px + pw - 30, py + 78)

    local y = py + 100
    Button.txtC("도달한 길: " .. tostring(G.ante) .. "-" .. tostring(G.stage), px + pw/2, y, P.text, HUD.fL)
    Button.txtC("최종 점수: " .. tostring(math.floor(G.totalScore)), px + pw/2, y + 40, P.gold, HUD.fX)

    local bw, bh = 180, 44
    local bx = px + (pw - bw)/2
    local by = py + ph - 82
    
    local mx, my = love.mouse.getPosition()
    local hovBtn = mx >= bx and mx <= bx + bw and my >= by and my <= by + bh
    
    Button.draw(bx, by, bw, bh, "다시 하기", true, hovBtn, HUD.fM)
    Button.txtC("또는 [R]키를 눌러 재시작", px + pw/2, by + bh + 12, P.dim, HUD.fS)
end

-- ── 마우스 입력 ──
function GameplayState.mousepressed(x, y, btn)
    if btn ~= 1 or not G then return end

    -- 1. 게임 오버 팝업 확인
    if G.phase == "gameover" then
        local pw, ph = 400, 340
        local px, py = C.HCX - pw/2, C.SH/2 - ph/2
        local bw, bh = 180, 44
        local bx = px + (pw - bw)/2
        local by = py + ph - 82
        if x >= bx and x <= bx + bw and y >= by and y <= by + bh then
            G.reset()
            Audio.play("discard")
        end
        return
    end

    -- 2. 주머니 보기 오버레이 닫기 확인
    if G.showBag then
        local backX, backY, backW, backH = C.HCX - 540, 604, 1080, 42
        local closeX, closeY, closeW, closeH = C.HCX + 420, 82, 84, 32
        if (x >= backX and x <= backX + backW and y >= backY and y <= backY + backH) or
           (x >= closeX and x <= closeX + closeW and y >= closeY and y <= closeY + closeH) then
            G.showBag = false
            Audio.play("select")
        end
        return
    end

    -- 3. 우상단 리셋 버튼
    local resetX, resetY, resetW, resetH = C.LX + C.LW - 78, C.LY + 20, 58, 26
    if x >= resetX and x <= resetX + resetW and y >= resetY and y <= resetY + resetH then
        G.reset()
        Audio.play("discard")
        return
    end

    -- 4. 플레이 동작 클릭 감지 (하단 패널 내 좌표에 맞춰 갱신)
    if G.phase == "play" then
        -- 4.1 바꾸기 버튼 (하단 패널 내부: X: C.HX + C.HW - 150, Y: C.HY + 95)
        local swapX, swapY, swapW, swapH = C.HX + C.HW - 150, C.HY + 95, 130, 40
        if x >= swapX and x <= swapX + swapW and y >= swapY and y <= swapY + swapH then
            TurnManager.discard(G)
            return
        end

        -- 4.2 주머니 보기 스택 버튼 (우측 패널 내부: X: C.RX + 20, Y: C.RY + 20)
        local bagX, bagY, bagW, bagH = C.RX + 20, C.RY + 20, C.RW - 40, 110
        if x >= bagX and x <= bagX + bagW and y >= bagY and y <= bagY + bagH then
            G.showBag = true
            Audio.play("select")
            return
        end

        -- 4.3 실행 버튼 (하단 패널 내부: X: C.HX + C.HW - 150, Y: C.HY + 30)
        local runX, runY, runW, runH = C.HX + C.HW - 150, C.HY + 30, 130, 48
        if x >= runX and x <= runX + runW and y >= runY and y <= runY + runH then
            TurnManager.executeHand(G)
            return
        end

        -- 4.4 캐릭터 카드 드래그 개시 판정
        Drag.handlePressed(G, x, y)
    end
end

function GameplayState.mousereleased(x, y, btn)
    if btn ~= 1 or not G then return end
    Drag.handleReleased(G, x, y)
end

-- ── 키보드 입력 ──
function GameplayState.keypressed(key)
    if not G then return end

    if key == "escape" then
        if G.showBag then
            G.showBag = false
            return
        end
        love.event.quit()
        return
    end
    
    if key == "r" then
        G.reset()
        return
    end
 
    if G.showBag then
        if key == "b" or key == "return" or key == "space" then
            G.showBag = false
            Audio.play("select")
        end
        return
    end

    if G.phase == "play" then
        if key == "d" then
            TurnManager.discard(G)
        elseif key == "b" then
            G.showBag = true
            Audio.play("select")
        elseif key == "return" or key == "space" then
            TurnManager.executeHand(G)
        end
    end
end

-- 라운드 진입 배너 그리기
function GameplayState.drawBanner()
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
    
    love.graphics.setColor(P.bg[1], P.bg[2], P.bg[3], alpha * 0.96)
    love.graphics.rectangle("fill", 0, C.SH/2 - 90, C.SW, 180)
    
    love.graphics.setColor(P.panelBd[1], P.panelBd[2], P.panelBd[3], alpha * 0.5)
    love.graphics.setLineWidth(1.5)
    love.graphics.line(0, C.SH/2 - 90, C.SW, C.SH/2 - 90)
    love.graphics.line(0, C.SH/2 + 90, C.SW, C.SH/2 + 90)
    
    love.graphics.setFont(HUD.fXX)
    love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], alpha)
    
    local gateTitle = G.stage == 1 and "쉬운 관문" or G.stage == 2 and "도전 관문" or "특별 관문"
    local title = "월드 " .. G.ante .. " - " .. gateTitle
    love.graphics.print(title, (C.SW - HUD.fXX:getWidth(title))/2, C.SH/2 - 60)
    
    love.graphics.setFont(HUD.fL)
    love.graphics.setColor(P.text[1], P.text[2], P.text[3], alpha)
    local subText = ""
    if G.stage == 3 then
        local desc = require("entities/modifier").getBossGimmickBannerDesc(G.bossGimmick)
        subText = "특별 규칙: " .. desc
    else
        subText = "목표 점수: " .. G.targetScore
    end
    love.graphics.print(subText, (C.SW - HUD.fL:getWidth(subText))/2, C.SH/2 + 10)
    
    love.graphics.setFont(HUD.fS)
    love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], alpha * 0.8)
    local startTxt = "준비하세요..."
    love.graphics.print(startTxt, (C.SW - HUD.fS:getWidth(startTxt))/2, C.SH/2 + 50)
end

return GameplayState
