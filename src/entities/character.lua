------------------------------------------------------------
-- character.lua · 색친구(캐릭터) 그래픽 렌더링 엔티티
------------------------------------------------------------
local Character = {}
local C = require("core.constants")
local P = C.P

-- 캐릭터 둥글둥글 렌더링
function Character.draw(x, y, rad, blk, opts)
    if not blk then return end
    opts = opts or {}
    local cr, cg, cb = blk.color[1], blk.color[2], blk.color[3]
    local bob = opts.bob or 0
    local isActive = opts.active or false -- 계산 발동 중 여부

    -- 바닥 그림자 타원
    love.graphics.setColor(0, 0, 0, 0.12)
    love.graphics.ellipse("fill", x, y + rad + 3, rad * 0.6, rad * 0.15)

    -- 외곽선 테두리 그림자용 두꺼운 원
    love.graphics.setColor(cr * 0.55, cg * 0.55, cb * 0.55)
    love.graphics.circle("fill", x, y + bob, rad + 1.5)
    
    -- 기본 몸통 원
    love.graphics.setColor(cr, cg, cb)
    love.graphics.circle("fill", x, y + bob, rad)
    
    -- 입체 후광 하이라이트 아크
    love.graphics.setColor(1, 1, 1, 0.22)
    love.graphics.arc("fill", x, y + bob - 1, rad * 0.72, -math.pi, -0.05)

    -- 몸통 선 테두리색
    love.graphics.setLineWidth(blk.name == "White" and 1.8 or 1.2)
    if blk.name == "White" then
        love.graphics.setColor(0.12, 0.12, 0.16, 0.6)
    elseif blk.name == "Black" then
        love.graphics.setColor(0.28, 0.30, 0.40, 0.35)
    else
        love.graphics.setColor(cr * 0.45, cg * 0.45, cb * 0.45, 0.35)
    end
    love.graphics.circle("line", x, y + bob, rad)

    -- 눈동자 굴리기
    local eyeY = y + bob - rad * 0.13
    local eyeX = rad * 0.28
    local eyeW = rad * 0.15
    local eyeH = rad * 0.20
    
    local mx, my = love.mouse.getPosition()
    local dx, dy = mx - x, my - (y + bob)
    local dist = math.max(1, math.sqrt(dx * dx + dy * dy))
    local px = dx / dist * rad * 0.035
    local py = math.max(-rad * 0.025, math.min(rad * 0.04, dy / dist * rad * 0.035))

    -- 눈 바탕 타원 그리기 (윙크 기믹 추가: 발동 중일 때 왼쪽 눈을 감음)
    if blk.name == "Black" then
        love.graphics.setColor(0.95, 0.95, 0.98, 0.94)
    else
        love.graphics.setColor(0.12, 0.16, 0.22, 0.85)
    end
    
    if isActive then
        -- 윙크 (왼쪽 눈 감기: 얇은 가로선)
        love.graphics.setLineWidth(2)
        love.graphics.line(x - eyeX + px - eyeW, eyeY + py, x - eyeX + px + eyeW, eyeY + py)
        -- 오른쪽 눈은 크게 뜨기
        love.graphics.ellipse("fill", x + eyeX + px, eyeY + py, eyeW * 1.2, eyeH * 1.2)
        
        -- 오른쪽 눈동자 하이라이트
        love.graphics.setColor(1, 1, 1, 0.85)
        love.graphics.circle("fill", x + eyeX + px - eyeW * 0.2, eyeY + py - eyeH * 0.3, eyeW * 0.35)
    else
        -- 기본 두 눈
        love.graphics.ellipse("fill", x - eyeX + px, eyeY + py, eyeW, eyeH)
        love.graphics.ellipse("fill", x + eyeX + px, eyeY + py, eyeW, eyeH)
        
        -- 양쪽 눈동자 하이라이트
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.circle("fill", x - eyeX + px - eyeW * 0.25, eyeY + py - eyeH * 0.30, eyeW * 0.28)
        love.graphics.circle("fill", x + eyeX + px - eyeW * 0.25, eyeY + py - eyeH * 0.30, eyeW * 0.28)
    end

    -- 홍조 (발동 중이면 더 진하게)
    if blk.name ~= "Black" then
        if isActive then
            love.graphics.setColor(0.95, 0.3, 0.4, 0.45)
            love.graphics.circle("fill", x - rad * 0.45, y + bob + rad * 0.12, rad * 0.18)
            love.graphics.circle("fill", x + rad * 0.45, y + bob + rad * 0.12, rad * 0.18)
        else
            love.graphics.setColor(0.95, 0.35, 0.45, 0.22)
            love.graphics.circle("fill", x - rad * 0.48, y + bob + rad * 0.12, rad * 0.12)
            love.graphics.circle("fill", x + rad * 0.48, y + bob + rad * 0.12, rad * 0.12)
        end
    end

    -- 미소 아크 라인 (발동 중이면 더 크게 벌려 웃음)
    if blk.name == "Black" then
        love.graphics.setColor(0.95, 0.95, 0.98, 0.65)
    else
        love.graphics.setColor(0.12, 0.16, 0.22, 0.35)
    end
    
    if isActive then
        love.graphics.setLineWidth(1.8)
        love.graphics.arc("line", "open", x, y + bob + rad * 0.12, rad * 0.28, 0.1, math.pi - 0.1)
    else
        love.graphics.setLineWidth(1.3)
        love.graphics.arc("line", "open", x, y + bob + rad * 0.18, rad * 0.20, 0.18, math.pi - 0.18)
    end

    -- 선택 상태 시 반짝이는 외곽 콤보 호광 링
    if opts.selected then
        love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], 0.7 + math.sin(love.timer.getTime() * 4) * 0.2)
        love.graphics.setLineWidth(2.2)
        love.graphics.arc("line", "open", x, y + bob, rad + 4, 0.4, math.pi - 0.4)
    end

    -- 특별 에디션 신비로운 오라 이펙트
    if blk.edition and blk.edition ~= "normal" then
        local time = love.timer.getTime()
        local ec = P.gold
        if blk.edition == "foil" then
            ec = P.cMirr
        elseif blk.edition == "holo" then
            ec = P.mult
        elseif blk.edition == "gold" then
            ec = P.gold
        end
        
        -- 외곽 빛 퍼짐 링
        love.graphics.setColor(ec[1], ec[2], ec[3], 0.25 + math.sin(time * 6) * 0.12)
        love.graphics.setLineWidth(1.5)
        love.graphics.circle("line", x, y + bob, rad + 3)
        
        -- 미세한 회전 스파크 파티클
        love.graphics.setColor(ec[1], ec[2], ec[3], 0.8)
        for a = 1, 4 do
            local angle = time * 2.2 + a * (math.pi / 2)
            local px = x + math.cos(angle) * (rad + 3.5)
            local py = y + bob + math.sin(angle) * (rad + 3.5)
            love.graphics.circle("fill", px, py, 1.4)
        end
    end
end

return Character
