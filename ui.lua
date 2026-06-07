------------------------------------------------------------
-- ui.lua · 공통 UI 컴포넌트 및 유틸리티
------------------------------------------------------------
local C = require("config")
local P = C.P
local UI = {}

-- 폰트
UI.fS, UI.fM, UI.fL, UI.fX, UI.fXX = nil, nil, nil, nil, nil

function UI.initFonts()
    -- 폰트 파일 로드 (다운로드된 한글 폰트 사용)
    local fontPath = "assets/fonts/NanumGothic.ttf"
    local fontBoldPath = "assets/fonts/NanumGothic-Bold.ttf"
    
    local success, _ = pcall(function()
        UI.fS  = love.graphics.newFont(fontPath, 13)
        UI.fM  = love.graphics.newFont(fontBoldPath, 16)
        UI.fL  = love.graphics.newFont(fontBoldPath, 22)
        UI.fX  = love.graphics.newFont(fontBoldPath, 28)
        UI.fXX = love.graphics.newFont(fontBoldPath, 44)
    end)
    
    if not success then
        -- Fallback to default if font file doesn't exist
        UI.fS  = love.graphics.newFont(13)
        UI.fM  = love.graphics.newFont(16)
        UI.fL  = love.graphics.newFont(22)
        UI.fX  = love.graphics.newFont(28)
        UI.fXX = love.graphics.newFont(44)
        print("Warning: Failed to load custom Korean font. Using default font.")
    end
end

function UI.rr(mode, x, y, w, h, r)
    love.graphics.rectangle(mode, x, y, w, h, r or 8, r or 8)
end

function UI.txt(s, x, y, col, f)
    if f then love.graphics.setFont(f) end
    love.graphics.setColor(col or P.text)
    love.graphics.print(s, x, y)
end

function UI.txtC(s, cx, y, col, f)
    if f then love.graphics.setFont(f) end
    local w = love.graphics.getFont():getWidth(s)
    UI.txt(s, cx - w / 2, y, col)
end

function UI.panel(x, y, w, h, r)
    r = r or 10
    love.graphics.setColor(0.20, 0.27, 0.40, 0.08)
    UI.rr("fill", x + 2, y + 5, w, h, r)
    love.graphics.setColor(0.20, 0.27, 0.40, 0.06)
    UI.rr("fill", x, y + 2, w, h, r)

    love.graphics.setColor(P.panel)
    UI.rr("fill", x, y, w, h, r)
    love.graphics.setColor(P.panelHi[1], P.panelHi[2], P.panelHi[3], 0.75)
    UI.rr("fill", x + 1, y + 1, w - 2, math.max(10, h * 0.22), math.max(4, r - 2))
    love.graphics.setColor(P.panelBd)
    love.graphics.setLineWidth(1)
    UI.rr("line", x, y, w, h, r)
end

function UI.button(x, y, w, h, label, active, hover, font)
    font = font or UI.fM
    love.graphics.setColor(0.25, 0.24, 0.22, 0.16)
    UI.rr("fill", x + 1, y + 3, w, h, 7)
    if active then
        love.graphics.setColor(hover and P.btnRH or P.btnR)
    else
        love.graphics.setColor(P.btnG)
    end
    UI.rr("fill", x, y, w, h, 7)
    love.graphics.setColor(1, 1, 1, active and 0.16 or 0.06)
    UI.rr("fill", x + 1, y + 1, w - 2, h * 0.45, 6)
    love.graphics.setColor(active and P.white or {0.55, 0.57, 0.62})
    love.graphics.setFont(font)
    love.graphics.print(label, x + (w - font:getWidth(label)) / 2, y + (h - font:getHeight()) / 2)
end

function UI.pill(x, y, w, h, label, col, font)
    font = font or UI.fS
    love.graphics.setColor(col[1], col[2], col[3], 0.95)
    UI.rr("fill", x, y, w, h, math.floor(h / 2))
    love.graphics.setColor(1, 1, 1, 0.15)
    UI.rr("fill", x + 1, y + 1, w - 2, h * 0.45, math.floor(h / 2))
    love.graphics.setColor(P.white)
    love.graphics.setFont(font)
    love.graphics.print(label, x + (w - font:getWidth(label)) / 2, y + (h - font:getHeight()) / 2)
end

function UI.catCol(c)
    if c == "MONO"   then return P.cMono end
    if c == "MIRROR" then return P.cMirr end
    if c == "STEP"   then return P.cStep end
    return P.text
end

-- 이징 (Easing)
function UI.easeBack(t) local s=1.7; t=t-1; return t*t*((s+1)*t+s)+1 end
function UI.easeCubic(t) t=t-1; return t*t*t+1 end
function UI.easeElastic(t)
    if t==0 or t==1 then return t end
    return math.pow(2,-10*t)*math.sin((t-.075)*2*math.pi/.3)+1
end

function UI.chipB(cx, cy, val)
    love.graphics.setFont(UI.fM)
    local s = tostring(val)
    local tw = math.max(UI.fM:getWidth(s) + 14, 42)
    UI.pill(cx - tw / 2, cy - 11, tw, 22, s, P.chip, UI.fM)
end

function UI.multB(cx, cy, val)
    love.graphics.setFont(UI.fM)
    local s = "x" .. tostring(val)
    local tw = math.max(UI.fM:getWidth(s) + 14, 40)
    UI.pill(cx - tw / 2, cy - 11, tw, 22, s, P.mult, UI.fM)
end

return UI
