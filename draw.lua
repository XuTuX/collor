------------------------------------------------------------
-- draw.lua · 렌더링 전체 (캐릭터, 이펙트 및 메인 관리)
------------------------------------------------------------
local C = require("config")
local G = require("game")
local P = C.P
local UI = require("ui")
local S = require("screens")
local R = {}

------------------------------------------------------------
-- 초기화
------------------------------------------------------------
function R.init()
    UI.initFonts()
    require("sound").init()
end

------------------------------------------------------------
-- 캐릭터 그리기
------------------------------------------------------------
function R.character(x, y, rad, blk, opts)
    if not blk then return end
    opts = opts or {}
    local cr,cg,cb = blk.color[1], blk.color[2], blk.color[3]
    local bob = opts.bob or 0

    love.graphics.setColor(0,0,0,0.18)
    love.graphics.ellipse("fill", x, y + rad + 3, rad*0.6, rad*0.15)

    love.graphics.setColor(cr*0.45, cg*0.45, cb*0.45)
    love.graphics.circle("fill", x, y+bob, rad+1.5)
    
    love.graphics.setColor(cr, cg, cb)
    love.graphics.circle("fill", x, y+bob, rad)
    
    love.graphics.setColor(1,1,1,0.14)
    love.graphics.arc("fill", x, y+bob-1, rad*0.72, -math.pi, -0.05)

    love.graphics.setLineWidth(blk.name=="White" and 2 or 1.2)
    if blk.name=="White" then
        love.graphics.setColor(0.12,0.12,0.16,0.85)
    elseif blk.name=="Black" then
        love.graphics.setColor(0.28,0.30,0.40,0.40)
    else
        love.graphics.setColor(cr*0.50,cg*0.50,cb*0.50,0.45)
    end
    love.graphics.circle("line", x, y+bob, rad)

    local eyeY = y + bob - rad*0.13
    local eyeX = rad * 0.28
    local eyeW = rad * 0.15
    local eyeH = rad * 0.20
    local mx, my = love.mouse.getPosition()
    local dx, dy = mx - x, my - (y+bob)
    local dist = math.max(1, math.sqrt(dx*dx + dy*dy))
    local px = dx / dist * rad * 0.035
    local py = math.max(-rad * 0.025, math.min(rad * 0.04, dy / dist * rad * 0.035))

    if blk.name=="Black" then
        love.graphics.setColor(0.92,0.92,0.96,0.94)
    else
        love.graphics.setColor(0.08,0.08,0.12,0.82)
    end
    love.graphics.ellipse("fill", x-eyeX+px, eyeY+py, eyeW, eyeH)
    love.graphics.ellipse("fill", x+eyeX+px, eyeY+py, eyeW, eyeH)

    love.graphics.setColor(1,1,1,0.55)
    love.graphics.circle("fill", x-eyeX+px-eyeW*0.25, eyeY+py-eyeH*0.30, eyeW*0.28)
    love.graphics.circle("fill", x+eyeX+px-eyeW*0.25, eyeY+py-eyeH*0.30, eyeW*0.28)

    if blk.name ~= "Black" then
        love.graphics.setColor(1,1,1,0.18)
        love.graphics.circle("fill", x-rad*0.48, y+bob+rad*0.12, rad*0.12)
        love.graphics.circle("fill", x+rad*0.48, y+bob+rad*0.12, rad*0.12)
    end

    love.graphics.setLineWidth(1.3)
    if blk.name=="Black" then
        love.graphics.setColor(0.92,0.92,0.96,0.58)
    else
        love.graphics.setColor(0.08,0.08,0.12,0.26)
    end
    love.graphics.arc("line","open", x, y+bob+rad*0.18, rad*0.20, 0.18, math.pi-0.18)

    if opts.selected then
        love.graphics.setColor(P.gold[1],P.gold[2],P.gold[3],0.7+math.sin(love.timer.getTime()*4)*0.2)
        love.graphics.setLineWidth(2.5)
        love.graphics.arc("line","open", x, y+bob, rad+4, 0.4, math.pi-0.4)
    end
end

------------------------------------------------------------
-- 배경
------------------------------------------------------------
function R.background()
    love.graphics.setColor(P.bg)
    love.graphics.rectangle("fill", 0, 0, C.SW, C.SH)

    for y = 0, C.SH, 16 do
        local t = y / C.SH
        love.graphics.setColor(
            P.felt[1] * (1 - t) + P.felt2[1] * t,
            P.felt[2] * (1 - t) + P.felt2[2] * t,
            P.felt[3] * (1 - t) + P.felt2[3] * t,
            0.34
        )
        love.graphics.rectangle("fill", 0, y, C.SW, 16)
    end

    love.graphics.setColor(1, 1, 1, 0.035)
    love.graphics.setLineWidth(1)
    for x = -C.SH, C.SW, 44 do
        love.graphics.line(x, 0, x + C.SH, C.SH)
    end
end

