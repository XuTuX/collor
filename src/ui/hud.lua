------------------------------------------------------------
-- hud.lua · 상단 정보판, 족보표, 주머니 오버레이 렌더링 HUD 모듈
------------------------------------------------------------
local HUD = {}
local C = require("core.constants")
local P = C.P
local Panel = require("ui.panel")
local Button = require("ui.button")
local Modifier = require("entities/modifier")

-- 폰트 객체 선언 (의존성 단일화)
HUD.fS, HUD.fM, HUD.fL, HUD.fX, HUD.fXX = nil, nil, nil, nil, nil

-- 폰트 초기화 (ui.lua 로직 완벽 보존)
function HUD.initFonts()
    local fontPath = "assets/fonts/NanumGothic.ttf"
    local fontBoldPath = "assets/fonts/NanumGothic-Bold.ttf"
    
    local success, _ = pcall(function()
        HUD.fS  = love.graphics.newFont(fontPath, 13)
        HUD.fM  = love.graphics.newFont(fontBoldPath, 16)
        HUD.fL  = love.graphics.newFont(fontBoldPath, 22)
        HUD.fX  = love.graphics.newFont(fontBoldPath, 28)
        HUD.fXX = love.graphics.newFont(fontBoldPath, 44)
    end)
    
    if not success then
        HUD.fS  = love.graphics.newFont(13)
        HUD.fM  = love.graphics.newFont(16)
        HUD.fL  = love.graphics.newFont(22)
        HUD.fX  = love.graphics.newFont(28)
        HUD.fXX = love.graphics.newFont(44)
        print("Warning: Failed to load custom Korean font. Using default font.")
    end
end

-- 관문 이름 헬퍼
local function getGateName(stage)
    if stage == 1 then return "쉬운 관문" end
    if stage == 2 then return "도전 관문" end
    return "특별 관문"
end

-- 색 이름 한글 헬퍼
function HUD.getColorKoreanName(name)
    if name == "Red" then return "빨강" end
    if name == "Orange" then return "주황" end
    if name == "Yellow" then return "노랑" end
    if name == "White" then return "하양" end
    if name == "Black" then return "검정" end
    return name
end

-- 리스트 내 고유 색친구 빈도수 합산
local function countColors(list)
    local counts = {}
    for _, c in ipairs(C.COLORS or {}) do counts[c.name] = 0 end
    -- COLORS가 없는 경우에 대비한 동적 셋업
    counts["Red"] = 0; counts["Orange"] = 0; counts["Yellow"] = 0; counts["White"] = 0; counts["Black"] = 0;
    
    for _, item in ipairs(list or {}) do
        if item.name then 
            counts[item.name] = (counts[item.name] or 0) + 1 
        end
    end
    return counts
end

-- 상단 정보 판넬 그리기 (S.topUI 로직 완벽 보존)
function HUD.drawTopUI(G)
    local x, y, w, h = C.LX, C.LY, C.LW, 220
    Panel.draw(x, y, w, h, 12)

    Button.txt("컬러 퍼즐 7", x + 18, y + 14, P.text, HUD.fL)
    
    -- 재시작 버튼 감지
    local mx, my = love.mouse.getPosition()
    local btnW, btnH = 56, 24
    local bx, by = x + w - 74, y + 14
    local hovReset = mx >= bx and mx <= bx + btnW and my >= by and my <= by + btnH
    Button.draw(bx, by, btnW, btnH, "재시작", true, hovReset, HUD.fS)
    
    Button.pill(x + 18, y + 48, 78, 24, "월드 " .. tostring(G.ante), P.cMirr, HUD.fS)
    Button.pill(x + 104, y + 48, 116, 24, getGateName(G.stage), P.btnR, HUD.fS)

    -- 통계 스탯 박스 헬퍼
    local function statBox(sx, sy, label, value, col)
        love.graphics.setColor(0.25, 0.32, 0.44, 0.06)
        love.graphics.rectangle("fill", sx, sy + 2, 100, 60, 8, 8)
        love.graphics.setColor(1, 1, 1, 0.86)
        love.graphics.rectangle("fill", sx, sy, 100, 60, 8, 8)
        love.graphics.setColor(P.panelBd)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", sx, sy, 100, 60, 8, 8)
        Button.txt(label, sx + 12, sy + 7, P.dim, HUD.fS)
        love.graphics.setFont(HUD.fL)
        love.graphics.setColor(col)
        love.graphics.print(value, sx + 12, sy + 26)
    end

    statBox(x + 18, y + 84, "목표", tostring(G.targetScore), P.mult)
    local scoreColor = G.roundCleared and P.cMono or P.gold
    statBox(x + 126, y + 84, "현재 점수", tostring(math.floor(G.dScore)), scoreColor)
    statBox(x + 18, y + 152, "코인", "$" .. tostring(G.gold), P.gold)
    statBox(x + 126, y + 152, "남은 실행", G.execLeft .. "/4", P.cStep)
