------------------------------------------------------------
-- tween.lua · 프레임 레이트 보정 값 보간 및 트윈 도구
------------------------------------------------------------
local Tween = {}

-- 특정 수렴 속도(rate)로 현재 값을 목표 값으로 이동시킴
-- 기존 current + (target - current) * math.min(1, dt * rate) 구문을 표준화
function Tween.smoothTo(current, target, rate, dt)
    return current + (target - current) * math.min(1, dt * rate)
end

return Tween
