------------------------------------------------------------
-- effect_system.lua · 입자(파티클) 및 텍스트 파티클 관리 시스템
------------------------------------------------------------
local EffectSystem = {}
local particles = {}

-- 파티클 초기화
function EffectSystem.clear()
    particles = {}
end

-- 기본 파티클 폭발 스폰
function EffectSystem.spawnParticles(x, y, color, count)
    count = count or 10
    for _ = 1, count do
        local angle = love.math.random() * math.pi * 2
        local speed = love.math.random(60, 180)
        table.insert(particles, {
            x = x,
            y = y,
            dx = math.cos(angle) * speed,
            dy = math.sin(angle) * speed - love.math.random(30, 80),
            color = {color[1], color[2], color[3]},
            rad = love.math.random(2, 4),
            age = 0,
            maxAge = love.math.random(0.3, 0.6)
        })
    end
end

-- 떠오르는 점수 텍스트 파티클 스폰
function EffectSystem.spawnTextParticle(x, y, text, color)
    table.insert(particles, {
        type = "text",
        x = x,
        y = y,
        text = text,
        color = {color[1], color[2], color[3]},
        dy = -40,
        age = 0,
        maxAge = 0.8
    })
end

-- 매 프레임 파티클 업데이트
function EffectSystem.update(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.age = p.age + dt
        if p.age >= p.maxAge then
            table.remove(particles, i)
        else
            if p.type == "text" then
                p.y = p.y + p.dy * dt
                p.dy = p.dy * 0.94 -- 서서히 상승 속도 감속
            else
                p.x = p.x + p.dx * dt
                p.y = p.y + p.dy * dt
                p.dy = p.dy + 350 * dt -- 중력 적용
            end
        end
    end
end

-- 파티클 그리기 (ui/hud.lua 에 정의될 fL 폰트 사용)
function EffectSystem.draw()
    local hud = require("ui.hud")
    local fL = hud.fL
    if not fL then return end
    
    for _, p in ipairs(particles) do
        local alpha = 1 - p.age / p.maxAge
        if p.type == "text" then
            love.graphics.setFont(fL)
            
            -- 드롭 섀도우 효과
            love.graphics.setColor(0, 0, 0, alpha * 0.7)
            love.graphics.print(p.text, p.x - fL:getWidth(p.text)/2 + 1, p.y - fL:getHeight()/2 + 1)
            
            -- 실제 텍스트
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
            love.graphics.print(p.text, p.x - fL:getWidth(p.text)/2, p.y - fL:getHeight()/2)
        else
            love.graphics.setLineWidth(1)
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha * 0.8)
            love.graphics.circle("fill", p.x, p.y, p.rad)
            
            love.graphics.setColor(p.color[1]*1.2, p.color[2]*1.2, p.color[3]*1.2, alpha * 0.3)
            love.graphics.circle("line", p.x, p.y, p.rad + 1.2)
        end
    end
end

return EffectSystem
