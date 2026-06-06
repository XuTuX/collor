------------------------------------------------------------
-- main.lua · Love2D 콜백 (얇은 glue 레이어)
------------------------------------------------------------
local C = require("config")
local G = require("game")
local R = require("draw")

function love.load()
    love.graphics.setBackgroundColor(C.P.bg)
    R.init()
    G.reset()
end

function love.update(dt)
    local mx, my = love.mouse.getPosition()
    G.hSlot = -1
    G.hCard = -1

    if G.phase == "play" then
        -- 보드 슬롯 호버
        for i = 1, C.BN do
            local sx = C.BX + (i-1) * (C.BSW + C.BGAP)
            if mx >= sx and mx <= sx+C.BSW and my >= C.BY and my <= C.BY+C.BSH then
                G.hSlot = i
            end
        end

        -- 핸드 캐릭터 호버 (드래그 중이 아닐 때만 체크하며, 지터 방지를 위해 히트박스 동적 확장 적용)
        if G.dragIndex <= 0 then
            local n = #G.hand
            local mid = (n+1) / 2
            for i = n, 1, -1 do
                local off = i - mid
                local cx = C.HCX + off * C.HSPC
                local cy = C.HY
                if G.hand[i].sel then cy = cy - 18 end
                
                local hr = C.HCR + 6
                if G.prevHCard == i then 
                    cy = cy - 8 
                    hr = C.HCR + 14 -- 히스테리시스용 히트박스 확장 (지터 루프 방지)
                end
                
                if mx >= cx-hr and mx <= cx+hr and my >= cy-hr and my <= cy+hr then
                    G.hCard = i
                    break
                end
            end
            G.prevHCard = G.hCard
        else
            G.hCard = -1
            G.prevHCard = -1
            -- 드래그 위치 업데이트
            G.dragX, G.dragY = mx, my
        end
    end

    G.update(dt)
end

function love.draw()
    R.all()
end

function love.mousepressed(x, y, btn)
    if btn ~= 1 then return end

    if G.phase == "title" then
        G.phase = "play"
        require("sound").play("discard")
        return
    end

    -- 공통: 리셋 버튼 클릭 감지
    if x >= C.RX and x <= C.RX+C.RW and y >= C.RY and y <= C.RY+C.RH then
        G.reset()
        require("sound").play("discard")
        return
    end

    -- 상점 상태 감지 및 입력 처리
    if G.phase == "shop" then
        local px, py = C.HCX - 300, 80
        local startX = px + 30
        local itemW = 160
        local itemH = 260
        local gap = 30
        
        -- 아이템 구매 버튼 클릭 체크
        for i = 1, 3 do
            local ix = startX + (i-1) * (itemW + gap)
            local iy = py + 110
            local bx = ix + 15
            local by = iy + itemH - 50
            local bw = itemW - 30
            local bh = 34
            
            if x >= bx and x <= bx+bw and y >= by and y <= by+bh then
                G.buyItem(i)
                return
            end
        end
        
        -- NEXT ROUND 버튼 클릭 체크
        local nW, nH = 180, 44
        local nX = px + (600 - nW)/2
        local nY = py + 520 - 80
        if x >= nX and x <= nX+nW and y >= nY and y <= nY+nH then
            G.exitShop()
            return
        end
        return
    end

    -- 게임 오버 상태
    if G.phase == "gameover" then
        local pw,ph = 400,340
        local px,py = C.HCX-pw/2, C.SH/2-ph/2
        local bw, bh = 180, 44
        local bx = px + (pw-bw)/2
        local by = py + ph - 80
        if x >= bx and x <= bx+bw and y >= by and y <= by+bh then
            G.reset()
            require("sound").play("discard")
        end
        return
    end

    -- 스코어링 중 → 스킵
    if G.phase == "scoring" then
        local s = G.sc
        if s.phase == "total" and s.timer > 1.2 then
            s.active = false
            G.score = G.score + G.rndScore
            G.phase = "result"
            if G.score >= G.targetScore then
                require("sound").play("clear")
            end
        elseif s.phase == "nohand" and s.timer > 0.8 then
            s.active = false
            G.score = G.score + G.rndScore
            G.phase = "result"
            if G.score >= G.targetScore then
                require("sound").play("clear")
            end
        end
        return
    end

    -- 결과 → 상점으로 진입 또는 게임 오버로 전환
    if G.phase == "result" then
        if G.score >= G.targetScore then
            -- 상점 진입 전 골드 보상 더하기
            local totalGold = G.calcGoldReward()
            G.gold = G.gold + totalGold
            
            G.enterShop()
            require("sound").play("discard")
        else
            G.phase = "gameover"
            require("sound").play("gameover")
        end
        return
    end


    -- 플레이 중
    if G.phase == "play" then
        -- 디스카드 버튼
        local bw, bh = 88, 34
        local bx = C.HCX + 294
        local by = C.HY - 10
        if x >= bx and x <= bx+bw and y >= by and y <= by+bh then
            G.discard()
            return
        end

        -- 핸드 캐릭터 클릭 (드래그 시작)
        if G.hCard > 0 and G.hCard <= #G.hand then
            G.dragIndex = G.hCard
            G.dragX, G.dragY = x, y
            G.dragStartPos.x, G.dragStartPos.y = x, y
            return
        end

        -- 보드 슬롯 클릭
        if G.hSlot > 0 then
            local sel = G.selCards()
            if #sel == 1 then
                if G.board[G.hSlot] then
                    G.swap(sel[1], G.hSlot)
                else
                    G.place(sel[1], G.hSlot)
                end
            else
                -- 클릭 시 회수 (Undo)
                G.recall(G.hSlot)
            end
            return
        end
    end
