------------------------------------------------------------
-- board.lua · 실행 무대(보드) 슬롯 데이터 조작 모듈
------------------------------------------------------------
local Board = {}
local C = require("core.constants")

-- 보드 초기화 (비우기)
function Board.clear(boardTable)
    for i = 1, C.BN do
        boardTable[i] = nil
    end
end

-- 특정 슬롯 카드 조회
function Board.get(boardTable, index)
    return boardTable[index]
end

-- 특정 슬롯 카드 지정
function Board.set(boardTable, index, card)
    boardTable[index] = card
end

return Board