-- 실행 미리보기
------------------------------------------------------------
function R.board()
    if G.phase == "title" then return end
    local preview = (G.phase == "play") and G.previewCards() or G.board
    UI.panel(C.BX-18, C.BY-42, C.BW+36, C.BSH+64, 12)

    for i = 1, C.BN do
        local sx = C.BX + (i-1)*(C.BSW+C.BGAP)
        local sy = C.BY

        love.graphics.setColor(0.25, 0.30, 0.42, 0.10)
        UI.rr("fill", sx+1, sy+3, C.BSW, C.BSH, 8)
        love.graphics.setColor(preview[i] and P.slotHov or P.slot)
        UI.rr("fill",sx,sy,C.BSW,C.BSH,6)
        love.graphics.setColor(preview[i] and P.slotHBd or P.slotBd)
        love.graphics.setLineWidth(preview[i] and 2.0 or 1.1)
        UI.rr("line",sx,sy,C.BSW,C.BSH,6)
        love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], preview[i] and 0.95 or 0.28)
        UI.rr("fill", sx+6, sy+6, C.BSW-12, 4, 3)

        if not preview[i] then
            love.graphics.setColor(P.dim[1],P.dim[2],P.dim[3],0.18)
            local cx,cy = sx+C.BSW/2, sy+C.BSH/2
            love.graphics.setLineWidth(2)
            love.graphics.arc("line", "open", cx, cy, 13, -0.65, math.pi+0.65)
            love.graphics.line(cx-8, cy, cx+8, cy)
        end

        love.graphics.setFont(UI.fS)
        love.graphics.setColor(P.dim[1],P.dim[2],P.dim[3],0.25)
        local ns=tostring(i)
        love.graphics.print(ns, sx+(C.BSW-UI.fS:getWidth(ns))/2, sy+C.BSH-15)

        if preview[i] then
            local sc, offY = 1, 0
            if G.slotAnim[i] then
                local p = math.min(1, G.slotAnim[i].t / G.slotAnim[i].dur)
                sc = UI.easeBack(p)
                offY = (1 - UI.easeCubic(p)) * (-16)
            end
            local tx = sx + C.BSW/2
            local ty = sy + C.BSH/2 - 2 + offY
            love.graphics.push()
            love.graphics.translate(tx,ty)
            love.graphics.scale(sc,sc)
            love.graphics.translate(-tx,-ty)
            R.character(tx, ty, C.CR, preview[i])
            love.graphics.pop()
        end
    end
end

------------------------------------------------------------
-- 내 색친구
------------------------------------------------------------
function R.hand()
    if G.phase ~= "play" then return end
    local n = #G.hand
    local time = love.timer.getTime()

    UI.panel(C.HCX - 360, C.HY - C.HCR - 34, 720, C.HCR*2 + 68, 12)
    UI.txt("내 색친구", C.HCX - 342, C.HY - C.HCR - 25, P.text, UI.fM)

    if n == 0 then return end
    local mid = (n+1)/2

    local order = {}
    for i = 1, n do
        local off = i - mid
        local bx = C.HCX + off * C.HSPC
        local by = C.HY
        local sel = G.hand[i].sel
        local hov = (G.hCard == i)
        local dy = 0
        if sel then dy = -22 end
        if hov then dy = dy - 8 end
        
        local rx, ry = bx, by + dy
        local bob = math.sin(time*1.8 + i*0.7) * 1.5
        local sc = 1
        
        if G.dragIndex == i then
            rx = G.dragX
            ry = G.dragY
            bob = 0
            sc = 1.1
        else
            local age = time - (G.hand[i].spawnT or 0)
            if age < 0.25 then sc = UI.easeBack(age/0.25) end
        end
        
        table.insert(order, {
            i=i, x=rx, y=ry, bob=bob, sc=sc, hov=hov, sel=sel, card=G.hand[i],
            pri=(G.dragIndex == i and 5 or (sel and 1 or 0)+(hov and 2 or 0))
        })
    end
    table.sort(order, function(a,b) return a.pri < b.pri end)

    for _, o in ipairs(order) do
        love.graphics.push()
        love.graphics.translate(o.x, o.y)
        love.graphics.scale(o.sc, o.sc)
        love.graphics.translate(-o.x, -o.y)
        R.character(o.x, o.y, C.HCR, o.card, {selected=o.sel, bob=o.bob})
        
        if G.dragIndex ~= o.i then
            love.graphics.setFont(UI.fS)
            love.graphics.setColor(P.dim[1],P.dim[2],P.dim[3],0.55)
            
            -- 색 이름 한글화 표시
            local cname = o.card.name
            if cname == "Red" then cname = "빨강"
            elseif cname == "Orange" then cname = "주황"
            elseif cname == "Yellow" then cname = "노랑"
            elseif cname == "White" then cname = "하양"
            elseif cname == "Black" then cname = "검정"
            end
            
            local nw = UI.fS:getWidth(cname)
            love.graphics.print(cname, o.x-nw/2, o.y+C.HCR+8+o.bob)
        end
        love.graphics.pop()
    end
end

------------------------------------------------------------
-- 파티클
------------------------------------------------------------
function R.particles()
    love.graphics.setLineWidth(1)
    for _, p in ipairs(G.particles) do
        local alpha = 1 - p.age / p.maxAge
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha * 0.8)
        love.graphics.circle("fill", p.x, p.y, p.rad)
        
        love.graphics.setColor(p.color[1]*1.2, p.color[2]*1.2, p.color[3]*1.2, alpha * 0.3)
        love.graphics.circle("line", p.x, p.y, p.rad + 1.2)
    end
end

------------------------------------------------------------
-- 전체 그리기
------------------------------------------------------------
function R.all()
    R.background()
    
    if G.phase == "title" then
        S.title()
        return
    end
    
    love.graphics.push()
    if G.shake > 0 then
        local dx = (love.math.random() * 2 - 1) * G.shake
        local dy = (love.math.random() * 2 - 1) * G.shake
        love.graphics.translate(dx, dy)
    end
    
    S.topUI()
    R.board()
    R.hand()
    S.deckUI()
    S.cheatSheet()
    
    S.jokers()
    
    R.particles()
    
    S.scoring()
    S.result()
    S.gameover()
    
    love.graphics.pop()
    
    S.shop()
    S.roundStartAnim()
    S.bagOverlay()
end

return R
