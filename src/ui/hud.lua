------------------------------------------------------------
-- hud.lua · 상단 정보판, 족보표, 주머니 오버레이 렌더링 HUD 모듈
------------------------------------------------------------
local HUD = {}
local C = require("core.constants")
local P = C.P
local Panel = require("ui.panel")
local Button = require("ui.button")
local Modifier = require("entities/modifier")
local PData = require("data.patterns")

-- 폰트 객체 선언 (의존성 단일화)
HUD.fS, HUD.fM, HUD.fL, HUD.fX, HUD.fXX = nil, nil, nil, nil, nil

-- 폰트 초기화
function HUD.initFonts()
    local fontPath = "assets/fonts/NanumGothic.ttf"
    local fontBoldPath = "assets/fonts/NanumGothic-Bold.ttf"
    
    local success, _ = pcall(function()
        HUD.fS  = love.graphics.newFont(fontPath, 13)
        HUD.fM  = love.graphics.newFont(fontBoldPath, 16)
        HUD.fL  = love.graphics.newFont(fontBoldPath, 20)
        HUD.fX  = love.graphics.newFont(fontBoldPath, 26)
        HUD.fXX = love.graphics.newFont(fontBoldPath, 36)
    end)
    
    if not success then
        HUD.fS  = love.graphics.newFont(13)
        HUD.fM  = love.graphics.newFont(16)
        HUD.fL  = love.graphics.newFont(20)
        HUD.fX  = love.graphics.newFont(26)
        HUD.fXX = love.graphics.newFont(36)
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
    counts["Red"] = 0; counts["Orange"] = 0; counts["Yellow"] = 0; counts["White"] = 0; counts["Black"] = 0;
    
    for _, item in ipairs(list or {}) do
        if item.name then 
            counts[item.name] = (counts[item.name] or 0) + 1 
        end
    end
    return counts
end

