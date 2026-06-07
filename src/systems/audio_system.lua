------------------------------------------------------------
-- audio_system.lua · 절차적 오디오 합성기 (리소스 프리 효과음)
------------------------------------------------------------
local AudioSystem = {}
local sources = {}

-- 헬퍼: 빔/스윕 효과음 데이터 생성
local function createSweep(fStart, fEnd, duration, type, volume)
    local rate = 44100
    local length = math.floor(rate * duration)
    local soundData = love.sound.newSoundData(length, rate, 16, 1)
    local phase = 0
    
    for i = 0, length - 1 do
        local t = i / rate
        local f = fStart + (fEnd - fStart) * (t / duration)
        phase = phase + f / rate
        local p = phase % 1
        local val = 0
        
        if type == "sine" then
            val = math.sin(p * 2 * math.pi)
        elseif type == "triangle" then
            val = math.abs(p - 0.5) * 4 - 1
        elseif type == "square" then
            val = p >= 0.5 and 0.5 or -0.5
        elseif type == "noise" then
            val = love.math.random() * 2 - 1
        end
        
        -- 페이드아웃 엔벨로프
        local env = 1 - t / duration
        soundData:setSample(i, val * env * (volume or 0.25))
    end
    
    return love.audio.newSource(soundData)
end

-- 헬퍼: 화음 효과음 데이터 생성
local function createChord(freqs, duration, type, volume)
    local rate = 44100
    local length = math.floor(rate * duration)
    local soundData = love.sound.newSoundData(length, rate, 16, 1)
    local phases = {}
    for i = 1, #freqs do phases[i] = 0 end
    
    for i = 0, length - 1 do
        local t = i / rate
        local val = 0
        for idx, freq in ipairs(freqs) do
            phases[idx] = phases[idx] + freq / rate
            local p = phases[idx] % 1
            if type == "sine" then
                val = val + math.sin(p * 2 * math.pi)
            elseif type == "triangle" then
                val = val + (math.abs(p - 0.5) * 4 - 1)
            elseif type == "square" then
                val = val + (p >= 0.5 and 0.5 or -0.5)
            end
        end
        val = val / #freqs
        
        -- 페이드아웃 엔벨로프
        local env = 1 - t / duration
        soundData:setSample(i, val * env * (volume or 0.2))
    end
    
    return love.audio.newSource(soundData)
end

-- 효과음 사전 생성
function AudioSystem.init()
    -- 1. 색친구 선택 (짧은 고음 사인파)
    sources.select = createSweep(400, 700, 0.07, "sine", 0.12)
    -- 2. 색친구 적용 (짧고 묵직한 삼각파)
    sources.place = createSweep(350, 150, 0.10, "triangle", 0.18)
    -- 3. 회수 / 언두 (올라가는 사인파)
    sources.recall = createSweep(200, 500, 0.08, "sine", 0.15)
    -- 4. 바꾸기 / 섞기 (노이즈 스윕)
    sources.discard = createSweep(300, 100, 0.22, "noise", 0.10)
    -- 5. 스코어 카운트 틱 (극도로 짧은 고정 고음)
    sources.tick = createSweep(1000, 1000, 0.02, "sine", 0.08)
    -- 6. 색 규칙 노출 (중간 길이 삼각파 스윕)
    sources.reveal = createSweep(300, 600, 0.14, "triangle", 0.12)
    -- 7. 관문 통과 (C 메이저 화음)
    sources.clear = createChord({261.63, 329.63, 392.00, 523.25}, 0.55, "sine", 0.15)
    -- 8. 게임 오버 (G 마이너 어두운 화음)
    sources.gameover = createChord({196.00, 233.08, 293.66}, 0.85, "triangle", 0.15)
end

-- 효과음 재생
function AudioSystem.play(name)
    local src = sources[name]
    if src then
        local clone = src:clone()
        clone:play()
    end
end

return AudioSystem
