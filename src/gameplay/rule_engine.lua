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
            -- 배율 스케일링 인자 S 계산
            local S = 1
            local power = 1.5
            
            if h.cat == "MONO" or h.cat == "MIRROR" or h.cat == "ZIGZAG" then
                S = math.max(1, h.length - 2)
                power = 1.5
            elseif h.cat == "CRESCENDO" then
                S = math.max(1, h.length - 2)
                power = 1.8 -- 등급 스트레이트 난이도 가중치 반영
            elseif h.cat == "TWINS" then
                S = math.max(1, h.pairs)
                power = 1.5
            end
            
            -- 비선형(power승) 스케일링 계산
            local scaleMultiplier = S ^ power
            h.chips = math.floor(stats.chips * scaleMultiplier)
            h.mult = math.floor(stats.mult * scaleMultiplier)
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
