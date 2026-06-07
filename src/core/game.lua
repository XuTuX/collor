------------------------------------------------------------
-- game.lua · 메인 게임 마스터 컨트롤러 및 전역 상태 저장소
------------------------------------------------------------
local Game = {}
local C = require("core.constants")
local PatternsData = require("data.patterns")
local CharactersData = require("data.characters")
local Random = require("utils.random")
local Tween = require("utils.tween")

-- 하위 시스템 의존성
local Audio = require("systems.audio_system")
local Effect = require("systems.effect_system")
local Anim = require("systems.animation_system")
local ScoreSys = require("systems.score_system")
local Tile = require("gameplay.tile")

-- ── 전역 데이터 상태 초기 정의 ──
Game.board       = {}
Game.hand        = {}
Game.deck        = {}
Game.score       = 0
Game.totalScore  = 0
Game.execLeft    = 4
Game.dScore      = 0        -- 부드럽게 점수가 올라가는 효과용
Game.round       = 1
Game.rndScore    = 0
Game.discLeft    = C.MAXDISC
Game.phase       = "play"   -- title | play | executing | scoring | result | gameover | shop
Game.hSlot       = -1       -- 마우스 오버 중인 보드 슬롯
Game.hCard       = -1       -- 마우스 오버 중인 패 카드
Game.prevHCard   = -1
Game.detected    = {}       -- 감지된 규칙 리스트

-- 마우스 드래그 상태
Game.dragIndex      = -1
Game.dragX, Game.dragY = 0, 0
Game.dragStartPos   = { x = 0, y = 0 }
Game.dragStartIndex = -1

-- 모험 진행 상태 (Ante & Stage)
Game.targetScore = 300
Game.ante        = 1
Game.stage       = 1
Game.bossGimmick = "none"   -- none | no_red | no_black | no_discard | high_target
Game.gold        = 4
Game.jokers      = {}       -- 보유 조커(도우미) 목록
Game.shopItems   = {}       -- 상점 판매 아이템 목록
Game.deckConfig  = {}       -- 영구 덱 구성

-- 알림 토스트 연출용
Game.noticeText  = ""
Game.noticeTimer = 0
Game.noticeKind  = "info"
Game.showBag     = false    -- 주머니 전체보기 오버레이 활성화 여부

-- 규칙 강화 레벨 정보 (data/patterns 템플릿 복제본)
Game.handStats = {}

-- 쥬스 연출 스탯
Game.shake     = 0

-- 상태 머신 인스턴스
Game.stateMachine = nil

-- 게임 구동부 초기 생성
function Game.init()
    local HUD = require("ui.hud")
    HUD.initFonts()
    Audio.init()
    
    -- 상태 머신 구성
    local StateMachine = require("core.state_machine")
    Game.stateMachine = StateMachine.new({
        title    = require("states.menu_state"),
        play     = require("states.gameplay_state"),
        result   = require("states.result_state"),
        shop     = require("states.settings_state"), -- 상점 상태를 settings_state에 맵핑
        gameover = require("states.gameplay_state")  -- 게임오버 키 처리는 gameplay_state와 유사하게 구성 가능하나, 개별 위임
    })
end

-- 알림 토스트 출력 트리거
function Game.notice(text, kind)
    Game.noticeText = text or ""
    Game.noticeKind = kind or "info"
    Game.noticeTimer = 1.8
end

-- 게임판 족보 집계 및 점수 계산 시퀀스 개시
function Game.scoreBoard()
    local PatternChecker = require("gameplay.pattern_checker")
    local RuleEngine = require("gameplay.rule_engine")
    
    Game.detected = PatternChecker.evaluate(Game.board)
    RuleEngine.applyStatsAndGimmicks(Game.detected, Game.handStats, Game.stage, Game.bossGimmick)
    
    Game.phase = "scoring"
    ScoreSys.start(Game.board, Game.detected, Game.jokers, Game)
    Game.stateMachine:change("result", Game)
end

