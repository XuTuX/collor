------------------------------------------------------------
-- character.lua · 색친구(캐릭터) 그래픽 렌더링 엔티티
------------------------------------------------------------
local Character = {}
local C = require("core.constants")
local P = C.P

-- 캐릭터 둥글둥글 렌더링 (R.character 로직 완벽 보존)
function Character.draw(x, y, rad, blk, opts)
    if not blk then return end
    opts = opts or {}
    local cr, cg, cb = blk.color[1], blk.color[2], blk.color[3]
    local bob = opts.bob or 0

    -- 바닥 그림자 타원
    love.graphics.setColor(0, 0, 0, 0.18)
    love.graphics.ellipse("fill", x, y + rad + 3, rad * 0.6, rad * 0.15)

    -- 외곽선 테두리 그림자용 두꺼운 원
    love.graphics.setColor(cr * 0.45, cg * 0.45, cb * 0.45)
    love.graphics.circle("fill", x, y + bob, rad + 1.5)
    
    -- 기본 몸통 원
    love.graphics.setColor(cr, cg, cb)
    love.graphics.circle("fill", x, y + bob, rad)
    
    -- 입체 후광 하이라이트 아크
    love.graphics.setColor(1, 1, 1, 0.14)
    love.graphics.arc("fill", x, y + bob - 1, rad * 0.72, -math.pi, -0.05)

    -- 몸통 선 테두리색 (하양, 검정에 따른 개성 반영)
    love.graphics.setLineWidth(blk.name == "White" and 2 or 1.2)
    if blk.name == "White" then
        love.graphics.setColor(0.12, 0.12, 0.16, 0.85)
    elseif blk.name == "Black" then
        love.graphics.setColor(0.28, 0.30, 0.40, 0.40)
    else
        love.graphics.setColor(cr * 0.50, cg * 0.50, cb * 0.50, 0.45)
    end
    love.graphics.circle("line", x, y + bob, rad)

    -- 눈동자 굴리기: 마우스 커서 위치를 추종하는 자연스러운 눈동자
    local eyeY = y + bob - rad * 0.13
    local eyeX = rad * 0.28
    local eyeW = rad * 0.15
    local eyeH = rad * 0.20
    
    local mx, my = love.mouse.getPosition()
    local dx, dy = mx - x, my - (y + bob)
    local dist = math.max(1, math.sqrt(dx * dx + dy * dy))
    local px = dx / dist * rad * 0.035
    local py = math.max(-rad * 0.025, math.min(rad * 0.04, dy / dist * rad * 0.035))

    -- 눈 바탕 타원
    if blk.name == "Black" then
        love.graphics.setColor(0.92, 0.92, 0.96, 0.94)
    else
        love.graphics.setColor(0.08, 0.08, 0.12, 0.82)
    end
    love.graphics.ellipse("fill", x - eyeX + px, eyeY + py, eyeW, eyeH)
    love.graphics.ellipse("fill", x + eyeX + px, eyeY + py, eyeW, eyeH)

    -- 눈동자 내 초롱초롱 빛 하이라이트
    love.graphics.setColor(1, 1, 1, 0.55)
    love.graphics.circle("fill", x - eyeX + px - eyeW * 0.25, eyeY + py - eyeH * 0.30, eyeW * 0.28)
    love.graphics.circle("fill", x + eyeX + px - eyeW * 0.25, eyeY + py - eyeH * 0.30, eyeW * 0.28)

    -- 홍조 (검정 친구가 아닐 때에만)
    if blk.name ~= "Black" then
        love.graphics.setColor(1, 1, 1, 0.18)
        love.graphics.circle("fill", x - rad * 0.48, y + bob + rad * 0.12, rad * 0.12)
        love.graphics.circle("fill", x + rad * 0.48, y + bob + rad * 0.12, rad * 0.12)
    end

    -- 미소 아크 라인
    love.graphics.setLineWidth(1.3)
    if blk.name == "Black" then
        love.graphics.setColor(0.92, 0.92, 0.96, 0.58)
    else
        love.graphics.setColor(0.08, 0.08, 0.12, 0.26)
    end
    love.graphics.arc("line", "open", x, y + bob + rad * 0.18, rad * 0.20, 0.18, math.pi - 0.18)

    -- 선택 상태 시 반짝이는 외곽 콤보 호광 링
    if opts.selected then
        love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], 0.7 + math.sin(love.timer.getTime() * 4) * 0.2)
        love.graphics.setLineWidth(2.5)
        love.graphics.arc("line", "open", x, y + bob, rad + 4, 0.4, math.pi - 0.4)
    end
end

return Character
