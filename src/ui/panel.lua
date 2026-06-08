------------------------------------------------------------
-- panel.lua · 테두리 하이라이트 및 그림자 효과 공통 패널 컴포넌트
------------------------------------------------------------
local Panel = {}
local C = require("core.constants")
local P = C.P

local function rr(mode, x, y, w, h, r)
    love.graphics.rectangle(mode, x, y, w, h, r or 8, r or 8)
end

-- 네오 브루탈리즘 스타일 평면/하드 섀도우 패널 드로우
function Panel.draw(x, y, w, h, r)
    r = r or 24 -- 네오 브루탈리즘 특유의 둥근 모서리
    
    -- 1. 네오 브루탈리즘 하드 섀도우 (100% 불투명, 오프셋 3,3)
    love.graphics.setColor(0.102, 0.102, 0.102, 1.0)
    rr("fill", x + 3, y + 3, w, h, r)
    
    -- 2. 메인 단색 배경판 (그라데이션/하이라이트 없음)
    love.graphics.setColor(P.panel)
    rr("fill", x, y, w, h, r)
    
    -- 3. 굵고 명확한 테두리선
    love.graphics.setColor(P.panelBd)
    love.graphics.setLineWidth(2.0)
    rr("line", x, y, w, h, r)
end

return Panel

