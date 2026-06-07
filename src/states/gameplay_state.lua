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

    -- 1. 배경 felt 테이블 및 체크 격자 무늬 그리기 (R.background)
    love.graphics.setColor(P.bg)
    love.graphics.rectangle("fill", 0, 0, C.SW, C.SH)
    for y = 0, C.SH, 16 do
        local t = y / C.SH
        love.graphics.setColor(
            P.felt[1] * (1 - t) + P.felt2[1] * t,
            P.felt[2] * (1 - t) + P.felt2[2] * t,
            P.felt[3] * (1 - t) + P.felt2[3] * t,
            0.34
        )
        love.graphics.rectangle("fill", 0, y, C.SW, 16)
    end
    love.graphics.setColor(1, 1, 1, 0.035)
    love.graphics.setLineWidth(1)
    for x = -C.SH, C.SW, 44 do
        love.graphics.line(x, 0, x + C.SH, C.SH)
    end

    -- 2. 게임 득점 흔들림 연출 적용
    love.graphics.push()
    if G.shake > 0 then
        local dx = (love.math.random() * 2 - 1) * G.shake
        local dy = (love.math.random() * 2 - 1) * G.shake
        love.graphics.translate(dx, dy)
    end

    -- 3. HUD 및 보드 드로우
    HUD.drawTopUI(G)
    CardSlot.drawBoard(G.board, G.slotAnim, ScoreSys.getState())
    GameplayState.drawHand()
    GameplayState.drawDeckUI()
    HUD.drawCheatSheet()
    GameplayState.drawJokers()
    Effect.draw()
    
    love.graphics.pop()

    -- 4. 오버레이 및 상위 모달 그리기
    HUD.drawBagOverlay(G)
    GameplayState.drawGameOver()
    
    -- 5. 라운드 진입 배너 애니메이션 그리기
    GameplayState.drawBanner()
end

-- 내 손패 카드 렌더링 (R.hand 이식)
function GameplayState.drawHand()
    if G.phase ~= "play" then return end
    local n = #G.hand
    local time = love.timer.getTime()

    Panel.draw(C.HCX - 360, C.HY - C.HCR - 34, 720, C.HCR*2 + 68, 12)
    Button.txt("내 색친구", C.HCX - 342, C.HY - C.HCR - 25, P.text, HUD.fM)

    if n == 0 then return end
    local mid = (n + 1) / 2

    local order = {}
    for i = 1, n do
        local off = i - mid
        local bx = G.hand[i].visX or (C.HCX + off * C.HSPC)
        local by = C.HY
        local sel = G.hand[i].sel
        local hov = (G.hCard == i)
        local dy = 0
        if sel then dy = -22 end
        if hov then dy = dy - 8 end
        
        local rx, ry = bx, by + dy
        local bob = math.sin(time*1.8 + i*0.7) * 1.5
        local sc = 1
        
        if G.dragIndex == i then
            rx = G.dragX
            ry = G.dragY
            bob = 0
            sc = 1.1
        else
            local age = time - (G.hand[i].spawnT or 0)
            if age < 0.25 then sc = MathUtils.easeBack(age/0.25) end
        end
        
        table.insert(order, {
            i=i, x=rx, y=ry, bob=bob, sc=sc, hov=hov, sel=sel, card=G.hand[i],
            pri=(G.dragIndex == i and 5 or (sel and 1 or 0)+(hov and 2 or 0))
        })
    end
    table.sort(order, function(a, b) return a.pri < b.pri end)

    for _, o in ipairs(order) do
        love.graphics.push()
        love.graphics.translate(o.x, o.y)
        love.graphics.scale(o.sc, o.sc)
        love.graphics.translate(-o.x, -o.y)
        CharacterEntity.draw(o.x, o.y, C.HCR, o.card, { selected = o.sel, bob = o.bob })
        
        if G.dragIndex ~= o.i then
            love.graphics.setFont(HUD.fS)
            love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.55)
            local kname = HUD.getColorKoreanName(o.card.name)
            local nw = HUD.fS:getWidth(kname)
            love.graphics.print(kname, o.x - nw/2, o.y + C.HCR + 8 + o.bob)
        end
        love.graphics.pop()
    end
end

