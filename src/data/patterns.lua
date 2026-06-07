------------------------------------------------------------
-- patterns.lua · 족보 규칙 템플릿 및 표시 이름
------------------------------------------------------------
local Patterns = {}

-- 각 색 규칙(족보)의 1레벨 기본 스탯 및 레벨업 시 스케일 비율
Patterns.handStatsTemplate = {
    ["Mini Mono"]      = {level=1, chips=30,  mult=3,  scaleChips=15, scaleMult=1.5},
    ["Half Mono"]      = {level=1, chips=60,  mult=5,  scaleChips=25, scaleMult=2.0},
    ["Tower"]          = {level=1, chips=150, mult=12, scaleChips=40, scaleMult=3.0},
    ["Half Mirror"]    = {level=1, chips=100, mult=8,  scaleChips=30, scaleMult=2.5},
    ["Grand Mirror"]   = {level=1, chips=400, mult=40, scaleChips=80, scaleMult=8.0},
    ["Half Step"]      = {level=1, chips=120, mult=10, scaleChips=35, scaleMult=3.0},
    ["Perfect Ladder"] = {level=1, chips=300, mult=25, scaleChips=60, scaleMult=5.0},
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
