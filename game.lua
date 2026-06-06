------------------------------------------------------------
-- game.lua · 게임 상태, 덱 관리, 로직
------------------------------------------------------------
local C = require("config")
local D = require("detect")
local G = {}

-- ── 상태 ──
G.board      = {}
G.hand       = {}
G.deck       = {}
G.score      = 0
G.dScore     = 0       -- 부드러운 표시용
G.round      = 1
G.rndScore   = 0
G.discLeft   = C.MAXDISC
G.phase      = "play"  -- play | scoring | result | gameover | shop
G.hSlot      = -1      -- 호버 슬롯
G.hCard      = -1      -- 호버 카드
G.detected   = {}
G.slotAnim   = {}      -- [i] = {t, dur}

-- 드래그 관련
G.dragIndex   = -1
G.dragX, G.dragY = 0, 0
G.dragStartPos = {x = 0, y = 0}

-- 목표 점수 및 런닝 스테이지 (Balatro style)
G.targetScore = 300
G.ante        = 1
G.stage       = 1      -- 1: Small, 2: Big, 3: Boss
G.bossGimmick = "none" -- none | no_red | no_black | no_discard | high_target
G.gold        = 4
G.jokers      = {}     -- 보유 조커 목록
G.shopItems   = {}     -- 상점 품목 목록
G.deckConfig  = {}     -- 영구 덱 설정

-- 족보 레벨 업 업그레이드 스탯
G.handStats = {
    ["Mini Mono"]      = {level=1, chips=30,  mult=3,  scaleChips=15, scaleMult=1.5},
    ["Half Mono"]      = {level=1, chips=60,  mult=5,  scaleChips=25, scaleMult=2.0},
    ["Tower"]          = {level=1, chips=150, mult=12, scaleChips=40, scaleMult=3.0},
    ["Half Mirror"]    = {level=1, chips=100, mult=8,  scaleChips=30, scaleMult=2.5},
    ["Grand Mirror"]   = {level=1, chips=400, mult=40, scaleChips=80, scaleMult=8.0},
    ["Half Step"]      = {level=1, chips=120, mult=10, scaleChips=35, scaleMult=3.0},
    ["Perfect Ladder"] = {level=1, chips=300, mult=25, scaleChips=60, scaleMult=5.0},
}

-- 연출용 (주스)
G.shake      = 0
G.particles  = {}
G.roundStartAnim = { t = 0, dur = 1.6, active = true, subText = "" }

-- 스코어링 시퀀스
G.sc = {
    active = false, hands = {}, idx = 0, timer = 0,
    phase = "idle",   -- reveal | total | nohand
    dChips = 0, dMult = 0, tChips = 0, tMult = 0,
    dTotal = 0, revealed = {},
    prevDChips = 0, prevDMult = 0,
}



-- ── 덱 ──
function G.createDeck()
    local d = {}
    for _, card in ipairs(G.deckConfig) do
        table.insert(d, {name=card.name, color={card.color[1],card.color[2],card.color[3]}})
    end
    for i = #d, 2, -1 do
        local j = love.math.random(1, i)
        d[i], d[j] = d[j], d[i]
    end
    return d
end

function G.drawCards(n)
    local drawn = {}
    for _ = 1, n do
        if #G.deck > 0 then
            local c = table.remove(G.deck)
            c.sel = false
            c.spawnT = love.timer.getTime()
            table.insert(drawn, c)
        end
    end
    return drawn
end

-- ── 선택 관련 ──
function G.selCards()
    local s = {}
    for i, c in ipairs(G.hand) do if c.sel then table.insert(s, i) end end
    return s
end

function G.selCount()
    local n = 0
    for _, c in ipairs(G.hand) do if c.sel then n = n + 1 end end
    return n
end

