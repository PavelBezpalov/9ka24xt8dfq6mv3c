local bxhnz7tp5bge7wvu = bxhnz7tp5bge7wvu_interface
local IT = items
local SB = spellbook
local HL = HeroLib
local HeroUnit = HL.Unit
local HeroTarget = HeroUnit.Target

local volley_up = false
local wild_spirits_up = false
local trinket_14 = false
local trinket_14_overlay_toggle = false
local trinket_14_up = false

local function time_to_die()
  return HeroTarget:TimeToDie()
end

local function haste_mod()
  local haste = UnitSpellHaste("player")
  return 1 + haste / 100
end

local function gcd_duration()
  return 1.5 / haste_mod()
end

local function rapid_fire_execute_time()
  local rf_channeling_time = 2 / haste_mod()
  return math.max(gcd_duration(), rf_channeling_time) 
end

local function cost(spell)
  return GetSpellPowerCost(spell)[1].cost
end

local function last_cast(spell)
  local last_cast_spell = bxhnz7tp5bge7wvu.tmp.fetch('last_cast_spell_id', false)
  return last_cast_spell == spell
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

local function volley_overlay()
  local usable, noMana = IsUsableSpell(SB.Volley)
  local start, duration = GetSpellCooldown(SB.Volley)
  local startGCD, durationGCD = GetSpellCooldown(61304)
  volley_up = usable and (start == 0 or start == startGCD and duration == durationGCD) and UnitAffectingCombat("player")
  if volley_up then
    SpellActivationOverlay_ShowOverlay(SpellActivationOverlayFrame, SB.Volley, 962497, "LEFT", 1, 255, 255, 255, false, false)
  else
    SpellActivationOverlay_HideOverlays(SpellActivationOverlayFrame, SB.Volley)
  end
end

local function wild_spirits_overlay()
  local usable, noMana = IsUsableSpell(SB.WildSpirits)
  local start, duration = GetSpellCooldown(SB.WildSpirits)
  local startGCD, durationGCD = GetSpellCooldown(61304)
  wild_spirits_up = usable and (start == 0 or start == startGCD and duration == durationGCD) and UnitAffectingCombat("player")
  if wild_spirits_up then
    SpellActivationOverlay_ShowOverlay(SpellActivationOverlayFrame, SB.WildSpirits, 592058, "RIGHT", 1, 255, 255, 255, false, true)
  else
    SpellActivationOverlay_HideOverlays(SpellActivationOverlayFrame, SB.WildSpirits)
  end
end

local function trinket_14_overlay()
  local start, duration, enable = GetInventoryItemCooldown("player", 14)
  trinket_14_up = trinket_14 and trinket_14_overlay_toggle and enable == 1 and start == 0 and UnitAffectingCombat("player")
  if trinket_14_up then
    SpellActivationOverlay_ShowOverlay(SpellActivationOverlayFrame, SB.HuntersMark, 467696, "TOP", 1, 255, 255, 255, false, true)
  else
    SpellActivationOverlay_HideOverlays(SpellActivationOverlayFrame, SB.HuntersMark)
  end
end