-- 상점 아이템 구매 처리 (원래 game.lua 이식)
function Game.buyItem(idx)
    local item = Game.shopItems[idx]
    if not item or item.sold then
        Game.notice("이미 가져간 물건이에요", "warn")
        return false, "이미 판매되었습니다"
    end
    if Game.gold < item.price then
        Game.notice("코인이 부족해요", "warn")
        return false, "코인이 부족합니다"
    end
    
    if item.type == "joker" then
        local JokerSystem = require("systems.joker_system")
        if not JokerSystem.canAddJoker(Game.jokers) then
            Game.notice("도우미 자리가 가득 찼어요", "warn")
            return false, "도우미 자리가 가득 찼습니다 (최대 3)"
        end
        table.insert(Game.jokers, {id=item.id, name=item.name, desc=item.desc})
    elseif item.type == "upgrade" then
        local stats = Game.handStats[item.hand]
        if stats then
            stats.level = stats.level + 1
            stats.chips = stats.chips + stats.scaleChips
            stats.mult = stats.mult + stats.scaleMult
        end
    elseif item.type == "deck_add" then
        table.insert(Game.deckConfig, {name=item.colorName, color=item.colorVal})
    elseif item.type == "deck_remove" then
        if #Game.deckConfig > 7 then
            table.remove(Game.deckConfig, love.math.random(1, #Game.deckConfig))
        else
            Game.notice("주머니가 너무 작아요", "warn")
            return false, "주머니에 색친구가 너무 적습니다"
        end
    end
    
    Game.gold = Game.gold - item.price
    item.sold = true
    Audio.play("clear")
    Game.shake = Game.shake + 4
    Game.notice("가져왔어요", "ok")
    return true
end

-- 게임 모험 전체 리셋
function Game.reset()
    Game.score = 0
    Game.totalScore = 0
    Game.dScore = 0
    Game.round = 1
    Game.ante = 1
    Game.stage = 1
    Game.gold = 4
    Game.jokers = {}
    
    -- 보스 기믹 셔플 결정
    local gimmicks = {"no_red", "no_black", "no_discard", "high_target"}
    Game.bossGimmick = gimmicks[love.math.random(1, #gimmicks)]
    Game.roundCleared = false
    
    -- 규칙 강화 레벨 리셋 (patterns 템플릿을 Deep Copy 복사)
    Game.handStats = {}
    for name, stats in pairs(PatternsData.handStatsTemplate) do
        Game.handStats[name] = {
            level = stats.level,
            chips = stats.chips,
            mult = stats.mult,
            scaleChips = stats.scaleChips,
            scaleMult = stats.scaleMult
        }
    end
    
    -- 기본 영구 주머니(덱) 구성 빌드
    Game.deckConfig = {}
    for _, c in ipairs(CharactersData) do
        for _ = 1, c.count do
            table.insert(Game.deckConfig, { name = c.name, color = { c.color[1], c.color[2], c.color[3] } })
        end
    end
    
    local TurnManager = require("gameplay.turn_manager")
    TurnManager.newRound(Game)
    
    -- 타이틀(메뉴) 화면 상태로 변경
    Game.phase = "title"
    Game.stateMachine:change("title", Game)
end

-- 실시간 업데이트 루프 (G.update 이식)
function Game.update(dt)
    -- 1. 애니메이션 수명 갱신
    Anim.update(dt, Game)
    
    -- 2. 화면 흔들림(shake) 감쇄 감쇠 처리
    if Game.shake > 0 then
        Game.shake = Game.shake * math.exp(-15 * dt)
        if Game.shake < 0.1 then 
            Game.shake = 0 
        end
    end
    
    -- 3. 파티클 수명 업데이트
    Effect.update(dt)
    
    -- 4. 토스트 알림 연출 타이머 갱신
    if Game.noticeTimer > 0 then
        Game.noticeTimer = math.max(0, Game.noticeTimer - dt)
    end

    -- 5. 부드러운 점수 보간 수렴 계산 (utils/tween 적용)
    local targetVal = Game.score
    local scState = ScoreSys.getState()
    if scState.active then
        targetVal = Game.score + scState.dTotal
    end
    Game.dScore = Tween.smoothTo(Game.dScore, targetVal, 6, dt)
    if math.abs(Game.dScore - targetVal) < 1 then 
        Game.dScore = targetVal 
    end

    -- 6. 관문 돌파 실시간 판단 연출 (발라트로 스타일 코인 폭발)
    if not Game.roundCleared and Game.dScore >= Game.targetScore and Game.phase ~= "title" then
        Game.roundCleared = true
        Audio.play("clear")
        Game.shake = Game.shake + 12
        
        -- 현재 점수 판넬 위치(x+126, y+84 where x=30, y=30) 부근에서 금빛 파티클
        local sx = 30 + 126 + 50
        local sy = 30 + 84 + 30
        Effect.spawnParticles(sx, sy, {0.98, 0.85, 0.20}, 30)
        Game.notice("관문 통과!", "ok")
    end
    
    -- 7. 내 손패 visualX 부드러운 순서 정렬 보간 (drag visual)
    local n = #Game.hand
    if n > 0 then
        local mid = (n + 1) / 2
        local dragIdx = Game.dragIndex
        local targetIdx = -1
        if dragIdx > 0 then
            targetIdx = Tile.handIndexFromX(Game.hand, Game.dragX)
        end

        for i = 1, n do
            local card = Game.hand[i]
            local targetX
            
            if dragIdx == i then
                targetX = Game.dragX
                card.visX = Game.dragX
            else
                local slot = i
                if dragIdx > 0 then
                    local rIdx = i
                    if i > dragIdx then
                        rIdx = i - 1
                    end
                    if rIdx < targetIdx then
                        slot = rIdx
                    else
                        slot = rIdx + 1
                    end
                end
                targetX = C.HCX + (slot - mid) * C.HSPC
            end

            if not card.visX then
                card.visX = C.HCX + (i - mid) * C.HSPC
            end
            
            card.visX = Tween.smoothTo(card.visX, targetX, 18, dt)
        end
    end
    
    -- 8. 득점 시퀀스 업데이트
    ScoreSys.update(dt, Game)
    
    -- 9. 마우스 드래그 오버 상태 실시간 트래킹
    local mx, my = love.mouse.getPosition()
    local Drag = require("ui.drag_handler")
    Drag.updateHover(Game, mx, my)
    
    -- 10. 활성 화면 상태 업데이트 위임
    Game.stateMachine:update(dt)
end

-- 마우스 눌림 브릿지
function Game.mousepressed(x, y, button)
    Game.stateMachine:mousepressed(x, y, button)
end

-- 마우스 떼어짐 브릿지
function Game.mousereleased(x, y, button)
    Game.stateMachine:mousereleased(x, y, button)
end

-- 키보드 눌림 브릿지
function Game.keypressed(key)
    Game.stateMachine:keypressed(key)
end

return Game
