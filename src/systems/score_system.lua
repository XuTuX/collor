------------------------------------------------------------
-- score_system.lua · 득점 시퀀스 및 발라트로 스타일 점수 계산기
------------------------------------------------------------
local ScoreSystem = {}
local C = require("core.constants")
local CharactersData = require("data.characters")
local MathUtils = require("utils.math")
local Tween = require("utils.tween")
local Audio = require("systems.audio_system")
local Effect = require("systems.effect_system")

-- 득점 연출 상태 데이터
local sc = {
    active = false,
    idx = 0,
    timer = 0,
    phase = "idle",   -- reveal | total | nohand | process
    dChips = 0,
    dMult = 1,
    tChips = 0,
    tMult = 1,
    dTotal = 0,
    revealed = {},
    hopIdx = {},
    events = {},
    prevDChips = 0,
    prevDMult = 0
}

function ScoreSystem.clear()
    sc.active = false
    sc.idx = 0
    sc.timer = 0
    sc.phase = "idle"
    sc.dChips = 0
    sc.dMult = 1
    sc.tChips = 0
    sc.tMult = 1
    sc.dTotal = 0
    sc.revealed = {}
    sc.hopIdx = {}
    sc.events = {}
    sc.prevDChips = 0
    sc.prevDMult = 0
end

function ScoreSystem.getState()
    return sc
end

-- 득점 연출 시퀀스 초기화 및 이벤트 리스트 구성
function ScoreSystem.start(board, detectedPatterns, jokers, G)
    sc.active = true
    sc.idx = 0
    sc.timer = 0
    sc.dChips = 0
    sc.dMult = 1
    sc.tChips = 0
    sc.tMult = 1
    sc.dTotal = 0
    sc.prevDChips = 0
    sc.prevDMult = 0
    sc.revealed = {}
    sc.events = {}
    sc.hopIdx = {}

    -- 1. 다채로움 보너스 (Diversity Check)
    local uniqueColors = {}
    for i = 1, C.BN do
        local c = board[i]
        if c then
            uniqueColors[c.name] = true
        end
    end
    local ucCount = 0
    for _ in pairs(uniqueColors) do ucCount = ucCount + 1 end
    if ucCount >= 3 then
        local c, m = 0, 0
        if ucCount == 3 then c = 5; m = 2
        elseif ucCount == 4 then c = 15; m = 3
        else c = 30; m = 4 end
        table.insert(sc.events, {type="diversity", count=ucCount, chips=c, mult=m})
    end

    -- 2. 개별 색친구 기본 점수 가산 (Base Cards Check)
    for i = 1, C.BN do
        local c = board[i]
        if c then
            local base = 10
            for _, info in ipairs(CharactersData) do
                if info.name == c.name then base = info.base or 10; break end
            end
            
            -- 특별 에디션 보너스 적용
            local extraChips = 0
            local extraMult = 0
            if c.edition == "foil" then
                extraChips = 15
            elseif c.edition == "holo" then
                extraMult = 3
            elseif c.edition == "gold" and G then
                G.gold = G.gold + 1
                G.notice("황금 카드 보너스! +$1", "ok")
            end
            
            table.insert(sc.events, {
                type = "card",
                idx = i,
                chips = base + extraChips,
                mult = extraMult,
                name = c.name,
                edition = c.edition
            })
        end
    end

    -- 3. 매칭된 규칙 적용 (Rules Check)
    for _, h in ipairs(detectedPatterns or {}) do
        table.insert(sc.events, {type="rule", rule=h})
    end

    -- 4. 보유 도우미 적용 (Jokers Check)
    local JokerSystem = require("systems.joker_system")
    JokerSystem.evaluate(jokers, uniqueColors, ucCount, detectedPatterns, sc.events, board, G)

    -- 5. 총합 (Total)
    table.insert(sc.events, {type="total"})
    
    if #sc.events == 1 then -- 매칭 규칙도 없고 카드도 없는 예외 상황
        sc.phase = "nohand"
    else
        sc.phase = "process"
    end
end

