------------------------------------------------------------
-- main.lua · Love2D 콜백을 게임 코어 FSM으로 라우팅하는 얇은 진입점
------------------------------------------------------------
local Game = require("core.game")

-- 초기 로드
function love.load()
    Game.init()
    Game.reset()
end

-- 매 프레임 업데이트
function love.update(dt)
    Game.update(dt)
end

-- 화면 렌더링
function love.draw()
    Game.stateMachine:draw()
end

-- 마우스 클릭 입력 전달
function love.mousepressed(x, y, button)
    Game.mousepressed(x, y, button)
end

-- 마우스 떼어짐 입력 전달
function love.mousereleased(x, y, button)
    Game.mousereleased(x, y, button)
end

-- 키보드 입력 전달
function love.keypressed(key)
    Game.keypressed(key)
end
