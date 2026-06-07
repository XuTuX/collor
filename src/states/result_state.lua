------------------------------------------------------------
-- result_state.lua · 득점 집계 및 라운드 결과 정산 상태 모듈
------------------------------------------------------------
local ResultState = {}
local C = require("core.constants")
local P = C.P

-- UI 컴포넌트
local Panel = require("ui.panel")
local Button = require("ui.button")
local CardSlot = require("ui.card_slot")
local HUD = require("ui.hud")

-- 시스템 및 플레이어 액션 의존성
local Audio = require("systems.audio_system")
local Effect = require("systems.effect_system")
local ScoreSys = require("systems.score_system")
local Tile = require("gameplay.tile")
local TurnManager = require("gameplay.turn_manager")
local MathUtils = require("utils.math")

local G = nil

function ResultState.enter(gameInstance)
    G = gameInstance
end

function ResultState.exit()
end

function ResultState.update(dt)
end

-- 정산 렌더링 루프
function ResultState.draw()
    if not G then return end

    -- 1. 기본 인게임 배경 및 패널 유지
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
    
    love.graphics.push()
    if G.shake > 0 then
        local dx = (love.math.random() * 2 - 1) * G.shake
        local dy = (love.math.random() * 2 - 1) * G.shake
        love.graphics.translate(dx, dy)
    end

    HUD.drawTopUI(G)
    CardSlot.drawBoard(G.board, G.slotAnim, ScoreSys.getState())
    HUD.drawCheatSheet()
    Effect.draw()
    
    love.graphics.pop()

    -- 2. 점수 계산 중 또는 최종 결과 팝업 드로우
    if G.phase == "scoring" then
        ResultState.drawScoring()
    elseif G.phase == "result" then
        ResultState.drawResult()
    end
end