-- 우측 액션 판넬 렌더링 (S.deckUI 이식)
function GameplayState.drawDeckUI()
    if G.phase ~= "play" then return end

    local x, y, w, h = C.RX, C.RY, C.RW, C.RH
    Panel.draw(x, y, w, h, 12)

    local mx, my = love.mouse.getPosition()
    local nCards = #G.hand

    -- 주머니 카드더미
    local bx0, by0, bw0, bh0 = x + 30, y + 30, w - 60, 100
    G.hBag = mx >= bx0 and mx <= bx0 + bw0 and my >= by0 and my <= by0 + bh0
    CardSlot.drawDeckStack(bx0, by0, bw0, bh0, #G.deck, G.hBag)

    -- 실행 및 바꾸기 액션 버튼
    local runW, runH = w - 60, 60
    local runX, runY = x + 30, y + h - 180
    local canRun = nCards > 0
    G.hRun = mx >= runX and mx <= runX + runW and my >= runY and my <= runY + runH
    Button.draw(runX, runY, runW, runH, "실행!", canRun, G.hRun, HUD.fX)

    local bw, bh = w - 60, 50
    local bx, by = x + 30, y + h - 100
    local canDiscard = Tile.getSelectionCount(G.hand) > 0 and G.discLeft > 0
    G.hDiscard = mx >= bx and mx <= bx + bw and my >= by and my <= by + bh

    Button.draw(bx, by, bw, bh, "바꾸기", canDiscard, G.hDiscard, HUD.fL)
    love.graphics.setFont(HUD.fS)
    local rtxt = G.discLeft .. "/" .. C.MAXDISC
    love.graphics.setColor(canDiscard and P.gold or P.dim)
    love.graphics.print(rtxt, bx + (bw - HUD.fS:getWidth(rtxt))/2, by + 32)

    love.graphics.setFont(HUD.fM)
    love.graphics.setColor(canRun and P.gold or P.dim)
    local toExec = math.min(C.BN, nCards)
    local pickTxt = toExec .. "명 모두 출전"
    love.graphics.print(pickTxt, runX + (runW - HUD.fM:getWidth(pickTxt))/2, runY - 22)

    -- 알림 토스트 배너 피드백
    if G.noticeTimer > 0 then
        local nc = G.noticeKind == "ok" and P.cMono or P.btnR
        local nw = math.min(260, HUD.fS:getWidth(G.noticeText) + 24)
        Button.pill(C.HCX - nw / 2, C.BY + C.BSH + 20, nw, 22, G.noticeText, nc, HUD.fS)
    end
end

-- 중앙 상단 조커 장착 슬롯 그리기 (S.jokers 이식)
function GameplayState.drawJokers()
    Panel.draw(C.JX, C.JY, C.JW, C.JH, 10)
    Button.txt("도우미", C.JX + 14, C.JY + 10, P.text, HUD.fM)
    Button.pill(C.JX + C.JW - 62, C.JY + 12, 42, 20, #G.jokers .. "/3", P.cMirr, HUD.fS)
    
    love.graphics.setFont(HUD.fS)
    
    if #G.jokers == 0 then
        love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.35)
        Button.txtC("비어 있음", C.JX + C.JW/2, C.JY + C.JH/2, P.dim, HUD.fM)
        return
    end
    
    local jw = (C.JW - 40) / 3
    local jh = C.JH - 40
    local sx = C.JX + 10
    local sy = C.JY + 30
    
    for i, j in ipairs(G.jokers) do
        local cx, cy = sx + (i-1) * (jw + 10), sy
        
        love.graphics.setColor(0, 0, 0, 0.04)
        love.graphics.rectangle("fill", cx, cy + 2, jw, jh, 6, 6)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", cx, cy, jw, jh, 6, 6)
        
        love.graphics.setColor(P.cMirr)
        love.graphics.setLineWidth(1.2)
        love.graphics.rectangle("line", cx, cy, jw, jh, 6, 6)
        
        Button.txtC(j.name, cx + jw/2, cy + 12, P.text, HUD.fS)
        
        love.graphics.setFont(HUD.fS)
        love.graphics.setColor(P.dim)
        
        local lineY = cy + 32
        for line in string.gmatch(j.desc, "[^\n]+") do
            Button.txtC(line, cx + jw/2, lineY, P.dim, HUD.fS)
            lineY = lineY + 16
        end
    end
end

-- 게임오버 오버레이 카드 그리기 (S.gameover 이식)
function GameplayState.drawGameOver()
    if G.phase ~= "gameover" then return end
    
    love.graphics.setColor(0.08, 0.08, 0.12, 0.85)
    love.graphics.rectangle("fill", 0, 0, C.SW, C.SH)

    local pw, ph = 400, 340
    local px, py = C.HCX - pw/2, C.SH/2 - ph/2
    
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", px, py + 4, pw, ph + 2, 14, 14)
    love.graphics.setColor(1, 1, 1, 0.98)
    love.graphics.rectangle("fill", px, py, pw, ph, 14, 14)
    love.graphics.setColor(P.btnR)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", px, py, pw, ph, 14, 14)

    Button.txtC("게임 오버", px + pw/2, py + 24, P.btnR, HUD.fXX)
    love.graphics.setColor(P.panelBd)
    love.graphics.line(px + 30, py + 74, px + pw - 30, py + 74)

    local y = py + 95
    Button.txtC("도달한 길: " .. tostring(G.ante) .. "-" .. tostring(G.stage), px + pw/2, y, P.text, HUD.fL)
    Button.txtC("최종 점수: " .. tostring(math.floor(G.totalScore)), px + pw/2, y + 38, P.gold, HUD.fX)

    local bw, bh = 180, 44
    local bx = px + (pw - bw)/2
    local by = py + ph - 80
    
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
        local by = py + ph - 80
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
    local resetX, resetY, resetW, resetH = C.LX + C.LW - 74, C.LY + 14, 56, 24
    if x >= resetX and x <= resetX + resetW and y >= resetY and y <= resetY + resetH then
        G.reset()
        Audio.play("discard")
        return
    end

    -- 4. 플레이 동작 클릭 감지
    if G.phase == "play" then
        -- 4.1 바꾸기 버튼
        local swapX, swapY, swapW, swapH = C.RX + 30, C.RY + C.RH - 100, C.RW - 60, 50
        if x >= swapX and x <= swapX + swapW and y >= swapY and y <= swapY + swapH then
            TurnManager.discard(G)
            return
        end

        -- 4.2 주머니 보기 스택 버튼
        local bagX, bagY, bagW, bagH = C.RX + 30, C.RY + 30, C.RW - 60, 100
        if x >= bagX and x <= bagX + bagW and y >= bagY and y <= bagY + bagH then
            G.showBag = true
            Audio.play("select")
            return
        end

        -- 4.3 실행 버튼
        local runX, runY, runW, runH = C.RX + 30, C.RY + C.RH - 180, C.RW - 60, 60
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

-- 라운드 진입 배너 그리기 (S.roundStartAnim 이식)
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

return GameplayState
