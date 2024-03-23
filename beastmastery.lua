local bxhnz7tp5bge7wvu = bxhnz7tp5bge7wvu_interface
local SB = spellbook

local flare_up = false
local tar_trap_up = false
local wild_spirits_up = false

local function haste_mod()
  local haste = UnitSpellHaste("player")
  return 1 + haste / 100
end

local function gcd_duration()
  return 1.5 / haste_mod()
end

local function cost(spell)
  return GetSpellPowerCost(spell)[1].cost
end

local function has_buff_to_steal_or_purge(unit)
  local has_buffs = false
  for i=1,32 do 
    local name,_,_,_,_,_,_,can_steal_or_purge = UnitAura(unit.unitID, i)
    if name and can_steal_or_purge then
      has_buffs = true
      break
    end
  end
  return has_buffs
end

local function flare_overlay()
  if flare_up then
    SpellActivationOverlay_ShowOverlay(SpellActivationOverlayFrame, SB.Flare, 962497, "LEFT", 1, 255, 255, 255, false, false)
  else
    SpellActivationOverlay_HideOverlays(SpellActivationOverlayFrame, SB.Flare)
  end
end

local function tar_trap_overlay()
  if tar_trap_up then
    SpellActivationOverlay_ShowOverlay(SpellActivationOverlayFrame, SB.TarTrap, 450923, "BOTTOM", 1, 255, 255, 255, true, false)
  else
    SpellActivationOverlay_HideOverlays(SpellActivationOverlayFrame, SB.TarTrap)
  end
end

local function wild_spirits_overlay()
  if wild_spirits_up then
    SpellActivationOverlay_ShowOverlay(SpellActivationOverlayFrame, SB.WildSpirits, 592058, "RIGHT", 1, 255, 255, 255, false, true)
  else
    SpellActivationOverlay_HideOverlays(SpellActivationOverlayFrame, SB.WildSpirits)
  end
end

local function combat() 
  if not player.alive then return end
  
  local pet_attack_focus = bxhnz7tp5bge7wvu.settings.fetch('bm_nikopol_pet_attack_focus', false)
  local pet_target = target
  if pet_attack_focus and focus.exists and focus.alive then pet_target = focus end
  
  local interrupt_focus = bxhnz7tp5bge7wvu.settings.fetch('bm_nikopol_interrupt_focus', false)
  local interrupt_target = target
  if interrupt_focus and focus.exists and focus.alive then interrupt_target = focus end
  
  local purge_focus = bxhnz7tp5bge7wvu.settings.fetch('bm_nikopol_purge_focus', false)
  local purge_target = target
  if purge_focus and focus.exists and focus.alive then purge_target = focus end
  
  local soulforge_embers = toggle('soulforge_embers', false)
  
  flare_overlay()
  flare_up = false
  
  tar_trap_overlay()
  tar_trap_up = false
  
  wild_spirits_overlay()
  wild_spirits_up = false
  
  if GetCVar("nameplateShowEnemies") == '0' then
    SetCVar("nameplateShowEnemies", 1)
  end
  
  local enemies_in_combat_within_same_range_as_target = enemies.count(function (unit)
    return unit.alive and unit.combat and unit.distance == target.distance
  end)

  macro('/cqs')
    
  if GetItemCooldown(5512) == 0 and player.health.effective < 30 then
    macro('/use Healthstone')
  end
  
  if castable(SB.Exhilaration) and player.health.effective < 20 then
    return cast(SB.Exhilaration)
  end
  
  local function use_items()
    local trinket_13 = bxhnz7tp5bge7wvu.settings.fetch('bm_nikopol_trinket_13', false)
    local trinket_14 = bxhnz7tp5bge7wvu.settings.fetch('bm_nikopol_trinket_14', false)
    
    local start, duration, enable = GetInventoryItemCooldown("player", 13)
    if trinket_13 and enable == 1 and start == 0 then
      return macro('/use 13')
    end
    
    start, duration, enable = GetInventoryItemCooldown("player", 14)
    if trinket_14 and enable == 1 and start == 0 then
      return macro('/use 14')
    end
  end
  
  local function cds()
    if castable(SB.Berserking) and target.debuff(SB.WildMark).up then
      cast(SB.Berserking)
    end
  end
  
  local function cleave()
    if pet.exists and pet.alive and castable(SB.AspectoftheWild) and toggle('cooldowns', false) then
      cast(SB.AspectoftheWild)
    end
    
    if castable(SB.BarbedShot) and pet.buff(SB.Frenzy).up and pet.buff(SB.Frenzy).remains <= gcd_duration() then
      return cast(SB.BarbedShot, target)
    end
    
    if castable(SB.MultiShot) and gcd_duration() - pet.buff(SB.BeastCleave).remains > 0.25 then
      return cast(SB.MultiShot, target)
    end

    if castable(SB.TarTrap) then
      if modifier.lshift or soulforge_embers then
        return cast(SB.TarTrap, "ground")
      else
        tar_trap_up = true
      end
    end

    if castable(SB.WildSpirits) and toggle('cooldowns', false) then
      if modifier.lshift then
        return cast(SB.WildSpirits, "ground")
      else
        wild_spirits_up = true
      end
    end
    
    if castable(SB.BarbedShot) and ((spell(SB.BarbedShot).full_recharge_time < gcd_duration() and spell(SB.BestialWrath).cooldown > 0) or (spell(SB.BestialWrath).cooldown < 12 + gcd_duration() and talent(2,1))) then
      return cast(SB.BarbedShot, target)
    end
    
    if pet.exists and pet.alive and castable(SB.BestialWrath) and player.buff(SB.BestialWrath).down and toggle('cooldowns', false) then
      return cast(SB.BestialWrath)
    end
