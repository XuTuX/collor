------------------------------------------------------------
-- debug.lua · 디버깅 툴 및 테스트 시나리오 보드 셋업
------------------------------------------------------------
local Debug = {}

-- 디버그를 위한 테스트 보드 생성 함수
function Debug.setupTestBoard(gameInstance, testCaseIndex)
    if testCaseIndex == 1 then
        -- 테스트 1: Tower  → 150×12 = 1800
        gameInstance.board = {
            {name="Red",color={.92,.22,.25}},{name="Red",color={.92,.22,.25}},
            {name="Red",color={.92,.22,.25}},{name="Red",color={.92,.22,.25}},
            {name="Red",color={.92,.22,.25}},{name="Orange",color={.95,.55,.15}},
            {name="Yellow",color={.95,.85,.15}},
        }
    elseif testCaseIndex == 2 then
        -- 테스트 2: Grand Mirror → 400×40 = 16000
        gameInstance.board = {
            {name="Red",color={.92,.22,.25}},{name="Orange",color={.95,.55,.15}},
            {name="Yellow",color={.95,.85,.15}},{name="White",color={.94,.94,.96}},
            {name="Yellow",color={.95,.85,.15}},{name="Orange",color={.95,.55,.15}},
            {name="Red",color={.92,.22,.25}},
        }
    elseif testCaseIndex == 3 then
        -- 테스트 3: Perfect Ladder + Mini Mono → (300+30)×(25+3) = 9240
        gameInstance.board = {
            {name="Red",color={.92,.22,.25}},{name="Orange",color={.95,.55,.15}},
            {name="Orange",color={.95,.55,.15}},{name="Yellow",color={.95,.85,.15}},
            {name="Yellow",color={.95,.85,.15}},{name="Yellow",color={.95,.85,.15}},
            {name="Black",color={.12,.12,.16}},
        }
    end
end

return Debug
