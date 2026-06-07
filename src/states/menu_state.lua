------------------------------------------------------------
-- menu_state.lua · 타이틀(메뉴) 화면 상태 관리 모듈
------------------------------------------------------------
local MenuState = {}
local C = require("core.constants")
local P = C.P
local Panel = require("ui.panel")
local Button = require("ui.button")
local Audio = require("systems.audio_system")
local HUD = require("ui.hud")
local CharactersData = require("data.characters")

local G = nil

function MenuState.enter(gameInstance)
    G = gameInstance
end

function MenuState.exit()
end

function MenuState.update(dt)
end

-- 타이틀 화면 그리기 (S.title 로직 완벽 보존)
function MenuState.draw()
    if not G then return end
    
    love.graphics.setColor(P.bg)
    love.graphics.rectangle("fill", 0, 0, C.SW, C.SH)

    local time = love.timer.getTime()

    -- 방사형 후광 효과
    love.graphics.setColor(P.cMirr[1], P.cMirr[2], P.cMirr[3], 0.15)
    love.graphics.circle("fill", C.SW / 2, C.SH / 2, 400 + math.sin(time) * 20)
    
    -- 부드러운 당구대 felt 텍스처 배경 그라데이션
    for y = 0, C.SH, 24 do
        local t = y / C.SH
        love.graphics.setColor(
            P.felt[1] * (1 - t) + P.felt2[1] * t,
            P.felt[2] * (1 - t) + P.felt2[2] * t,
            P.felt[3] * (1 - t) + P.felt2[3] * t,
            0.6
        )
        love.graphics.rectangle("fill", 0, y, C.SW, 24)
    end

    -- 마스코트 그리기 헬퍼
    local function mascot(cx, cy, rad, col, lift)
        local y = cy + math.sin(time * 1.6 + lift) * 4
        love.graphics.setColor(0.20, 0.27, 0.40, 0.12)
        love.graphics.ellipse("fill", cx, y + rad + 5, rad * 0.64, rad * 0.16)
        love.graphics.setColor(col[1] * 0.55, col[2] * 0.55, col[3] * 0.55, 0.88)
        love.graphics.circle("fill", cx, y + 2, rad + 2)
        love.graphics.setColor(col)
        love.graphics.circle("fill", cx, y, rad)
        love.graphics.setColor(1, 1, 1, 0.16)
        love.graphics.arc("fill", cx, y - 2, rad * 0.72, -math.pi, -0.05)
        
        -- 눈동자
        love.graphics.setColor(0.08, 0.08, 0.12, col == CharactersData[5].color and 0.0 or 0.74)
        if col == CharactersData[5].color then 
            love.graphics.setColor(0.92, 0.92, 0.96, 0.90) 
        end
        love.graphics.ellipse("fill", cx - rad * 0.24, y - rad * 0.10, rad * 0.11, rad * 0.16)
        love.graphics.ellipse("fill", cx + rad * 0.24, y - rad * 0.10, rad * 0.11, rad * 0.16)
        
        -- 미소 아크
        love.graphics.setLineWidth(1.4)
        love.graphics.setColor(col == CharactersData[5].color and {0.92, 0.92, 0.96, 0.48} or {0.08, 0.08, 0.12, 0.24})
        love.graphics.arc("line", "open", cx, y + rad * 0.18, rad * 0.18, 0.25, math.pi - 0.25)
    end

    local cx = C.SW / 2
    local cy = C.SH / 2
    
    local pw, ph = 500, 440
    local px = cx - pw / 2
    local py = cy - ph / 2 - 20
    
    Panel.draw(px, py, pw, ph, 14)
    
    Button.txtC("컬러 퍼즐 7", cx, py + 36, P.gold, HUD.fXX)
    Button.txtC("색친구들의 무대 모험", cx, py + 92, P.dim, HUD.fS)
    
    love.graphics.setColor(P.panelBd)
    love.graphics.line(px + 30, py + 120, px + pw - 30, py + 120)
    
    -- 색친구 마스코트들 가로 정렬
    local colors = {
        CharactersData[1].color, 
        CharactersData[2].color, 
        CharactersData[3].color, 
        CharactersData[4].color, 
        CharactersData[5].color
    }
    local mascotY = py + 210
    for i = 1, 5 do
        mascot(cx - 160 + (i - 1) * 80, mascotY, 28, colors[i], i)
        Button.txtC(HUD.getColorKoreanName(CharactersData[i].name), cx - 160 + (i - 1) * 80, mascotY + 38, P.dim, HUD.fS)
    end
    
    -- 시작 버튼
    local mx, my = love.mouse.getPosition()
    local btnW, btnH = 200, 48
    local btnX = cx - btnW / 2
    local btnY = py + ph - 85
    local hovStart = mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH
    Button.draw(btnX, btnY, btnW, btnH, "새 모험 시작", true, hovStart, HUD.fL)
    Button.txtC("Enter / Space", cx, btnY + btnH + 8, P.dim, HUD.fS)
end

-- 마우스 눌림 처리
function MenuState.mousepressed(x, y, btn)
    if btn ~= 1 or not G then return end
    
    local cx = C.SW / 2
    local py = C.SH / 2 - 440 / 2 - 20
    local btnW, btnH = 200, 48
    local btnX = cx - btnW / 2
    local btnY = py + 440 - 85
    
    if x >= btnX and x <= btnX + btnW and y >= btnY and y <= btnY + btnH then
        G.phase = "play"
        G.stateMachine:change("play", G)
        Audio.play("discard")
    end
end

-- 키보드 처리
function MenuState.keypressed(key)
    if not G then return end
    if key == "return" or key == "space" then
        G.phase = "play"
        G.stateMachine:change("play", G)
        Audio.play("discard")
    end
end

return MenuState