local function combat()
  if not player.alive or player.buff(SB.FeignDeath).up then return end
  
  local interrupt_focus = bxhnz7tp5bge7wvu.settings.fetch('mm_nikopol_interrupt_focus', false)
  local interrupt_target = target
  if interrupt_focus and focus.exists and focus.alive then interrupt_target = focus end
  
  local purge_focus = bxhnz7tp5bge7wvu.settings.fetch('mm_nikopol_purge_focus', false)
  local purge_target = target
  if purge_focus and focus.exists and focus.alive then purge_target = focus end
  
  local soulforge_ember_equipted = bxhnz7tp5bge7wvu.settings.fetch('mm_nikopol_soulforge_ember_equipted', false)
  local soulforge_embers_toggle = toggle('soulforge_embers', false)
  local trinket_13 = bxhnz7tp5bge7wvu.settings.fetch('mm_nikopol_trinket_13', false)
  trinket_14 = bxhnz7tp5bge7wvu.settings.fetch('mm_nikopol_trinket_14', false)
  trinket_14_overlay_toggle = bxhnz7tp5bge7wvu.settings.fetch('mm_nikopol_trinket_14_overlay', false)
  
  if toggle('cooldowns', false) then
    trinket_14_overlay()
    wild_spirits_overlay()
  end
  
  volley_overlay()
  
  if GetCVar("nameplateShowEnemies") == '0' then
    SetCVar("nameplateShowEnemies", 1)
  end

  macro('/cqs')
    
  if GetItemCooldown(5512) == 0 and player.health.effective < 30 then
    macro('/use Healthstone')
  end
  
  if castable(SB.Exhilaration) and player.health.effective < 20 then
    return cast(SB.Exhilaration)
  end
  
  if UnitChannelInfo('player') then return end
  
  if modifier.lalt and castable(SB.Misdirection) then
    if tank.exists and tank.alive and tank ~= player and tank.castable(SB.Misdirection) then
      return cast(SB.Misdirection, tank)
    elseif UnitExists('focus') and not UnitCanAttack('player', 'focus') and not UnitIsDeadOrGhost('focus') then
      return cast(SB.Misdirection, 'focus')
    elseif pet.exists and pet.alive then
      return cast(SB.Misdirection, 'pet')
    end
  end
  
  if pet.exists and pet.alive and pet.health.percent < 50 and castable(SB.MendPet) then
		return cast(SB.MendPet)
  end
  
  if not (target.enemy and target.alive) then return end
  
  local in_44_range = target.in_range(SB.ArcaneShot)
  local enemies_in_44_range = enemies.count(function (unit)
    return unit.alive and unit.combat and unit.in_range(SB.ArcaneShot)
  end)

  macro('/startattack')
    
  if modifier.lcontrol and castable(SB.TarTrap) then
    return cast(SB.TarTrap, "player")
  end
  
  if toggle('dispell', false) and castable(SB.TranquilizaingShot) and has_buff_to_steal_or_purge(purge_target) and purge_target.in_range(SB.TranquilizaingShot) then
    return cast(SB.TranquilizaingShot, purge_target)
  end
  
  if toggle('interrupts', false) and interrupt_target.interrupt(75) then
    if castable(SB.CounterShot) and interrupt_target.in_range(SB.CounterShot) then
      cast(SB.CounterShot, interrupt_target)
    end
  end
    
  local function use_items()    
    local start, duration, enable = GetInventoryItemCooldown("player", 13)
    local trinket_id = GetInventoryItemID("player", 13)
    if trinket_13 and enable == 1 and start == 0
      and (trinket_id ~= IT.BottledFlayedwingToxinId or trinket_id == IT.BottledFlayedwingToxinId and player.buff(IT.BottledFlayedwingToxinBuff).remains < 30) then
      macro('/use 13')
    end
    
    start, duration, enable = GetInventoryItemCooldown("player", 14)
    trinket_id = GetInventoryItemID("player", 14)
    if trinket_14 and enable == 1 and start == 0 and (not trinket_14_overlay_toggle or trinket_14_overlay_toggle and modifier.lshift)
      and (trinket_id ~= IT.BottledFlayedwingToxinId or trinket_id == IT.BottledFlayedwingToxinId and player.buff(IT.BottledFlayedwingToxinBuff).remains < 30) then
      macro('/use 14')
    end
  end
    
  local function cds()
    if castable(SB.Berserking) and (player.buff(SB.Trueshot).up or time_to_die() < 13) then
      cast(SB.Berserking)
    end
  end
  
  local function st()
    if not player.moving and castable(SB.SteadyShot) and talent(4,1) and (last_cast(SB.SteadyShot) and player.buff(SB.SteadyFocus).remains < 5 or player.buff(SB.SteadyFocus).down) then
      return cast(SB.SteadyShot, target)
    end
    
    if castable(SB.KillShot) then
      return cast(SB.KillShot, target)
    end
    
    if castable(SB.DoubleTap) and (spell(SB.WildSpirits).cooldown < gcd_duration() or spell(SB.Trueshot).cooldown > 55 or time_to_die() < 15) then
      return cast(SB.DoubleTap)
    end
    
    if castable(SB.ExplosiveShot) then
      return cast(SB.ExplosiveShot, target)
    end
    
    if castable(SB.WildSpirits) and toggle('cooldowns', false) and modifier.lshift then
      return cast(SB.WildSpirits, "ground")
    end
    
    if castable(SB.AMurderOfCrows) then
      return cast(SB.AMurderOfCrows, target)
    end
    
    if castable(SB.Volley) and (player.buff(SB.PreciseShots).down or not talent(4,3) or enemies_in_44_range < 2) and modifier.lshift then
      return cast(SB.Volley, "ground")
    end
    
    if castable(SB.Trueshot) and toggle('cooldowns', false) and (player.buff(SB.PreciseShots).down or target.debuff(SB.WildMark).up or player.buff(SB.Volley).up and enemies_in_44_range > 1) then
      return cast(SB.Trueshot)
    end
    
    if not player.moving and castable(SB.AimedShot) and (player.buff(SB.PreciseShots).down or (player.buff(SB.Trueshot).up or spell(SB.AimedShot).full_recharge_time < gcd_duration() + spell(SB.AimedShot).castingtime) and (not talent(4,3) or enemies_in_44_range < 2) or player.buff(SB.TrickShots).remains > spell(SB.AimedShot).castingtime and enemies_in_44_range > 1) then
      return cast(SB.AimedShot, target)
    end
    
    if castable(SB.RapidFire) and player.power.focus.actual + player.power.focus.regen * rapid_fire_execute_time() < player.power.focus.max and (player.buff(SB.DoubleTap).down or talent(4,2)) then
      return cast(SB.RapidFire, target)
    end
    
    if castable(SB.ChimaeraShot) and (player.buff(SB.PreciseShots).up or player.power.focus.actual > cost(SB.ChimaeraShot) + cost(SB.AimedShot)) then
      return cast(SB.ChimaeraShot, target)
    end
    
    if castable(SB.ArcaneShot) and (player.buff(SB.PreciseShots).up or player.power.focus.actual > cost(SB.ArcaneShot) + cost(SB.AimedShot)) then
      return cast(SB.ArcaneShot, target)
    end
    
    if castable(SB.SerpentStingMM) and target.debuff(SB.SerpentStingMM).remains <= target.debuff(SB.SerpentStingMM).duration * 0.3 and time_to_die() > 18 then
      return cast(SB.SerpentStingMM, target)
    end
    
    if castable(SB.Barrage) and enemies_in_44_range > 1 then
      return cast(SB.Barrage)
    end
    
    if castable(SB.RapidFire) and player.power.focus.actual + player.power.focus.regen * rapid_fire_execute_time() < player.power.focus.max and (player.buff(SB.DoubleTap).down or talent(4,2)) then
      return cast(SB.RapidFire, target)
    end
    
    if castable(SB.SteadyShot) then
      return cast(SB.SteadyShot, target)
    end
  end
  
  local function trickshots()
    if castable(SB.SteadyShot) and talent(4,1) and player.buff(SB.SteadyFocus).remains < 5 then
      return cast(SB.SteadyShot, target)
    end
    
    if castable(SB.DoubleTap) and (spell(SB.WildSpirits).cooldown < gcd_duration() or spell(SB.Trueshot).cooldown > 55 or time_to_die() < 10) then
      return cast(SB.DoubleTap)
    end
    
    if castable(SB.ExplosiveShot) then
      return cast(SB.ExplosiveShot, target)
    end
    
    if castable(SB.WildSpirits) and toggle('cooldowns', false) and modifier.lshift then
      return cast(SB.WildSpirits, "ground")
    end
    
    if castable(SB.Volley) and modifier.lshift then
      return cast(SB.Volley, "ground")
    end
    
    if castable(SB.Barrage) then
      return cast(SB.Barrage)
    end
    
    if castable(SB.Trueshot) and toggle('cooldowns', false) then
      return cast(SB.Trueshot)
    end
    
    if not player.moving and castable(SB.AimedShot) and player.buff(SB.TrickShots).remains >= spell(SB.AimedShot).castingtime and (player.buff(SB.PreciseShots).down or spell(SB.AimedShot).full_recharge_time < gcd_duration() + spell(SB.AimedShot).castingtime or player.buff(SB.Trueshot).up) then
      return cast(SB.AimedShot, target)
    end
    
    if castable(SB.RapidFire) and player.buff(SB.TrickShots).remains >= rapid_fire_execute_time() then
      return cast(SB.RapidFire, target)
    end
    
    if castable(SB.MultiShotMM) and (player.buff(SB.TrickShots).down or player.buff(SB.PreciseShots).up and player.power.focus.actual > cost(SB.MultiShotMM) + cost(SB.AimedShot) and (not talent(4,3) or enemies_in_44_range > 3)) then
      return cast(SB.MultiShotMM, target)
    end
    
    if castable(SB.ChimaeraShot) and player.buff(SB.PreciseShots).up and player.power.focus.actual > cost(SB.ChimaeraShot) + cost(SB.AimedShot) and enemies_in_44_range < 4 then
      return cast(SB.ChimaeraShot, target)
    end
    
    if castable(SB.KillShot) and player.buff(SB.DeadEye).down then
      return cast(SB.KillShot, target)
    end
    
    if castable(SB.AMurderOfCrows) then
      return cast(SB.AMurderOfCrows, target)
    end
    
    if castable(SB.SerpentStingMM) and target.debuff(SB.SerpentStingMM).remains <= target.debuff(SB.SerpentStingMM).duration * 0.3 then
      return cast(SB.SerpentStingMM, target)
    end
    
    if castable(SB.MultiShotMM) and player.power.focus.actual > cost(SB.MultiShotMM) + cost(SB.AimedShot) then
      return cast(SB.MultiShotMM, target)
    end
    
    if castable(SB.SteadyShot) then
      return cast(SB.SteadyShot, target)
    end
  end
  
  if toggle('cooldowns', false) and in_44_range then
    use_items()
    cds()
  end
  
  if in_44_range and (enemies_in_44_range < 3 or enemies_in_44_range > 2 and not toggle('multitarget', false)) then
    st()
  end
    
  if in_44_range and enemies_in_44_range > 2 and toggle('multitarget', false) then
    trickshots()
  end
  
  if in_60_range and target.debuff(SB.HuntersMark).down then
    return cast(SB.HuntersMark, target)
  end
