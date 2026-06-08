------------------------------------------------------------
-- button.lua · 버튼, 알약 배지(Pill), 칩/배수(Mult) UI 위젯 모듈
------------------------------------------------------------
local Button = {}
local C = require("core.constants")
local P = C.P

local function rr(mode, x, y, w, h, r)
    love.graphics.rectangle(mode, x, y, w, h, r or 8, r or 8)
end

-- 기본 텍스트 렌더링
function Button.txt(s, x, y, col, font)
    if font then love.graphics.setFont(font) end
    love.graphics.setColor(col or P.text)
    love.graphics.print(s, x, y)
end

-- 중앙 정렬 텍스트 렌더링
function Button.txtC(s, cx, y, col, font)
    if font then love.graphics.setFont(font) end
    local w = love.graphics.getFont():getWidth(s)
    Button.txt(s, cx - w / 2, y, col)
end

-- 네오 브루탈리즘 버튼 그리기
function Button.draw(x, y, w, h, label, active, hover, font)
    local hud = require("ui.hud")
    font = font or hud.fM
    if not font then return end
    
    local r = 20 -- 네오 브루탈리즘 둥근 모서리
    
    -- 1. 네오 브루탈리즘 하드 섀도우 (클릭/호버 시 위치 변화 처리 가능, 현재는 고정 오프셋)
    love.graphics.setColor(0.102, 0.102, 0.102, 1.0)
    local dx, dy = 3, 3
    if hover and active then dx, dy = 1, 1 end -- 눌리는 느낌을 위해 그림자 축소
    rr("fill", x + dx, y + dy, w, h, r)
    
    -- 눌리는 느낌(호버) 시 몸체 위치 이동
    local bx, by = x, y
    if hover and active then
        bx, by = x + 2, y + 2
    end
    
    -- 2. 버튼 몸체
    if active then
        love.graphics.setColor(P.btnR) -- 네오 브루탈리즘은 호버 시에도 원색 유지
    else
        love.graphics.setColor(P.btnG)
    end
    rr("fill", bx, by, w, h, r)
    
    -- 3. 굵고 뚜렷한 테두리
    love.graphics.setColor(0.102, 0.102, 0.102, 1.0)
    love.graphics.setLineWidth(2.0)
    rr("line", bx, by, w, h, r)
    
    -- 4. 버튼 텍스트
    love.graphics.setFont(font)
    if not active then
        love.graphics.setColor(0.45, 0.49, 0.55)
    else
        love.graphics.setColor(P.white)
    end
    love.graphics.print(label, bx + (w - font:getWidth(label)) / 2, by + (h - font:getHeight()) / 2)
end

-- 네오 브루탈리즘 알약 배지(Pill) 그리기
function Button.pill(x, y, w, h, label, col, font)
    local hud = require("ui.hud")
    font = font or hud.fS
    if not font then return end
    
    local r = math.floor(h / 2)
    
    -- 1. 하드 섀도우
    love.graphics.setColor(0.102, 0.102, 0.102, 1.0)
    rr("fill", x + 2, y + 2, w, h, r)
    
    -- 2. 몸체 판
    love.graphics.setColor(col[1], col[2], col[3], 1.0)
    rr("fill", x, y, w, h, r)
    
    -- 3. 굵은 테두리선
    love.graphics.setColor(0.102, 0.102, 0.102, 1.0)
    love.graphics.setLineWidth(2.0)
    rr("line", x, y, w, h, r)
    
    -- 4. 내부 텍스트
    love.graphics.setColor(P.white)
    love.graphics.setFont(font)
    love.graphics.print(label, x + (w - font:getWidth(label)) / 2, y + (h - font:getHeight()) / 2)
end

-- 카테고리별 색상 매핑 헬퍼
function Button.catCol(c)
    if c == "MONO"      then return P.cMono end
    if c == "MIRROR"    then return P.cMirr end
    if c == "CRESCENDO" then return P.cStep end
    if c == "TWINS"     then return P.cTwins end
    if c == "ZIGZAG"    then return P.cZigzag end
    return P.text
end

-- 칩 배지 그리기
function Button.chipB(cx, cy, val)
    local hud = require("ui.hud")
    local font = hud.fM
    if not font then return end
    
    local s = tostring(val)
    local tw = math.max(font:getWidth(s) + 14, 42)
    Button.pill(cx - tw / 2, cy - 11, tw, 22, s, P.chip, font)
end

-- 콤보(배수) 배지 그리기
function Button.multB(cx, cy, val)
    local hud = require("ui.hud")
    local font = hud.fM
    if not font then return end
    
    local s = "x" .. tostring(val)
    local tw = math.max(font:getWidth(s) + 14, 40)
    Button.pill(cx - tw / 2, cy - 11, tw, 22, s, P.mult, font)
end

return Button

