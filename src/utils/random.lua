------------------------------------------------------------
-- random.lua · 난수 관련 도구 및 셔플 헬퍼
------------------------------------------------------------
local RandomUtils = {}

-- love.math.random 래퍼
function RandomUtils.random(min, max)
    if not min then
        return love.math.random()
    elseif not max then
        return love.math.random(min)
    else
        return love.math.random(min, max)
    end
end

-- 피셔-예이츠 셔플 알고리즘 (기존 game.lua 내부 셔플 로직 공통화)
function RandomUtils.shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = love.math.random(1, i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

-- 리스트에서 임의의 아이템 하나 선택
function RandomUtils.choose(tbl)
    if #tbl == 0 then return nil end
    return tbl[love.math.random(1, #tbl)]
end

return RandomUtils
