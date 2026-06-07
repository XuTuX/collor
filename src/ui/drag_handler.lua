------------------------------------------------------------
-- drag_handler.lua · 내 색친구 카드 마우스 드래그 앤 드롭 제어 모듈
------------------------------------------------------------
local DragHandler = {}
local C = require("core.constants")
local Tile = require("gameplay.tile")

-- 마우스 오버 카드 감지 (main.lua love.update 루프 이식)
function DragHandler.updateHover(G, mx, my)
    G.hCard = -1
    
    if G.phase ~= "play" or G.showBag then
        return
    end

    if G.dragIndex > 0 then
        G.dragX, G.dragY = mx, my
        G.hCard = -1
        G.prevHCard = -1
        return
    end

    local n = #G.hand
    local mid = (n + 1) / 2
    for i = n, 1, -1 do
        local card = G.hand[i]
        local cx = card.visX or (C.HCX + (i - mid) * C.HSPC)
        local cy = C.HY
        if card.sel then
            cy = cy - 22
        end

        local hr = C.HCR + 8

        if mx >= cx - hr and mx <= cx + hr and my >= cy - hr and my <= cy + hr then
            G.hCard = i
            break
        end
    end
    G.prevHCard = G.hCard
end

-- 마우스 클릭 시 드래그 개시 판정
function DragHandler.handlePressed(G, x, y)
    if G.phase == "play" and not G.showBag then
        if G.hCard > 0 and G.hCard <= #G.hand then
            G.dragIndex = G.hCard
            G.dragStartIndex = G.hCard
            G.dragX, G.dragY = x, y
            G.dragStartPos.x, G.dragStartPos.y = x, y
            return true
        end
    end
    return false
end

-- 마우스 버튼을 뗐을 때 드래그 완료 판정 (정렬 혹은 토글)
function DragHandler.handleReleased(G, x, y)
    if G.phase == "play" and G.dragIndex > 0 then
        local dragI = G.dragIndex
        G.dragIndex = -1
        G.dragStartIndex = -1

        local dx = x - G.dragStartPos.x
        local dy = y - G.dragStartPos.y
        local dist = math.sqrt(dx * dx + dy * dy)
        
        if dist >= 8 then
            -- 드래그 거리가 8 이상이면 순서 정렬
            Tile.reorderHand(G.hand, dragI, x)
        else
            -- 드래그 거리가 짧으면 선택 상태 전환
            Tile.toggleSelect(G.hand, dragI, function(msg, kind) G.notice(msg, kind) end)
        end
        return true
    end
    return false
end

return DragHandler
