------------------------------------------------------------
-- turn_manager.lua · 게임 턴(바꾸기, 실행, 신규 라운드) 제어 모듈
------------------------------------------------------------
local TurnManager = {}
local C = require("core.constants")
local Tile = require("gameplay.tile")
local Balance = require("data.balance")
local Audio = require("systems.audio_system")
local Anim = require("systems.animation_system")
local ScoreSys = require("systems.score_system")

-- 바꾸기(버리기) 액션 실행
function TurnManager.discard(G)
    if G.discLeft <= 0 then
        G.notice("바꾸기 기회가 없어요", "warn")
        return false
    end
    
    local selectedIndices = Tile.getSelectedIndices(G.hand)
    local toDiscard = #selectedIndices
    
    if toDiscard == 0 then
        G.notice("바꿀 색친구를 선택해주세요", "warn")
        return false
    end
    
    -- 선택한 카드를 패에서 제거 (인덱스가 꼬이지 않도록 역순으로 삭제)
    table.sort(selectedIndices, function(a, b) return a > b end)
    for _, idx in ipairs(selectedIndices) do
        table.remove(G.hand, idx)
    end
    
    -- 제거한 수만큼 주머니에서 새로 뽑기
    local drawn = Tile.drawCards(G.deck, toDiscard)
    for _, c in ipairs(drawn) do
        table.insert(G.hand, c)
    end
    
    G.discLeft = G.discLeft - 1
    Audio.play("discard")
    G.notice(toDiscard .. "명을 바꿨어요", "ok")
    return true
end

-- 실행(무대로 카드 보내기) 액션 실행
function TurnManager.executeHand(G)
    local count = math.min(C.BN, #G.hand)
    if count == 0 then return false end
    
    G.execLeft = G.execLeft - 1
    G.phase = "executing"
    
    -- 카드 순차 비행 애니메이션 실행 목록 수집
    local flyingCards = {}
    for i = 1, count do
        local card = table.remove(G.hand, 1)
        card.sel = false
        table.insert(flyingCards, card)
    end
    
    -- 남아있는 패 카드들의 선택 상태 초기화
    for _, c in ipairs(G.hand) do
        c.sel = false
    end
    
    -- 보드판 일단 비우기
    G.board = {}
    for i = 1, C.BN do
        G.board[i] = nil
    end
    
    Anim.startExecAnim(flyingCards)
    Audio.play("select")
    return true
end

-- 신규 라운드 개설 및 데이터 셋업
function TurnManager.newRound(G)
    G.score = 0
    G.dScore = 0
    G.execLeft = 4
    
    -- 보드판 초기화
    G.board = {}
    for i = 1, C.BN do
        G.board[i] = nil
    end
    
    -- 애니메이션 및 득점 시스템 클리어
    Anim.clear()
    ScoreSys.clear()
    
    -- 덱 구성 및 드로우
    G.deck = Tile.createDeck(G.deckConfig)
    G.hand = Tile.drawCards(G.deck, C.HN)
    G.discLeft = C.MAXDISC
    
    -- 특별 관문 기믹 적용: 바꾸기 불능화
    if G.stage == 3 and G.bossGimmick == "no_discard" then
        G.discLeft = 0
    end
    
    G.phase = "play"
    G.detected = {}
    G.rndScore = 0
    G.hSlot = -1
    G.hCard = -1
    G.dragIndex = -1
    G.showBag = false
    
    -- 목표 점수 스케일링 계산
    G.targetScore = Balance.getTargetScore(G.ante, G.stage, G.bossGimmick)
    
    G.shake = 0
    G.particles = {}
    G.roundCleared = (G.score >= G.targetScore)
    
    -- 라운드 시작 진입 배너 애니메이션 발동
    Anim.startRoundStartAnim(1.6)
end

return TurnManager