-- 좌측 통합 정보 패널 그리기
function HUD.drawTopUI(G)
    local x, y, w, h = C.LX, C.LY, C.LW, C.LH
    Panel.draw(x, y, w, h, 14)

    -- 타이틀 및 재시작 버튼
    Button.txt("컬러 퍼즐 7", x + 20, y + 22, P.text, HUD.fL)
    
    local mx, my = love.mouse.getPosition()
    local btnW, btnH = 58, 26
    local bx, by = x + w - 78, y + 20
    local hovReset = mx >= bx and mx <= bx + btnW and my >= by and my <= by + btnH
    Button.draw(bx, by, btnW, btnH, "재시작", true, hovReset, HUD.fS)
    
    -- 스테이지 정보 배지
    local stageY = y + 62
    Button.pill(x + 20, stageY, 76, 24, "월드 " .. tostring(G.ante), P.cMirr, HUD.fS)
    Button.pill(x + 102, stageY, 100, 24, getGateName(G.stage), P.btnR, HUD.fS)

    -- 보스 기믹 텍스트 표시
    if G.stage == 3 and G.bossGimmick ~= "none" then
        love.graphics.setFont(HUD.fS)
        love.graphics.setColor(P.mult)
        local bossDesc = Modifier.getBossGimmickDesc(G.bossGimmick)
        love.graphics.printf("규칙: " .. bossDesc, x + 20, stageY + 34, w - 40, "left")
    end

    -- 목표 점수 & 현재 점수 대형 모던 보드
    local scoreBoxY = stageY + 68
    local boxW = w - 40
    
    -- 목표 점수 라벨
    love.graphics.setFont(HUD.fS)
    love.graphics.setColor(P.dim)
    love.graphics.print("목표 점수", x + 20, scoreBoxY)
    love.graphics.setFont(HUD.fX)
    love.graphics.setColor(P.text)
    love.graphics.print(tostring(G.targetScore), x + 20, scoreBoxY + 18)

    -- 현재 점수 라벨
    local curScoreY = scoreBoxY + 54
    love.graphics.setFont(HUD.fS)
    love.graphics.setColor(P.dim)
    love.graphics.print("현재 점수", x + 20, curScoreY)
    
    love.graphics.setFont(HUD.fX)
    local scoreColor = G.roundCleared and P.cMono or P.gold
    love.graphics.setColor(scoreColor)
    
    local sScale = G.scoreScale or 1.0
    if sScale ~= 1.0 then
        love.graphics.push()
        local st = tostring(math.floor(G.dScore))
        local tw = HUD.fX:getWidth(st)
        local th = HUD.fX:getHeight()
        local tx = x + 20 + tw / 2
        local ty = curScoreY + 18 + th / 2
        love.graphics.translate(tx, ty)
        love.graphics.scale(sScale, sScale)
        love.graphics.translate(-tx, -ty)
        love.graphics.print(st, x + 20, curScoreY + 18)
        love.graphics.pop()
    else
        love.graphics.print(tostring(math.floor(G.dScore)), x + 20, curScoreY + 18)
    end

    -- ───────────────────────────────────────────
    -- Balatro 스타일 체인(별) x 콤보(배수) 대형 대시보드
    -- ───────────────────────────────────────────
    local balatroY = curScoreY + 70
    
    -- 구분선
    love.graphics.setColor(P.panelBd[1], P.panelBd[2], P.panelBd[3], 0.4)
    love.graphics.setLineWidth(1)
    love.graphics.line(x + 20, balatroY, x + w - 20, balatroY)
    
    local dashY = balatroY + 20
    local dashH = 70
    
    -- 득점 연출 스케일 값 로드
    local ScoreSys = require("systems.score_system")
    local scState = ScoreSys.getState()
    local chipVal = math.floor(scState.dChips)
    local multVal = math.floor(scState.dMult)
    
    local cScale = G.chipScale or 1.0
    local mScale = G.multScale or 1.0
    
    -- 파란색 칩(체인) 박스
    local boxSizeW = 100
    local chipBoxX = x + 20
    love.graphics.push()
    love.graphics.translate(chipBoxX + boxSizeW/2, dashY + dashH/2)
    love.graphics.scale(cScale, cScale)
    love.graphics.translate(-(chipBoxX + boxSizeW/2), -(dashY + dashH/2))
    
    -- 하드 섀도우
    love.graphics.setColor(0.102, 0.102, 0.102, 1.0)
    love.graphics.rectangle("fill", chipBoxX + 3, dashY + 3, boxSizeW, dashH, 16, 16)
    
    -- 메인 색상
    love.graphics.setColor(P.chip)
    love.graphics.rectangle("fill", chipBoxX, dashY, boxSizeW, dashH, 16, 16)
    
    -- 굵은 테두리
    love.graphics.setColor(0.102, 0.102, 0.102, 1.0)
    love.graphics.setLineWidth(2.0)
    love.graphics.rectangle("line", chipBoxX, dashY, boxSizeW, dashH, 16, 16)
    
    love.graphics.setFont(HUD.fS)
    Button.txtC("체인 (별)", chipBoxX + boxSizeW/2, dashY + 8, P.white)
    love.graphics.setFont(HUD.fL)
    Button.txtC(tostring(chipVal), chipBoxX + boxSizeW/2, dashY + 32, P.white)
    love.graphics.pop()

    -- 중앙 곱하기 'X' 문자
    love.graphics.setFont(HUD.fX)
    love.graphics.setColor(P.dim)
    local xText = "X"
    love.graphics.print(xText, x + 132, dashY + dashH/2 - HUD.fX:getHeight()/2)

    -- 빨간색 배수(콤보) 박스
    local multBoxX = x + 160
    love.graphics.push()
    love.graphics.translate(multBoxX + boxSizeW/2, dashY + dashH/2)
    love.graphics.scale(mScale, mScale)
    love.graphics.translate(-(multBoxX + boxSizeW/2), -(dashY + dashH/2))
    
    -- 하드 섀도우
    love.graphics.setColor(0.102, 0.102, 0.102, 1.0)
    love.graphics.rectangle("fill", multBoxX + 3, dashY + 3, boxSizeW, dashH, 16, 16)
    
    -- 메인 색상
    love.graphics.setColor(P.mult)
    love.graphics.rectangle("fill", multBoxX, dashY, boxSizeW, dashH, 16, 16)
    
    -- 굵은 테두리
    love.graphics.setColor(0.102, 0.102, 0.102, 1.0)
    love.graphics.setLineWidth(2.0)
    love.graphics.rectangle("line", multBoxX, dashY, boxSizeW, dashH, 16, 16)
    
    love.graphics.setFont(HUD.fS)
    Button.txtC("콤보 (배수)", multBoxX + boxSizeW/2, dashY + 8, P.white)
    love.graphics.setFont(HUD.fL)
    local mText = "x" .. tostring(multVal)
    Button.txtC(mText, multBoxX + boxSizeW/2, dashY + 32, P.white)
    love.graphics.pop()

    -- ───────────────────────────────────────────
    -- 남은 기회 및 코인 통계 (좌측 패널 하단 배치)
    -- ───────────────────────────────────────────
    local statY = dashY + dashH + 34
    love.graphics.setColor(P.panelBd[1], P.panelBd[2], P.panelBd[3], 0.4)
    love.graphics.line(x + 20, statY - 14, x + w - 20, statY - 14)

    local function leftStatRow(label, val, col, sy)
        love.graphics.setFont(HUD.fS)
        love.graphics.setColor(P.dim)
        love.graphics.print(label, x + 20, sy)
        
        love.graphics.setFont(HUD.fL)
        love.graphics.setColor(col)
        local valStr = tostring(val)
        love.graphics.print(valStr, x + w - 20 - HUD.fL:getWidth(valStr), sy - 2)
    end

    leftStatRow("남은 실행", G.execLeft .. " / 4", P.cStep, statY)
    leftStatRow("남은 바꾸기", G.discLeft .. " / " .. C.MAXDISC, P.gold, statY + 32)
    leftStatRow("보유 코인", "$" .. tostring(G.gold), P.success, statY + 64)
