------------------------------------------------------------
-- game.lua · 게임 상태, 주머니 관리, 로직
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
G.hCard      = -1      -- 호버 색친구
G.detected   = {}
G.slotAnim   = {}      -- [i] = {t, dur}
G.execAnim   = { active = false, cards = {}, idx = 0, timer = 0, phase = "idle" }

-- 드래그 관련
G.dragIndex   = -1
G.dragX, G.dragY = 0, 0
G.dragStartPos = {x = 0, y = 0}
G.dragStartIndex = -1

-- 목표 점수 및 런닝 스테이지 (Balatro style)
G.targetScore = 300
G.ante        = 1
G.stage       = 1      -- 1: Small, 2: Big, 3: Boss
G.bossGimmick = "none" -- none | no_red | no_black | no_discard | high_target
G.gold        = 4
G.jokers      = {}     -- 보유 도우미 목록
G.shopItems   = {}     -- 상점 품목 목록
G.deckConfig  = {}     -- 영구 주머니 설정
G.noticeText  = ""
G.noticeTimer = 0
G.noticeKind  = "info"
G.showBag     = false

-- 색 규칙 레벨 업 스탯
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



local function cloneCard(card)
    return {name=card.name, color={card.color[1], card.color[2], card.color[3]}}
end

-- ── 색친구 주머니 ──
function G.createDeck()
    local d = {}
    for _, card in ipairs(G.deckConfig) do
        table.insert(d, cloneCard(card))
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

function G.selectedCards()
    local picked = {}
    for _, c in ipairs(G.hand) do
        if c.sel then table.insert(picked, c) end
    end
    return picked
end

function G.toggleSelect(i)
    local card = G.hand[i]
    if not card then return false end
    if card.sel then
        card.sel = false
    else
        if G.selCount() >= C.BN then
            G.notice("더 이상 고를 수 없어요", "warn")
            return false
        end
        card.sel = true
    end
    require("sound").play("select")
    return true
end

function G.previewCards()
    local picked = G.selectedCards()
    if #picked == 0 and G.phase ~= "play" then
        return G.board
    end
    return picked
end

function G.selCount()
    local n = 0
    for _, c in ipairs(G.hand) do if c.sel then n = n + 1 end end
    return n
end

function G.handIndexFromX(x)
    local n = #G.hand
    if n <= 1 then return 1 end
    local firstX = C.HCX - ((n - 1) / 2) * C.HSPC
    local idx = math.floor((x - firstX + C.HSPC / 2) / C.HSPC) + 1
    return math.max(1, math.min(n, idx))
end

function G.reorderHand(fromIndex, x)
    if fromIndex < 1 or fromIndex > #G.hand then return false end
    local toIndex = G.handIndexFromX(x)
    if toIndex == fromIndex then return false end
    local card = table.remove(G.hand, fromIndex)
    if toIndex > #G.hand + 1 then toIndex = #G.hand + 1 end
    table.insert(G.hand, toIndex, card)
    require("sound").play("select")
    return true
end

function G.notice(text, kind)
    G.noticeText = text or ""
    G.noticeKind = kind or "info"
    G.noticeTimer = 1.8
end

function G.applyBoard(cards)
    G.board = {}
    G.slotAnim = {}
    for i = 1, C.BN do
        local card = cards[i]
        if card then
            G.board[i] = cloneCard(card)
            G.slotAnim[i] = {t=0, dur=0.28}
            local sx = C.BX + (i-1)*(C.BSW+C.BGAP) + C.BSW/2
            local sy = C.BY + C.BSH/2
            G.spawnParticles(sx, sy, card.color, 8)
        end
    end
end

function G.scoreBoard()
    G.detected = D.evaluate(G.board)
    for _, h in ipairs(G.detected) do
        local stats = G.handStats[h.name]
        if stats then
            h.chips = stats.chips
            h.mult = stats.mult
        end
        if G.stage == 3 then
            if G.bossGimmick == "no_red" and string.find(h.pat, "R") then
                h.chips = 0; h.mult = 0
            elseif G.bossGimmick == "no_black" and string.find(h.pat, "K") then
                h.chips = 0; h.mult = 0
            end
        end
    end

    G.startScoring()
end

