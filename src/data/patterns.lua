------------------------------------------------------------
-- patterns.lua · 족보 규칙 템플릿 및 표시 이름
------------------------------------------------------------
local Patterns = {}

-- 각 색 규칙(족보)의 1레벨 기본 스탯 및 레벨업 시 스케일 비율
Patterns.handStatsTemplate = {
    ["Mini Mono"]      = {level=1, chips=40,  mult=4,  scaleChips=20, scaleMult=2.0},
    ["Half Mono"]      = {level=1, chips=80,  mult=6,  scaleChips=30, scaleMult=2.5},
    ["Tower"]          = {level=1, chips=200, mult=15, scaleChips=50, scaleMult=4.0},
    ["Half Mirror"]    = {level=1, chips=150, mult=10, scaleChips=40, scaleMult=3.0},
    ["Grand Mirror"]   = {level=1, chips=500, mult=50, scaleChips=100, scaleMult=10.0},
    ["Half Step"]      = {level=1, chips=180, mult=12, scaleChips=45, scaleMult=4.0},
    ["Perfect Ladder"] = {level=1, chips=400, mult=30, scaleChips=80, scaleMult=6.0},
}

Patterns.RULE_NAMES = {
    ["Mini Mono"] = "세 친구",
    ["Half Mono"] = "네 친구",
    ["Tower"] = "색 탑",
    ["Half Mirror"] = "작은 거울",
    ["Grand Mirror"] = "큰 거울",
    ["Half Step"] = "작은 계단",
    ["Perfect Ladder"] = "무지개 계단",
}

Patterns.CAT_NAMES = {
    MONO = "같은색",
    MIRROR = "거울",
    STEP = "계단",
}

return Patterns