--actions.cleave+=/stampede,if=buff.aspect_of_the_wild.up|target.time_to_die<15
    
    if castable(SB.KillShot) then
      return cast(SB.KillShot, target)
    end
    
--actions.cleave+=/chimaera_shot
    
    if pet.exists and pet.alive and castable(SB.Bloodshed) and pet_target.distance <= 50 then
      return cast(SB.Bloodshed, pet_target)
    end
    
--actions.cleave+=/a_murder_of_crows
--actions.cleave+=/barrage,if=pet.main.buff.frenzy.remains>execute_time
    
    if pet.exists and pet.alive and castable(SB.KillCommand) and player.power.focus.actual > cost(SB.KillCommand) + cost(SB.MultiShot) and pet_target.distance <= 50 then
      return cast(SB.KillCommand, pet_target)
    end
    
--actions.cleave+=/dire_beast
--actions.cleave+=/barbed_shot,target_if=min:dot.barbed_shot.remains,if=target.time_to_die<9
    
    if castable(SB.CobraShot) and player.power.focus.tomax < gcd_duration() * 2 then
      return cast(SB.CobraShot, target)
    end
  end
  
  local function st()
    if pet.exists and pet.alive and castable(SB.AspectoftheWild) and toggle('cooldowns', false) then
      cast(SB.AspectoftheWild)
    end

    if castable(SB.BarbedShot) and pet.buff(SB.Frenzy).up and pet.buff(SB.Frenzy).remains <= gcd_duration() then
      return cast(SB.BarbedShot, target)
    end
    
    if castable(SB.TarTrap) then
      if modifier.lshift or soulforge_embers then
        return cast(SB.TarTrap, "ground")
      else
        tar_trap_up = true
      end
    end

    if pet.exists and pet.alive and castable(SB.Bloodshed) and pet_target.distance <= 50 then
      return cast(SB.Bloodshed, pet_target)
    end

    if castable(SB.WildSpirits) and toggle('cooldowns', false) then
      if modifier.lshift then
        return cast(SB.WildSpirits, "ground")
      else
        wild_spirits_up = true
      end
    end
    
    if castable(SB.KillShot) then
      return cast(SB.KillShot, target)
    end
    
    if castable(SB.BarbedShot) and ((spell(SB.BestialWrath).cooldown < 12 * spell(SB.BarbedShot).fractionalcharges + gcd_duration() and talent(2,1)) or (spell(SB.BarbedShot).full_recharge_time < gcd_duration() and spell(SB.BestialWrath).cooldown > 0)) then
      return cast(SB.BarbedShot, target)
    end
    
