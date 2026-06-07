------------------------------------------------------------
-- animation_system.lua · 애니메이션 타이머 및 연출 제어 시스템
------------------------------------------------------------
local AnimationSystem = {}
local MathUtils = require("utils.math")
local Audio = require("systems.audio_system")
local Effect = require("systems.effect_system")
local C = require("core.constants")

local slotAnim = {}
local roundStartAnim = { t = 0, dur = 1.6, active = false }
local execAnim = { active = false, cards = {}, idx = 0, timer = 0, phase = "idle" }

-- 상태 초기화
function AnimationSystem.clear()
    slotAnim = {}
    roundStartAnim.t = 0
    roundStartAnim.active = false
    execAnim.active = false
    execAnim.cards = {}
    execAnim.idx = 0
    execAnim.timer = 0
    execAnim.phase = "idle"
end

-- 특정 슬롯 바운스 애니메이션 발동
function AnimationSystem.startSlotAnim(idx, dur)
    slotAnim[idx] = { t = 0, dur = dur or 0.28 }
end

-- 라운드 진입 배너 시작
function AnimationSystem.startRoundStartAnim(dur)
    roundStartAnim.t = 0
    roundStartAnim.dur = dur or 1.6
    roundStartAnim.active = true
end

-- 카드 순차 비행 애니메이션 시작
function AnimationSystem.startExecAnim(cards)
    execAnim.active = true
    execAnim.cards = cards
    execAnim.idx = 1
    execAnim.timer = 0
    execAnim.phase = "flying"
end

-- 상태 데이터 접근 헬퍼
function AnimationSystem.getRoundStartAnim()
    return roundStartAnim
end

function AnimationSystem.getExecAnim()
    return execAnim
end

-- 특정 슬롯의 현재 스케일과 오프셋Y 구하기
function AnimationSystem.getSlotVisuals(idx)
    local a = slotAnim[idx]
    if not a then
        return 1.0, 0.0
    end
    local p = math.min(1.0, a.t / a.dur)
    local sc = MathUtils.easeBack(p)
    local offY = (1.0 - MathUtils.easeCubic(p)) * (-16.0)
    return sc, offY
end

-- 업데이트 루프
function AnimationSystem.update(dt, G)
    -- 1. 슬롯 애니메이션 업데이트
    for idx, a in pairs(slotAnim) do
        a.t = a.t + dt
        if a.t >= a.dur then
            slotAnim[idx] = nil
        end
    end

    -- 2. 라운드 배너 애니메이션 업데이트
    if roundStartAnim.active then
        roundStartAnim.t = roundStartAnim.t + dt
        if roundStartAnim.t >= roundStartAnim.dur then
            roundStartAnim.active = false
        end
    end

    -- 3. 카드 비행 애니메이션 업데이트 (실행 단계)
    if G.phase == "executing" and execAnim.active then
        local a = execAnim
        a.timer = a.timer + dt
        if a.phase == "flying" then
            if a.timer >= 0.15 then
                local card = a.cards[a.idx]
                if card then
                    -- 보드에 복제된 카드 배치
                    G.board[a.idx] = { name = card.name, color = { card.color[1], card.color[2], card.color[3] }, edition = card.edition }
                    AnimationSystem.startSlotAnim(a.idx, 0.28)
                    G.shake = G.shake + 3
                    
                    local sx = C.BX + (a.idx - 1) * (C.BSW + C.BGAP) + C.BSW / 2
                    local sy = C.BY + C.BSH / 2
                    Effect.spawnParticles(sx, sy, card.color, 12)
                    Audio.play("place")
                    
                    a.idx = a.idx + 1
                    a.timer = 0
                    
                    if a.idx > #a.cards then
                        a.phase = "done"
                        a.active = false
                        G.scoreBoard() -- 점수 집계 트리거
                    end
                end
            end
        end
    end
end

return AnimationSystem
