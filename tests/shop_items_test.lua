package.path = "src/?.lua;src/?/init.lua;" .. package.path

local ShopItems = require("data.shop_items")

local pool = ShopItems.buildPool()
local seen = {}

for _, item in ipairs(pool) do
    assert(item.type, "shop item missing type")
    assert(item.name, "shop item missing name")
    assert(item.desc, "shop item missing desc")
    assert(item.price, "shop item missing price")
    assert(item.id ~= "time_accelerator", "time_accelerator should not be sold")
    assert(item.id ~= "time_fever", "time_fever should not be sold")
    if item.type == "joker" then
        assert(not seen[item.id], "duplicate joker id: " .. tostring(item.id))
        seen[item.id] = true
    end
end

local hasTransform = false
local hasRemoveColor = false
for _, item in ipairs(pool) do
    if item.type == "deck_transform" then hasTransform = true end
    if item.type == "deck_remove_color" then hasRemoveColor = true end
end

assert(hasTransform, "expected deck_transform item")
assert(hasRemoveColor, "expected deck_remove_color item")

print("shop_items_test ok")
