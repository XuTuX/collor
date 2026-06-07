------------------------------------------------------------
-- screens.lua · 각종 화면 및 UI 렌더링
------------------------------------------------------------
local UI = require("ui")
local C = require("config")
local P = C.P
local G = require("game")

local S = {}

local RULE_NAMES = {
    ["Mini Mono"] = "세 친구",
    ["Half Mono"] = "네 친구",
    ["Tower"] = "색 탑",
    ["Half Mirror"] = "작은 거울",
    ["Grand Mirror"] = "큰 거울",
    ["Half Step"] = "작은 계단",
    ["Perfect Ladder"] = "무지개 계단",
}

local CAT_NAMES = {
    MONO = "같은색",
    MIRROR = "거울",
    STEP = "계단",
}

local function ruleName(name)
    return RULE_NAMES[name] or name
end

local function catName(cat)
    return CAT_NAMES[cat] or cat
end

local function gateName()
    if G.stage == 1 then return "쉬운 관문" end
    if G.stage == 2 then return "도전 관문" end
    return "특별 관문"
end

local function colorName(name)
    if name == "Red" then return "빨강" end
    if name == "Orange" then return "주황" end
    if name == "Yellow" then return "노랑" end
    if name == "White" then return "하양" end
    if name == "Black" then return "검정" end
    return name
end

local function countColors(list)
    local counts = {}
    for _, c in ipairs(C.COLORS) do counts[c.name] = 0 end
    for _, item in ipairs(list or {}) do
        if item.name then counts[item.name] = (counts[item.name] or 0) + 1 end
    end
    return counts
end

local function getTargetScoreForStage(ante, stage, bossGimmick)
    local base = 250
    local target = 0
    if ante == 1 then
        if stage == 1 then target = 300
        elseif stage == 2 then target = 700
        else target = 1500 end
    else
        local multi = (stage == 1 and 1 or stage == 2 and 1.8 or 3.5)
        target = math.floor(base * math.pow(2.4, ante - 1) * multi * 10)
        target = math.floor(target / 100) * 100
    end
    if stage == 3 and bossGimmick == "high_target" then
        target = math.floor(target * 1.5)
    end
    return target
end

function S.title()
    if G.phase ~= "title" then return end
    
    love.graphics.setColor(P.bg)
    love.graphics.rectangle("fill", 0, 0, C.SW, C.SH)

    local time = love.timer.getTime()

    -- 방사형 후광 효과 (단순화된 원)
    love.graphics.setColor(P.cMirr[1], P.cMirr[2], P.cMirr[3], 0.15)
    love.graphics.circle("fill", C.SW/2, C.SH/2, 400 + math.sin(time)*20)
    
    for y = 0, C.SH, 24 do
        local t = y / C.SH
        love.graphics.setColor(
            P.felt[1] * (1 - t) + P.felt2[1] * t,
            P.felt[2] * (1 - t) + P.felt2[2] * t,
            P.felt[3] * (1 - t) + P.felt2[3] * t,
            0.6
        )
        love.graphics.rectangle("fill", 0, y, C.SW, 24)
    end

    local function mascot(cx, cy, rad, col, lift)
        local y = cy + math.sin(time * 1.6 + lift) * 4
        love.graphics.setColor(0.20, 0.27, 0.40, 0.12)
        love.graphics.ellipse("fill", cx, y + rad + 5, rad * 0.64, rad * 0.16)
        love.graphics.setColor(col[1] * 0.55, col[2] * 0.55, col[3] * 0.55, 0.88)
        love.graphics.circle("fill", cx, y + 2, rad + 2)
        love.graphics.setColor(col)
        love.graphics.circle("fill", cx, y, rad)
        love.graphics.setColor(1, 1, 1, 0.16)
        love.graphics.arc("fill", cx, y - 2, rad * 0.72, -math.pi, -0.05)
        love.graphics.setColor(0.08, 0.08, 0.12, col == C.COLORS[5].color and 0.0 or 0.74)
        if col == C.COLORS[5].color then love.graphics.setColor(0.92,0.92,0.96,0.90) end
        love.graphics.ellipse("fill", cx - rad * 0.24, y - rad * 0.10, rad * 0.11, rad * 0.16)
        love.graphics.ellipse("fill", cx + rad * 0.24, y - rad * 0.10, rad * 0.11, rad * 0.16)
        love.graphics.setLineWidth(1.4)
        love.graphics.setColor(col == C.COLORS[5].color and {0.92,0.92,0.96,0.48} or {0.08,0.08,0.12,0.24})
        love.graphics.arc("line", "open", cx, y + rad * 0.18, rad * 0.18, 0.25, math.pi - 0.25)
    end

    local cx = C.SW / 2
    local cy = C.SH / 2
    
    local pw, ph = 500, 440
    local px = cx - pw / 2
    local py = cy - ph / 2 - 20
    
    UI.panel(px, py, pw, ph, 14)
    
    love.graphics.setFont(UI.fXX)
    UI.txtC("컬러 퍼즐 7", cx, py + 36, P.gold, UI.fXX)
    
    love.graphics.setFont(UI.fS)
    UI.txtC("색친구들의 무대 모험", cx, py + 92, P.dim, UI.fS)
    
    love.graphics.setColor(P.panelBd)
    love.graphics.line(px + 30, py + 120, px + pw - 30, py + 120)
    
    -- 색친구들 순서대로 그리기 (위에 나란히)
    local colors = {C.COLORS[1].color, C.COLORS[2].color, C.COLORS[3].color, C.COLORS[4].color, C.COLORS[5].color}
    local mascotY = py + 210
    for i = 1, 5 do
        mascot(cx - 160 + (i - 1) * 80, mascotY, 28, colors[i], i)
        
        -- 색상 이름 작게 표시
        local cname = C.COLORS[i].name
        if cname == "Red" then cname = "빨강"
        elseif cname == "Orange" then cname = "주황"
        elseif cname == "Yellow" then cname = "노랑"
        elseif cname == "White" then cname = "하양"
        elseif cname == "Black" then cname = "검정" end
        UI.txtC(cname, cx - 160 + (i - 1) * 80, mascotY + 38, P.dim, UI.fS)
    end
    
    local mx, my = love.mouse.getPosition()
    local btnW, btnH = 200, 48
    local btnX = cx - btnW / 2
    local btnY = py + ph - 85
    local hovStart = mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH
    UI.button(btnX, btnY, btnW, btnH, "새 모험 시작", true, hovStart, UI.fL)
    UI.txtC("Enter / Space", cx, btnY + btnH + 8, P.dim, UI.fS)
