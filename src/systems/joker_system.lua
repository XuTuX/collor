------------------------------------------------------------
-- joker_system.lua · 증강체 로직 및 상점 상호작용 관리
------------------------------------------------------------
local C = require("core.constants")
local JokerSystem = {}

-- 증강체 소지 한도 체크
function JokerSystem.canAddJoker(ownedJokers)
    return #ownedJokers < 3
end

-- 점수 산정 과정에서 증강체들의 특수 효과를 체크하여 이벤트 큐에 삽입
function JokerSystem.evaluate(ownedJokers, uniqueColors, ucCount, detectedPatterns, eventsList, board, G)
    local hasMirror = false
    local hasStep = false
    
    for _, h in ipairs(detectedPatterns or {}) do
        if h.cat == "MIRROR" and h.chips > 0 then 
            hasMirror = true 
        end
        if h.cat == "STEP" and h.chips > 0 then 
            hasStep = true 
        end
    end
    
    -- 보드판의 특정 색상 세기
    local redCount = 0
    local yellowCount = 0
    for i = 1, C.BN do
        local card = board and board[i]
        if card then
            if card.name == "Red" then redCount = redCount + 1 end
            if card.name == "Yellow" then yellowCount = yellowCount + 1 end
        end
    end
    
    -- 연쇄 반응(Synergy)을 계산하기 위해 각 증강체의 발동 가능 여부를 pre-check
    local triggered = {}
    for _, j in ipairs(ownedJokers or {}) do
        local isTrig = false
        if j.id == "shiny_eye" and uniqueColors["White"] then
            isTrig = true
        elseif j.id == "dark_side" and uniqueColors["Black"] then
            isTrig = true
        elseif j.id == "mirror_shield" and hasMirror then
            isTrig = true
        elseif j.id == "rainbow" and ucCount >= 4 then
            isTrig = true
        elseif j.id == "ladder_master" and hasStep then
            isTrig = true
        elseif j.id == "chaos" and (not detectedPatterns or #detectedPatterns == 0) then
            isTrig = true
        elseif j.id == "savings" then
            isTrig = true
        elseif j.id == "mono_pride" and ucCount == 1 and board and #board > 0 then
            isTrig = true
        elseif j.id == "burning" and redCount > 0 then
            isTrig = true
        elseif j.id == "lemonade" and yellowCount > 0 then
            isTrig = true
        elseif j.id == "eclipse" and uniqueColors["White"] and uniqueColors["Black"] then
            isTrig = true
        elseif j.id == "alchemy" and redCount >= 2 and yellowCount >= 2 then
            isTrig = true
        elseif j.id == "resonance" and hasMirror and hasStep then
            isTrig = true
        elseif j.id == "time_accelerator" and G and (G.timeScoreSnapshot or 0) >= 4 then
            isTrig = true
        elseif j.id == "reroll_boost" and G and (G.discardMultBonus or 0) > 0 then
            isTrig = true
        end
        triggered[j.id] = isTrig
    end
    
    -- 연쇄 가속기용 활성화 증강체 개수 산출
    local activeCount = 0
    for id, trig in pairs(triggered) do
        if trig and id ~= "overload" then
            activeCount = activeCount + 1
        end
    end
    
    for _, j in ipairs(ownedJokers or {}) do
        local trigger = false
        local bonusChips = 0
        local bonusMult = 0
        local bonusXMult = 1.0
        
        if j.id == "shiny_eye" and triggered["shiny_eye"] then
            trigger = true
            bonusChips = 50
        elseif j.id == "dark_side" and triggered["dark_side"] then
            trigger = true
            bonusMult = 5
        elseif j.id == "mirror_shield" and triggered["mirror_shield"] then
            trigger = true
            bonusXMult = 1.8
        elseif j.id == "rainbow" and triggered["rainbow"] then
            trigger = true
            bonusChips = 60
            bonusMult = 6
        elseif j.id == "ladder_master" and triggered["ladder_master"] then
            trigger = true
            bonusChips = 100
        elseif j.id == "chaos" and triggered["chaos"] then
            trigger = true
            bonusXMult = 2.2
        elseif j.id == "savings" and G then
            trigger = true
            bonusMult = math.floor(G.gold / 2)
        elseif j.id == "mono_pride" and triggered["mono_pride"] then
            trigger = true
            bonusXMult = 2.5
        elseif j.id == "burning" and triggered["burning"] then
            trigger = true
            bonusMult = redCount * 3
        elseif j.id == "lemonade" and triggered["lemonade"] then
            trigger = true
            bonusChips = yellowCount * 25
        elseif j.id == "overload" and activeCount > 0 then
            trigger = true
            bonusMult = activeCount * 4
        elseif j.id == "eclipse" and triggered["eclipse"] then
            trigger = true
            bonusXMult = 1.8
        elseif j.id == "alchemy" and triggered["alchemy"] then
            trigger = true
            bonusChips = 80
            if G then G.gold = G.gold + 2 end
        elseif j.id == "resonance" and triggered["resonance"] then
            trigger = true
            bonusXMult = 2.0
        elseif j.id == "time_accelerator" and triggered["time_accelerator"] then
            trigger = true
            bonusMult = math.floor((G.timeScoreSnapshot or 0) / 4) * 2
        elseif j.id == "reroll_boost" and triggered["reroll_boost"] then
            trigger = true
            bonusMult = G.discardMultBonus or 0
        end
        
        if trigger then
            table.insert(eventsList, {
                type = "joker",
                name = j.name,
                chips = bonusChips,
                mult = bonusMult,
                xmult = bonusXMult
            })
        end
    end
end

return JokerSystem
