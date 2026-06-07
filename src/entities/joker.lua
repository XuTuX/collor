------------------------------------------------------------
-- joker.lua · 도우미(조커) 상점 카드 아이콘 그리기 모듈
------------------------------------------------------------
local Joker = {}
local C = require("core.constants")
local P = C.P

local function rr(mode, x, y, w, h, r)
    love.graphics.rectangle(mode, x, y, w, h, r or 8, r or 8)
end

-- 상점 내 도우미 및 아이템 아이콘 그리기 (shopIcon 로직 완전 보존)
function Joker.drawIcon(item, cx, cy, accent)
    love.graphics.setColor(0.24, 0.30, 0.42, 0.10)
    rr("fill", cx - 39, cy - 35, 78, 74, 12)
    love.graphics.setColor(1, 1, 1, 0.78)
    rr("fill", cx - 40, cy - 38, 78, 74, 12)
    love.graphics.setColor(accent[1], accent[2], accent[3], 0.35)
    rr("fill", cx - 34, cy - 32, 66, 62, 10)
    love.graphics.setColor(accent)
    love.graphics.setLineWidth(1.4)
    rr("line", cx - 40, cy - 38, 78, 74, 12)

    if item.type == "joker" then
        love.graphics.setColor(accent[1] * 0.75, accent[2] * 0.75, accent[3] * 0.75, 0.95)
        love.graphics.polygon("fill", cx - 24, cy - 8, cx - 34, cy - 28, cx - 15, cy - 20)
        love.graphics.polygon("fill", cx + 24, cy - 8, cx + 34, cy - 28, cx + 15, cy - 20)
        love.graphics.setColor(P.gold)
        love.graphics.circle("fill", cx - 34, cy - 28, 4)
        love.graphics.circle("fill", cx + 34, cy - 28, 4)
        love.graphics.setColor(accent)
        love.graphics.circle("fill", cx, cy, 25)
        love.graphics.setColor(1, 1, 1, 0.18)
        love.graphics.arc("fill", cx, cy - 3, 18, -math.pi, -0.05)
        love.graphics.setColor(1, 1, 1, 0.94)
        love.graphics.ellipse("fill", cx - 8, cy - 4, 4, 6)
        love.graphics.ellipse("fill", cx + 8, cy - 4, 4, 6)
        love.graphics.setColor(0.08, 0.08, 0.12, 0.36)
        love.graphics.arc("line", "open", cx, cy + 8, 8, 0.25, math.pi - 0.25)
    elseif item.type == "upgrade" then
        love.graphics.setColor(P.chip)
        rr("fill", cx - 27, cy + 13, 15, 14, 4)
        love.graphics.setColor(P.gold)
        rr("fill", cx - 7, cy + 3, 15, 24, 4)
        love.graphics.setColor(P.mult)
        rr("fill", cx + 13, cy - 8, 15, 35, 4)
        love.graphics.setColor(accent)
        love.graphics.setLineWidth(4)
        love.graphics.line(cx - 24, cy - 3, cx, cy - 25, cx + 24, cy - 3)
        love.graphics.polygon("fill", cx, cy - 34, cx - 9, cy - 18, cx + 9, cy - 18)
    elseif item.type == "deck_add" then
        local col = item.colorVal or accent
        love.graphics.setColor(0.24, 0.30, 0.42, 0.18)
        rr("fill", cx - 28, cy - 20, 42, 54, 7)
        love.graphics.setColor(1, 1, 1, 0.92)
        rr("fill", cx - 32, cy - 25, 42, 54, 7)
        love.graphics.setColor(col)
        love.graphics.circle("fill", cx - 11, cy + 2, 15)
        love.graphics.setColor(accent)
        love.graphics.setLineWidth(5)
        love.graphics.line(cx + 23, cy - 11, cx + 23, cy + 15)
        love.graphics.line(cx + 10, cy + 2, cx + 36, cy + 2)
    elseif item.type == "deck_remove" then
        love.graphics.setColor(0.24, 0.30, 0.42, 0.18)
        rr("fill", cx - 26, cy - 18, 44, 52, 7)
        love.graphics.setColor(1, 1, 1, 0.92)
        rr("fill", cx - 31, cy - 24, 44, 52, 7)
        love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.45)
        love.graphics.circle("fill", cx - 9, cy + 1, 15)
        love.graphics.setColor(P.btnR)
        love.graphics.setLineWidth(5)
        love.graphics.line(cx + 9, cy + 2, cx + 35, cy + 2)
    end
end

return Joker