-- ── 라운드 시작 ──
function G.newRound()
    G.board = {}
    for i = 1, C.BN do G.board[i] = nil end
    G.slotAnim = {}
    G.deck = G.createDeck()
    G.hand = G.drawCards(C.HN)
    G.discLeft = C.MAXDISC
    
    -- 보스 기믹: 디스카드 차단
    if G.stage == 3 and G.bossGimmick == "no_discard" then
        G.discLeft = 0
    end
    
    G.phase = "play"
    G.detected = {}
    G.rndScore = 0
    G.hSlot = -1
    G.hCard = -1
    G.dragIndex = -1
    G.sc.active = false
    G.sc.revealed = {}
    
    -- 목표 점수 계산 (Ante & Stage 기준 발라트로풍 스케일링)
    local base = 250
    if G.ante == 1 then
        if G.stage == 1 then G.targetScore = 300
        elseif G.stage == 2 then G.targetScore = 700
        else G.targetScore = 1500 end
    else
        local multi = (G.stage == 1 and 1 or G.stage == 2 and 1.8 or 3.5)
        G.targetScore = math.floor(base * math.pow(2.4, G.ante - 1) * multi * 10)
        G.targetScore = math.floor(G.targetScore / 100) * 100
    end
    
    -- 보스 기믹: 목표 점수 1.5배 상승
    if G.stage == 3 and G.bossGimmick == "high_target" then
        G.targetScore = math.floor(G.targetScore * 1.5)
    end
    
    G.shake = 0
    G.particles = {}
    
    -- 라운드 배너 애니메이션 트리거
    G.roundStartAnim.t = 0
    G.roundStartAnim.active = true
end

function G.reset()
    G.score = 0
    G.dScore = 0
    G.round = 1
    G.ante = 1
    G.stage = 1
    G.gold = 4
    G.jokers = {}
    G.bossGimmick = "none"
    
    -- 족보 레벨 초기화
    for name, stats in pairs(G.handStats) do
        stats.level = 1
        stats.chips = (name == "Mini Mono" and 30 or name == "Half Mono" and 60 or name == "Tower" and 150 or name == "Half Mirror" and 100 or name == "Grand Mirror" and 400 or name == "Half Step" and 120 or 300)
        stats.mult = (name == "Mini Mono" and 3 or name == "Half Mono" and 5 or name == "Tower" and 12 or name == "Half Mirror" and 8 or name == "Grand Mirror" and 40 or name == "Half Step" and 10 or 25)
    end
    
    G.deckConfig = {}
    local perColor = C.DECK / #C.COLORS
    for _, c in ipairs(C.COLORS) do
        for _ = 1, perColor do
            table.insert(G.deckConfig, {name=c.name, color={c.color[1],c.color[2],c.color[3]}})
        end
    end
    
    G.newRound()
    G.phase = "title" -- 시작 시 타이틀 화면으로
end



-- ── 배치 ──
function G.place(ci, si)
    if si < 1 or si > C.BN or G.board[si] then return false end
    local card = G.hand[ci]
    if not card then return false end

    G.board[si] = {name=card.name, color={card.color[1],card.color[2],card.color[3]}}
    table.remove(G.hand, ci)

    G.slotAnim[si] = {t=0, dur=0.28}
    G.shake = G.shake + 3
    
    -- 배치 파티클 스폰
    local sx = C.BX + (si-1)*(C.BSW+C.BGAP) + C.BSW/2
    local sy = C.BY + C.BSH/2
    G.spawnParticles(sx, sy, card.color, 12)
    require("sound").play("place")

    -- 보드 풀?
    local full = true
    for i = 1, C.BN do if not G.board[i] then full = false; break end end
    if full then
        G.detected = D.evaluate(G.board)
        
        -- 족보 레벨 업 수치 주입 및 보스 기믹(무력화) 필터
        for _, h in ipairs(G.detected) do
            local stats = G.handStats[h.name]
            if stats then
                h.chips = stats.chips
                h.mult = stats.mult
            end
            -- 보스 기믹 필터링
            if G.stage == 3 then
                if G.bossGimmick == "no_red" and string.find(h.pat, "R") then
                    h.chips = 0
                    h.mult = 0
                elseif G.bossGimmick == "no_black" and string.find(h.pat, "K") then
                    h.chips = 0
                    h.mult = 0
                end
            end
        end
        
        G.rndScore = G.calcTotalScore()
        G.startScoring()
    end
    return true
end


-- ── 배치 취소 (회수) ──
function G.recall(si)
    if si < 1 or si > C.BN or not G.board[si] then return false end
    local card = G.board[si]
    G.board[si] = nil
    card.sel = false
    card.spawnT = love.timer.getTime()
    table.insert(G.hand, card)
    require("sound").play("recall")
    return true
end

-- ── 카드 위치 교환 (Swap) ──
function G.swap(ci, si)
    if si < 1 or si > C.BN or not G.board[si] then return false end
    local cardInHand = G.hand[ci]
    if not cardInHand then return false end
    local cardOnBoard = G.board[si]
    
    G.board[si] = {name=cardInHand.name, color={cardInHand.color[1],cardInHand.color[2],cardInHand.color[3]}}
    G.hand[ci] = {name=cardOnBoard.name, color={cardOnBoard.color[1],cardOnBoard.color[2],cardOnBoard.color[3]}, sel=false, spawnT=love.timer.getTime()}
    
    G.slotAnim[si] = {t=0, dur=0.28}
    G.shake = G.shake + 4
    
    local sx = C.BX + (si-1)*(C.BSW+C.BGAP) + C.BSW/2
    local sy = C.BY + C.BSH/2
    G.spawnParticles(sx, sy, cardInHand.color, 8)
    require("sound").play("place")
    return true