end

-- 우측 패널 안의 색 규칙 가이드 테이블 그리기
function HUD.drawCheatSheet(G)
    local cx, cy, cw, ch = C.RX, C.RY + 200, C.RW, C.RH - 200
    Panel.draw(cx, cy, cw, ch, 12)
    Button.txt("색 규칙", cx + 18, cy + 14, P.text, HUD.fM)
    
    -- Title underline
    love.graphics.setColor(P.panelBd[1], P.panelBd[2], P.panelBd[3], 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.line(cx + 18, cy + 34, cx + cw - 18, cy + 34)
    
    local y = cy + 42

    local function entry(cc, name, desc, statsKey)
        local stats = (G and G.handStats) and G.handStats[statsKey] or PData.handStatsTemplate[statsKey]
        local chips = stats.chips
        local mult = stats.mult
        
        -- Colored bullet
        love.graphics.setColor(cc[1], cc[2], cc[3], 0.8)
        love.graphics.circle("fill", cx + 22, y + 8, 3.5)
        
        -- Name
        love.graphics.setFont(HUD.fS)
        love.graphics.setColor(P.text)
        love.graphics.print(name, cx + 32, y)
        
        -- Dim description
        love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.5)
        local nw = HUD.fS:getWidth(name)
        love.graphics.print(desc, cx + 32 + nw + 6, y)
        
        -- Right-aligned pills
        local pw, ph = 32, 16
        local mx = cx + cw - 18 - pw
        local cpx = mx - pw - 4
        Button.pill(cpx, y + 1, pw, ph, tostring(chips), P.chip, HUD.fS)
        Button.pill(mx, y + 1, pw, ph, "x" .. tostring(mult), P.mult, HUD.fS)
        
        y = y + 30
    end

    local function sectionHeader(cc, title)
        if y > cy + 45 then
            y = y + 4
            love.graphics.setColor(P.panelBd[1], P.panelBd[2], P.panelBd[3], 0.15)
            love.graphics.setLineWidth(1)
            love.graphics.line(cx + 18, y, cx + cw - 18, y)
            y = y + 6
        end
        
        love.graphics.setColor(cc)
        love.graphics.setFont(HUD.fS)
        love.graphics.print(title, cx + 18, y)
        y = y + 18
    end

    sectionHeader(P.cMono, "모노")
    entry(P.cMono, "모노", "동일 색상 3장 이상", "Mono")
    
    sectionHeader(P.cMirr, "대칭")
    entry(P.cMirr, "대칭", "좌우 대칭 3장 이상", "Mirror")
    
    sectionHeader(P.cTwins, "쌍둥이")
    entry(P.cTwins, "쌍둥이", "인접한 색상 1쌍 이상", "Twins")
    
    sectionHeader(P.cStep, "크레센도")
    entry(P.cStep, "크레센도", "색상 순서 정렬 3장 이상", "Crescendo")
    
    sectionHeader(P.cZigzag, "지그재그")
    entry(P.cZigzag, "지그재그", "두 색상 교대 3장 이상", "Zigzag")
    
    -- 동적 배율 팁 추가
    y = y + 10
    love.graphics.setFont(HUD.fS)
    love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], 0.85)
    love.graphics.printf("※ 규칙 기여 카드가 많을수록\n   득점 배율이 더욱 상승합니다!", cx + 18, y, cw - 36, "left")
    
    -- Bottom formula
    love.graphics.setColor(P.panelBd[1], P.panelBd[2], P.panelBd[3], 0.2)
    love.graphics.line(cx + 18, cy + ch - 30, cx + cw - 18, cy + ch - 30)
    
    love.graphics.setFont(HUD.fS)
    love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.7)
    love.graphics.print("최종 점수 = 체인 x 콤보", cx + 18, cy + ch - 23)
