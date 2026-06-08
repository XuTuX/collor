package.path = "src/?.lua;src/?/init.lua;" .. package.path

local PatternChecker = require("gameplay.pattern_checker")
local RuleEngine = require("gameplay.rule_engine")
local Patterns = require("data.patterns")

local function card(name)
    return {name = name, color = {1, 1, 1}}
end

local function hasCat(results, cat)
    for _, r in ipairs(results) do
        if r.cat == cat then return true, r end
    end
    return false, nil
end

local function freshStats()
    local stats = {}
    for name, v in pairs(Patterns.handStatsTemplate) do
        stats[name] = {
            level = v.level,
            chips = v.chips,
            mult = v.mult,
            scaleChips = v.scaleChips,
            scaleMult = v.scaleMult
        }
    end
    return stats
end

local monoBoard = {
    card("Red"), card("Red"), card("Red"),
    card("Orange"), card("Yellow"), card("White"), card("Black")
}
local mono = PatternChecker.evaluate(monoBoard)
assert(hasCat(mono, "MONO"))

local mirrorBoard = {
    card("Red"), card("Orange"), card("Yellow"), card("Orange"), card("Red")
}
local mirror = PatternChecker.evaluate(mirrorBoard)
assert(hasCat(mirror, "MIRROR"))

local crescendoBoard = {
    card("Red"), card("Orange"), card("Yellow"), card("White"), card("Black")
}
local crescendo = PatternChecker.evaluate(crescendoBoard)
local ok, rule = hasCat(crescendo, "CRESCENDO")
assert(ok)
RuleEngine.applyStatsAndGimmicks(crescendo, freshStats(), 1, "none")
assert(rule.chips > 0)
assert(rule.mult > 0)

local bossBlocked = PatternChecker.evaluate(monoBoard)
RuleEngine.applyStatsAndGimmicks(bossBlocked, freshStats(), 3, "no_red")
local _, blockedRule = hasCat(bossBlocked, "MONO")
assert(blockedRule.chips == 0)
assert(blockedRule.mult == 0)

print("pattern_checker_test ok")