--actions.st+=/stampede,if=buff.aspect_of_the_wild.up|target.time_to_die<15
--actions.st+=/a_murder_of_crows

    if pet.exists and pet.alive and castable(SB.BestialWrath) and spell(SB.WildSpirits).cooldown > 15 and player.buff(SB.BestialWrath).down and toggle('cooldowns', false) then
      return cast(SB.BestialWrath)
    end
    
--actions.cleave+=/chimaera_shot
    
    if pet.exists and pet.alive and castable(SB.KillCommand) and pet_target.distance <= 50 then
      return cast(SB.KillCommand, pet_target)
    end
    
--actions.st+=/dire_beast
    
    if castable(SB.CobraShot) and (((player.power.focus.actual - cost(SB.CobraShot) + player.power.focus.regen * (spell(SB.KillCommand).cooldown - 1) > cost(SB.KillCommand)) or (spell(SB.KillCommand).cooldown > 1 + gcd_duration())) or player.buff(SB.BestialWrath).up) then
      return cast(SB.CobraShot, target)
    end
    
    if castable(SB.BarbedShot) and target.debuff(SB.WildMark).up then
      return cast(SB.BarbedShot, target)
    end
  end
  
  if toggle('auto_target', false) then
    local nearest_target = enemies.match(function (unit)
      return unit.alive and unit.combat and unit.distance <= 40
    end)
    
    if (not target.exists or target.distance > 40) and nearest_target and nearest_target.name then
      macro('/target ' .. nearest_target.name)
    end
  end
  
  if castable(SB.Flare) then
    if modifier.lcontrol or soulforge_embers and spell(SB.TarTrap).cooldown > 0 and spell(SB.TarTrap).cooldown <= 24 then
      return cast(SB.Flare, "ground")
    else
      flare_up = true
    end
  end
  
  if modifier.lalt and castable(SB.Misdirection) then
    if tank.exists and tank.alive and tank ~= player and tank.castable(SB.Misdirection) then
      return cast(SB.Misdirection, tank)
    elseif pet.exists and pet.alive then
      return cast(SB.Misdirection, 'pet')
    end
  end
  
  if pet.exists and pet.alive and pet.health.percent < 50 and castable(SB.MendPet) then
		return cast(SB.MendPet)
  end
  
  if not (target.enemy and target.alive and target.distance <= 40) then return end
  
   macro('/startattack')
  
  if pet_attack_focus then macro("/petattack focus") end
    
  if toggle('dispell', false) and castable(SB.TranquilizaingShot) and has_buff_to_steal_or_purge(purge_target) and purge_target.distance <= 40 then
    return cast(SB.TranquilizaingShot, purge_target)
  end
  
  if toggle('interrupts', false) and interrupt_target.interrupt(75) then
    if castable(SB.CounterShot) and interrupt_target.distance <= 40 then
      cast(SB.CounterShot, interrupt_target)
    end
    
    if pet.exists and pet.alive and castable(SB.Intimidation) then
      cast(SB.Intimidation, interrupt_target)
    end
  end
  
  if toggle('cooldowns', false) then
    use_items()
    cds()
  end
  
  if enemies_in_combat_within_same_range_as_target < 2 or not toggle('multitarget', false) then
    st()
  end
  
  if enemies_in_combat_within_same_range_as_target > 1 and toggle('multitarget', false) then
    cleave()
  end
end

