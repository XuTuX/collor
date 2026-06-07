------------------------------------------------------------
-- math.lua · 수학 및 이징(Easing) 유틸리티 함수
------------------------------------------------------------
local MathUtils = {}

-- 이징: Back Out
function MathUtils.easeBack(t)
    local s = 1.7
    t = t - 1
    return t * t * ((s + 1) * t + s) + 1
end

-- 이징: Cubic Out
function MathUtils.easeCubic(t)
    t = t - 1
    return t * t * t + 1
end

-- 이징: Elastic Out
function MathUtils.easeElastic(t)
    if t == 0 or t == 1 then return t end
    return math.pow(2, -10 * t) * math.sin((t - 0.075) * 2 * math.pi / 0.3) + 1
end

-- 선형 보간 (Lerp)
function MathUtils.lerp(a, b, t)
    return a + (b - a) * math.max(0, math.min(1, t))
end

return MathUtils
