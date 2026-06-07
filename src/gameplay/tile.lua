------------------------------------------------------------
-- tile.lua · 색친구 카드(타일) 객체 팩토리 및 손패/주머니 로직
------------------------------------------------------------
local Tile = {}
local C = require("core.constants")
local Random = require("utils.random")
local Audio = require("systems.audio_system")

-- 카드 복제
function Tile.clone(card)
    if not card then return nil end
    return {
        name = card.name,
        color = { card.color[1], card.color[2], card.color[3] }
    }
end

-- 덱 설정 데이터(config)를 바탕으로 셔플된 실시간 주머니(덱) 리스트 생성
function Tile.createDeck(deckConfig)
    local d = {}
    for _, card in ipairs(deckConfig) do
        table.insert(d, Tile.clone(card))
    end
    Random.shuffle(d)
    return d
end

-- 주머니에서 카드 드로우
function Tile.drawCards(deckList, count)
    local drawn = {}
    for _ = 1, count do
        if #deckList > 0 then
            local c = table.remove(deckList)
            c.sel = false
            c.spawnT = love.timer.getTime()
            table.insert(drawn, c)
        end
    end
    return drawn
end

-- 손에 쥔 색친구 선택 상태 반전
function Tile.toggleSelect(handList, index, noticeCallback)
    local card = handList[index]
    if not card then return false end
    
    if card.sel then
        card.sel = false
    else
        -- 현재 선택된 개수 합산
        local selCount = 0
        for _, c in ipairs(handList) do
            if c.sel then selCount = selCount + 1 end
        end
        
        if selCount >= C.BN then
            if noticeCallback then
                noticeCallback("더 이상 고를 수 없어요", "warn")
            end
            return false
        end
        card.sel = true
    end
    
    Audio.play("select")
    return true
end

-- 선택된 색친구의 총 개수 반환
function Tile.getSelectionCount(handList)
    local n = 0
    for _, c in ipairs(handList) do
        if c.sel then n = n + 1 end
    end
    return n
end

-- 선택된 카드의 실제 인덱스 목록
function Tile.getSelectedIndices(handList)
    local s = {}
    for i, c in ipairs(handList) do
        if c.sel then table.insert(s, i) end
    end
    return s
end

-- 선택된 카드의 복제본 데이터 목록
function Tile.getSelectedCards(handList)
    local picked = {}
    for _, c in ipairs(handList) do
        if c.sel then
            table.insert(picked, Tile.clone(c))
        end
    end
    return picked
end

-- 마우스 X 좌표에 대응하는 손패 인덱스 계산 (드래그/재정렬용)
function Tile.handIndexFromX(handList, mouseX)
    local n = #handList
    if n <= 1 then return 1 end
    local firstX = C.HCX - ((n - 1) / 2) * C.HSPC
    local idx = math.floor((mouseX - firstX + C.HSPC / 2) / C.HSPC) + 1
    return math.max(1, math.min(n, idx))
end

-- 손패 순서 재정렬
function Tile.reorderHand(handList, fromIndex, mouseX)
    if fromIndex < 1 or fromIndex > #handList then return false end
    local toIndex = Tile.handIndexFromX(handList, mouseX)
    if toIndex == fromIndex then return false end
    
    local card = table.remove(handList, fromIndex)
    if toIndex > #handList + 1 then
        toIndex = #handList + 1
    end
    table.insert(handList, toIndex, card)
    Audio.play("select")
    return true
end

return Tile