end

local function drawBagPiece(x, y, w, h, colorInfo, state, edition)
    local col = colorInfo.color
    local isGone = state == "gone"
    local isPicked = state == "picked"
    local isHand = state == "hand"
    
    local cx, cy = x + w/2, y + h/2
    local rad = math.min(w, h)/2 - 2
    
    if not isGone then
        -- Edition Aura
        if edition == "foil" then
            love.graphics.setColor(P.cMirr[1], P.cMirr[2], P.cMirr[3], 0.7)
            love.graphics.circle("fill", cx, cy, rad + 3)
            love.graphics.setColor(P.cMirr)
            love.graphics.circle("line", cx, cy, rad + 3)
        elseif edition == "holo" then
            love.graphics.setColor(P.mult[1], P.mult[2], P.mult[3], 0.7)
            love.graphics.circle("fill", cx, cy, rad + 3)
            love.graphics.setColor(P.mult)
            love.graphics.circle("line", cx, cy, rad + 3)
        elseif edition == "gold" then
            love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], 0.7)
            love.graphics.circle("fill", cx, cy, rad + 3)
            love.graphics.setColor(P.gold)
            love.graphics.circle("line", cx, cy, rad + 3)
        end
        
        -- State Highlights
        if isPicked then
            love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], 0.9)
            love.graphics.setLineWidth(2.5)
            love.graphics.circle("line", cx, cy, rad + 4)
        elseif isHand then
            love.graphics.setColor(0.357, 0.486, 0.980, 0.6)
            love.graphics.setLineWidth(1.5)
            love.graphics.circle("line", cx, cy, rad + 3)
        end
        
        -- Character Body
        love.graphics.setColor(col)
        love.graphics.circle("fill", cx, cy, rad)
        if colorInfo.name == "White" then
            love.graphics.setColor(0.7, 0.75, 0.85, 0.5)
        else
            love.graphics.setColor(col[1]*0.5, col[2]*0.5, col[3]*0.5, 0.8)
        end
        love.graphics.setLineWidth(1.5)
        love.graphics.circle("line", cx, cy, rad)
        
        -- Character Eyes
        local eyeW, eyeH = rad*0.2, rad*0.25
        if colorInfo.name == "Black" then
            love.graphics.setColor(0.95, 0.95, 0.98)
        else
            love.graphics.setColor(0.12, 0.16, 0.22)
        end
        love.graphics.ellipse("fill", cx - rad*0.35, cy - rad*0.1, eyeW, eyeH)
        love.graphics.ellipse("fill", cx + rad*0.35, cy - rad*0.1, eyeW, eyeH)
        
        -- Eye Highlights
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.circle("fill", cx - rad*0.35 - 0.5, cy - rad*0.1 - 1.2, eyeW*0.4)
        love.graphics.circle("fill", cx + rad*0.35 - 0.5, cy - rad*0.1 - 1.2, eyeW*0.4)
    else
        -- Gone / Discarded State
        local mult = 0.65
        if colorInfo.name == "Black" then
            mult = 0.85
        elseif colorInfo.name == "White" then
            mult = 0.45
        end
        love.graphics.setColor(col[1]*mult, col[2]*mult, col[3]*mult, 0.25)
        love.graphics.circle("fill", cx, cy, rad)
        
        love.graphics.setColor(0, 0, 0, 0.08)
        love.graphics.setLineWidth(1)
        love.graphics.circle("line", cx, cy, rad)
    end