end

function love.mousereleased(x, y, btn)
    if btn ~= 1 then return end

    if G.phase == "play" and G.dragIndex > 0 then
        local dragI = G.dragIndex
        G.dragIndex = -1

        local dx = x - G.dragStartPos.x
        local dy = y - G.dragStartPos.y
        local dist = math.sqrt(dx*dx + dy*dy)

        if dist < 6 then
            -- 단순 클릭: 토글 선택
            G.hand[dragI].sel = not G.hand[dragI].sel
            require("sound").play("select")
        else
            -- 드래그 드롭 완료
            if G.hSlot > 0 then
                if G.board[G.hSlot] then
                    G.swap(dragI, G.hSlot)
                else
                    G.place(dragI, G.hSlot)
                end
            end
        end
    end
end

function love.keypressed(key)
    if key == "r" then G.reset() end
    if key == "escape" then love.event.quit() end
end

------------------------------------------------------------
-- 디버그 테스트: love.load() 안 G.reset() 뒤에 추가
------------------------------------------------------------
--[[ 테스트 1: Tower  → 150×12 = 1800
G.board = {
    {name="Red",color={.92,.22,.25}},{name="Red",color={.92,.22,.25}},
    {name="Red",color={.92,.22,.25}},{name="Red",color={.92,.22,.25}},
    {name="Red",color={.92,.22,.25}},{name="Orange",color={.95,.55,.15}},
    {name="Yellow",color={.95,.85,.15}},
}
G.detected=require("detect").evaluate(G.board)
G.rndScore=require("detect").calcScore(G.detected)
G.startScoring()
--]]

--[[ 테스트 2: Grand Mirror → 400×40 = 16000
G.board = {
    {name="Red",color={.92,.22,.25}},{name="Orange",color={.95,.55,.15}},
    {name="Yellow",color={.95,.85,.15}},{name="White",color={.94,.94,.96}},
    {name="Yellow",color={.95,.85,.15}},{name="Orange",color={.95,.55,.15}},
    {name="Red",color={.92,.22,.25}},
}
--]]

--[[ 테스트 3: Perfect Ladder + Mini Mono → (300+30)×(25+3) = 9240
G.board = {
    {name="Red",color={.92,.22,.25}},{name="Orange",color={.95,.55,.15}},
    {name="Orange",color={.95,.55,.15}},{name="Yellow",color={.95,.85,.15}},
    {name="Yellow",color={.95,.85,.15}},{name="Yellow",color={.95,.85,.15}},
    {name="Black",color={.12,.12,.16}},
}
--]]
