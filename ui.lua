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
    -- 부드러운 이중 드롭 섀도우 (Ambient Occlusion 효과)
    love.graphics.setColor(0.08, 0.10, 0.18, 0.04)
    UI.rr("fill", x, y + 4, w, h + 2, r)
    love.graphics.setColor(0.08, 0.10, 0.18, 0.06)
    UI.rr("fill", x, y + 2, w, h, r)

    love.graphics.setColor(P.panel)
    UI.rr("fill", x, y, w, h, r)
    love.graphics.setColor(P.panelBd)
    love.graphics.setLineWidth(1)
    UI.rr("line", x, y, w, h, r)
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
    love.graphics.setColor(P.chip)
    UI.rr("fill", cx - tw / 2, cy - 11, tw, 22, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(s, cx - UI.fM:getWidth(s) / 2, cy - UI.fM:getHeight() / 2 + 1)
end

function UI.multB(cx, cy, val)
    love.graphics.setFont(UI.fM)
    local s = "x" .. tostring(val)
    local tw = math.max(UI.fM:getWidth(s) + 14, 40)
    love.graphics.setColor(P.mult)
    UI.rr("fill", cx - tw / 2, cy - 11, tw, 22, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(s, cx - UI.fM:getWidth(s) / 2, cy - UI.fM:getHeight() / 2 + 1)
end

return UI
