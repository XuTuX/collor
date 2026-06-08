------------------------------------------------------------
-- pattern_checker.lua · 보드 위의 색친구들의 패턴(족보) 판정기
------------------------------------------------------------
local PatternChecker = {}
local C = require("core.constants")
local CharactersData = require("data.characters")

-- 색상 등급 정의 (크레센도 판정용)
local rankMap = {
    Red = 1,
    Orange = 2,
    Yellow = 3,
    White = 4,
    Black = 5
}

-- 보드에 놓인 카드 개수 반환
local function boardLen(boardTable)
    local n = 0
    for i = 1, C.BN do
        if not boardTable[i] then break end
        n = i
    end
    return n
end

-- 색 약자 구하기 (Red -> R, Yellow -> Y 등)
local function getShortName(name)
    for _, c in ipairs(CharactersData) do
        if c.name == name then 
            return c.short 
        end
    end
    return "?"
end

-- 연속 덩어리 추출
function PatternChecker.getRuns(boardTable)
    local runs = {}
    if not boardTable[1] then return runs end
    
    local col, st, len = boardTable[1].name, 1, 1
    local n = boardLen(boardTable)
    
    for i = 2, n do
        if boardTable[i].name == col then
            len = len + 1
        else
            table.insert(runs, {color = col, start = st, length = len})
            col, st, len = boardTable[i].name, i, 1
        end
    end
    table.insert(runs, {color = col, start = st, length = len})
    return runs
end

-- MONO: 같은 색 연속 3개 이상 검출 (모든 검출 덩어리 반환)
function PatternChecker.checkMono(boardTable)
    local results = {}
    for _, r in ipairs(PatternChecker.getRuns(boardTable)) do
        if r.length >= 3 then
            local patternStr = string.rep(getShortName(r.color), r.length)
            local indices = {}
            for i = r.start, r.start + r.length - 1 do 
                table.insert(indices, i) 
            end
            table.insert(results, {cat="MONO", name="Mono", length=r.length, pat=patternStr, idx=indices})
        end
    end
    return results
end

-- MIRROR: 좌우 대칭인 패턴 검출 (최장 길이 1개만 반환)
function PatternChecker.checkMirror(boardTable)
    local results = {}
    local n = boardLen(boardTable)
    
    local function checkSymmetry(si, length)
        local ei = si + length - 1
        if ei > n then return false end
        for i = si, ei do 
            if not boardTable[i] then return false end 
        end
        
        -- 대칭 체크
        for i = 0, math.floor(length / 2) - 1 do
            if boardTable[si + i].name ~= boardTable[ei - i].name then 
                return false 
            end
        end
        
        -- 사용된 고유 색상이 2종류 이상이어야 함 (모노와의 중복 방지)
        local colorMap = {}
        local colorCount = 0
        for i = si, ei do
            local name = boardTable[i].name
            if not colorMap[name] then 
                colorMap[name] = true
                colorCount = colorCount + 1 
            end
        end
        return colorCount >= 2
    end
    
    local function makePatternString(si, length)
        local p = ""
        for i = si, si + length - 1 do 
            p = p .. getShortName(boardTable[i].name) 
        end
        return p
    end
    
    local function getIndices(si, length)
        local indices = {}
        for i = si, si + length - 1 do 
            table.insert(indices, i) 
        end
        return indices
    end
    
    -- 가장 긴 대칭부터 3개까지 역순 탐색
    for length = n, 3, -1 do
        for start = 1, n - length + 1 do
            if checkSymmetry(start, length) then
                table.insert(results, {cat="MIRROR", name="Mirror", length=length, pat=makePatternString(start, length), idx=getIndices(start, length)})
                return results
            end
        end
    end
    
    return results
end

-- TWINS: 인접 동일 색쌍 검출 (비중복 쌍 개수 카운트)
function PatternChecker.checkTwins(boardTable)
    local results = {}
    local n = boardLen(boardTable)
    if n < 2 then return results end
    
    local pairsCount = 0
    local idx = {}
    local pat = ""
    local i = 1
    
    while i < n do
        if boardTable[i] and boardTable[i+1] and boardTable[i].name == boardTable[i+1].name then
            pairsCount = pairsCount + 1
            table.insert(idx, i)
            table.insert(idx, i+1)
            pat = pat .. getShortName(boardTable[i].name) .. getShortName(boardTable[i+1].name)
            i = i + 2 -- 겹치지 않게 건너뜀
        else
            i = i + 1
        end
    end
    
    if pairsCount >= 1 then
        table.insert(results, {cat="TWINS", name="Twins", pairs=pairsCount, pat=pat, idx=idx})
    end
    
    return results