end

-- 주머니 전체 오버레이 그리기 (밝은 테마 스타일)
function HUD.drawBagOverlay(G)
    if not G.showBag then return end

    -- 불투명 단색 배경 (네오 브루탈리즘 스타일)
    love.graphics.setColor(P.bg[1], P.bg[2], P.bg[3], 0.95)
    love.graphics.rectangle("fill", 0, 0, C.SW, C.SH)

    local px, py, pw, ph = C.HCX - 560, 70, 1120, 590
    Panel.draw(px, py, pw, ph, 14)

    Button.txtC("주머니 전체", C.HCX, py + 22, P.text, HUD.fX)

    local mx, my = love.mouse.getPosition()
    local closeX, closeY, closeW, closeH = px + pw - 28 - 84, py + 20, 84, 32
    local hovClose = mx >= closeX and mx <= closeX + closeW and my >= closeY and my <= closeY + closeH
    Button.draw(closeX, closeY, closeW, closeH, "닫기", true, hovClose, HUD.fS)

    -- 고유 색상 데이터 조회
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
    local sx, sy, sw, sh = px + 28, py + 70, 240, 420
    love.graphics.setColor(P.bg[1], P.bg[2], P.bg[3], 0.4)
    love.graphics.rectangle("fill", sx, sy, sw, sh, 8, 8)
    love.graphics.setColor(P.panelBd)
    love.graphics.setLineWidth(1.2)
    love.graphics.rectangle("line", sx, sy, sw, sh, 8, 8)

    Button.txtC("색친구 수", sx + sw / 2, sy + 14, P.text, HUD.fL)
    love.graphics.setFont(HUD.fS)
    love.graphics.setColor(P.dim)
    
    local col1X = sx + 110
    local col2X = sx + 154
    local col3X = sx + 198
    
    love.graphics.print("전체", col1X - HUD.fS:getWidth("전체")/2, sy + 42)
    love.graphics.print("남음", col2X - HUD.fS:getWidth("남음")/2, sy + 42)
    love.graphics.print("손", col3X - HUD.fS:getWidth("손")/2, sy + 42)

    local gy = py + 130
    local gx = px + 350
    local cellW, cellH = 35, 48
    local gapX, gapY = 5, 12
    local perRow = 18

    for row, colorInfo in ipairs(CharsList) do
        local y = gy + (row - 1) * (cellH + gapY)
        
        -- 왼쪽 요약판 행 배경
        love.graphics.setColor(P.bg[1], P.bg[2], P.bg[3], 0.6)
        love.graphics.rectangle("fill", sx + 10, y - 2, sw - 20, 52, 6, 6)
        
        local c = colorInfo.color
        love.graphics.setColor(c)
        love.graphics.circle("fill", sx + 28, y + 24, 8)
        
        love.graphics.setColor(P.text)
        love.graphics.setFont(HUD.fM)
        love.graphics.print(HUD.getColorKoreanName(colorInfo.name), sx + 44, y + 16)
        
        love.graphics.setColor(P.dim)
        local totStr = tostring(totalCounts[colorInfo.name] or 0)
        love.graphics.print(totStr, col1X - HUD.fM:getWidth(totStr)/2, y + 16)
        
        love.graphics.setColor(P.gold)
        local leftStr = tostring(leftCounts[colorInfo.name] or 0)
        love.graphics.print(leftStr, col2X - HUD.fM:getWidth(leftStr)/2, y + 16)
        
        love.graphics.setColor(P.chip)
        local handStr = tostring(handCounts[colorInfo.name] or 0)
        love.graphics.print(handStr, col3X - HUD.fM:getWidth(handStr)/2, y + 16)
    end

    local legendY = sy + sh - 35
    local function legend(lx, label, col, isOutline)
        local cx = lx + 9
        local cy = legendY + 6
        local r = 6
        
        love.graphics.setColor(col or P.slot)
        love.graphics.circle("fill", cx, cy, r)
        
        if isOutline then
            love.graphics.setColor(col)
            love.graphics.setLineWidth(1.5)
            love.graphics.circle("line", cx, cy, r + 1.5)
        else
            love.graphics.setColor(0, 0, 0, 0.08)
            love.graphics.circle("line", cx, cy, r)
        end
        Button.txt(label, lx + 24, legendY - 2, P.text, HUD.fS)
    end
    legend(sx + 18, "남음", P.bg, false)
    legend(sx + 92, "손", P.chip, true)
    legend(sx + 154, "고른", P.gold, true)

    -- 오른쪽 그리드 뷰
    for row, colorInfo in ipairs(CharsList) do
        local y = gy + (row - 1) * (cellH + gapY)
        
        -- 오른쪽 그리드 행 배경
        love.graphics.setColor(P.bg[1], P.bg[2], P.bg[3], 0.3)
        love.graphics.rectangle("fill", gx - 75, y - 2, 805, 52, 6, 6)
        
        love.graphics.setColor(colorInfo.color)
        love.graphics.circle("fill", gx - 60, y + cellH/2, 6)
        Button.txt(HUD.getColorKoreanName(colorInfo.name), gx - 44, y + cellH/2 - 8, P.text, HUD.fM)
        
        local renderList = {}
        
        for _, c in ipairs(G.hand) do 
            if c.name == colorInfo.name then 
                if c.sel then
                    table.insert(renderList, {state="picked", edition=c.edition or "normal"})
                else
                    table.insert(renderList, {state="hand", edition=c.edition or "normal"})
                end
            end 
        end
        for _, c in ipairs(G.deck) do 
            if c.name == colorInfo.name then 
                table.insert(renderList, {state="left", edition=c.edition or "normal"})
            end 
        end
        
        local tempFound = {}
        for _, item in ipairs(renderList) do table.insert(tempFound, item.edition) end
        
        for _, c in ipairs(G.deckConfig) do
            if c.name == colorInfo.name then
                local ed = c.edition or "normal"
                local foundIdx = nil
                for i, v in ipairs(tempFound) do
                    if v == ed then foundIdx = i; break end
                end
                if foundIdx then
                    table.remove(tempFound, foundIdx)
                else
                    table.insert(renderList, {state="gone", edition=ed})
                end
            end
        end
        
        local stateOrder = {picked=1, hand=2, left=3, gone=4}
        table.sort(renderList, function(a, b)
            if stateOrder[a.state] ~= stateOrder[b.state] then
                return stateOrder[a.state] < stateOrder[b.state]
            end
            return a.edition < b.edition
        end)
        
        for i, item in ipairs(renderList) do
            local x = gx + ((i - 1) % perRow) * (cellW + gapX)
            local yy = y + math.floor((i - 1) / perRow) * (cellH + 4)
            drawBagPiece(x, yy, cellW, cellH, colorInfo, item.state, item.edition)
        end
    end

    local backX, backY, backW, backH = px + 28, py + ph - 28 - 42, pw - 56, 42
    local hovBack = mx >= backX and mx <= backX + backW and my >= backY and my <= backY + backH
    Button.draw(backX, backY, backW, backH, "뒤로", true, hovBack, HUD.fL)
    Button.txtC("[B] 주머니 보기 / 닫기", C.HCX, backY - 28, P.dim, HUD.fS)
end

return HUD
