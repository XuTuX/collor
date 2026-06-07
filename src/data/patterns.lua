------------------------------------------------------------
-- patterns.lua · 족보 규칙 템플릿 및 표시 이름
------------------------------------------------------------
local Patterns = {}

-- 각 색 규칙(족보)의 1레벨 기본 스탯 및 레벨업 시 스케일 비율
Patterns.handStatsTemplate = {
    ["Mini Mono"]      = {level=1, chips=30,  mult=3,  scaleChips=15, scaleMult=1.0},
    ["Half Mono"]      = {level=1, chips=50,  mult=4,  scaleChips=20, scaleMult=1.5},
    ["Tower"]          = {level=1, chips=80,  mult=6,  scaleChips=30, scaleMult=2.0},
    ["Half Mirror"]    = {level=1, chips=60,  mult=5,  scaleChips=25, scaleMult=1.5},
    ["Grand Mirror"]   = {level=1, chips=120, mult=10, scaleChips=40, scaleMult=3.0},
    ["Half Step"]      = {level=1, chips=70,  mult=5,  scaleChips=25, scaleMult=1.5},
    ["Perfect Ladder"] = {level=1, chips=150, mult=12, scaleChips=50, scaleMult=3.5},
    ["Double Twins"]   = {level=1, chips=45,  mult=4,  scaleChips=20, scaleMult=1.0},
    ["Triple Twins"]   = {level=1, chips=100, mult=8,  scaleChips=35, scaleMult=2.0},
    ["Mini Zigzag"]    = {level=1, chips=65,  mult=5,  scaleChips=25, scaleMult=1.5},
    ["Grand Zigzag"]   = {level=1, chips=180, mult=14, scaleChips=60, scaleMult=4.0},
}

Patterns.RULE_NAMES = {
    ["Mini Mono"] = "세 친구",
    ["Half Mono"] = "네 친구",
    ["Tower"] = "색 탑",
    ["Half Mirror"] = "작은 거울",
    ["Grand Mirror"] = "큰 거울",
    ["Half Step"] = "작은 계단",
    ["Perfect Ladder"] = "무지개 계단",
    ["Double Twins"] = "쌍둥이",
    ["Triple Twins"] = "세 쌍둥이",
    ["Mini Zigzag"] = "작은 지그재그",
    ["Grand Zigzag"] = "큰 지그재그",
}

Patterns.CAT_NAMES = {
    MONO = "같은색",
    MIRROR = "거울",
    STEP = "계단",
    TWINS = "쌍둥이",
    ZIGZAG = "지그재그",
}

return Patterns