-- 규칙 매칭 스코어 판넬 애니메이션 그리기 (S.scoring 이식)
function ResultState.drawScoring()
    local s = ScoreSys.getState()
    if not s.active then return end

    if s.phase == "nohand" then
        local a = math.min(1, s.timer * 2)
        Button.txtC("맞는 규칙 없음...", C.HCX, C.SH / 2 - 20, {P.dim[1], P.dim[2], P.dim[3], a}, HUD.fXX)
        Button.txtC("0 점", C.HCX, C.SH / 2 + 30, {P.dim[1], P.dim[2], P.dim[3], a * 0.5}, HUD.fM)
        
        if s.timer > 0.8 then
            local mx, my = love.mouse.getPosition()
            local bx, by, bw, bh = C.HCX - 74, C.SH / 2 + 68, 148, 34
            local hov = mx >= bx and mx <= bx + bw and my >= by and my <= by + bh
            Button.draw(bx, by, bw, bh, "계속", true, hov, HUD.fM)
        end
        return
    end

    local lw, lh = 320, 38
    local startY = 390
    for idx, h in ipairs(s.revealed) do
        local age = (idx == #s.revealed and s.phase == "reveal") and math.min(1, s.timer / 0.2) or 1
        local cy = startY + (idx - 1) * (lh + 4)
        local ox = (1 - MathUtils.easeCubic(age)) * 40
        
        love.graphics.push()
        love.graphics.translate(C.HCX - lw / 2 + ox, cy)
        
        love.graphics.setColor(0.08, 0.10, 0.18, age * 0.04)
        love.graphics.rectangle("fill", 0, 2, lw * MathUtils.easeBack(age), lh, 6, 6)
        love.graphics.setColor(1, 1, 1, age * 0.96)
        love.graphics.rectangle("fill", 0, 0, lw * MathUtils.easeBack(age), lh, 6, 6)
        love.graphics.setColor(P.panelBd[1], P.panelBd[2], P.panelBd[3], age * 0.6)
        love.graphics.rectangle("line", 0, 0, lw * MathUtils.easeBack(age), lh, 6, 6)

        local cc = Button.catCol(h.cat)
        love.graphics.setColor(cc[1], cc[2], cc[3], age)
        love.graphics.rectangle("fill", 0, 0, 3, lh, 2, 2)
        love.graphics.setFont(HUD.fS)
        love.graphics.setColor(cc[1], cc[2], cc[3], age * 0.6)
        local cName = h.cat == "MONO" and "같은색" or h.cat == "MIRROR" and "거울" or "계단"
        love.graphics.print(cName, 10, 3)
        
        love.graphics.setFont(HUD.fM)
        love.graphics.setColor(P.text[1], P.text[2], P.text[3], age)
        local rName = PatternsData.RULE_NAMES[h.name] or h.name
        love.graphics.print(rName, 10, 17)
        
        local bw2 = lw * MathUtils.easeBack(age)
        love.graphics.setColor(P.chip[1], P.chip[2], P.chip[3], age)
        love.graphics.rectangle("fill", bw2 - 95, 8, 40, 22, 4, 4)
        love.graphics.setColor(1, 1, 1, age)
        love.graphics.setFont(HUD.fM)
        local cs = tostring(h.chips)
        love.graphics.print(cs, bw2 - 95 + (40 - HUD.fM:getWidth(cs)) / 2, 10)
        
        love.graphics.setColor(P.mult[1], P.mult[2], P.mult[3], age)
        love.graphics.rectangle("fill", bw2 - 50, 8, 40, 22, 4, 4)
        love.graphics.setColor(1, 1, 1, age)
        local ms = "x" .. tostring(h.mult)
        love.graphics.print(ms, bw2 - 50 + (40 - HUD.fM:getWidth(ms)) / 2, 10)
        love.graphics.pop()
    end

    if #s.revealed > 0 then
        local ty = C.SH - 190
        Button.chipB(C.HCX - 35, ty, math.floor(s.dChips))
        love.graphics.setFont(HUD.fL); love.graphics.setColor(P.text)
        love.graphics.print("x", C.HCX - 4, ty - 12)
        Button.multB(C.HCX + 35, ty, math.floor(s.dMult))
    end

    if s.phase == "total" then
        local a = math.min(1, s.timer / 0.35)
        local sc = MathUtils.easeElastic(a)
        local sy = C.SH - 110
        
        love.graphics.push()
        love.graphics.translate(C.HCX, sy)
        love.graphics.scale(sc, sc)
        love.graphics.setFont(HUD.fXX)
        local st = tostring(math.floor(s.dTotal))
        love.graphics.setColor(0, 0, 0, 0.06)
        love.graphics.print(st, -HUD.fXX:getWidth(st) / 2 + 1, -HUD.fXX:getHeight() / 2 + 1)
        love.graphics.setColor(P.gold)
        love.graphics.print(st, -HUD.fXX:getWidth(st) / 2, -HUD.fXX:getHeight() / 2)
        love.graphics.pop()
        
        Button.txtC("점", C.HCX, sy + 25 * sc, {P.dim[1], P.dim[2], P.dim[3], a * 0.6}, HUD.fM)
        
        if s.timer > 1.2 then
            local mx, my = love.mouse.getPosition()
            local bx, by, bw, bh = C.HCX - 74, sy + 44, 148, 34
            local hov = mx >= bx and mx <= bx + bw and my >= by and my <= by + bh
            Button.draw(bx, by, bw, bh, "계속", true, hov, HUD.fM)
            Button.txtC("Enter / Space", C.HCX, by + bh + 8, P.dim, HUD.fS)
        end
    end
end

-- 관문 클리어 결과 카드 그리기 (S.result 이식)
function ResultState.drawResult()
    love.graphics.setColor(0.04, 0.05, 0.08, 0.85)
    love.graphics.rectangle("fill", 0, 0, C.SW, C.SH)

    local pw, ph = 360, 420
    local px, py = C.HCX - pw / 2, C.SH / 2 - ph / 2
    
    love.graphics.setColor(0.08, 0.10, 0.18, 0.06)
    love.graphics.rectangle("fill", px, py + 4, pw, ph + 2, 14, 14)
    love.graphics.setColor(0.08, 0.10, 0.18, 0.08)
    love.graphics.rectangle("fill", px, py + 2, pw, ph, 14, 14)
    love.graphics.setColor(1, 1, 1, 0.98)
    love.graphics.rectangle("fill", px, py, pw, ph, 14, 14)
    
    love.graphics.setColor(P.panelBd)
    love.graphics.setLineWidth(1.2)
    love.graphics.rectangle("line", px, py, pw, ph, 14, 14)

    Button.txtC("관문 통과", px + pw / 2, py + 14, P.gold, HUD.fL)
    love.graphics.setColor(P.panelBd)
    love.graphics.line(px + 20, py + 42, px + pw - 20, py + 42)

    local y = py + 52
    if #G.detected == 0 then
        Button.txtC("맞는 규칙 없음", px + pw / 2, y + 10, P.dim, HUD.fL)
    else
        for _, h in ipairs(G.detected) do
            local cc = Button.catCol(h.cat)
            love.graphics.setColor(cc)
            love.graphics.circle("fill", px + 20, y + 7, 3)
            love.graphics.setFont(HUD.fS)
            love.graphics.setColor(cc[1], cc[2], cc[3], 0.55)
            local cName = h.cat == "MONO" and "같은색" or h.cat == "MIRROR" and "거울" or "계단"
            love.graphics.print(cName, px + 30, y)
            
            love.graphics.setFont(HUD.fM)
            love.graphics.setColor(P.text)
            local rName = PatternsData.RULE_NAMES[h.name] or h.name
            love.graphics.print(rName, px + 95, y - 1)
            
            love.graphics.setColor(P.chip[1], P.chip[2], P.chip[3], 0.80)
            love.graphics.rectangle("fill", px + pw - 95, y, 38, 18, 3, 3)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(HUD.fS)
            local cs = tostring(h.chips)
            love.graphics.print(cs, px + pw - 95 + (38 - HUD.fS:getWidth(cs)) / 2, y + 2)
            
            love.graphics.setColor(P.mult[1], P.mult[2], P.mult[3], 0.80)
            love.graphics.rectangle("fill", px + pw - 52, y, 38, 18, 3, 3)
            love.graphics.setColor(1, 1, 1)
            local ms = "x" .. tostring(h.mult)
            love.graphics.print(ms, px + pw - 52 + (38 - HUD.fS:getWidth(ms)) / 2, y + 2)
            y = y + 25
        end
        y = y + 4
        love.graphics.setColor(P.panelBd)
        love.graphics.line(px + 20, y, px + pw - 20, y)
        y = y + 6
        
        local tc, tm = 0, 0
        for _, h in ipairs(G.detected) do 
            tc = tc + h.chips
            tm = tm + h.mult 
        end
        love.graphics.setFont(HUD.fM)
        love.graphics.setColor(P.dim)
        love.graphics.print("합계:", px + 20, y)
        Button.chipB(px + pw - 75, y + 9, tc)
        love.graphics.setFont(HUD.fM)
        love.graphics.setColor(P.text)
        love.graphics.print("x", px + pw - 50, y)
        Button.multB(px + pw - 30, y + 9, tm)
    end

    -- 골드 정산 정보 그리기 (balance.lua 보상 공식 이용)
    local Balance = require("data.balance")
    local totalGold, baseGold, discGold, interestGold, jokerGold = Balance.calcGoldReward(G.gold, G.discLeft, G.jokers)
    
    local gx = px + 20
    local gy = py + ph - 175
    local gw = pw - 40
    local gh = 70
    
    love.graphics.setColor(0.12, 0.14, 0.18)
    love.graphics.rectangle("fill", gx, gy, gw, gh, 6, 6)
    love.graphics.setColor(P.panelBd)
    love.graphics.rectangle("line", gx, gy, gw, gh, 6, 6)
    
    love.graphics.setFont(HUD.fS)
    love.graphics.setColor(P.dim)
    love.graphics.print("코인 받기:", gx + 10, gy + 8)
    
    local gtxt = string.format("기본 +$3  바꾸기 +$%d  저금 +$%d  도우미 +$%d", discGold, interestGold, jokerGold)
    love.graphics.setColor(P.text)
    love.graphics.print(gtxt, gx + 10, gy + 26)
    
    love.graphics.setFont(HUD.fM)
    love.graphics.setColor(P.gold)
    local totTxt = "총 코인: +$" .. totalGold
    love.graphics.print(totTxt, gx + gw - HUD.fM:getWidth(totTxt) - 10, gy + 45)

    -- 라운드 획득 점수
    love.graphics.setFont(HUD.fXX)
    local st = tostring(G.rndScore)
    love.graphics.setColor(0, 0, 0, 0.06)
    love.graphics.print(st, px + (pw - HUD.fXX:getWidth(st)) / 2 + 1, py + ph - 90 + 1)
    love.graphics.setColor(P.gold)
    love.graphics.print(st, px + (pw - HUD.fXX:getWidth(st)) / 2, py + ph - 90)
    Button.txtC("점", px + pw/2, py + ph - 48, {P.dim[1], P.dim[2], P.dim[3], 0.5}, HUD.fS)

    -- 계속 버튼
    local mx, my = love.mouse.getPosition()
    local bx, by, bw, bh = px + (pw - 150) / 2, py + ph - 40, 150, 34
    local hov = mx >= bx and mx <= bx + bw and my >= by and my <= by + bh
    local label = G.score >= G.targetScore and "상점으로" or "모험 종료"
    Button.draw(bx, by, bw, bh, label, true, hov, HUD.fM)
end

-- 시퀀스 계속 진행 처리 (main.lua 로직 완전 보존)
local function proceedNext()
    if not G then return end
    
    local s = ScoreSys.getState()
    s.active = false
    G.score = G.score + G.rndScore
    G.totalScore = G.totalScore + G.rndScore
    
    if G.score >= G.targetScore then
        -- 관문 통과 보상 지급 및 상점 전환
        local Balance = require("data.balance")
        local totalGold = Balance.calcGoldReward(G.gold, G.discLeft, G.jokers)
        G.gold = G.gold + totalGold
        
        -- 다음 스테이지로 진행도 미리 변경 (상점에서 클리어 상태가 올바르게 표시되도록 함)
        G.stage = G.stage + 1
        if G.stage > 3 then
            G.stage = 1
            G.ante = G.ante + 1
        end
        
        -- 특별 관문 규칙 미리 설정
        if G.stage == 1 then
            local gimmicks = {"no_red", "no_black", "no_discard", "high_target"}
            G.bossGimmick = gimmicks[love.math.random(1, #gimmicks)]
        end
        
        G.phase = "shop"
        local shop = require("systems.joker_system")
        local shopState = require("states.settings_state")
        shopState.enterShop(G) -- 상점 품목 생성
        G.stateMachine:change("shop", G)
        Audio.play("clear")
        G.notice("+$" .. totalGold .. " 획득 (기본+바꾸기+저금)", "ok")
    elseif G.execLeft > 0 then
        -- 아직 기회가 남음: 패 드로우 후 play 상태 복귀
        G.phase = "play"
        local need = C.HN - #G.hand
        local drawn = Tile.drawCards(G.deck, need)
        for _, c in ipairs(drawn) do
            table.insert(G.hand, c)
        end
        G.board = {}
        for i = 1, C.BN do G.board[i] = nil end
        G.stateMachine:change("play", G)
    else
        -- 횟수 초과: 게임오버
        G.phase = "gameover"
        G.stateMachine:change("play", G) -- 게임오버 오버레이는 gameplay_state에서 그립니다.
        Audio.play("gameover")
    end
end

-- ── 마우스 입력 ──
function ResultState.mousepressed(x, y, btn)
    if btn ~= 1 or not G then return end

    if G.phase == "scoring" then
        local s = ScoreSys.getState()
        local proceed = false
        if s.phase == "total" and s.timer > 1.2 then
            proceed = true
        elseif s.phase == "nohand" and s.timer > 0.8 then
            proceed = true
        end
        
        if proceed then
            proceedNext()
        end
        return
    end

    if G.phase == "result" then
        local pw, ph = 360, 420
        local px, py = C.HCX - pw / 2, C.SH / 2 - ph / 2
        local bx, by, bw, bh = px + (pw - 150) / 2, py + ph - 40, 150, 34
        
        if x >= bx and x <= bx + bw and y >= by and y <= by + bh then
            proceedNext()
        end
    end
end

function ResultState.mousereleased(x, y, btn)
end

-- ── 키보드 입력 ──
function ResultState.keypressed(key)
    if not G then return end

    if key == "return" or key == "space" then
        if G.phase == "scoring" then
            local s = ScoreSys.getState()
            local proceed = false
            if s.phase == "total" and s.timer > 1.2 then
                proceed = true
            elseif s.phase == "nohand" and s.timer > 0.8 then
                proceed = true
            end
            
            if proceed then
                proceedNext()
            end
        elseif G.phase == "result" then
            proceedNext()
        end
    end
end

return ResultState
