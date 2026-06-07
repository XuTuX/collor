------------------------------------------------------------
-- state_machine.lua · 게임 화면(씬) 상태 전환 관리자
------------------------------------------------------------
local StateMachine = {}
StateMachine.__index = StateMachine

-- 상태 맵을 받아 머신 생성
function StateMachine.new(states)
    local sm = {
        states = states or {},
        current = nil,
        currentName = "none"
    }
    return setmetatable(sm, StateMachine)
end

-- 특정 상태로 전환 (이전 상태 exit 후 신규 상태 enter)
function StateMachine:change(stateName, ...)
    if self.current and self.current.exit then
        self.current.exit()
    end
    
    self.current = self.states[stateName]
    self.currentName = stateName
    
    if self.current and self.current.enter then
        self.current.enter(...)
    end
end

-- 주기적인 프레임 업데이트 전파
function StateMachine:update(dt)
    if self.current and self.current.update then
        self.current.update(dt)
    end
end

-- 화면 그리기(렌더링) 이벤트 전파
function StateMachine:draw()
    if self.current and self.current.draw then
        self.current.draw()
    end
end

-- 마우스 눌림 이벤트 전파
function StateMachine:mousepressed(x, y, button)
    if self.current and self.current.mousepressed then
        self.current.mousepressed(x, y, button)
    end
end

-- 마우스 떼어짐 이벤트 전파
function StateMachine:mousereleased(x, y, button)
    if self.current and self.current.mousereleased then
        self.current.mousereleased(x, y, button)
    end
end

-- 키보드 눌림 이벤트 전파
function StateMachine:keypressed(key)
    if self.current and self.current.keypressed then
        self.current.keypressed(key)
    end
end

return StateMachine
