------------------------------------------------------------
-- joker_system.lua · 도우미(조커) 로직 및 상점 상호작용 관리
------------------------------------------------------------
local C = require("core.constants")
local JokerSystem = {}

-- 도우미 소지 한도 체크
function JokerSystem.canAddJoker(ownedJokers)
    return #ownedJokers < 3
end

-- 점수 산정 과정에서 도우미들의 특수 효과를 체크하여 이벤트 큐에 삽입
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
    
    for _, j in ipairs(ownedJokers or {}) do
        local trigger = false
        local bonusChips = 0
        local bonusMult = 0
        local bonusXMult = 1.0
        
        if j.id == "shiny_eye" and uniqueColors["White"] then
            trigger = true
            bonusChips = 50
        elseif j.id == "dark_side" and uniqueColors["Black"] then
            trigger = true
            bonusMult = 5
        elseif j.id == "mirror_shield" and hasMirror then
            trigger = true
            bonusXMult = 1.8
        elseif j.id == "rainbow" and ucCount >= 4 then
            trigger = true
            bonusChips = 60
            bonusMult = 6
        elseif j.id == "ladder_master" and hasStep then
            trigger = true
            bonusChips = 100
        elseif j.id == "chaos" and (not detectedPatterns or #detectedPatterns == 0) then
            trigger = true
            bonusXMult = 2.2
        elseif j.id == "savings" and G then
            trigger = true
            bonusMult = math.floor(G.gold / 2)
        elseif j.id == "mono_pride" and ucCount == 1 and board and #board > 0 then
            trigger = true
            bonusXMult = 2.5
        elseif j.id == "burning" and redCount > 0 then
            trigger = true
            bonusMult = redCount * 3
        elseif j.id == "lemonade" and yellowCount > 0 then
            trigger = true
            bonusChips = yellowCount * 25
        elseif j.id == "gold_rush" then
            -- "gold_rush" 는 라운드 보상 계산(balance.lua) 시 적용되므로 득점 단계에서는 스킵
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