end

-- 족보 가이드표 그리기 (S.cheatSheet 로직 완벽 보존)
function HUD.drawCheatSheet()
    local cx, cy, cw, ch = C.LX, C.LY + 240, C.LW, C.LH - 240
    Panel.draw(cx, cy, cw, ch, 10)
    Button.txt("색 규칙", cx + 14, cy + 10, P.text, HUD.fM)
    Button.txt("별 / 콤보", cx + cw - 78, cy + 13, P.dim, HUD.fS)
    love.graphics.setFont(HUD.fS)
    local y = cy + 42

    local function entry(cc, name, desc, chips, mult)
        love.graphics.setColor(cc)
        love.graphics.circle("fill", cx + 16, y + 6, 3)
        love.graphics.setColor(P.text)
        love.graphics.print(name, cx + 26, y)
        love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.50)
        love.graphics.print(desc, cx + 26, y + 14)
        Button.pill(cx + cw - 80, y + 1, 34, 15, tostring(chips), P.chip, HUD.fS)
        Button.pill(cx + cw - 42, y + 1, 34, 15, "x" .. tostring(mult), P.mult, HUD.fS)
        y = y + 32
    end

    love.graphics.setColor(P.cMono); love.graphics.print("같은색", cx + 14, y); y = y + 16
    entry(P.cMono, "세 친구", "같은색 3", 30, 3)
    entry(P.cMono, "네 친구", "같은색 4", 60, 5)
    entry(P.cMono, "색 탑", "같은색 5+", 150, 12)
    y = y + 6
    love.graphics.setColor(P.cMirr); love.graphics.print("거울", cx + 14, y); y = y + 16
    entry(P.cMirr, "작은 거울", "5~6개 대칭", 100, 8)
    entry(P.cMirr, "큰 거울", "7개 대칭", 400, 40)
    y = y + 6
    love.graphics.setColor(P.cStep); love.graphics.print("계단", cx + 14, y); y = y + 16
    entry(P.cStep, "작은 계단", "1-2-3 모양", 120, 10)
    entry(P.cStep, "무지개 계단", "1-2-3-1 모양", 300, 25)
    y = y + 12
    love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.2)
    love.graphics.line(cx + 14, y, cx + cw - 14, y); y = y + 8
    love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.5)
    love.graphics.print("최종 점수 = 별 x 콤보", cx + 14, y)
end

-- 주머니 전체보기용 조그만 카드 조각 그리기
local function drawBagPiece(x, y, w, h, colorInfo, state)
    local col = colorInfo.color
    local alpha = state == "gone" and 0.24 or 0.96
    local fill = state == "left" and P.slotHov or P.panel
    if state == "picked" then fill = {0.98, 0.84, 0.22} end
    if state == "hand" then fill = {0.94, 0.98, 1.00} end

    love.graphics.setColor(0.03, 0.05, 0.05, 0.30)
    love.graphics.rectangle("fill", x + 2, y + 3, w, h, 5, 5)
    love.graphics.setColor(fill[1], fill[2], fill[3], alpha)
    love.graphics.rectangle("fill", x, y, w, h, 5, 5)
    love.graphics.setColor(col[1], col[2], col[3], state == "gone" and 0.32 or 0.92)
    love.graphics.rectangle("fill", x + 4, y + 4, w - 8, h - 8, 4, 4)
    love.graphics.setColor(1, 1, 1, state == "gone" and 0.06 or 0.18)
    love.graphics.line(x + 7, y + h - 8, x + w - 7, y + 8)
    love.graphics.setColor(state == "picked" and P.btnR or P.panelBd)
    love.graphics.setLineWidth(state == "picked" and 2.0 or 1.0)
    love.graphics.rectangle("line", x, y, w, h, 5, 5)
end