function G.startScoring()
    G.phase = "scoring"
    local s = G.sc
    s.active = true
    s.idx = 0
    s.timer = 0
    s.dChips = 0
    s.dMult = 1  -- Mult starts at 1
    s.tChips = 0
    s.tMult = 1
    s.dTotal = 0
    s.prevDChips = 0
    s.prevDMult = 0
    s.revealed = {}
    s.events = {}
    s.hopIdx = {}  -- Cards currently hopping

    -- 1. Card base scores
    local uniqueColors = {}
    for i = 1, C.BN do
        local c = G.board[i]
        if c then
            local base = 10
            for _, info in ipairs(C.COLORS) do
                if info.name == c.name then base = info.base or 10; break end
            end
            table.insert(s.events, {type="card", idx=i, chips=base, name=c.name})
            uniqueColors[c.name] = true
        end
    end

    -- 2. Diversity Bonus
    local ucCount = 0
    for _ in pairs(uniqueColors) do ucCount = ucCount + 1 end
    if ucCount >= 3 then
        local c, m = 0, 0
        if ucCount == 3 then c=10; m=1
        elseif ucCount == 4 then c=30; m=2
        else c=50; m=3 end
        table.insert(s.events, {type="diversity", count=ucCount, chips=c, mult=m})
    end

    -- 3. Rules
    for _, h in ipairs(G.detected) do
        table.insert(s.events, {type="rule", rule=h})
    end

    -- 4. Jokers
    local hasMirror, hasStep = false, false
    for _, h in ipairs(G.detected) do
        if h.cat == "MIRROR" and h.chips > 0 then hasMirror = true end
        if h.cat == "STEP" and h.chips > 0 then hasStep = true end
    end
    for _, j in ipairs(G.jokers) do
        local trig, jc, jm, jx = false, 0, 0, 1
        if j.id == "shiny_eye" and uniqueColors["White"] then trig=true; jc=40 end
        if j.id == "dark_side" and uniqueColors["Black"] then trig=true; jm=4 end
        if j.id == "mirror_shield" and hasMirror then trig=true; jx=1.5 end
        if j.id == "rainbow" and ucCount >= 4 then trig=true; jc=50; jm=5 end
        if j.id == "ladder_master" and hasStep then trig=true; jc=80 end
        if trig then
            table.insert(s.events, {type="joker", name=j.name, chips=jc, mult=jm, xmult=jx})
        end
    end

    -- 5. Total
    table.insert(s.events, {type="total"})
    
    if #s.events == 1 then -- Only total, no cards (shouldn't happen but safe)
        s.phase = "nohand"
    else
        s.phase = "process"
    end
end

function G.updateScoring(dt)
    local s = G.sc
    if not s.active then return end
    s.timer = s.timer + dt

    local function lr(a,b,t) return a + (b-a) * math.max(0,math.min(1,t)) end

    if s.phase == "nohand" then
        if s.timer > 1.8 then
            s.active = false
            G.phase = "result"
        end
        return
    end

    if s.phase == "process" then
        if s.timer >= 0.4 then
            s.idx = s.idx + 1
            s.timer = 0
            s.hopIdx = {} -- Clear hopping cards
            
            if s.idx <= #s.events then
                local e = s.events[s.idx]
                
                if e.type == "card" then
                    s.tChips = s.tChips + e.chips
                    s.hopIdx[e.idx] = true
                    require("sound").play("tick")
                    G.shake = G.shake + 2
                    
                elseif e.type == "diversity" then
                    s.tChips = s.tChips + e.chips
                    s.tMult = s.tMult + e.mult
                    G.notice(e.count.."색 보너스!", "ok")
                    require("sound").play("reveal")
                    G.shake = G.shake + 5
                    for i=1, C.BN do if G.board[i] then s.hopIdx[i] = true end end
                    
                elseif e.type == "rule" then
                    s.tChips = s.tChips + e.rule.chips
                    s.tMult = s.tMult + e.rule.mult
                    table.insert(s.revealed, e.rule)
                    require("sound").play("reveal")
                    G.shake = G.shake + 8
                    for _, hi in ipairs(e.rule.idx or {}) do s.hopIdx[hi] = true end
                    
                elseif e.type == "joker" then
                    s.tChips = s.tChips + e.chips
                    s.tMult = s.tMult + e.mult
                    s.tMult = s.tMult * e.xmult
                    G.notice(e.name.." 발동!", "ok")
                    require("sound").play("reveal")
                    G.shake = G.shake + 5
                    
                elseif e.type == "total" then
                    G.rndScore = math.floor(s.tChips * s.tMult)
                    s.phase = "total"
                    s.timer = 0
                end
            end
        end
        
        s.dChips = lr(s.dChips, s.tChips, dt * 10)
        s.dMult  = lr(s.dMult,  s.tMult,  dt * 10)
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