end

local function resting()
  trinket_14_overlay()
  volley_overlay()
  wild_spirits_overlay()
  
  if modifier.lalt and castable(SB.Misdirection) then
    if tank.exists and tank.alive and tank ~= player and tank.castable(SB.Misdirection) then
      return cast(SB.Misdirection, tank)
    elseif UnitExists('focus') and not UnitCanAttack('player', 'focus') and not UnitIsDeadOrGhost('focus') then
      return cast(SB.Misdirection, 'focus')
    elseif pet.exists and pet.alive then
      return cast(SB.Misdirection, 'pet')
    end
  end
  
  if pet.exists and pet.alive and pet.health.percent < 50 and castable(SB.MendPet) then
		return cast(SB.MendPet)
  end
end

local function interface()
  local ww_gui = {
    key = 'mm_nikopol',
    title = 'Marksmanship by Nikopol',
    width = 250,
    height = 320,
    resize = true,
    show = false,
    template = {
      { type = 'header', text = 'Trinkets' },
      { key = 'trinket_13', type = 'checkbox', text = '13', desc = 'use first trinket', default = false },
      { key = 'trinket_14', type = 'checkbox', text = '14', desc = 'use second trinket', default = false },
      { key = 'trinket_14_overlay', type = 'checkbox', text = '14 overlay', desc = 'show alert when ready and require hold shift to use', default = false },
      { type = 'header', text = 'Focus' },
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
  spec = bxhnz7tp5bge7wvu.rotation.classes.hunter.marksmanship,
  name = 'mm_nikopol',
  label = 'Marksmanship by Nikopol',
  combat = combat,
  resting = resting,
  interface = interface
})

bxhnz7tp5bge7wvu.event.register("UNIT_SPELLCAST_SUCCEEDED", function(...)
  local unitID, _, spellID = ...
  if unitID == "player" then
    bxhnz7tp5bge7wvu.tmp.store('last_cast_spell_id', spellID)
  end
end)