end

function S.topUI()
    if G.phase == "title" then return end

    local x, y, w, h = C.LX, C.LY, C.LW, 220
    UI.panel(x, y, w, h, 12)

    UI.txt("컬러 퍼즐 7", x+18, y+14, P.text, UI.fL)
    
    -- 재시작 버튼 우상단으로 이동
    local mx, my = love.mouse.getPosition()
    local btnW, btnH = 56, 24
    local bx, by = x + w - 74, y + 14
    local hovReset = mx >= bx and mx <= bx+btnW and my >= by and my <= by+btnH
    UI.button(bx, by, btnW, btnH, "재시작", true, hovReset, UI.fS)
    
    UI.pill(x+18, y+48, 78, 24, "월드 " .. tostring(G.ante), P.cMirr, UI.fS)
    UI.pill(x+104, y+48, 116, 24, gateName(), P.btnR, UI.fS)

    local function statBox(sx, sy, label, value, col)
        love.graphics.setColor(0.25, 0.32, 0.44, 0.06)
        UI.rr("fill", sx, sy+2, 100, 60, 8)
        love.graphics.setColor(1, 1, 1, 0.86)
        UI.rr("fill", sx, sy, 100, 60, 8)
        love.graphics.setColor(P.panelBd)
        love.graphics.setLineWidth(1)
        UI.rr("line", sx, sy, 100, 60, 8)
        UI.txt(label, sx+12, sy+7, P.dim, UI.fS)
        love.graphics.setFont(UI.fL)
        love.graphics.setColor(col)
        love.graphics.print(value, sx+12, sy+26)
    end

    statBox(x+18, y+84, "목표", tostring(G.targetScore), P.mult)
    local scoreColor = G.roundCleared and P.cMono or P.gold
    statBox(x+126, y+84, "현재 점수", tostring(math.floor(G.dScore)), scoreColor)
    statBox(x+18, y+152, "코인", "$" .. tostring(G.gold), P.gold)
    statBox(x+126, y+152, "남은 실행", G.execLeft .. "/4", P.cStep)
end