-- 득점 업데이트 갱신 루프
function ScoreSystem.update(dt, G)
    if not sc.active then return end
    sc.timer = sc.timer + dt

    if sc.phase == "nohand" then
        if sc.timer > 1.8 then
            sc.active = false
            G.phase = "result"
        end
        return
    end

    if sc.phase == "process" then
        if sc.timer >= 0.4 then
            sc.idx = sc.idx + 1
            sc.timer = 0
            sc.hopIdx = {} -- 뜀박질 상태 클리어
            if G then G.executingCardIdx = -1 end -- 활성화 표정 초기화
            
            if sc.idx <= #sc.events then
                local e = sc.events[sc.idx]
                
                if e.type == "card" then
                    sc.tChips = sc.tChips + e.chips
                    sc.tMult = sc.tMult + (e.mult or 0)
                    sc.hopIdx[e.idx] = true
                    if G then 
                        G.executingCardIdx = e.idx -- 현재 계산 중인 카드 표정 변경용
                        G.chipScale = 1.30
                        if (e.mult or 0) > 0 then
                            G.multScale = 1.30
                        end
                    end
                    Audio.play("place")
                    G.shake = G.shake + 2
                    
                    local sx = C.BX + (e.idx-1)*(C.BSW+C.BGAP) + C.BSW/2
                    local sy = C.BY - 10
                    
                    local msg = "+" .. e.chips
                    local col = C.P.chip
                    if e.edition == "foil" then
                        msg = "+" .. e.chips .. " (포일!)"
                        col = C.P.cMirr
                    elseif e.edition == "holo" then
                        msg = "+" .. e.chips .. "  x" .. e.mult .. " (홀로!)"
                        col = C.P.mult
                    elseif e.edition == "gold" then
                        msg = "+" .. e.chips .. " (황금!)"
                        col = C.P.gold
                    end
                    Effect.spawnTextParticle(sx, sy, msg, col)
                    
                elseif e.type == "diversity" then
                    sc.tChips = sc.tChips + e.chips
                    sc.tMult = sc.tMult + e.mult
                    if G then
                        G.chipScale = 1.35
                        G.multScale = 1.35
                    end
                    G.notice(e.count.."색 보너스! (+"..e.chips..", x"..e.mult..")", "ok")
                    Audio.play("reveal")
                    G.shake = G.shake + 5
                    for i = 1, C.BN do 
                        if G.board[i] then sc.hopIdx[i] = true end 
                    end
                    
                    Effect.spawnTextParticle(C.HCX, C.BY - 40, "+" .. e.chips .. "  x" .. e.mult, C.P.gold)
                    
                elseif e.type == "rule" then
                    sc.tChips = sc.tChips + e.rule.chips
                    sc.tMult = sc.tMult + e.rule.mult
                    if G then
                        G.chipScale = 1.40
                        G.multScale = 1.40
                    end
                    table.insert(sc.revealed, e.rule)
                    Audio.play("reveal")
                    G.shake = G.shake + 8
                    for _, hi in ipairs(e.rule.idx or {}) do 
                        sc.hopIdx[hi] = true 
                        if G then G.executingCardIdx = hi end -- 족보 기여 카드 표정 윙크
                    end
                    
                    Effect.spawnTextParticle(C.HCX, C.BY - 50, "+" .. e.rule.chips .. "  x" .. e.rule.mult, C.P.mult)
                    
                elseif e.type == "joker" then
                    sc.tChips = sc.tChips + e.chips
                    sc.tMult = sc.tMult + e.mult
                    sc.tMult = sc.tMult * e.xmult
                    if G then
                        if e.chips > 0 then G.chipScale = 1.35 end
                        if e.mult > 0 or e.xmult > 1 then G.multScale = 1.35 end
                    end
                    G.notice(e.name.." 발동!", "ok")
                    Audio.play("reveal")
                    G.shake = G.shake + 5
                    
                    local msg = ""
                    if e.chips > 0 then msg = msg .. "+" .. e.chips .. " " end
                    if e.mult > 0 then msg = msg .. "x" .. e.mult .. " " end
                    if e.xmult > 1 then msg = msg .. "x" .. e.xmult end
                    Effect.spawnTextParticle(C.HCX, C.BY - 60, msg, C.P.gold)
                    
                elseif e.type == "total" then
                    G.rndScore = math.floor(sc.tChips * sc.tMult)
                    sc.phase = "total"
                    sc.timer = 0
                    if G then 
                        G.executingCardIdx = -1 
                        G.chipScale = 1.45
                        G.multScale = 1.45
                    end
                    Audio.play("reveal")
                end
            end
        end
        
        -- 부드러운 값 추종 (utils/tween 적용)
        sc.dChips = Tween.smoothTo(sc.dChips, sc.tChips, 10, dt)
        sc.dMult  = Tween.smoothTo(sc.dMult,  sc.tMult,  10, dt)
    end

    if sc.phase == "total" then
        sc.dTotal = Tween.smoothTo(sc.dTotal, G.rndScore, 6, dt)
        if math.abs(sc.dTotal - G.rndScore) < 1 then 
            sc.dTotal = G.rndScore 
        end
        
        if math.floor(sc.dTotal) > sc.prevDChips then
            Audio.play("tick")
            sc.prevDChips = math.floor(sc.dTotal)
            G.shake = G.shake + 0.5 -- 롤링 카운팅 중 흔들림
        end
    end
end

return ScoreSystem

