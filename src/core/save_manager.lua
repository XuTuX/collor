------------------------------------------------------------
-- save_manager.lua · 세이브/로드 파일 매니저
------------------------------------------------------------
local SaveManager = {}
local SAVE_FILE = "collor_save.lua"

local function serialize(value, indent)
    indent = indent or ""
    local t = type(value)
    if t == "number" or t == "boolean" then
        return tostring(value)
    elseif t == "string" then
        return string.format("%q", value)
    elseif t == "table" then
        local nextIndent = indent .. "    "
        local parts = {"{"}
        for k, v in pairs(value) do
            local key
            if type(k) == "string" and string.match(k, "^[%a_][%w_]*$") then
                key = k
            else
                key = "[" .. serialize(k, nextIndent) .. "]"
            end
            table.insert(parts, "\n" .. nextIndent .. key .. " = " .. serialize(v, nextIndent) .. ",")
        end
        table.insert(parts, "\n" .. indent .. "}")
        return table.concat(parts)
    end
    return "nil"
end

-- 게임 데이터 저장
function SaveManager.save(gameData)
    if not love or not love.filesystem then
        return false, "love.filesystem unavailable"
    end
    local content = "return " .. serialize(gameData or {})
    return love.filesystem.write(SAVE_FILE, content)
end

-- 게임 데이터 로드
function SaveManager.load()
    if not love or not love.filesystem or not love.filesystem.getInfo(SAVE_FILE) then
        return nil
    end
    local chunk, err = love.filesystem.load(SAVE_FILE)
    if not chunk then
        return nil, err
    end
    local ok, data = pcall(chunk)
    if not ok then
        return nil, data
    end
    return data
end

return SaveManager