function S.deckUI()
    if G.phase ~= "play" then return end

    local x, y, w, h = C.RX, C.RY, C.RW, C.RH
    UI.panel(x, y, w, h, 12)

    local mx,my = love.mouse.getPosition()
    local nCards = #G.hand

    -- 주머니 잔량
    local bx0, by0, bw0, bh0 = x + 30, y + 30, w - 60, 100
    G.hBag = mx >= bx0 and mx <= bx0 + bw0 and my >= by0 and my <= by0 + bh0
    love.graphics.setColor(0.12, 0.08, 0.06, 0.28)
    UI.rr("fill", bx0 + 2, by0 + 4, bw0, bh0, 7)
    love.graphics.setColor(G.hBag and P.slotHov or P.panel)
    UI.rr("fill", bx0, by0, bw0, bh0, 7)
    love.graphics.setColor(G.hBag and P.slotHBd or P.panelBd)
    love.graphics.setLineWidth(1.4)
    UI.rr("line", bx0, by0, bw0, bh0, 7)

    local dx = bx0 + 30
    local dy = by0 + 40
    for j = 2, 0, -1 do
        love.graphics.setColor(P.dim[1],P.dim[2],P.dim[3],0.18+j*0.08)
        UI.rr("fill", dx-8+j*2, dy-12+j*2, 24, 34, 4)
    end
    UI.txtC("주머니", bx0 + bw0/2, by0 + 16, P.text, UI.fS)
    UI.txtC(tostring(#G.deck), bx0 + bw0/2, by0 + 46, P.gold, UI.fX)

    -- 실행 및 바꾸기 버튼
    local runW, runH = w - 60, 60
    local runX, runY = x + 30, y + h - 180
    local canRun = nCards > 0
    G.hRun = mx>=runX and mx<=runX+runW and my>=runY and my<=runY+runH
    UI.button(runX, runY, runW, runH, "실행!", canRun, G.hRun, UI.fX)

    local bw, bh = w - 60, 50
    local bx, by = x + 30, y + h - 100
    local canDiscard = G.selCount() > 0 and G.discLeft > 0
    G.hDiscard = mx>=bx and mx<=bx+bw and my>=by and my<=by+bh

    UI.button(bx, by, bw, bh, "바꾸기", canDiscard, G.hDiscard, UI.fL)
    love.graphics.setFont(UI.fS)
    local rtxt = G.discLeft.."/"..C.MAXDISC
    love.graphics.setColor(canDiscard and P.gold or P.dim)
    love.graphics.print(rtxt, bx+(bw-UI.fS:getWidth(rtxt))/2, by+32)

    love.graphics.setFont(UI.fM)
    love.graphics.setColor(canRun and P.gold or P.dim)
    local toExec = math.min(C.BN, nCards)
    local pickTxt = toExec .. "명 모두 출전"
    love.graphics.print(pickTxt, runX + (runW - UI.fM:getWidth(pickTxt))/2, runY - 22)

    if G.noticeTimer > 0 then
        local nc = G.noticeKind == "ok" and P.cMono or P.btnR
        local nw = math.min(260, UI.fS:getWidth(G.noticeText) + 24)
        UI.pill(C.HCX - nw / 2, C.BY + C.BSH + 20, nw, 22, G.noticeText, nc, UI.fS)
    end
end

function S.cheatSheet()
    if G.phase == "title" then return end
    local cx, cy, cw, ch = C.LX, C.LY + 240, C.LW, C.LH - 240
    UI.panel(cx, cy, cw, ch, 10)
    UI.txt("색 규칙", cx+14, cy+10, P.text, UI.fM)
    UI.txt("별 / 콤보", cx+cw-78, cy+13, P.dim, UI.fS)
    love.graphics.setFont(UI.fS)
    local y = cy+42

    local function entry(cc, name, desc, chips, mult)
        love.graphics.setColor(cc)
        love.graphics.circle("fill", cx+16, y+6, 3)
        love.graphics.setColor(P.text)
        love.graphics.print(name, cx+26, y)
        love.graphics.setColor(P.dim[1],P.dim[2],P.dim[3],0.50)
        love.graphics.print(desc, cx+26, y+14)
        UI.pill(cx+cw-80,y+1,34,15,tostring(chips),P.chip,UI.fS)
        UI.pill(cx+cw-42,y+1,34,15,"x"..tostring(mult),P.mult,UI.fS)
        y = y + 32
    end

    love.graphics.setColor(P.cMono); love.graphics.print("같은색",cx+14,y); y=y+16
    entry(P.cMono,"세 친구","같은색 3",30,3)
    entry(P.cMono,"네 친구","같은색 4",60,5)
    entry(P.cMono,"색 탑","같은색 5+",150,12)
    y=y+6
    love.graphics.setColor(P.cMirr); love.graphics.print("거울",cx+14,y); y=y+16
    entry(P.cMirr,"작은 거울","5~6개 대칭",100,8)
    entry(P.cMirr,"큰 거울","7개 대칭",400,40)
    y=y+6
    love.graphics.setColor(P.cStep); love.graphics.print("계단",cx+14,y); y=y+16
    entry(P.cStep,"작은 계단","1-2-3 모양",120,10)
    entry(P.cStep,"무지개 계단","1-2-3-1 모양",300,25)
    y=y+12
    love.graphics.setColor(P.dim[1],P.dim[2],P.dim[3],0.2)
    love.graphics.line(cx+14,y,cx+cw-14,y); y=y+8
    love.graphics.setColor(P.dim[1],P.dim[2],P.dim[3],0.5)
    love.graphics.print("최종 점수 = 별 x 콤보",cx+14,y)
end

function S.jokers()
    if G.phase == "title" then return end
    UI.panel(C.JX, C.JY, C.JW, C.JH, 10)
    UI.txt("도우미", C.JX+14, C.JY+10, P.text, UI.fM)
    UI.pill(C.JX+C.JW-62, C.JY+12, 42, 20, #G.jokers .. "/3", P.cMirr, UI.fS)
    
    love.graphics.setFont(UI.fS)
    
    if #G.jokers == 0 then
        love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.35)
        UI.txtC("비어 있음", C.JX + C.JW/2, C.JY + C.JH/2, P.dim, UI.fM)
        return
    end
    
    local jw = (C.JW - 40) / 3
    local jh = C.JH - 40
    local sx = C.JX + 10
    local sy = C.JY + 30
    
    for i, j in ipairs(G.jokers) do
        local cx, cy = sx + (i-1)*(jw + 10), sy
        
        love.graphics.setColor(0, 0, 0, 0.04)
        UI.rr("fill", cx, cy + 2, jw, jh, 6)
        
        love.graphics.setColor(1, 1, 1)
        UI.rr("fill", cx, cy, jw, jh, 6)
        
        love.graphics.setColor(P.cMirr)
        love.graphics.setLineWidth(1.2)
        UI.rr("line", cx, cy, jw, jh, 6)
        
        UI.txtC(j.name, cx + jw/2, cy + 12, P.text, UI.fS)
        
        love.graphics.setFont(UI.fS)
        love.graphics.setColor(P.dim)
        
        local lineY = cy + 32
        for line in string.gmatch(j.desc, "[^\n]+") do
            UI.txtC(line, cx + jw/2, lineY, P.dim, UI.fS)
            lineY = lineY + 16
        end
    end
end

local function drawBagPiece(x, y, w, h, colorInfo, state)
    local col = colorInfo.color
    local alpha = state == "gone" and 0.24 or 0.96
    local fill = state == "left" and P.slotHov or P.panel
    if state == "picked" then fill = {0.98, 0.84, 0.22} end
    if state == "hand" then fill = {0.94, 0.98, 1.00} end

    love.graphics.setColor(0.03, 0.05, 0.05, 0.30)
    UI.rr("fill", x + 2, y + 3, w, h, 5)
    love.graphics.setColor(fill[1], fill[2], fill[3], alpha)
    UI.rr("fill", x, y, w, h, 5)
    love.graphics.setColor(col[1], col[2], col[3], state == "gone" and 0.32 or 0.92)
    UI.rr("fill", x + 4, y + 4, w - 8, h - 8, 4)
    love.graphics.setColor(1, 1, 1, state == "gone" and 0.06 or 0.18)
    love.graphics.line(x + 7, y + h - 8, x + w - 7, y + 8)
    love.graphics.setColor(state == "picked" and P.btnR or P.panelBd)
    love.graphics.setLineWidth(state == "picked" and 2.0 or 1.0)
    UI.rr("line", x, y, w, h, 5)
end

function S.bagOverlay()
    if not G.showBag then return end

    love.graphics.setColor(0.02, 0.04, 0.04, 0.76)
    love.graphics.rectangle("fill", 0, 0, C.SW, C.SH)
    love.graphics.setColor(P.felt[1], P.felt[2], P.felt[3], 0.38)
    love.graphics.rectangle("fill", 0, 0, C.SW, C.SH)
    love.graphics.setColor(1, 1, 1, 0.035)
    for y = 0, C.SH, 6 do
        love.graphics.line(0, y, C.SW, y)
    end

    local px, py, pw, ph = C.HCX - 560, 70, 1120, 590
    love.graphics.setColor(0.95, 0.88, 0.95, 0.22)
    love.graphics.setLineWidth(2)
    UI.rr("line", px - 14, py - 14, pw + 28, ph + 28, 16)
    UI.panel(px, py, pw, ph, 12)

    UI.txtC("주머니 전체", C.HCX, py + 22, P.text, UI.fX)
    love.graphics.setColor(P.btnR)
    love.graphics.polygon("fill", C.HCX - 8, py + 6, C.HCX + 8, py + 6, C.HCX, py + 22)

    local mx, my = love.mouse.getPosition()
    local closeX, closeY, closeW, closeH = C.HCX + 420, 82, 84, 32
    local hovClose = mx >= closeX and mx <= closeX + closeW and my >= closeY and my <= closeY + closeH
    UI.button(closeX, closeY, closeW, closeH, "닫기", true, hovClose, UI.fS)

    local totalCounts = countColors(G.deckConfig)
    local leftCounts = countColors(G.deck)
    local handCounts = countColors(G.hand)
    local pickedCounts = {}
    for _, c in ipairs(C.COLORS) do pickedCounts[c.name] = 0 end
    for _, card in ipairs(G.hand) do
        if card.sel then pickedCounts[card.name] = pickedCounts[card.name] + 1 end
    end

    local sx, sy, sw, sh = px + 28, py + 84, 230, 390
    love.graphics.setColor(0.02, 0.04, 0.04, 0.72)
    UI.rr("fill", sx, sy, sw, sh, 8)
    love.graphics.setColor(P.slotHBd)
    love.graphics.setLineWidth(1.2)
    UI.rr("line", sx, sy, sw, sh, 8)

    UI.txtC("색친구 수", sx + sw / 2, sy + 16, P.white, UI.fL)
    love.graphics.setFont(UI.fS)
    love.graphics.setColor(0.85, 0.96, 0.92, 0.76)
    love.graphics.print("전체", sx + 88, sy + 54)
    love.graphics.print("남음", sx + 132, sy + 54)
    love.graphics.print("손", sx + 176, sy + 54)

    local rowY = sy + 78
    for _, colorInfo in ipairs(C.COLORS) do
        local c = colorInfo.color
        love.graphics.setColor(c)
        love.graphics.circle("fill", sx + 28, rowY + 8, 8)
        love.graphics.setColor(P.white)
        love.graphics.setFont(UI.fM)
        love.graphics.print(colorName(colorInfo.name), sx + 44, rowY - 1)
        love.graphics.setFont(UI.fM)
        love.graphics.setColor(0.95, 0.98, 1.0)
        love.graphics.print(tostring(totalCounts[colorInfo.name] or 0), sx + 92, rowY - 1)
        love.graphics.setColor(P.gold)
        love.graphics.print(tostring(leftCounts[colorInfo.name] or 0), sx + 138, rowY - 1)
        love.graphics.setColor(P.cStep)
        love.graphics.print(tostring(handCounts[colorInfo.name] or 0), sx + 182, rowY - 1)
        rowY = rowY + 42
    end

    local legendY = sy + sh - 84
    local function legend(x, label, col)
        love.graphics.setColor(col)
        UI.rr("fill", x, legendY, 18, 12, 3)
        UI.txt(label, x + 24, legendY - 2, P.white, UI.fS)
    end
    legend(sx + 18, "남은", P.slotHov)
    legend(sx + 92, "손", {0.94, 0.98, 1.00})
    legend(sx + 154, "고른", {0.98, 0.84, 0.22})

    local gx, gy = px + 285, py + 104
    local cellW, cellH = 35, 48
    local gapX, gapY = 5, 12
    local perRow = 16

    for row, colorInfo in ipairs(C.COLORS) do
        local y = gy + (row - 1) * (cellH + gapY)
        UI.txt(colorName(colorInfo.name), gx - 58, y + 15, P.white, UI.fM)
        local total = totalCounts[colorInfo.name] or 0
        local left = leftCounts[colorInfo.name] or 0
        local hand = handCounts[colorInfo.name] or 0
        local picked = pickedCounts[colorInfo.name] or 0
        for i = 1, total do
            local state = "gone"
            if i <= picked then
                state = "picked"
            elseif i <= hand then
                state = "hand"
            elseif i <= hand + left then
                state = "left"
            end
            local x = gx + ((i - 1) % perRow) * (cellW + gapX)
            local yy = y + math.floor((i - 1) / perRow) * (cellH + 4)
            drawBagPiece(x, yy, cellW, cellH, colorInfo, state)
        end
    end

    local backX, backY, backW, backH = C.HCX - 540, 604, 1080, 42
    local hovBack = mx >= backX and mx <= backX + backW and my >= backY and my <= backY + backH
    UI.button(backX, backY, backW, backH, "뒤로", true, hovBack, UI.fL)
    UI.txtC("[B] 주머니 보기 / 닫기", C.HCX, backY - 28, {0.85, 0.96, 0.92, 0.72}, UI.fS)
end

function S.scoring()
    local s = G.sc
    if not s.active then return end

    if s.phase == "nohand" then
        local a = math.min(1, s.timer*2)
        UI.txtC("맞는 규칙 없음...", C.HCX, C.SH/2-20, {P.dim[1],P.dim[2],P.dim[3],a}, UI.fXX)
        UI.txtC("0 점", C.HCX, C.SH/2+30, {P.dim[1],P.dim[2],P.dim[3],a*.5}, UI.fM)
        if s.timer > 0.8 then
            local mx, my = love.mouse.getPosition()
            local bx, by, bw, bh = C.HCX - 74, C.SH/2 + 68, 148, 34
            local hov = mx >= bx and mx <= bx + bw and my >= by and my <= by + bh
            UI.button(bx, by, bw, bh, "계속", true, hov, UI.fM)
        end
        return
    end

    local lw, lh = 320, 38
    local startY = 390
    for idx, h in ipairs(s.revealed) do
        local age = (idx==#s.revealed and s.phase=="reveal") and math.min(1,s.timer/.2) or 1
        local cy = startY + (idx-1)*(lh+4)
        local ox = (1-UI.easeCubic(age))*40
        love.graphics.push()
        love.graphics.translate(C.HCX-lw/2+ox, cy)
        
        love.graphics.setColor(0.08,0.10,0.18,age*0.04)
        UI.rr("fill",0,2,lw*UI.easeBack(age),lh,6)
        love.graphics.setColor(1,1,1,age*0.96)
        UI.rr("fill",0,0,lw*UI.easeBack(age),lh,6)
        love.graphics.setColor(P.panelBd[1],P.panelBd[2],P.panelBd[3],age*0.6)
        UI.rr("line",0,0,lw*UI.easeBack(age),lh,6)

        local cc = UI.catCol(h.cat)
        love.graphics.setColor(cc[1],cc[2],cc[3],age)
        UI.rr("fill",0,0,3,lh,2)
        love.graphics.setFont(UI.fS)
        love.graphics.setColor(cc[1],cc[2],cc[3],age*.6)
        love.graphics.print(catName(h.cat),10,3)
        love.graphics.setFont(UI.fM)
        love.graphics.setColor(P.text[1],P.text[2],P.text[3],age)
        love.graphics.print(ruleName(h.name),10,17)
        local bw2=lw*UI.easeBack(age)
        love.graphics.setColor(P.chip[1],P.chip[2],P.chip[3],age)
        UI.rr("fill",bw2-95,8,40,22,4)
        love.graphics.setColor(1,1,1,age)
        love.graphics.setFont(UI.fM)
        local cs=tostring(h.chips); love.graphics.print(cs,bw2-95+(40-UI.fM:getWidth(cs))/2,10)
        love.graphics.setColor(P.mult[1],P.mult[2],P.mult[3],age)
        UI.rr("fill",bw2-50,8,40,22,4)
        love.graphics.setColor(1,1,1,age)
        local ms="x"..tostring(h.mult); love.graphics.print(ms,bw2-50+(40-UI.fM:getWidth(ms))/2,10)
        love.graphics.pop()
    end

    if #s.revealed > 0 then
        local ty = C.SH - 190
        UI.chipB(C.HCX-35, ty, math.floor(s.dChips))
        love.graphics.setFont(UI.fL); love.graphics.setColor(P.text)
        love.graphics.print("x", C.HCX-4, ty-12)
        UI.multB(C.HCX+35, ty, math.floor(s.dMult))
    end

    if s.phase == "total" then
        local a = math.min(1, s.timer/0.35)
        local sc = UI.easeElastic(a)
        local sy = C.SH - 110
        love.graphics.push()
        love.graphics.translate(C.HCX, sy)
        love.graphics.scale(sc, sc)
        love.graphics.setFont(UI.fXX)
        local st = tostring(math.floor(s.dTotal))
        love.graphics.setColor(0,0,0,0.06)
        love.graphics.print(st, -UI.fXX:getWidth(st)/2+1, -UI.fXX:getHeight()/2+1)
        love.graphics.setColor(P.gold)
        love.graphics.print(st, -UI.fXX:getWidth(st)/2, -UI.fXX:getHeight()/2)
        love.graphics.pop()
        UI.txtC("점", C.HCX, sy+25*sc, {P.dim[1],P.dim[2],P.dim[3],a*.6}, UI.fM)
        if s.timer > 1.2 then
            local mx, my = love.mouse.getPosition()
            local bx, by, bw, bh = C.HCX - 74, sy + 44, 148, 34
            local hov = mx >= bx and mx <= bx + bw and my >= by and my <= by + bh
            UI.button(bx, by, bw, bh, "계속", true, hov, UI.fM)
            UI.txtC("Enter / Space", C.HCX, by + bh + 8, P.dim, UI.fS)
        end
    end
end

function S.result()
    if G.phase ~= "result" then return end
    love.graphics.setColor(0.04, 0.05, 0.08, 0.85)
    love.graphics.rectangle("fill",0,0,C.SW,C.SH)

    local pw,ph = 360,420
    local px,py = C.HCX-pw/2, C.SH/2-ph/2
    
    love.graphics.setColor(0.08,0.10,0.18,0.06)
    UI.rr("fill",px,py+4,pw,ph+2,14)
    love.graphics.setColor(0.08,0.10,0.18,0.08)
    UI.rr("fill",px,py+2,pw,ph,14)

    love.graphics.setColor(1,1,1,0.98)
    UI.rr("fill",px,py,pw,ph,14)
    love.graphics.setColor(P.panelBd)
    love.graphics.setLineWidth(1.2)
    UI.rr("line",px,py,pw,ph,14)

    UI.txtC("관문 통과", px+pw/2, py+14, P.gold, UI.fL)
    love.graphics.setColor(P.panelBd)
    love.graphics.line(px+20,py+42,px+pw-20,py+42)

    local y = py+52
    if #G.detected == 0 then
        UI.txtC("맞는 규칙 없음", px+pw/2, y+10, P.dim, UI.fL)
    else
        for _,h in ipairs(G.detected) do
            local cc = UI.catCol(h.cat)
            love.graphics.setColor(cc); love.graphics.circle("fill",px+20,y+7,3)
            love.graphics.setFont(UI.fS); love.graphics.setColor(cc[1],cc[2],cc[3],0.55)
            love.graphics.print(catName(h.cat),px+30,y)
            love.graphics.setFont(UI.fM); love.graphics.setColor(P.text)
            love.graphics.print(ruleName(h.name),px+95,y-1)
            love.graphics.setColor(P.chip[1],P.chip[2],P.chip[3],0.80)
            UI.rr("fill",px+pw-95,y,38,18,3)
            love.graphics.setColor(1,1,1); love.graphics.setFont(UI.fS)
            local cs=tostring(h.chips); love.graphics.print(cs,px+pw-95+(38-UI.fS:getWidth(cs))/2,y+2)
            love.graphics.setColor(P.mult[1],P.mult[2],P.mult[3],0.80)
            UI.rr("fill",px+pw-52,y,38,18,3)
            love.graphics.setColor(1,1,1)
            local ms="x"..tostring(h.mult); love.graphics.print(ms,px+pw-52+(38-UI.fS:getWidth(ms))/2,y+2)
            y = y + 25
        end
        y = y + 4
        love.graphics.setColor(P.panelBd)
        love.graphics.line(px+20,y,px+pw-20,y)
        y = y + 6
        
        local tc,tm = 0,0
        for _,h in ipairs(G.detected) do tc=tc+h.chips; tm=tm+h.mult end
        love.graphics.setFont(UI.fM); love.graphics.setColor(P.dim)
        love.graphics.print("합계:",px+20,y)
        UI.chipB(px+pw-75, y+9, tc)
        love.graphics.setFont(UI.fM); love.graphics.setColor(P.text)
        love.graphics.print("x",px+pw-50,y)
        UI.multB(px+pw-30, y+9, tm)
    end

    local totalGold, baseGold, discGold, interestGold, jokerGold = G.calcGoldReward()
    local gx = px + 20
    local gy = py + ph - 175
    local gw = pw - 40
    local gh = 70
    
    love.graphics.setColor(0.12, 0.14, 0.18)
    UI.rr("fill", gx, gy, gw, gh, 6)
    love.graphics.setColor(P.panelBd)
    UI.rr("line", gx, gy, gw, gh, 6)
    
    love.graphics.setFont(UI.fS)
    love.graphics.setColor(P.dim)
    love.graphics.print("코인 받기:", gx + 10, gy + 8)
    
    local gtxt = string.format("기본 +$3  바꾸기 +$%d  저금 +$%d  도우미 +$%d", discGold, interestGold, jokerGold)
    love.graphics.setColor(P.text)
    love.graphics.print(gtxt, gx + 10, gy + 26)
    
    love.graphics.setFont(UI.fM)
    love.graphics.setColor(P.gold)
    local totTxt = "총 코인: +$" .. totalGold
    love.graphics.print(totTxt, gx + gw - UI.fM:getWidth(totTxt) - 10, gy + 45)

    love.graphics.setFont(UI.fXX)
    local st=tostring(G.rndScore)
    love.graphics.setColor(0,0,0,0.06)
    love.graphics.print(st,px+(pw-UI.fXX:getWidth(st))/2+1,py+ph-90+1)
    love.graphics.setColor(P.gold)
    love.graphics.print(st,px+(pw-UI.fXX:getWidth(st))/2,py+ph-90)
    UI.txtC("점", px+pw/2, py+ph-48, {P.dim[1],P.dim[2],P.dim[3],0.5}, UI.fS)

    local mx, my = love.mouse.getPosition()
    local bx, by, bw, bh = px + (pw - 150) / 2, py + ph - 40, 150, 34
    local hov = mx >= bx and mx <= bx + bw and my >= by and my <= by + bh
    local label = G.score >= G.targetScore and "상점으로" or "모험 종료"
    UI.button(bx, by, bw, bh, label, true, hov, UI.fM)
end

function S.gameover()
    if G.phase ~= "gameover" then return end
    love.graphics.setColor(0.08, 0.08, 0.12, 0.85)
    love.graphics.rectangle("fill",0,0,C.SW,C.SH)

    local pw,ph = 400,340
    local px,py = C.HCX-pw/2, C.SH/2-ph/2
    
    love.graphics.setColor(0,0,0,0.3)
    UI.rr("fill",px,py+4,pw,ph+2,14)
    love.graphics.setColor(1,1,1,0.98)
    UI.rr("fill",px,py,pw,ph,14)
    love.graphics.setColor(P.btnR)
    love.graphics.setLineWidth(2)
    UI.rr("line",px,py,pw,ph,14)

    UI.txtC("게임 오버", px+pw/2, py+24, P.btnR, UI.fXX)
    love.graphics.setColor(P.panelBd)
    love.graphics.line(px+30,py+74,px+pw-30,py+74)

    local y = py + 95
    UI.txtC("도달한 길: " .. tostring(G.ante) .. "-" .. tostring(G.stage), px+pw/2, y, P.text, UI.fL)
    UI.txtC("최종 점수: " .. tostring(math.floor(G.totalScore)), px+pw/2, y+38, P.gold, UI.fX)

    local bw, bh = 180, 44
    local bx = px + (pw-bw)/2
    local by = py + ph - 80
    
    local mx,my = love.mouse.getPosition()
    local hovBtn = mx>=bx and mx<=bx+bw and my>=by and my<=by+bh
    
    UI.button(bx, by, bw, bh, "다시 하기", true, hovBtn, UI.fM)
    
    UI.txtC("또는 [R]키를 눌러 재시작", px+pw/2, by+bh+12, P.dim, UI.fS)
end

local function shopIcon(item, cx, cy, accent)
    love.graphics.setColor(0.24, 0.30, 0.42, 0.10)
    UI.rr("fill", cx - 39, cy - 35, 78, 74, 12)
    love.graphics.setColor(1, 1, 1, 0.78)
    UI.rr("fill", cx - 40, cy - 38, 78, 74, 12)
    love.graphics.setColor(accent[1], accent[2], accent[3], 0.35)
    UI.rr("fill", cx - 34, cy - 32, 66, 62, 10)
    love.graphics.setColor(accent)
    love.graphics.setLineWidth(1.4)
    UI.rr("line", cx - 40, cy - 38, 78, 74, 12)

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
        UI.rr("fill", cx - 27, cy + 13, 15, 14, 4)
        love.graphics.setColor(P.gold)
        UI.rr("fill", cx - 7, cy + 3, 15, 24, 4)
        love.graphics.setColor(P.mult)
        UI.rr("fill", cx + 13, cy - 8, 15, 35, 4)
        love.graphics.setColor(accent)
        love.graphics.setLineWidth(4)
        love.graphics.line(cx - 24, cy - 3, cx, cy - 25, cx + 24, cy - 3)
        love.graphics.polygon("fill", cx, cy - 34, cx - 9, cy - 18, cx + 9, cy - 18)
    elseif item.type == "deck_add" then
        local col = item.colorVal or accent
        love.graphics.setColor(0.24, 0.30, 0.42, 0.18)
        UI.rr("fill", cx - 28, cy - 20, 42, 54, 7)
        love.graphics.setColor(1, 1, 1, 0.92)
        UI.rr("fill", cx - 32, cy - 25, 42, 54, 7)
        love.graphics.setColor(col)
        love.graphics.circle("fill", cx - 11, cy + 2, 15)
        love.graphics.setColor(accent)
        love.graphics.setLineWidth(5)
        love.graphics.line(cx + 23, cy - 11, cx + 23, cy + 15)
        love.graphics.line(cx + 10, cy + 2, cx + 36, cy + 2)
    elseif item.type == "deck_remove" then
        love.graphics.setColor(0.24, 0.30, 0.42, 0.18)
        UI.rr("fill", cx - 26, cy - 18, 44, 52, 7)
        love.graphics.setColor(1, 1, 1, 0.92)
        UI.rr("fill", cx - 31, cy - 24, 44, 52, 7)
        love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.45)
        love.graphics.circle("fill", cx - 9, cy + 1, 15)
        love.graphics.setColor(P.btnR)
        love.graphics.setLineWidth(5)
        love.graphics.line(cx + 9, cy + 2, cx + 35, cy + 2)
    end
end

function S.shop()
    if G.phase ~= "shop" then return end
    
    love.graphics.setColor(0.04, 0.05, 0.08, 0.88)
    love.graphics.rectangle("fill", 0, 0, C.SW, C.SH)
    
    local mx, my = love.mouse.getPosition()
    
    -- 1. 왼쪽 패널 (모험 관문 진행도)
    local lx, ly, lw, lh = 80, 80, 500, 560
    UI.panel(lx, ly, lw, lh, 14)
    UI.txt("모험 관문", lx + 30, ly + 24, P.text, UI.fX)
    UI.txt("현재 월드: " .. G.ante, lx + 30, ly + 58, P.dim, UI.fS)
    love.graphics.setColor(P.panelBd)
    love.graphics.line(lx + 20, ly + 78, lx + lw - 20, ly + 78)
    
    local stages = {
        {name="쉬운 관문 (Small Stage)"},
        {name="도전 관문 (Big Stage)"},
        {name="특별 관문 (Boss Stage)"}
    }
    
    local startY = ly + 95
    local boxH = 95
    local gapY = 15
    
    for i = 1, 3 do
        local sy = startY + (i - 1) * (boxH + gapY)
        local sx = lx + 30
        local sw = lw - 60
        
        local targetScore = getTargetScoreForStage(G.ante, i, G.bossGimmick)
        local state = "locked"
        if i < G.stage then
            state = "cleared"
        elseif i == G.stage then
            state = "current"
        end
        
        if state == "cleared" then
            love.graphics.setColor(0.08, 0.10, 0.18, 0.4)
            UI.rr("fill", sx, sy, sw, boxH, 8)
            love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.25)
            love.graphics.setLineWidth(1)
            UI.rr("line", sx, sy, sw, boxH, 8)
            
            UI.txt(stages[i].name, sx + 20, sy + 18, {0.5, 0.5, 0.5, 0.6}, UI.fM)
            UI.txt("목표 점수: " .. targetScore, sx + 20, sy + 44, {0.5, 0.5, 0.5, 0.5}, UI.fS)
            UI.pill(sx + sw - 85, sy + 16, 65, 20, "클리어", P.cMono, UI.fS)
        elseif state == "current" then
            love.graphics.setColor(0.12, 0.16, 0.28, 0.7)
            UI.rr("fill", sx, sy, sw, boxH, 8)
            love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], 0.8)
            love.graphics.setLineWidth(2)
            UI.rr("line", sx, sy, sw, boxH, 8)
            
            UI.txt(stages[i].name, sx + 20, sy + 18, P.text, UI.fM)
            UI.txt("목표 점수: " .. targetScore, sx + 20, sy + 44, P.gold, UI.fS)
            
            if i == 3 then
                local desc = ""
                if G.bossGimmick == "no_red" then desc = "빨강 색친구 점수 없음"
                elseif G.bossGimmick == "no_black" then desc = "검정 색친구 점수 없음"
                elseif G.bossGimmick == "no_discard" then desc = "바꾸기 사용 불가"
                elseif G.bossGimmick == "high_target" then desc = "목표 점수 1.5배"
                end
                UI.txt("특별 규칙: " .. desc, sx + 20, sy + 66, P.mult, UI.fS)
            end
            
            UI.pill(sx + sw - 85, sy + 16, 65, 20, "도전 중", P.btnR, UI.fS)
        else
            love.graphics.setColor(0.06, 0.08, 0.12, 0.6)
            UI.rr("fill", sx, sy, sw, boxH, 8)
            love.graphics.setColor(P.panelBd[1], P.panelBd[2], P.panelBd[3], 0.15)
            love.graphics.setLineWidth(1)
            UI.rr("line", sx, sy, sw, boxH, 8)
            
            UI.txt(stages[i].name, sx + 20, sy + 22, {0.4, 0.4, 0.4, 0.5}, UI.fM)
            UI.txt("목표 점수: " .. targetScore, sx + 20, sy + 48, {0.4, 0.4, 0.4, 0.4}, UI.fS)
            
            if i == 3 then
                local desc = ""
                if G.bossGimmick == "no_red" then desc = "빨강 색친구 점수 없음"
                elseif G.bossGimmick == "no_black" then desc = "검정 색친구 점수 없음"
                elseif G.bossGimmick == "no_discard" then desc = "바꾸기 사용 불가"
                elseif G.bossGimmick == "high_target" then desc = "목표 점수 1.5배"
                end
                UI.txt("특별 규칙: " .. desc, sx + 20, sy + 68, {0.4, 0.3, 0.3, 0.3}, UI.fS)
            end
            UI.pill(sx + sw - 85, sy + 16, 65, 20, "대기 중", P.btnG, UI.fS)
        end
    end
    
    local nW, nH = lw - 60, 50
    local nX = lx + 30
    local nY = ly + lh - 80
    local hovNext = mx >= nX and mx <= nX+nW and my >= nY and my <= nY+nH
    UI.button(nX, nY, nW, nH, "관문 시작!", true, hovNext, UI.fL)
    UI.txtC("Enter / Space", lx + lw / 2, nY + nH + 6, P.dim, UI.fS)
    
    -- 2. 오른쪽 패널 (상점)
    local rx, ry, rw, rh = 620, 80, 580, 560
    UI.panel(rx, ry, rw, rh, 14)
    UI.txt("컬러 상점", rx + 30, ry + 24, P.text, UI.fX)
    UI.txt("코인으로 능력과 주머니를 강화하세요.", rx + 30, ry + 58, P.dim, UI.fS)
    UI.pill(rx + rw - 104, ry + 30, 74, 24, "$" .. G.gold, P.gold, UI.fM)
    
    if G.noticeTimer > 0 then
        local nc = G.noticeKind == "ok" and P.cMono or P.btnR
        local nw = math.min(260, UI.fS:getWidth(G.noticeText) + 24)
        UI.pill(rx + rw - 118 - nw, ry + 32, nw, 22, G.noticeText, nc, UI.fS)
    end
    
    love.graphics.setColor(P.panelBd)
    love.graphics.line(rx + 20, ry + 78, rx + rw - 20, ry + 78)
    
    local startX = rx + 30
    local itemW = 160
    local itemH = 260
    local gap = 20
    
    for i = 1, 3 do
        local item = G.shopItems[i]
        if item then
            local ix = startX + (i-1) * (itemW + gap)
            local iy = ry + 110
            
            local bc = P.panelBd
            if item.sold then
                bc = P.dim
            elseif item.type == "joker" then
                bc = P.cMirr
            elseif item.type == "upgrade" then
                bc = P.cMono
            elseif item.type == "deck_add" or item.type == "deck_remove" then
                bc = P.cStep
            end

            love.graphics.setColor(0.25, 0.32, 0.44, 0.10)
            UI.rr("fill", ix + 2, iy + 4, itemW, itemH, 8)
            love.graphics.setColor(item.sold and {0.94,0.94,0.95} or P.panel)
            UI.rr("fill", ix, iy, itemW, itemH, 8)
            love.graphics.setColor(1, 1, 1, item.sold and 0.25 or 0.70)
            UI.rr("fill", ix + 1, iy + 1, itemW - 2, 50, 7)

            love.graphics.setColor(bc)
            love.graphics.setLineWidth(1.5)
            UI.rr("line", ix, iy, itemW, itemH, 8)
            UI.rr("fill", ix, iy, itemW, 5, 4)
            
            if item.sold then
                love.graphics.setFont(UI.fL)
                love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.3)
                UI.txtC("품절", ix + itemW/2, iy + itemH/2 - 10, P.dim, UI.fL)
            else
                UI.txtC(item.name, ix + itemW/2, iy + 14, P.text, UI.fM)
                
                love.graphics.setFont(UI.fS)
                local typeTxt = string.upper(item.type)
                if typeTxt == "DECK_ADD" or typeTxt == "DECK_REMOVE" then typeTxt = "주머니"
                elseif typeTxt == "JOKER" then typeTxt = "도우미"
                elseif typeTxt == "UPGRADE" then typeTxt = "반짝임" end
                
                UI.pill(ix + 16, iy + 34, 100, 20, typeTxt, bc, UI.fS)

                shopIcon(item, ix + itemW / 2, iy + 96, bc)
                
                local descY = iy + 138
                for line in string.gmatch(item.desc, "[^\n]+") do
                    UI.txt(line, ix + 16, descY, P.dim, UI.fS)
                    descY = descY + 18
                end
                
                local bx = ix + 15
                local by = iy + itemH - 50
                local bw = itemW - 30
                local bh = 34
                
                local hovBuy = mx >= bx and mx <= bx+bw and my >= by and my <= by+bh
                local canAfford = G.gold >= item.price
                UI.button(bx, by, bw, bh, "$" .. item.price, canAfford, hovBuy, UI.fM)
            end
        end
    end
    
    -- 보유 현황 패널 (도우미 + 주머니 개수)
    local sx = rx + 30
    local sy = ry + 390
    local sw = rw - 60
    local sh = 135
    
    love.graphics.setColor(0.08, 0.10, 0.18, 0.4)
    UI.rr("fill", sx, sy, sw, sh, 8)
    love.graphics.setColor(P.panelBd)
    love.graphics.setLineWidth(1)
    UI.rr("line", sx, sy, sw, sh, 8)
    
    -- 2.1 도우미
    love.graphics.setFont(UI.fS)
    love.graphics.setColor(P.text)
    love.graphics.print("보유 도우미 (" .. #G.jokers .. "/3)", sx + 15, sy + 12)
    
    local jw = 125
    local jh = 85
    for i = 1, 3 do
        local jx = sx + 15 + (i - 1) * (jw + 10)
        local jy = sy + 35
        
        love.graphics.setColor(0.04, 0.05, 0.08, 0.5)
        UI.rr("fill", jx, jy, jw, jh, 6)
        love.graphics.setColor(P.panelBd[1], P.panelBd[2], P.panelBd[3], 0.3)
        love.graphics.setLineWidth(1)
        UI.rr("line", jx, jy, jw, jh, 6)
        
        local j = G.jokers[i]
        if j then
            love.graphics.setFont(UI.fS)
            UI.txtC(j.name, jx + jw/2, jy + 10, P.cMirr, UI.fS)
            
            local lineY = jy + 30
            for line in string.gmatch(j.desc, "[^\n]+") do
                UI.txtC(line, jx + jw/2, lineY, P.dim, UI.fS)
                lineY = lineY + 15
            end
        else
            love.graphics.setFont(UI.fS)
            UI.txtC("비어 있음", jx + jw/2, jy + jh/2 - 7, {0.4, 0.4, 0.4, 0.5}, UI.fS)
        end
    end
    
    -- 2.2 주머니 크기
    local dx = sx + 400
    local dy = sy + 12
    local dw = sw - 415
    local dh = sh - 24
    
    love.graphics.setColor(0.04, 0.05, 0.08, 0.5)
    UI.rr("fill", dx, dy, dw, dh, 6)
    love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], 0.3)
    love.graphics.setLineWidth(1)
    UI.rr("line", dx, dy, dw, dh, 6)
    
    love.graphics.setFont(UI.fS)
    UI.txtC("주머니", dx + dw/2, dy + 12, P.text, UI.fS)
    
    love.graphics.setFont(UI.fX)
    local countStr = tostring(#G.deckConfig)
    UI.txtC(countStr, dx + dw/2, dy + 34, P.gold, UI.fX)
    
    love.graphics.setFont(UI.fS)
    UI.txtC("개", dx + dw/2, dy + 66, P.dim, UI.fS)
end

function S.roundStartAnim()
    local a = G.roundStartAnim
    if not a or not a.active then return end
    
    local p = a.t / a.dur
    local alpha = 1
    if p < 0.20 then
        alpha = p / 0.20
    elseif p > 0.80 then
        alpha = (1 - p) / 0.20
    end
    
    love.graphics.setColor(0.08, 0.08, 0.12, alpha * 0.90)
    love.graphics.rectangle("fill", 0, C.SH/2 - 90, C.SW, 180)
    
    love.graphics.setColor(P.btnR[1], P.btnR[2], P.btnR[3], alpha * 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, C.SH/2 - 90, C.SW, C.SH/2 - 90)
    love.graphics.line(0, C.SH/2 + 90, C.SW, C.SH/2 + 90)
    
    love.graphics.setFont(UI.fXX)
    love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], alpha)
    local title = "월드 " .. G.ante .. " - " .. gateName()
    love.graphics.print(title, (C.SW - UI.fXX:getWidth(title))/2, C.SH/2 - 60)
    
    love.graphics.setFont(UI.fL)
    love.graphics.setColor(1, 1, 1, alpha)
    local subText = ""
    if G.stage == 3 then
        local desc = ""
        if G.bossGimmick == "no_red" then desc = "빨강 색친구 쉬어가기"
        elseif G.bossGimmick == "no_black" then desc = "검정 색친구 쉬어가기"
        elseif G.bossGimmick == "no_discard" then desc = "바꾸기 사용 불가"
        elseif G.bossGimmick == "high_target" then desc = "목표 점수 1.5배 증가"
        end
        subText = "특별 규칙: " .. desc
    else
        subText = "목표 점수: " .. G.targetScore
    end
    love.graphics.print(subText, (C.SW - UI.fL:getWidth(subText))/2, C.SH/2 + 10)
    
    love.graphics.setFont(UI.fS)
    love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], alpha * 0.7)
    local startTxt = "준비하세요..."
    love.graphics.print(startTxt, (C.SW - UI.fS:getWidth(startTxt))/2, C.SH/2 + 50)
end

return S