local function resting()
  flare_up = false
  tar_trap_up = false
  wild_spirits_up = false
  
  if modifier.lalt and castable(SB.Misdirection) then
    if tank.exists and tank.alive and tank ~= player and tank.castable(SB.Misdirection) then
      return cast(SB.Misdirection, tank)
    elseif pet.exists and pet.alive then
      return cast(SB.Misdirection, 'pet')
    end
  end
  
  if pet.exists and pet.health.percent < 50 and castable(SB.MendPet) then
		return cast(SB.MendPet)
  end
end

local function interface()
  local ww_gui = {
    key = 'bm_nikopol',
    title = 'Beast Mastery by Nikopol',
    width = 250,
    height = 320,
    resize = true,
    show = false,
    template = {
      { type = 'header', text = 'Trinkets' },
      { key = 'trinket_13', type = 'checkbox', text = '13', desc = 'use first trinket', default = false },
      { key = 'trinket_14', type = 'checkbox', text = '14', desc = 'use second trinket', default = false },
      { type = 'header', text = 'Focus' },
      { key = 'pet_attack_focus', type = 'checkbox', text = 'Pet Attack', default = false },
      { key = 'interrupt_focus', type = 'checkbox', text = 'Interrupt', default = false },
      { key = 'purge_focus', type = 'checkbox', text = 'Purge', default = false },
    }
  }

  configWindow = bxhnz7tp5bge7wvu.interface.builder.buildGUI(ww_gui)
  
  bxhnz7tp5bge7wvu.interface.buttons.add_toggle({
    name = 'dispell',
    label = 'Auto Dispell',
    on = {
      label = 'DSP',
      color = bxhnz7tp5bge7wvu.interface.color.green,
      color2 = bxhnz7tp5bge7wvu.interface.color.green
    },
    off = {
      label = 'dsp',
      color = bxhnz7tp5bge7wvu.interface.color.grey,
      color2 = bxhnz7tp5bge7wvu.interface.color.dark_grey
    }
  })
  bxhnz7tp5bge7wvu.interface.buttons.add_toggle({
    name = 'auto_target',
    label = 'Auto Targeting',
    on = {
      label = 'AT',
      color = bxhnz7tp5bge7wvu.interface.color.green,
      color2 = bxhnz7tp5bge7wvu.interface.color.green
    },
    off = {
      label = 'AT',
      color = bxhnz7tp5bge7wvu.interface.color.grey,
      color2 = bxhnz7tp5bge7wvu.interface.color.dark_grey
    }
  })
  bxhnz7tp5bge7wvu.interface.buttons.add_toggle({
    name = 'soulforge_embers',
    label = 'Soulforge Embers',
    on = {
      label = 'SE',
      color = bxhnz7tp5bge7wvu.interface.color.green,
      color2 = bxhnz7tp5bge7wvu.interface.color.green
    },
    off = {
      label = 'SE',
      color = bxhnz7tp5bge7wvu.interface.color.grey,
      color2 = bxhnz7tp5bge7wvu.interface.color.dark_grey
    }
  })
  bxhnz7tp5bge7wvu.interface.buttons.add_toggle({
    name = 'settings',
    label = 'Rotation Settings',
    font = 'bxhnz7tp5bge7wvu_icon',
    on = {
      label = bxhnz7tp5bge7wvu.interface.icon('cog'),
      color = bxhnz7tp5bge7wvu.interface.color.cyan,
      color2 = bxhnz7tp5bge7wvu.interface.color.dark_cyan
    },
    off = {
      label = bxhnz7tp5bge7wvu.interface.icon('cog'),
      color = bxhnz7tp5bge7wvu.interface.color.grey,
      color2 = bxhnz7tp5bge7wvu.interface.color.dark_grey
    },
    callback = function(self)
      if configWindow.parent:IsShown() then
        configWindow.parent:Hide()
      else
        configWindow.parent:Show()
      end
    end
  })
end

bxhnz7tp5bge7wvu.rotation.register({
  spec = bxhnz7tp5bge7wvu.rotation.classes.hunter.beastmastery,
  name = 'bm_nikopol',
  label = 'Beast Mastery by Nikopol',
  combat = combat,
  resting = resting,
  interface = interface
})