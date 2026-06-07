------------------------------------------------------------
-- detect.lua · 색 규칙 판정
------------------------------------------------------------
local C = require("config")
local D = {}

local function boardLen(b)
    local n = 0
    for i = 1, C.BN do
        if not b[i] then break end
        n = i
    end
    return n
end

-- 연속 덩어리 추출
function D.getRuns(b)
    local runs = {}
    if not b[1] then return runs end
    local col, st, len = b[1].name, 1, 1
    local n = boardLen(b)
    for i = 2, n do
        if b[i].name == col then
            len = len + 1
        else
            table.insert(runs, {color=col, start=st, length=len})
            col, st, len = b[i].name, i, 1
        end
    end
    table.insert(runs, {color=col, start=st, length=len})
    return runs
end

-- 색 약자
local function sh(name)
    for _, c in ipairs(C.COLORS) do
        if c.name == name then return c.short end
    end
    return "?"
end

-- MONO: 같은 색 연속 3+, 구간별 최고만
function D.mono(b)
    local h = {}
    for _, r in ipairs(D.getRuns(b)) do
        local s = string.rep(sh(r.color), r.length)
        local idx = {}
        for i = r.start, r.start + r.length - 1 do table.insert(idx, i) end
        if     r.length >= 5 then table.insert(h, {cat="MONO", name="Tower",     chips=150, mult=12, pat=s, idx=idx})
        elseif r.length == 4 then table.insert(h, {cat="MONO", name="Half Mono", chips=60,  mult=5,  pat=s, idx=idx})
        elseif r.length == 3 then table.insert(h, {cat="MONO", name="Mini Mono", chips=30,  mult=3,  pat=s, idx=idx})
        end
    end
    return h
end

-- MIRROR: 좌우 대칭 + 2색 이상
function D.mirror(b)
    local h = {}
    local n = boardLen(b)
    local function chk(si, len)
        local ei = si + len - 1
        if ei > n then return false end
        for i = si, ei do if not b[i] then return false end end
        for i = 0, math.floor(len/2) - 1 do
            if b[si+i].name ~= b[ei-i].name then return false end
        end
        local cs, cn = {}, 0
        for i = si, ei do
            if not cs[b[i].name] then cs[b[i].name] = true; cn = cn + 1 end
        end
        return cn >= 2
    end
    local function pat(si, len)
        local p = ""
        for i = si, si + len - 1 do p = p .. sh(b[i].name) end
        return p
    end
    local function getIdx(si, len)
        local idx = {}
        for i = si, si + len - 1 do table.insert(idx, i) end
        return idx
    end
    -- 큰 거울은 7개 전체가 대칭일 때만
    if chk(1, 7) then
        table.insert(h, {cat="MIRROR", name="Grand Mirror", chips=400, mult=40, pat=pat(1,7), idx=getIdx(1,7)})
        return h
    end
    for len = math.min(6, n), 5, -1 do
        for st = 1, n - len + 1 do
            if chk(st, len) then
                table.insert(h, {cat="MIRROR", name="Half Mirror", chips=100, mult=8, pat=pat(st,len), idx=getIdx(st,len)})
                return h
            end
        end
    end
    return h
end

-- STEP: 덩어리 길이 패턴
function D.step(b)
    local h = {}
    local runs = D.getRuns(b)
    local n = boardLen(b)
    local lens = {}
    for _, r in ipairs(runs) do table.insert(lens, r.length) end
    local function fullPat()
        local p = ""
        for i = 1, n do p = p .. sh(b[i].name) end
        return p
    end
    local function getIdxAll()
        local idx = {}
        for i = 1, n do table.insert(idx, i) end
        return idx
    end
    -- Perfect Ladder (1-2-3-1 or 1-3-2-1) 우선
    if #lens == 4 then
        local a, b2, c, d = lens[1], lens[2], lens[3], lens[4]
        if (a==1 and b2==2 and c==3 and d==1) or
           (a==1 and b2==3 and c==2 and d==1) then
            table.insert(h, {cat="STEP", name="Perfect Ladder", chips=300, mult=25, pat=fullPat(), idx=getIdxAll()})
            return h
        end
    end
    -- Half Step (1-2-3 or 3-2-1)
    for i = 1, #lens - 2 do
        local a, b2, c = lens[i], lens[i+1], lens[i+2]
        if (a==1 and b2==2 and c==3) or (a==3 and b2==2 and c==1) then
            local sp = 0
            for j = 1, i-1 do sp = sp + lens[j] end
            local p = ""
            local idx = {}
            for j = sp+1, sp + a + b2 + c do 
                p = p .. sh(b[j].name)
                table.insert(idx, j)
            end
            table.insert(h, {cat="STEP", name="Half Step", chips=120, mult=10, pat=p, idx=idx})
            return h
        end
    end
    return h
end

-- 전체 평가
function D.evaluate(b)
    local all = {}
    for _, x in ipairs(D.mono(b))   do table.insert(all, x) end
    for _, x in ipairs(D.mirror(b)) do table.insert(all, x) end
    for _, x in ipairs(D.step(b))   do table.insert(all, x) end
    return all
end

-- 점수 계산 (발라트로식)
function D.calcScore(hands)
    if #hands == 0 then return 0 end
    local tc, tm = 0, 0
    for _, h in ipairs(hands) do tc = tc + h.chips; tm = tm + h.mult end
    return tc * tm
end

return D
