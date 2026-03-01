-----Init
everywhere_categories = {}
moev_profile = {}
local split_pattern = "[^%s,]+"
local setting_cat_value = settings.startup["moev-allow-cat"].value
local setting_profile_value = settings.startup["moev-profile"].value

for setpro in setting_profile_value:gmatch(split_pattern) do
  table.insert(moev_profile,tonumber(setpro))
end

-----Get categories
for setcat in setting_cat_value:gmatch(split_pattern) do
  table.insert(everywhere_categories,setcat)
end

if mods["space-age"] then
    table.insert(everywhere_categories,"quality")
end

if settings.startup["moev-allow-catmax"].value then
  everywhere_categories = {}
  for _, category in pairs(data.raw["module-category"]) do
    table.insert(everywhere_categories,category.name)
  end
end


-----Get effects
everywhere_effects = {"consumption", "speed", "pollution", "productivity"}

if feature_flags["quality"] then
  table.insert(everywhere_effects, "quality")
end

-----Entity level restrictions
local machinetypes = {
  beac = "beacon",
  asem = "assembling-machine",
  silo = "rocket-silo",
  furn = "furnace",
  lab = "lab",
  dril = "mining-drill"
}

for shorthand,mtype in pairs(machinetypes) do
  if settings.startup["moev-allow-entity"].value and settings.startup["moev-allow-"..shorthand].value then
    for _,entity in pairs(data.raw[mtype]) do
      entity.allowed_effects = everywhere_effects

      --Don't disturb the surface property
      if settings.startup["moev-allow-surface"].value then
        entity.effect_receiver = {uses_module_effects=true, uses_beacon_effects = true, uses_surface_effects = true}
      else
        if entity.effect_receiver == nil then
          entity.effect_receiver = {}
        end
        entity.effect_receiver.uses_module_effects=true
        entity.effect_receiver.uses_beacon_effects=true
      end

      --Get already there
      t_table = entity.allowed_module_categories
      if t_table == nil then
        t_table = {}
      end
      local existing = {}
      for _, cat in ipairs(t_table) do
        existing[cat] = true
      end
      --If not already there, add it!
      for _, category in ipairs(everywhere_categories) do
        if not existing[category] then
          t_table[#t_table+1]=category
        end
      end

      --Extra module (needed?)
      if settings.startup["moev-module-extra"].value ~= 0 then
        if entity.module_slots == nil then
          entity.module_slots = 0
        end
        entity.module_slots = entity.module_slots + settings.startup["moev-module-extra"].value
      end

      --Beacon profiles
      if mtype == "beacon" then
        entity.profile = moev_profile
        entity.beacon_counter = settings.startup["moev-counter"].value
      end
    end
  end
end


-----Recipe level restrictions

if settings.startup["moev-allow-recipe"].value then
  for _, recipe in pairs(data.raw.recipe) do
    recipe.allow_consumption = true
    recipe.allow_speed = true
    recipe.allow_productivity = true
    recipe.allow_pollution = true
    recipe.allow_quality = true
    recipe.allowed_module_categories = nil
  end
end

-----Set maximum productivity
if settings.startup["moev-maximum-productivity"].value ~= 0 then
  for _, recipe in pairs(data.raw.recipe) do
    if recipe.allow_productivity == true then
      recipe.maximum_productivity = settings.startup["moev-maximum-productivity"].value
    end
  end
end

-----Fix Beacon display/Graphics for Productivity & Quality Modules

local vanilla_productivity = {
  t1 = "productivity-module",
  t2 = "productivity-module-2",
  t3 = "productivity-module-3"
}

local vanilla_quality = {
  t1 = "quality-module",
  t2 = "quality-module-2",
  t3 = "quality-module-3"
}

for _,name in pairs(vanilla_productivity) do
  data.raw.module[name].beacon_tint = {primary = {r=1,g=0.463,b=0.322,a=1}, secondary = {r=1,g=0.976,b=0.388,a=1}}
  data.raw.module[name].art_style = "vanilla"
  data.raw.module[name].requires_beacon_alt_mode = false
end

if mods["space-age"] then
  for _,name in pairs(vanilla_quality) do
    data.raw.module[name].beacon_tint = {primary = {r=0.95,g=0.95,b=0.95,a=1}, secondary = {r=1,g=0.05,b=0.05,a=1}}
    data.raw.module[name].art_style = "vanilla"
    data.raw.module[name].requires_beacon_alt_mode = false
  end
end
