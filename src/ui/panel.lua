------------------------------------------------------------
-- panel.lua · 테두리 하이라이트 및 그림자 효과 공통 패널 컴포넌트
------------------------------------------------------------
local Panel = {}
local C = require("core.constants")
local P = C.P

local function rr(mode, x, y, w, h, r)
    love.graphics.rectangle(mode, x, y, w, h, r or 8, r or 8)
end

-- 섀도우 및 하이라이트 공통 패널 드로우 (UI.panel 로직 완벽 보존)
function Panel.draw(x, y, w, h, r)
    r = r or 10
    
    -- 1. 드롭 그림자
    love.graphics.setColor(0, 0, 0, 0.4)
    rr("fill", x + 6, y + 8, w, h, r)
    
    -- 2. 메인 배경판
    love.graphics.setColor(P.panel)
    rr("fill", x, y, w, h, r)
    
    -- 3. 패널 상단 하이라이트 빔
    love.graphics.setColor(P.panelHi[1], P.panelHi[2], P.panelHi[3], 0.4)
    rr("fill", x, y, w, math.max(10, h * 0.15), r)
    
    -- 4. 외곽 테두리선
    love.graphics.setColor(P.panelBd)
    love.graphics.setLineWidth(3)
    rr("line", x, y, w, h, r)
    
    -- 5. 보조 미세 테두리선
    love.graphics.setColor(P.panelBd[1] * 1.5, P.panelBd[2] * 1.5, P.panelBd[3] * 1.5, 0.5)
    love.graphics.setLineWidth(1)
    rr("line", x, y, w, h, r)
end

return Panel