-- 코인 획득 계산
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
        -- 색 규칙 강화
        {type="upgrade", hand="Mini Mono", name="세 친구 반짝임", desc="세 친구 규칙 +1\n(+15 별, +1.5 콤보)", price=3},
        {type="upgrade", hand="Half Mono", name="네 친구 반짝임", desc="네 친구 규칙 +1\n(+25 별, +2 콤보)", price=3},
        {type="upgrade", hand="Tower", name="색 탑 반짝임", desc="색 탑 규칙 +1\n(+40 별, +3 콤보)", price=3},
        {type="upgrade", hand="Half Mirror", name="작은 거울 반짝임", desc="작은 거울 규칙 +1\n(+30 별, +2.5 콤보)", price=3},
        {type="upgrade", hand="Grand Mirror", name="큰 거울 반짝임", desc="큰 거울 규칙 +1\n(+80 별, +8 콤보)", price=3},
        {type="upgrade", hand="Half Step", name="작은 계단 반짝임", desc="작은 계단 규칙 +1\n(+35 별, +3 콤보)", price=3},
        {type="upgrade", hand="Perfect Ladder", name="무지개 계단 반짝임", desc="무지개 계단 규칙 +1\n(+60 별, +5 콤보)", price=3},

        -- 도우미
        {type="joker", id="shiny_eye", name="반짝이는 눈", desc="위에 하양이 있으면\n+40 별", price=6},
        {type="joker", id="dark_side", name="밤빛 친구", desc="위에 검정이 있으면\n+4 콤보", price=6},
        {type="joker", id="mirror_shield", name="거울 방패", desc="거울 규칙이 나오면\nx1.5 콤보", price=6},
        {type="joker", id="rainbow", name="무지개", desc="다른 색이 4종류\n이상이면\n+50 별, +5 콤보", price=7},
        {type="joker", id="ladder_master", name="계단 대장", desc="계단 규칙이 나오면\n+80 별", price=5},
        {type="joker", id="gold_rush", name="코인 주머니", desc="관문 종료 시\n+$3 코인 추가", price=5},

        -- 색친구 주머니 조정
        {type="deck_add", colorName="Red", colorVal={0.92,0.22,0.25}, name="빨강 추가", desc="빨강 색친구 1개를\n주머니에 계속 추가", price=2},
        {type="deck_add", colorName="Black", colorVal={0.12,0.12,0.16}, name="검정 추가", desc="검정 색친구 1개를\n주머니에 계속 추가", price=2},
        {type="deck_remove", name="색친구 줄이기", desc="무작위 색친구 1개를\n주머니에서 줄이기", price=3},
    }
    
    -- 보유 도우미 필터링
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
    if not item or item.sold then
        G.notice("이미 가져간 물건이에요", "warn")
        return false, "이미 판매되었습니다"
    end
    if G.gold < item.price then
        G.notice("코인이 부족해요", "warn")
        return false, "코인이 부족합니다"
    end
    
    if item.type == "joker" then
        if #G.jokers >= 3 then
            G.notice("도우미 자리가 가득 찼어요", "warn")
            return false, "도우미 자리가 가득 찼습니다 (최대 3)"
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
            G.notice("주머니가 너무 작아요", "warn")
            return false, "주머니에 색친구가 너무 적습니다"
        end
    end
    
    G.gold = G.gold - item.price
    item.sold = true
    require("sound").play("clear")
    G.shake = G.shake + 4
    G.notice("가져왔어요", "ok")
    return true
end

-- 상점 나가기 및 다음 관문 적용
function G.exitShop()
    G.stage = G.stage + 1
    if G.stage > 3 then
        G.stage = 1
        G.ante = G.ante + 1
    end
    
    -- 특별 관문 규칙 랜덤 결정
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
    
    -- 관문 진입 배너 애니메이션
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
    
    -- 짧은 피드백 메시지
    if G.noticeTimer > 0 then
        G.noticeTimer = math.max(0, G.noticeTimer - dt)
    end

    -- 부드러운 스코어
    G.dScore = G.dScore + (G.score - G.dScore) * math.min(1, dt * 6)
    if math.abs(G.dScore - G.score) < 1 then G.dScore = G.score end
    
    -- 실행 애니메이션
    if G.phase == "executing" and G.execAnim.active then
        local a = G.execAnim
        a.timer = a.timer + dt
        if a.phase == "flying" then
            if a.timer >= 0.15 then -- 카드 1개당 딜레이
                local card = a.cards[a.idx]
                G.board[a.idx] = {name=card.name, color={card.color[1],card.color[2],card.color[3]}}
                G.slotAnim[a.idx] = {t=0, dur=0.28}
                G.shake = G.shake + 3
                
                local sx = C.BX + (a.idx-1)*(C.BSW+C.BGAP) + C.BSW/2
                local sy = C.BY + C.BSH/2
                G.spawnParticles(sx, sy, card.color, 12)
                require("sound").play("place")
                
                a.idx = a.idx + 1
                a.timer = 0
                
                if a.idx > #a.cards then
                    a.phase = "done"
                    a.active = false
                    G.scoreBoard()
                end
            end
        end
    end
    
    -- 스코어링
    G.updateScoring(dt)
end



return G
