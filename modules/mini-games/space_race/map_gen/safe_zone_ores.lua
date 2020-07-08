local b = require 'utils.map_gen.builders'
local Random = require 'utils.map_gen.random'
local Global = require 'utils.global'
local MS = require 'utils.map_gen.minigame_surface'

local Map_gen_config = (require 'config.mini_games.space_race').map_gen

local seed = nil -- set to number to force seed
local seed_2 = nil -- set to number to force seed

local width_2 = Map_gen_config.width_2

local pic = require 'modules.mini-games.space_race.map_gen.life'
pic = b.decompress(pic)

local life_shape = b.picture(pic)
life_shape = b.scale(life_shape, 0.05, 0.05)

local function value(base, mult, pow)
    return function(x, y)
        local d = math.sqrt(x * x + y * y)
        return base + mult * d ^ pow
    end
end

local function non_transform(shape)
    return shape
end

local ores = {
    {weight = 275},
    {transform = non_transform, resource = 'iron-ore', value = value(500, 0.75, 1.2), weight = 12},
    {transform = non_transform, resource = 'copper-ore', value = value(400, 0.75, 1.2), weight = 10},
    {transform = non_transform, resource = 'stone', value = value(250, 0.3, 1.05), weight = 3},
    {transform = non_transform, resource = 'coal', value = value(400, 0.8, 1.075), weight = 8}
}

local total_ore_weights = {}
local ore_t = 0
for _, v in ipairs(ores) do
    ore_t = ore_t + v.weight
    table.insert(total_ore_weights, ore_t)
end

local random_ore = Random.new(seed, seed_2)
local ore_pattern = {}

local p_cols = width_2
local p_rows = 32

for r = 1, p_rows do
    local row = {}
    ore_pattern[r] = row
    for c = 1, p_cols do
        local i = random_ore:next_int(1, ore_t)
        local index = table.binary_search(total_ore_weights, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end
        local ore_data = ores[index]

        local transform = ore_data.transform
        if not transform then
            row[c] = b.no_entity
        else
            local ore_shape = transform(life_shape)

            local x = random_ore:next_int(-16, 16)
            local y = random_ore:next_int(-16, 16)
            ore_shape = b.translate(ore_shape, x, y)
            ore_shape = b.resource(ore_shape, ore_data.resource, ore_data.value, true)
            row[c] = ore_shape
        end
    end
end

local mirrored_ore = b.grid_pattern_full_overlap(ore_pattern, p_cols, p_rows, 48, 48)

local primitives = {}
local function on_init()
    primitives.seed = seed or MS.get_surface().map_gen_settings.seed
    primitives.seed_2 = seed_2 or primitives.seed * 2
end

Global.register(primitives, function(tbl)
    seed = tbl.seed
    seed_2 = tbl.seed_2
end)

return { shape = mirrored_ore, on_init = on_init }