end

-- ── 디스카드 ──
function G.discard()
    if G.discLeft <= 0 then return end
    local sel = G.selCards()
    if #sel == 0 then return end
    G.discLeft = G.discLeft - 1
    table.sort(sel, function(a,b) return a > b end)
    for _, i in ipairs(sel) do table.remove(G.hand, i) end
    local drawn = G.drawCards(#sel)
    for _, c in ipairs(drawn) do table.insert(G.hand, c) end
    require("sound").play("discard")
end


-- ── 스코어링 ──
function G.startScoring()
    G.phase = "scoring"
    local s = G.sc
    s.active = true
    s.hands = G.detected
    s.idx = 0; s.timer = 0
    s.dChips = 0; s.dMult = 0
    s.tChips = 0; s.tMult = 0
    s.dTotal = 0; s.revealed = {}
    s.prevDChips = 0; s.prevDMult = 0
    s.phase = #G.detected == 0 and "nohand" or "reveal"
end

function G.updateScoring(dt)
    local s = G.sc
    if not s.active then return end
    s.timer = s.timer + dt

    if s.phase == "nohand" then
        if s.timer > 1.8 then
            s.active = false
            G.score = G.score + G.rndScore
            G.phase = "result"
            if G.score >= G.targetScore then
                require("sound").play("clear")
            end
        end
        return
    end

    local function lr(a,b,t) return a + (b-a) * math.max(0,math.min(1,t)) end

    if s.phase == "reveal" then
        if s.timer >= 0.5 then
            s.idx = s.idx + 1; s.timer = 0
            if s.idx <= #s.hands then
                local h = s.hands[s.idx]
                table.insert(s.revealed, h)
                s.tChips = s.tChips + h.chips
                s.tMult  = s.tMult  + h.mult
                
                require("sound").play("reveal")
                G.shake = G.shake + 8
                
                -- 스코어링 족보 출현 파티클 스폰 (보드의 카드 위치에서)
                for j = 1, C.BN do
                    if G.board[j] then
                        local sx = C.BX + (j-1)*(C.BSW+C.BGAP) + C.BSW/2
                        local sy = C.BY + C.BSH/2
                        G.spawnParticles(sx, sy, G.board[j].color, 5)
                    end
                end
            else
                s.phase = "total"; s.timer = 0
            end
        end
        
        s.dChips = lr(s.dChips, s.tChips, dt * 10)
        s.dMult  = lr(s.dMult,  s.tMult,  dt * 10)
        
        -- 점수 누적 틱 사운드
        if math.floor(s.dChips) > s.prevDChips or math.floor(s.dMult) > s.prevDMult then
            require("sound").play("tick")
        end
        s.prevDChips = math.floor(s.dChips)
        s.prevDMult = math.floor(s.dMult)
    end

    if s.phase == "total" then
        s.dTotal = lr(s.dTotal, G.rndScore, dt * 6)
        if math.abs(s.dTotal - G.rndScore) < 1 then s.dTotal = G.rndScore end
        
        if math.floor(s.dTotal) > s.prevDChips then
            require("sound").play("tick")
            s.prevDChips = math.floor(s.dTotal)
        end
        
        if s.timer >= 2.2 then
            s.active = false
            G.score = G.score + G.rndScore
            G.phase = "result"
            if G.score >= G.targetScore then
                require("sound").play("clear")
            end
        end
    end
end


-- ── 파티클 스폰 ──
function G.spawnParticles(x, y, color, count)
    count = count or 10
    for _ = 1, count do
        local angle = love.math.random() * math.pi * 2
        local speed = love.math.random(60, 180)
        table.insert(G.particles, {
            x = x,
            y = y,
            dx = math.cos(angle) * speed,
            dy = math.sin(angle) * speed - love.math.random(30, 80),
            color = {color[1], color[2], color[3]},
            rad = love.math.random(2, 4),
            age = 0,
            maxAge = love.math.random(0.3, 0.6)
        })
    end
end

-- ── 조커 및 상점 헬퍼 함수 ──
function G.applyJokers(tc, tm)
    local colorsOnBoard = {}
    local hasMirror = false
    local hasStep = false
    
    for i = 1, C.BN do
        if G.board[i] then
            colorsOnBoard[G.board[i].name] = true
        end
    end
    
    local uniqueColorCount = 0
    for _ in pairs(colorsOnBoard) do uniqueColorCount = uniqueColorCount + 1 end
    
    for _, h in ipairs(G.detected) do
        if h.cat == "MIRROR" and h.chips > 0 then hasMirror = true end
        if h.cat == "STEP" and h.chips > 0 then hasStep = true end
    end
    
    local explain = {}
    for _, j in ipairs(G.jokers) do
        if j.id == "shiny_eye" and colorsOnBoard["White"] then
            tc = tc + 40
            table.insert(explain, j.name .. " (+40 Chips)")
        elseif j.id == "dark_side" and colorsOnBoard["Black"] then
            tm = tm + 4
            table.insert(explain, j.name .. " (+4 Mult)")
        elseif j.id == "mirror_shield" and hasMirror then
            tm = tm * 1.5
            table.insert(explain, j.name .. " (x1.5 Mult)")
        elseif j.id == "rainbow" and uniqueColorCount >= 4 then
            tc = tc + 50
            tm = tm + 5
            table.insert(explain, j.name .. " (+50 Chips, +5 Mult)")
        elseif j.id == "ladder_master" and hasStep then
            tc = tc + 80
            table.insert(explain, j.name .. " (+80 Chips)")
        end
    end
    
    return math.floor(tc), math.floor(tm), explain
end

function G.calcTotalScore()
    local tc, tm = 0, 0
    for _, h in ipairs(G.detected) do
        tc = tc + h.chips
        tm = tm + h.mult
    end
    local finalChips, finalMult, explain = G.applyJokers(tc, tm)
    G.jokerExplain = explain
    return finalChips * finalMult
end

-- 골드 획득 계산
function G.calcGoldReward()
    local base = 3
    local discBonus = G.discLeft
    local interest = math.min(5, math.floor(G.gold / 5))
    local jokerBonus = 0
    for _, j in ipairs(G.jokers) do
        if j.id == "gold_rush" then jokerBonus = 3 end
    end
    local total = base + discBonus + interest + jokerBonus
    return total, base, discBonus, interest, jokerBonus
end

-- 상점 진입
function G.enterShop()
    G.phase = "shop"
    G.shopItems = {}
    
    local pool = {
        -- 족보 강화 (Planet 카드 스타일)
        {type="upgrade", hand="Mini Mono", name="미니 모노 레벨업", desc="미니 모노 레벨 +1\n(+15 칩, +1.5 배수)", price=3},
        {type="upgrade", hand="Half Mono", name="하프 모노 레벨업", desc="하프 모노 레벨 +1\n(+25 칩, +2 배수)", price=3},
        {type="upgrade", hand="Tower", name="타워 레벨업", desc="타워 레벨 +1\n(+40 칩, +3 배수)", price=3},
        {type="upgrade", hand="Half Mirror", name="하프 미러 레벨업", desc="하프 미러 레벨 +1\n(+30 칩, +2.5 배수)", price=3},
        {type="upgrade", hand="Grand Mirror", name="그랜드 미러 레벨업", desc="그랜드 미러 레벨 +1\n(+80 칩, +8 배수)", price=3},
        {type="upgrade", hand="Half Step", name="하프 스텝 레벨업", desc="하프 스텝 레벨 +1\n(+35 칩, +3 배수)", price=3},
        {type="upgrade", hand="Perfect Ladder", name="퍼펙트 래더 레벨업", desc="퍼펙트 래더 레벨 +1\n(+60 칩, +5 배수)", price=3},
        
        -- 조커 (패시브)
        {type="joker", id="shiny_eye", name="반짝이는 눈", desc="보드에 흰색 카드 있을 시:\n+40 칩 보너스", price=6},
        {type="joker", id="dark_side", name="다크 사이드", desc="보드에 검은색 카드 있을 시:\n+4 배수 보너스", price=6},
        {type="joker", id="mirror_shield", name="거울 방패", desc="미러 계열 족보 점수 계산 시:\nx1.5 총 배수", price=6},
        {type="joker", id="rainbow", name="무지개", desc="보드에 4개 이상의 다른 색상\n있을 시: +50 칩, +5 배수", price=7},
        {type="joker", id="ladder_master", name="사다리 장인", desc="스텝 계열 족보 점수 계산 시:\n+80 칩 보너스", price=5},
        {type="joker", id="gold_rush", name="골드 러시", desc="라운드 종료 시\n+$3 추가 골드 획득", price=5},
        
        -- 덱 조작
        {type="deck_add", colorName="Red", colorVal={0.92,0.22,0.25}, name="빨간색 추가", desc="빨간색 카드 1장을\n덱에 영구적으로 추가", price=2},
        {type="deck_add", colorName="Black", colorVal={0.12,0.12,0.16}, name="검은색 추가", desc="검은색 카드 1장을\n덱에 영구적으로 추가", price=2},
        {type="deck_remove", name="카드 제거", desc="무작위 카드 1장을\n덱에서 영구적으로 제거", price=3},
    }
    
    -- 보유 조커 필터링
    local temp = {}
    for _, item in ipairs(pool) do
        local owned = false
        if item.type == "joker" then
            for _, ownedJ in ipairs(G.jokers) do
                if ownedJ.id == item.id then owned = true break end
            end
        end
        if not owned then table.insert(temp, item) end
    end
    
    -- 랜덤 셔플 후 3개 선택
    for i = #temp, 2, -1 do
        local j = love.math.random(1, i)
        temp[i], temp[j] = temp[j], temp[i]
    end
    
    for i = 1, math.min(3, #temp) do
        G.shopItems[i] = {
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

-- 상점 아이템 구매
function G.buyItem(idx)
    local item = G.shopItems[idx]
    if not item or item.sold then return false, "이미 판매되었습니다" end
    if G.gold < item.price then return false, "골드가 부족합니다" end
    
    if item.type == "joker" then
        if #G.jokers >= 3 then
            return false, "조커 슬롯이 가득 찼습니다 (최대 3)"
        end
        table.insert(G.jokers, {id=item.id, name=item.name, desc=item.desc})
    elseif item.type == "upgrade" then
        local stats = G.handStats[item.hand]
        if stats then
            stats.level = stats.level + 1
            stats.chips = stats.chips + stats.scaleChips
            stats.mult = stats.mult + stats.scaleMult
        end
    elseif item.type == "deck_add" then
        table.insert(G.deckConfig, {name=item.colorName, color=item.colorVal})
    elseif item.type == "deck_remove" then
        if #G.deckConfig > 7 then
            table.remove(G.deckConfig, love.math.random(1, #G.deckConfig))
        else
            return false, "덱에 카드가 너무 적습니다"
        end
    end
    
    G.gold = G.gold - item.price
    item.sold = true
    require("sound").play("clear")
    G.shake = G.shake + 4
    return true
end

-- 상점 나가기 및 다음 블라인드 적용
function G.exitShop()
    G.stage = G.stage + 1
    if G.stage > 3 then
        G.stage = 1
        G.ante = G.ante + 1
    end
    
    -- 보스 블라인드 기믹 랜덤 결정
    if G.stage == 3 then
        local gimmicks = {"no_red", "no_black", "no_discard", "high_target"}
        G.bossGimmick = gimmicks[love.math.random(1, #gimmicks)]
    else
        G.bossGimmick = "none"
    end
    
    G.newRound()
end

-- ── 프레임 업데이트 ──
function G.update(dt)
    -- 슬롯 애니메이션
    for i, a in pairs(G.slotAnim) do
        a.t = a.t + dt
        if a.t >= a.dur then G.slotAnim[i] = nil end
    end
    
    -- 라운드 진입 배너 애니메이션
    if G.roundStartAnim.active then
        G.roundStartAnim.t = G.roundStartAnim.t + dt
        if G.roundStartAnim.t >= G.roundStartAnim.dur then
            G.roundStartAnim.active = false
        end
    end
    
    -- 화면 흔들림 감쇠
    if G.shake > 0 then
        G.shake = G.shake * math.exp(-15 * dt)
        if G.shake < 0.1 then G.shake = 0 end
    end
    
    -- 파티클 업데이트
    for i = #G.particles, 1, -1 do
        local p = G.particles[i]
        p.age = p.age + dt
        if p.age >= p.maxAge then
            table.remove(G.particles, i)
        else
            p.x = p.x + p.dx * dt
            p.y = p.y + p.dy * dt
            p.dy = p.dy + 350 * dt -- 중력 적용
        end
    end
    
    -- 부드러운 스코어
    G.dScore = G.dScore + (G.score - G.dScore) * math.min(1, dt * 6)
    if math.abs(G.dScore - G.score) < 1 then G.dScore = G.score end
    -- 스코어링
    G.updateScoring(dt)
end



return G
