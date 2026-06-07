------------------------------------------------------------
-- balance.lua · 목표 점수 공식 및 골드 보상 공식
------------------------------------------------------------
local Balance = {}

-- 기본 목표 점수 리스트 (테스트용)
Balance.TARGETS = {300, 1000, 2500, 6000, 15000, 35000, 80000, 180000, 400000, 1000000}

-- 보스 기믹 종류
Balance.BOSS_GIMMICKS = {"no_red", "no_black", "no_discard", "high_target"}

-- Ante 및 Stage에 따른 목표 점수 스케일링 계산 (중복 로직 통합)
function Balance.getTargetScore(ante, stage, bossGimmick)
    local base = 180
    local target = 0
    if ante == 1 then
        if stage == 1 then target = 300
        elseif stage == 2 then target = 700
        else target = 1500 end
    else
        local multi = (stage == 1 and 1 or stage == 2 and 1.8 or 3.5)
        target = math.floor(base * math.pow(2.1, ante - 1) * multi * 10)
        target = math.floor(target / 100) * 100
    end
    
    -- 보스 기믹: 목표 점수 1.5배 상승
    if stage == 3 and bossGimmick == "high_target" then
        target = math.floor(target * 1.5)
    end
    
    return target
end

-- 라운드 클리어 골드 보상 계산 (골드 보유량, 남은 바꾸기 횟수, 보유 조커 목록 입력)
function Balance.calcGoldReward(currentGold, discLeft, jokers)
    local base = 3
    local discBonus = discLeft or 0
    local interest = math.min(5, math.floor(currentGold / 5))
    local jokerBonus = 0
    
    for _, j in ipairs(jokers or {}) do
        if j.id == "gold_rush" then 
            jokerBonus = 4 
        end
    end
    
    local total = base + discBonus + interest + jokerBonus
    return total, base, discBonus, interest, jokerBonus
end

return Balance