end

-- CRESCENDO: 색상 등급이 순차적으로 상승하거나 하강하는 스트레이트 패턴 (최장 길이 1개만 반환)
function PatternChecker.checkCrescendo(boardTable)
    local results = {}
    local n = boardLen(boardTable)
    if n < 3 then return results end
    
    local function checkSeq(si, length)
        local ei = si + length - 1
        if ei > n then return false end
        for i = si, ei do
            if not boardTable[i] then return false end
        end
        
        local isIncreasing = true
        local isDecreasing = true
        
        for i = si, ei - 1 do
            local r1 = rankMap[boardTable[i].name]
            local r2 = rankMap[boardTable[i+1].name]
            if not r1 or not r2 then return false end
            
            if r2 <= r1 then isIncreasing = false end
            if r2 >= r1 then isDecreasing = false end
        end
        
        return isIncreasing or isDecreasing
    end
    
    local function makePatternString(si, length)
        local p = ""
        for i = si, si + length - 1 do 
            p = p .. getShortName(boardTable[i].name) 
        end
        return p
    end
    
    local function getIndices(si, length)
        local indices = {}
        for i = si, si + length - 1 do 
            table.insert(indices, i) 
        end
        return indices
    end
    
    -- 가장 긴 연속 순서부터 3개까지 역순 탐색
    for length = n, 3, -1 do
        for start = 1, n - length + 1 do
            if checkSeq(start, length) then
                table.insert(results, {cat="CRESCENDO", name="Crescendo", length=length, pat=makePatternString(start, length), idx=getIndices(start, length)})
                return results
            end
        end
    end
    
    return results
end

-- ZIGZAG: 두 색이 번갈아가며 나타나는 교대 패턴 검출 (최장 길이 1개만 반환)
function PatternChecker.checkZigzag(boardTable)
    local results = {}
    local n = boardLen(boardTable)
    if n < 3 then return results end
    
    local function checkAlternating(si, length)
        local ei = si + length - 1
        if ei > n then return false end
        for i = si, ei do 
            if not boardTable[i] then return false end 
        end
        
        local c1 = boardTable[si].name
        local c2 = boardTable[si + 1].name
        if c1 == c2 then return false end
        
        for i = 0, length - 1 do
            local expected = (i % 2 == 0) and c1 or c2
            if boardTable[si + i].name ~= expected then
                return false
            end
        end
        return true
    end
    
    local function makePatternString(si, length)
        local p = ""
        for i = si, si + length - 1 do 
            p = p .. getShortName(boardTable[i].name) 
        end
        return p
    end
    
    local function getIndices(si, length)
        local indices = {}
        for i = si, si + length - 1 do 
            table.insert(indices, i) 
        end
        return indices
    end
    
    -- 가장 긴 지그재그부터 3개까지 역순 탐색
    for length = n, 3, -1 do
        for start = 1, n - length + 1 do
            if checkAlternating(start, length) then
                table.insert(results, {cat="ZIGZAG", name="Zigzag", length=length, pat=makePatternString(start, length), idx=getIndices(start, length)})
                return results
            end
        end
    end
    
    return results
end

-- 보드 전체 평가 및 규칙 감지 결과 수집
function PatternChecker.evaluate(boardTable)
    local detected = {}
    
    for _, x in ipairs(PatternChecker.checkMono(boardTable)) do 
        table.insert(detected, x) 
    end
    for _, x in ipairs(PatternChecker.checkMirror(boardTable)) do 
        table.insert(detected, x) 
    end
    for _, x in ipairs(PatternChecker.checkCrescendo(boardTable)) do 
        table.insert(detected, x) 
    end
    for _, x in ipairs(PatternChecker.checkTwins(boardTable)) do 
        table.insert(detected, x) 
    end
    for _, x in ipairs(PatternChecker.checkZigzag(boardTable)) do 
        table.insert(detected, x) 
    end
    
    return detected
end

return PatternChecker
