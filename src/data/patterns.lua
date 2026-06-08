------------------------------------------------------------
-- patterns.lua · 족보 규칙 템플릿 및 표시 이름
------------------------------------------------------------
local Patterns = {}

-- 각 색 규칙(족보)의 1레벨 기본 스탯 및 레벨업 시 스케일 비율
Patterns.handStatsTemplate = {
    ["Mono"]      = {level=1, chips=30,  mult=3,  scaleChips=15, scaleMult=1.0},
    ["Mirror"]    = {level=1, chips=40,  mult=4,  scaleChips=20, scaleMult=1.5},
    ["Twins"]     = {level=1, chips=25,  mult=2.5, scaleChips=12, scaleMult=1.0},
    ["Crescendo"] = {level=1, chips=50,  mult=5,  scaleChips=25, scaleMult=2.0},
    ["Zigzag"]    = {level=1, chips=35,  mult=3.5, scaleChips=18, scaleMult=1.2},
}

Patterns.RULE_NAMES = {
    ["Mono"]      = "모노",
    ["Mirror"]    = "대칭",
    ["Twins"]     = "쌍둥이",
    ["Crescendo"] = "크레센도",
    ["Zigzag"]    = "지그재그",
}

Patterns.CAT_NAMES = {
    MONO = "모노",
    MIRROR = "대칭",
    TWINS = "쌍둥이",
    CRESCENDO = "크레센도",
    ZIGZAG = "지그재그",
}

return Patterns
