------------------------------------------------------------
-- card_slot.lua · 보드판 슬롯 및 주머니 스택 UI 렌더링 컴포넌트
------------------------------------------------------------
local CardSlot = {}
local C = require("core.constants")
local P = C.P
local Panel = require("ui.panel")
local Button = require("ui.button")
local CharacterEntity = require("entities/character")
local CharactersData = require("data.characters")

local function rr(mode, x, y, w, h, r)
    love.graphics.rectangle(mode, x, y, w, h, r or 8, r or 8)
end

-- 실행 무대 슬롯판 그리기
function CardSlot.drawBoard(G, board, slotAnimState, scState)
    local hud = require("ui.hud")
    local fS = hud.fS
    if not fS then return end
    
    -- 외곽 마스터 판넬 (보드를 둘러싸는 연한 플레이트)
    Panel.draw(C.BX - 16, C.BY - 38, C.BW + 32, C.BSH + 54, 12)

    for i = 1, C.BN do
        local sx = C.BX + (i - 1) * (C.BSW + C.BGAP)
        local sy = C.BY
        local card = board[i]

        -- 슬롯 바닥면 그리기 (부드러운 그림자 + 기본 밝은 면)
        love.graphics.setColor(0, 0, 0, 0.04)
        rr("fill", sx + 1, sy + 3, C.BSW, C.BSH, 8)
        love.graphics.setColor(card and P.slotHov or P.slot)
        rr("fill", sx, sy, C.BSW, C.BSH, 6)
        love.graphics.setColor(card and P.slotHBd or P.slotBd)
        love.graphics.setLineWidth(card and 1.8 or 1)
        rr("line", sx, sy, C.BSW, C.BSH, 6)
        
        -- 상단 장식 바
        love.graphics.setColor(P.gold[1], P.gold[2], P.gold[3], card and 0.95 or 0.2)
        rr("fill", sx + 6, sy + 6, C.BSW - 12, 3, 2)

        -- 빈 슬롯 표시: 플러스 십자선 아이콘
        if not card then
            love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.22)
            local cx, cy = sx + C.BSW / 2, sy + C.BSH / 2
            love.graphics.setLineWidth(1.5)
            love.graphics.arc("line", "open", cx, cy, 11, -0.65, math.pi + 0.65)
            love.graphics.line(cx - 6, cy, cx + 6, cy)
        end

        -- 하단 배치 인덱스 숫자
        love.graphics.setFont(fS)
        love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.4)
        local ns = tostring(i)
        love.graphics.print(ns, sx + (C.BSW - fS:getWidth(ns)) / 2, sy + C.BSH - 16)

        -- 배치된 캐릭터 그리기
        if card then
            local AnimSys = require("systems.animation_system")
            local sc, offY = AnimSys.getSlotVisuals(i)
            
            -- 득점 카운트 시 위아래 뜀박질 보정
            if scState and scState.active and scState.hopIdx and scState.hopIdx[i] then
                offY = offY - 20
            end

            local tx = sx + C.BSW / 2
            local ty = sy + C.BSH / 2 - 2 + offY
            
            local activeFace = false
            if G and G.executingCardIdx == i then
                activeFace = true
            end

            love.graphics.push()
            love.graphics.translate(tx, ty)
            love.graphics.scale(sc, sc)
            love.graphics.translate(-tx, -ty)
            CharacterEntity.draw(tx, ty, C.CR, card, { active = activeFace })
            love.graphics.pop()
            
            -- 캐릭터 머리 위 실시간 개별 별 점수 말풍선 (득점 연출 중일 때)
            if scState and scState.active then
                local base = 10
                for _, info in ipairs(CharactersData) do
                    if info.name == card.name then 
                        base = info.base or 10
                        break 
                    end
                end
                
                local isHopping = scState.hopIdx and scState.hopIdx[i]
                local pillCol = P.chip
                if isHopping then
                    pillCol = P.gold
                end
                
                local valStr = "+" .. tostring(base)
                local valW = fS:getWidth(valStr) + 8
                local valH = 15
                
                Button.pill(tx - valW / 2, ty - C.CR - 14, valW, valH, valStr, pillCol, fS)
            end
        end
    end
end

-- 주머니 덱 카드 겹침 그래픽 그리기
function CardSlot.drawDeckStack(bx, by, bw, bh, deckSize, isHovered)
    local hud = require("ui.hud")
    local fS = hud.fS
    local fX = hud.fX
    if not fS or not fX then return end
    
    -- 입체 밑그림자 판
    love.graphics.setColor(0, 0, 0, 0.05)
    rr("fill", bx, by + 3, bw, bh, 8)
    
    -- 기본 카드 주머니 슬롯 상자
    love.graphics.setColor(isHovered and P.slotHov or P.panel)
    rr("fill", bx, by, bw, bh, 8)
    love.graphics.setColor(isHovered and P.slotHBd or P.panelBd)
    love.graphics.setLineWidth(1.5)
    rr("line", bx, by, bw, bh, 8)

    -- 카드 여러 장 겹쳐진 입체 이펙트 라인
    local dx = bx + 28
    local dy = by + 40
    for j = 2, 0, -1 do
        love.graphics.setColor(P.dim[1], P.dim[2], P.dim[3], 0.12 + j * 0.05)
        rr("fill", dx - 8 + j * 1.5, dy - 12 + j * 1.5, 22, 32, 4)
    end
    
    -- 주머니 타이틀 및 수량 출력
    Button.txtC("주머니", bx + bw / 2, by + 16, P.text, fS)
    Button.txtC(tostring(deckSize), bx + bw / 2, by + 46, P.gold, fX)
end

return CardSlot

