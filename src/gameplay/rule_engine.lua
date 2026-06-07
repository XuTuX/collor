------------------------------------------------------------
-- rule_engine.lua · 규칙 강화 레벨 및 보스 기믹 점수 조율 엔진
------------------------------------------------------------
local RuleEngine = {}

-- 감지된 규칙 배열에 사용자의 현재 레벨 스탯을 투영하고, 보스 기믹(점수 제한)을 평가
function RuleEngine.applyStatsAndGimmicks(detectedPatterns, handStats, stage, bossGimmick)
    for _, h in ipairs(detectedPatterns or {}) do
        -- 1. 규칙 강화 레벨 스탯 투영
        local stats = handStats[h.name]
        if stats then
            h.chips = stats.chips
            h.mult = stats.mult
        end
        
        -- 2. 보스 기믹 적용 (Ante Stage 3 에서만 발동)
        if stage == 3 then
            if bossGimmick == "no_red" and string.find(h.pat, "R") then
                h.chips = 0
                h.mult = 0
            elseif bossGimmick == "no_black" and string.find(h.pat, "K") then
                h.chips = 0
                h.mult = 0
            end
        end
    end
    
    return detectedPatterns
end

return RuleEngine
