------------------------------------------------------------
-- panel.lua · 테두리 하이라이트 및 그림자 효과 공통 패널 컴포넌트
------------------------------------------------------------
local Panel = {}
local C = require("core.constants")
local P = C.P

local function rr(mode, x, y, w, h, r)
    love.graphics.rectangle(mode, x, y, w, h, r or 8, r or 8)
end

-- 섀도우 및 현대적인 플랫/소프트 패널 드로우
function Panel.draw(x, y, w, h, r)
    r = r or 10
    
    -- 1. 부드러운 현대적 그림자 (다중 섀도우 레이어로 부드러움 향상)
    love.graphics.setColor(0.08, 0.12, 0.22, 0.05)
    rr("fill", x, y + 4, w, h, r)
    love.graphics.setColor(0.08, 0.12, 0.22, 0.03)
    rr("fill", x, y + 8, w, h, r)
    
    -- 2. 메인 순백색 배경판
    love.graphics.setColor(P.panel)
    rr("fill", x, y, w, h, r)
    
    -- 3. 미세한 상단 그라데이션 대신 아주 옅은 보조 하이라이트
    love.graphics.setColor(P.panelHi[1], P.panelHi[2], P.panelHi[3], 0.3)
    rr("fill", x, y, w, math.max(12, h * 0.08), r)
    
    -- 4. 얇고 깔끔한 외곽 테두리선
    love.graphics.setColor(P.panelBd)
    love.graphics.setLineWidth(1.5)
    rr("line", x, y, w, h, r)
end

return Panel

