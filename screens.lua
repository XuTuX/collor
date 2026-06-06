------------------------------------------------------------
-- screens.lua · 각종 화면 및 UI 렌더링
------------------------------------------------------------
local UI = require("ui")
local C = require("config")
local P = C.P
local G = require("game")

local S = {}

function S.title()
    if G.phase ~= "title" then return end
    
    love.graphics.setColor(P.bg)
    love.graphics.rectangle("fill", 0, 0, C.SW, C.SH)

    -- 장식 배경
    local time = love.timer.getTime()
    for i = 1, 5 do
        local bob = math.sin(time*2 + i) * 10
        UI.rr("line", C.SW/2 - 150 + i*50, C.SH/2 - 80 + bob, 40, 50, 4)
    end

    love.graphics.setColor(1, 1, 1, 0.9)
    UI.panel(C.SW/2 - 250, C.SH/2 - 120, 500, 240, 16)
    
    UI.txtC("컬러 퍼즐 7", C.SW/2, C.SH/2 - 50, P.gold, UI.fXX)
    
    local bk = 0.4 + math.sin(time*4)*0.4
    UI.txtC("화면을 클릭하여 시작하세요", C.SW/2, C.SH/2 + 30, {P.btnR[1], P.btnR[2], P.btnR[3], bk}, UI.fL)
end

function S.topUI()
    if G.phase == "title" then return end

    -- 타이틀 패널
    UI.panel(C.BX-8, 18, 280, 42, 8)
    UI.txt("컬러 퍼즐 7", C.BX+6, 24, P.gold, UI.fX)

    -- 골드 주머니 패널
    UI.panel(C.BX+280, 18, 100, 42, 8)
    UI.txt("골드", C.BX+288, 25, P.dim, UI.fS)
    local gstr = "$" .. G.gold
    UI.txt(gstr, C.BX+372-UI.fM:getWidth(gstr), 25, P.gold, UI.fM)

    -- 라운드/목표 패널 (넓이 380으로 확장)
    UI.panel(C.BX-8, 68, 380, 62, 8)
    
    UI.txt("앤티", C.BX+8, 74, P.dim, UI.fS)
    UI.txt(tostring(G.ante), C.BX+8, 88, P.text, UI.fL)
    
    UI.txt("목표", C.BX+65, 74, P.dim, UI.fS)
    UI.txt(tostring(G.targetScore), C.BX+65, 88, P.mult, UI.fL)
    
    UI.txt("점수", C.BX+145, 74, P.dim, UI.fS)
    UI.txt(tostring(math.floor(G.dScore)), C.BX+145, 82, P.gold, UI.fX)

    -- 현재 블라인드 종류 표시
    local blindStr = "스몰 블라인드"
    if G.stage == 2 then blindStr = "빅 블라인드"
    elseif G.stage == 3 then blindStr = "보스 블라인드" end
    UI.txt(blindStr, C.BX+8, 110, P.dim, UI.fS)
    
    -- 보스 블라인드 기믹 설명 표시
    if G.stage == 3 then
        local gimmickDesc = ""
        if G.bossGimmick == "no_red" then gimmickDesc = "빨간색 카드 점수 무효"
        elseif G.bossGimmick == "no_black" then gimmickDesc = "검은색 카드 점수 무효"
        elseif G.bossGimmick == "no_discard" then gimmickDesc = "버리기 사용 불가"
        elseif G.bossGimmick == "high_target" then gimmickDesc = "목표 점수 1.5배 증가"
        end
        UI.txt(gimmickDesc, C.BX+95, 110, P.btnR, UI.fS)
    end

    -- 리셋 버튼 그리기
    local mx, my = love.mouse.getPosition()
    local hovReset = mx >= C.RX and mx <= C.RX+C.RW and my >= C.RY and my <= C.RY+C.RH
    
    love.graphics.setColor(hovReset and P.btnRH or P.btnR)
    UI.rr("fill", C.RX, C.RY, C.RW, C.RH, 6)
    
    love.graphics.setFont(UI.fS)
    love.graphics.setColor(1, 1, 1)
    local rtxt = "재시작"
    love.graphics.print(rtxt, C.RX + (C.RW - UI.fS:getWidth(rtxt))/2, C.RY + (C.RH - UI.fS:getHeight())/2)
end