-- 주머니 전체 오버레이 그리기 (S.bagOverlay 로직 완벽 보존)
function HUD.drawBagOverlay(G)
    if not G.showBag then return end

    -- 반투명 흐림 배경
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
    love.graphics.rectangle("line", px - 14, py - 14, pw + 28, ph + 28, 16, 16)
    Panel.draw(px, py, pw, ph, 12)

    Button.txtC("주머니 전체", C.HCX, py + 22, P.text, HUD.fX)
    love.graphics.setColor(P.btnR)
    love.graphics.polygon("fill", C.HCX - 8, py + 6, C.HCX + 8, py + 6, C.HCX, py + 22)

    local mx, my = love.mouse.getPosition()
    local closeX, closeY, closeW, closeH = C.HCX + 420, 82, 84, 32
    local hovClose = mx >= closeX and mx <= closeX + closeW and my >= closeY and my <= closeY + closeH
    Button.draw(closeX, closeY, closeW, closeH, "닫기", true, hovClose, HUD.fS)

    -- 고유 색상 데이터 조회 (constants의 COLORS가 사라졌으므로 data/characters 데이터 활용)
    local CharsList = require("data.characters")
    local totalCounts = countColors(G.deckConfig)
    local leftCounts = countColors(G.deck)
    local handCounts = countColors(G.hand)
    
    local pickedCounts = {}
    for _, c in ipairs(CharsList) do pickedCounts[c.name] = 0 end
    for _, card in ipairs(G.hand) do
        if card.sel then 
            pickedCounts[card.name] = (pickedCounts[card.name] or 0) + 1 
        end
    end

    -- 왼쪽 통계 요약판
    local sx, sy, sw, sh = px + 28, py + 84, 230, 390
    love.graphics.setColor(0.02, 0.04, 0.04, 0.72)
    love.graphics.rectangle("fill", sx, sy, sw, sh, 8, 8)
    love.graphics.setColor(P.slotHBd)
    love.graphics.setLineWidth(1.2)
    love.graphics.rectangle("line", sx, sy, sw, sh, 8, 8)

    Button.txtC("색친구 수", sx + sw / 2, sy + 16, P.white, HUD.fL)
    love.graphics.setFont(HUD.fS)
    love.graphics.setColor(0.85, 0.96, 0.92, 0.76)
    love.graphics.print("전체", sx + 88, sy + 54)
    love.graphics.print("남음", sx + 132, sy + 54)
    love.graphics.print("손", sx + 176, sy + 54)

    local rowY = sy + 78
    for _, colorInfo in ipairs(CharsList) do
        local c = colorInfo.color
        love.graphics.setColor(c)
        love.graphics.circle("fill", sx + 28, rowY + 8, 8)
        love.graphics.setColor(P.white)
        love.graphics.setFont(HUD.fM)
        love.graphics.print(HUD.getColorKoreanName(colorInfo.name), sx + 44, rowY - 1)
        love.graphics.setFont(HUD.fM)
        love.graphics.setColor(0.95, 0.98, 1.0)
        love.graphics.print(tostring(totalCounts[colorInfo.name] or 0), sx + 92, rowY - 1)
        love.graphics.setColor(P.gold)
        love.graphics.print(tostring(leftCounts[colorInfo.name] or 0), sx + 138, rowY - 1)
        love.graphics.setColor(P.cStep)
        love.graphics.print(tostring(handCounts[colorInfo.name] or 0), sx + 182, rowY - 1)
        rowY = rowY + 42
    end

    local legendY = sy + sh - 84
    local function legend(lx, label, col)
        love.graphics.setColor(col)
        love.graphics.rectangle("fill", lx, legendY, 18, 12, 3, 3)
        Button.txt(label, lx + 24, legendY - 2, P.white, HUD.fS)
    end
    legend(sx + 18, "남은", P.slotHov)
    legend(sx + 92, "손", {0.94, 0.98, 1.00})
    legend(sx + 154, "고른", {0.98, 0.84, 0.22})

    -- 오른쪽 그리드 뷰
    local gx, gy = px + 285, py + 104
    local cellW, cellH = 35, 48
    local gapX, gapY = 5, 12
    local perRow = 16

    for row, colorInfo in ipairs(CharsList) do
        local y = gy + (row - 1) * (cellH + gapY)
        Button.txt(HUD.getColorKoreanName(colorInfo.name), gx - 58, y + 15, P.white, HUD.fM)
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
    Button.draw(backX, backY, backW, backH, "뒤로", true, hovBack, HUD.fL)
    Button.txtC("[B] 주머니 보기 / 닫기", C.HCX, backY - 28, {0.85, 0.96, 0.92, 0.72}, HUD.fS)
end

return HUD
