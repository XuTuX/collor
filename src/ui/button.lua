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

-- 버튼 그리기 (모던 미니멀 스타일)
function Button.draw(x, y, w, h, label, active, hover, font)
    local hud = require("ui.hud")
    font = font or hud.fM
    if not font then return end
    
    -- 1. 부드러운 미세 그림자
    love.graphics.setColor(0.08, 0.12, 0.22, 0.08)
    rr("fill", x, y + 3, w, h, 8)
    
    -- 2. 버튼 몸체
    if active then
        love.graphics.setColor(hover and P.btnRH or P.btnR)
    else
        love.graphics.setColor(P.btnG)
    end
    rr("fill", x, y, w, h, 8)
    
    -- 3. 미세 하이라이트
    love.graphics.setColor(1, 1, 1, active and 0.15 or 0.05)
    rr("fill", x, y, w, h * 0.25, 8)
    
    -- 4. 얇은 테두리
    if hover and active then
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.setLineWidth(1.8)
    else
        love.graphics.setColor(0, 0, 0, 0.06)
        love.graphics.setLineWidth(1)
    end
    rr("line", x, y, w, h, 8)
    
    -- 5. 버튼 텍스트
    love.graphics.setFont(font)
    if not active then
        love.graphics.setColor(0.45, 0.49, 0.55)
    else
        love.graphics.setColor(P.white)
    end
    love.graphics.print(label, x + (w - font:getWidth(label)) / 2, y + (h - font:getHeight()) / 2)
end

-- 알약 배지(Pill) 그리기
function Button.pill(x, y, w, h, label, col, font)
    local hud = require("ui.hud")
    font = font or hud.fS
    if not font then return end
    
    local r = math.floor(h / 2)
    
    -- 1. 미세 그림자
    love.graphics.setColor(0, 0, 0, 0.05)
    rr("fill", x, y + 2, w, h, r)
    
    -- 2. 몸체 판
    love.graphics.setColor(col[1], col[2], col[3], 1.0)
    rr("fill", x, y, w, h, r)
    
    -- 3. 얇은 테두리선
    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.setLineWidth(1)
    rr("line", x, y, w, h, r)
    
    -- 4. 내부 텍스트 (텍스트 가독성을 위해 어두운 계열 색상이면 하양, 밝은 계열이면 알맞게 조정하지만 기본 화이트 유지)
    love.graphics.setColor(P.white)
    love.graphics.setFont(font)
    love.graphics.print(label, x + (w - font:getWidth(label)) / 2, y + (h - font:getHeight()) / 2)
end

-- 카테고리별 색상 매핑 헬퍼
function Button.catCol(c)
    if c == "MONO"   then return P.cMono end
    if c == "MIRROR" then return P.cMirr end
    if c == "STEP"   then return P.cStep end
    if c == "TWINS"  then return P.cTwins end
    if c == "ZIGZAG" then return P.cZigzag end
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

