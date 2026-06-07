------------------------------------------------------------
-- save_manager.lua · 세이브/로드 파일 매니저 (확장용 스텁)
------------------------------------------------------------
local SaveManager = {}

-- 게임 데이터 저장 스텁
function SaveManager.save(gameData)
    -- TODO: 세이브 파일 IO 구현
    return true
end

-- 게임 데이터 로드 스텁
function SaveManager.load()
    -- TODO: 세이브 파일 로드 구현
    return nil
end

return SaveManager
