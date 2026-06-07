------------------------------------------------------------
-- pattern_checker.lua · 보드 위의 색친구들의 패턴(족보) 판정기
------------------------------------------------------------
local PatternChecker = {}
local C = require("core.constants")
local CharactersData = require("data.characters")

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

-- MONO: 같은 색 연속 3개 이상 검출 (덩어리 중 가장 긴 구간 1개만 적용)
function PatternChecker.checkMono(boardTable)
    local results = {}
    for _, r in ipairs(PatternChecker.getRuns(boardTable)) do
        local patternStr = string.rep(getShortName(r.color), r.length)
        local indices = {}
        for i = r.start, r.start + r.length - 1 do 
            table.insert(indices, i) 
        end
        
        if r.length >= 5 then 
            table.insert(results, {cat="MONO", name="Tower", chips=150, mult=12, pat=patternStr, idx=indices})
        elseif r.length == 4 then 
            table.insert(results, {cat="MONO", name="Half Mono", chips=60, mult=5, pat=patternStr, idx=indices})
        elseif r.length == 3 then 
            table.insert(results, {cat="MONO", name="Mini Mono", chips=30, mult=3, pat=patternStr, idx=indices})
        end
    end
    return results
end

-- MIRROR: 좌우 대칭 + 2색 이상인 경우 검출
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
        
        -- 사용된 고유 색상이 2종류 이상이어야 함
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
    
    -- 큰 거울(7개 전체) 대칭 체크
    if checkSymmetry(1, 7) then
        table.insert(results, {cat="MIRROR", name="Grand Mirror", chips=400, mult=40, pat=makePatternString(1, 7), idx=getIndices(1, 7)})
        return results
    end
    
    -- 작은 거울 (5~6개 대칭 체크)
    for length = math.min(6, n), 5, -1 do
        for start = 1, n - length + 1 do
            if checkSymmetry(start, length) then
                table.insert(results, {cat="MIRROR", name="Half Mirror", chips=100, mult=8, pat=makePatternString(start, length), idx=getIndices(start, length)})
                return results
            end
        end
    end
    
    return results
end

-- STEP: 연속된 덩어리들의 길이 계단형 패턴 검출
function PatternChecker.checkStep(boardTable)
    local results = {}
    local runs = PatternChecker.getRuns(boardTable)
    local n = boardLen(boardTable)
    local lengths = {}
    
    for _, r in ipairs(runs) do 
        table.insert(lengths, r.length) 
    end
    
    local function getFullPatternString()
        local p = ""
        for i = 1, n do 
            p = p .. getShortName(boardTable[i].name) 
        end
        return p
    end
    
    local function getAllIndices()
        local indices = {}
        for i = 1, n do 
            table.insert(indices, i) 
        end
        return indices
    end
    
    -- Perfect Ladder (1-2-3-1 혹은 1-3-2-1 형태)
    if #lengths == 4 then
        local a, b, c, d = lengths[1], lengths[2], lengths[3], lengths[4]
        if (a == 1 and b == 2 and c == 3 and d == 1) or
           (a == 1 and b == 3 and c == 2 and d == 1) then
            table.insert(results, {cat="STEP", name="Perfect Ladder", chips=300, mult=25, pat=getFullPatternString(), idx=getAllIndices()})
            return results
        end
    end
    
    -- Half Step (1-2-3 혹은 3-2-1 형태)
    for i = 1, #lengths - 2 do
        local a, b, c = lengths[i], lengths[i + 1], lengths[i + 2]
        if (a == 1 and b == 2 and c == 3) or (a == 3 and b == 2 and c == 1) then
            local startPos = 0
            for j = 1, i - 1 do 
                startPos = startPos + lengths[j] 
            end
            
            local patternStr = ""
            local indices = {}
            for j = startPos + 1, startPos + a + b + c do
                patternStr = patternStr .. getShortName(boardTable[j].name)
                table.insert(indices, j)
            end
            
            table.insert(results, {cat="STEP", name="Half Step", chips=120, mult=10, pat=patternStr, idx=indices})
            return results
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
    for _, x in ipairs(PatternChecker.checkStep(boardTable)) do 
        table.insert(detected, x) 
    end
    
    return detected
end

return PatternChecker