function S.deckUI()
    if G.phase ~= "play" then return end

    -- 덱 잔량 (왼쪽)
    local dx = C.HCX - 325
    local dy = C.HY - 5
    -- 미니 카드 스택
    for j = 2, 0, -1 do
        love.graphics.setColor(P.dim[1],P.dim[2],P.dim[3],0.15+j*0.08)
        UI.rr("fill", dx-8+j*2, dy-12+j*2, 16, 22, 3)
    end
    UI.txtC(tostring(#G.deck), dx+2, dy+16, P.dim, UI.fS)
    UI.txtC("덱", dx+2, dy+28, {P.dim[1],P.dim[2],P.dim[3],0.4}, UI.fS)

    -- 디스카드 버튼 (오른쪽)
    local bw, bh = 88, 34
    local bx = C.HCX + 294
    local by = C.HY - 10
    local selN = G.selCount()
    local can = selN > 0 and G.discLeft > 0

    -- 호버 감지
    local mx,my = love.mouse.getPosition()
    G.hDiscard = mx>=bx and mx<=bx+bw and my>=by and my<=by+bh

    love.graphics.setColor(0,0,0,0.20)
    UI.rr("fill",bx+1,by+2,bw,bh,6)
    if can then
        love.graphics.setColor(G.hDiscard and P.btnRH or P.btnR)
    else
        love.graphics.setColor(P.btnG)
    end
    UI.rr("fill",bx,by,bw,bh,6)

    love.graphics.setFont(UI.fM)
    local dtxt = "버리기"
    love.graphics.setColor(can and P.white or {0.52,0.52,0.55})
    love.graphics.print(dtxt, bx+(bw-UI.fM:getWidth(dtxt))/2, by+4)
    love.graphics.setFont(UI.fS)
    local rtxt = G.discLeft.."/"..C.MAXDISC
    love.graphics.setColor(can and P.gold or P.dim)
    love.graphics.print(rtxt, bx+(bw-UI.fS:getWidth(rtxt))/2, by+21)

    -- 선택 수
    if selN > 0 then
        love.graphics.setFont(UI.fS)
        love.graphics.setColor(P.gold[1],P.gold[2],P.gold[3],0.6)
        love.graphics.print(selN.."개 선택됨", bx-10, by-14)
    end

    -- 배치 현황
    local placed = 0
    for i=1,C.BN do if G.board[i] then placed=placed+1 end end
    UI.txtC(placed.."/"..C.BN, bx+bw/2, by+bh+6, {P.dim[1],P.dim[2],P.dim[3],0.4}, UI.fS)
end

function S.cheatSheet()
    if G.phase == "title" then return end
    local cx,cw = 18, 220
    UI.panel(cx, 18, cw, 500, 10)
    UI.txt("핸드 가이드 (족보)", cx+10, 26, P.gold, UI.fM)
    love.graphics.setFont(UI.fS)
    local y = 50

    local function entry(cc, name, desc, chips, mult)
        love.graphics.setColor(cc)
        love.graphics.circle("fill", cx+14, y+6, 3)
        love.graphics.setColor(P.text)
        love.graphics.print(name, cx+22, y)
        love.graphics.setColor(P.dim[1],P.dim[2],P.dim[3],0.50)
        love.graphics.print(desc, cx+22, y+14)
        love.graphics.setColor(P.chip[1],P.chip[2],P.chip[3],0.80)
        UI.rr("fill",cx+cw-76,y+1,32,14,3)
        love.graphics.setColor(1,1,1)
        love.graphics.print(tostring(chips),cx+cw-72,y+1)
        love.graphics.setColor(P.mult[1],P.mult[2],P.mult[3],0.80)
        UI.rr("fill",cx+cw-40,y+1,32,14,3)
        love.graphics.setColor(1,1,1)
        love.graphics.print("x"..tostring(mult),cx+cw-39,y+1)
        y = y + 32
    end

    love.graphics.setColor(P.cMono); love.graphics.print("MONO (모노)",cx+10,y); y=y+16
    entry(P.cMono,"미니 모노","같은색 3",30,3)
    entry(P.cMono,"하프 모노","같은색 4",60,5)
    entry(P.cMono,"타워","같은색 5+",150,12)
    y=y+6
    love.graphics.setColor(P.cMirr); love.graphics.print("MIRROR (미러)",cx+10,y); y=y+16
    entry(P.cMirr,"하프 미러","5~6개 대칭",100,8)
    entry(P.cMirr,"그랜드 미러","7개 대칭",400,40)
    y=y+6
    love.graphics.setColor(P.cStep); love.graphics.print("STEP (스텝)",cx+10,y); y=y+16
    entry(P.cStep,"하프 스텝","1-2-3 구조",120,10)
    entry(P.cStep,"퍼펙트 래더","1-2-3-1 구조",300,25)
    y=y+12
    love.graphics.setColor(P.dim[1],P.dim[2],P.dim[3],0.2)
    love.graphics.line(cx+10,y,cx+cw-10,y); y=y+8
    love.graphics.setColor(P.dim[1],P.dim[2],P.dim[3],0.5)
    love.graphics.print("총 칩 x 총 배수",cx+10,y)
end

function S.jokers()
    if G.phase == "title" then return end
    UI.panel(C.JX, C.JY, C.JW, C.JH, 10)
    UI.txt("조커 (" .. #G.jokers .. "/3)", C.JX+10, 26, P.gold, UI.fM)
    
    love.graphics.setFont(UI.fS)
    local y = 50
    
    if #G.jokers == 0 then
        love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.35)
        love.graphics.print("보유한 조커 없음", C.JX + 20, y + 20)
        return
    end
    
    for _, j in ipairs(G.jokers) do
        local cx, cy = C.JX + 10, y + 10
        local cw, ch = C.JW - 20, 84
        
        love.graphics.setColor(0, 0, 0, 0.04)
        UI.rr("fill", cx, cy + 2, cw, ch, 6)
        
        love.graphics.setColor(1, 1, 1)
        UI.rr("fill", cx, cy, cw, ch, 6)
        
        love.graphics.setColor(P.cMirr)
        love.graphics.setLineWidth(1.2)
        UI.rr("line", cx, cy, cw, ch, 6)
        
        UI.txt(j.name, cx + 8, cy + 6, P.text, UI.fM)
        
        love.graphics.setFont(UI.fS)
        love.graphics.setColor(P.dim)
        
        local lineY = cy + 28
        for line in string.gmatch(j.desc, "[^\n]+") do
            love.graphics.print(line, cx + 8, lineY)
            lineY = lineY + 14
        end
        
        y = y + ch + 12
    end
end

function S.scoring()
    local s = G.sc
    if not s.active then return end

    love.graphics.setColor(0.95,0.96,0.98,0.85)
    love.graphics.rectangle("fill",0,0,C.SW,C.SH)

    if s.phase == "nohand" then
        local a = math.min(1, s.timer*2)
        UI.txtC("조합 없음...", C.HCX, C.SH/2-20, {P.dim[1],P.dim[2],P.dim[3],a}, UI.fXX)
        UI.txtC("0 점", C.HCX, C.SH/2+30, {P.dim[1],P.dim[2],P.dim[3],a*.5}, UI.fM)
        return
    end

    local lw, lh = 320, 38
    local startY = 155
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
        love.graphics.print(h.cat,10,3)
        love.graphics.setFont(UI.fM)
        love.graphics.setColor(P.text[1],P.text[2],P.text[3],age)
        love.graphics.print(h.name,10,17)
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
        local ty = C.SH - 170
        UI.chipB(C.HCX-35, ty, math.floor(s.dChips))
        love.graphics.setFont(UI.fL); love.graphics.setColor(P.text)
        love.graphics.print("x", C.HCX-4, ty-12)
        UI.multB(C.HCX+35, ty, math.floor(s.dMult))
    end

    if s.phase == "total" then
        local a = math.min(1, s.timer/0.35)
        local sc = UI.easeElastic(a)
        local sy = C.SH - 100
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
            local bk = 0.3 + math.sin(love.timer.getTime()*3)*0.2
            UI.txtC("클릭하여 계속", C.HCX, sy+48, {P.dim[1],P.dim[2],P.dim[3],bk}, UI.fS)
        end
    end
end

function S.result()
    if G.phase ~= "result" then return end
    love.graphics.setColor(0.95,0.96,0.98,0.80)
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

    UI.txtC("라운드 클리어", px+pw/2, py+14, P.gold, UI.fL)
    love.graphics.setColor(P.panelBd)
    love.graphics.line(px+20,py+42,px+pw-20,py+42)

    local y = py+52
    if #G.detected == 0 then
        UI.txtC("조합 없음", px+pw/2, y+10, P.dim, UI.fL)
    else
        for _,h in ipairs(G.detected) do
            local cc = UI.catCol(h.cat)
            love.graphics.setColor(cc); love.graphics.circle("fill",px+20,y+7,3)
            love.graphics.setFont(UI.fS); love.graphics.setColor(cc[1],cc[2],cc[3],0.55)
            love.graphics.print(h.cat,px+30,y)
            love.graphics.setFont(UI.fM); love.graphics.setColor(P.text)
            love.graphics.print(h.name,px+95,y-1)
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
    
    love.graphics.setColor(0.96, 0.97, 0.99)
    UI.rr("fill", gx, gy, gw, gh, 6)
    love.graphics.setColor(P.panelBd)
    UI.rr("line", gx, gy, gw, gh, 6)
    
    love.graphics.setFont(UI.fS)
    love.graphics.setColor(P.dim)
    love.graphics.print("골드 획득 내역:", gx + 10, gy + 8)
    
    local gtxt = string.format("기본 +$3  버리기 +$%d  이자 +$%d  조커 +$%d", discGold, interestGold, jokerGold)
    love.graphics.setColor(P.text)
    love.graphics.print(gtxt, gx + 10, gy + 26)
    
    love.graphics.setFont(UI.fM)
    love.graphics.setColor(P.gold)
    local totTxt = "총 획득: +$" .. totalGold
    love.graphics.print(totTxt, gx + gw - UI.fM:getWidth(totTxt) - 10, gy + 45)

    love.graphics.setFont(UI.fXX)
    local st=tostring(G.rndScore)
    love.graphics.setColor(0,0,0,0.06)
    love.graphics.print(st,px+(pw-UI.fXX:getWidth(st))/2+1,py+ph-90+1)
    love.graphics.setColor(P.gold)
    love.graphics.print(st,px+(pw-UI.fXX:getWidth(st))/2,py+ph-90)
    UI.txtC("점", px+pw/2, py+ph-48, {P.dim[1],P.dim[2],P.dim[3],0.5}, UI.fS)

    local bk=0.3+math.sin(love.timer.getTime()*3)*0.2
    UI.txtC("클릭하여 계속", px+pw/2, py+ph-28, {P.gold[1],P.gold[2],P.gold[3],bk}, UI.fS)
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
    UI.txtC("도달한 라운드: " .. tostring(G.ante) .. "-" .. tostring(G.stage), px+pw/2, y, P.text, UI.fL)
    UI.txtC("최종 점수: " .. tostring(math.floor(G.score)), px+pw/2, y+38, P.gold, UI.fX)

    local bw, bh = 180, 44
    local bx = px + (pw-bw)/2
    local by = py + ph - 80
    
    local mx,my = love.mouse.getPosition()
    local hovBtn = mx>=bx and mx<=bx+bw and my>=by and my<=by+bh
    
    love.graphics.setColor(hovBtn and P.cMono or P.dim)
    UI.rr("fill",bx,by,bw,bh,8)
    
    love.graphics.setFont(UI.fM)
    love.graphics.setColor(1,1,1)
    local btnT = "다시 하기"
    love.graphics.print(btnT, bx+(bw-UI.fM:getWidth(btnT))/2, by+bh/2-UI.fM:getHeight()/2)
    
    UI.txtC("또는 [R]키를 눌러 재시작", px+pw/2, by+bh+12, P.dim, UI.fS)
end

function S.shop()
    if G.phase ~= "shop" then return end
    
    love.graphics.setColor(0.08, 0.08, 0.12, 0.75)
    love.graphics.rectangle("fill", 0, 0, C.SW, C.SH)
    
    local px, py = C.HCX - 300, 80
    local pw, ph = 600, 520
    
    UI.panel(px, py, pw, ph, 14)
    
    UI.txtC("상점", px + pw/2, py + 20, P.gold, UI.fXX)
    
    love.graphics.setFont(UI.fL)
    love.graphics.setColor(P.gold)
    local gtxt = "내 골드: $" .. G.gold
    love.graphics.print(gtxt, px + 30, py + 30)
    
    love.graphics.setColor(P.panelBd)
    love.graphics.line(px + 20, py + 72, px + pw - 20, py + 72)
    
    local startX = px + 30
    local itemW = 160
    local itemH = 260
    local gap = 30
    local mx, my = love.mouse.getPosition()
    
    for i = 1, 3 do
        local item = G.shopItems[i]
        if item then
            local ix = startX + (i-1) * (itemW + gap)
            local iy = py + 110
            
            love.graphics.setColor(0, 0, 0, 0.05)
            UI.rr("fill", ix, iy + 3, itemW, itemH, 8)
            love.graphics.setColor(1, 1, 1)
            UI.rr("fill", ix, iy, itemW, itemH, 8)
            
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
            love.graphics.setColor(bc)
            love.graphics.setLineWidth(1.5)
            UI.rr("line", ix, iy, itemW, itemH, 8)
            
            if item.sold then
                love.graphics.setFont(UI.fL)
                love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.3)
                UI.txtC("품절", ix + itemW/2, iy + itemH/2 - 10, P.dim, UI.fL)
            else
                UI.txtC(item.name, ix + itemW/2, iy + 14, P.text, UI.fM)
                
                love.graphics.setFont(UI.fS)
                local typeTxt = string.upper(item.type)
                if typeTxt == "DECK_ADD" or typeTxt == "DECK_REMOVE" then typeTxt = "덱 추가/제거"
                elseif typeTxt == "JOKER" then typeTxt = "조커"
                elseif typeTxt == "UPGRADE" then typeTxt = "업그레이드" end
                
                UI.txtC(typeTxt, ix + itemW/2, iy + 34, bc, UI.fS)
                
                local descY = iy + 65
                for line in string.gmatch(item.desc, "[^\n]+") do
                    UI.txtC(line, ix + itemW/2, descY, P.dim, UI.fS)
                    descY = descY + 18
                end
                
                local bx = ix + 15
                local by = iy + itemH - 50
                local bw = itemW - 30
                local bh = 34
                
                local hovBuy = mx >= bx and mx <= bx+bw and my >= by and my <= by+bh
                local canAfford = G.gold >= item.price
                
                if canAfford then
                    love.graphics.setColor(hovBuy and P.btnRH or P.btnR)
                else
                    love.graphics.setColor(P.btnG)
                end
                UI.rr("fill", bx, by, bw, bh, 6)
                
                love.graphics.setFont(UI.fM)
                love.graphics.setColor(canAfford and P.white or {0.52,0.52,0.55})
                local btnTxt = "$" .. item.price
                love.graphics.print(btnTxt, bx + (bw - UI.fM:getWidth(btnTxt))/2, by + bh/2 - UI.fM:getHeight()/2)
            end
        end
    end
    
    local nW, nH = 180, 44
    local nX = px + (pw - nW)/2
    local nY = py + ph - 80
    
    local hovNext = mx >= nX and mx <= nX+nW and my >= nY and my <= nY+nH
    
    love.graphics.setColor(0, 0, 0, 0.15)
    UI.rr("fill", nX, nY + 2, nW, nH, 8)
    
    love.graphics.setColor(hovNext and P.btnRH or P.btnR)
    UI.rr("fill", nX, nY, nW, nH, 8)
    
    love.graphics.setFont(UI.fL)
    love.graphics.setColor(1, 1, 1)
    local nextTxt = "다음 라운드"
    love.graphics.print(nextTxt, nX + (nW - UI.fL:getWidth(nextTxt))/2, nY + nH/2 - UI.fL:getHeight()/2)
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
    local title = "앤티 " .. G.ante .. " - " .. (G.stage == 1 and "스몰 블라인드" or G.stage == 2 and "빅 블라인드" or "보스 블라인드")
    love.graphics.print(title, (C.SW - UI.fXX:getWidth(title))/2, C.SH/2 - 60)
    
    love.graphics.setFont(UI.fL)
    love.graphics.setColor(1, 1, 1, alpha)
    local subText = ""
    if G.stage == 3 then
        local desc = ""
        if G.bossGimmick == "no_red" then desc = "빨간색 카드 점수 무효"
        elseif G.bossGimmick == "no_black" then desc = "검은색 카드 점수 무효"
        elseif G.bossGimmick == "no_discard" then desc = "버리기 사용 불가"
        elseif G.bossGimmick == "high_target" then desc = "목표 점수 1.5배 증가"
        end
        subText = "보스 기믹: " .. desc
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
