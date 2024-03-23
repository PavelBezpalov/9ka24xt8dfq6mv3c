local bxhnz7tp5bge7wvu = bxhnz7tp5bge7wvu_interface
local IT = imcva2pwjzu3skr6ny87f9
local SB = smcva2pwjzu3skr6ny87f9

local flare_up = false
local tar_trap_up = false
local wild_spirits_up = false
local trinket_14 = false
local trinket_14_overlay_toggle = false
local trinket_14_up = false
local set_bonus_tier31_2pc = true

function IsSpellTalented(spellID) -- this could be made to be a lot more efficient, if you already know the relevant nodeID and entryID
    local configID = C_ClassTalents.GetActiveConfigID()
    if configID == nil then return end

    local configInfo = C_Traits.GetConfigInfo(configID)
    if configInfo == nil then return end

    for _, treeID in ipairs(configInfo.treeIDs) do -- in the context of talent trees, there is only 1 treeID
        local nodes = C_Traits.GetTreeNodes(treeID)
        for i, nodeID in ipairs(nodes) do
            local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
            for _, entryID in ipairs(nodeInfo.entryIDsWithCommittedRanks) do -- there should be 1 or 0
                local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
                if entryInfo and entryInfo.definitionID then
                    local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                    if definitionInfo.spellID == spellID then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function is_available(spell)
  return IsSpellTalented(spell)
end

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
  
  local interrupt_focus = bxhnz7tp5bge7wvu.settings.fetch('sv_nikopol_interrupt_focus', false)
  local interrupt_target = target
  if interrupt_focus and focus.exists and focus.alive then interrupt_target = focus end
  
  local purge_focus = bxhnz7tp5bge7wvu.settings.fetch('sv_nikopol_purge_focus', false)
  local purge_target = target
  if purge_focus and focus.exists and focus.alive then purge_target = focus end
    
  local trinket_13 = bxhnz7tp5bge7wvu.settings.fetch('sv_nikopol_trinket_13', false)
  trinket_14 = bxhnz7tp5bge7wvu.settings.fetch('sv_nikopol_trinket_14', false)
  trinket_14_overlay_toggle = bxhnz7tp5bge7wvu.settings.fetch('sv_nikopol_trinket_14_overlay', false)
  
  local healing_potion = bxhnz7tp5bge7wvu.settings.fetch('sv_nikopol_healing_potion', false)
  
--  flare_overlay()
--  flare_up = false
  
--  tar_trap_overlay()
--  tar_trap_up = false
  
--  if toggle('cooldowns', false) then
--    trinket_14_overlay()
--    wild_spirits_overlay()
--  end

  if healing_potion and GetItemCooldown(191380) == 0 and player.health.effective < 10 then
    macro('/use Refreshing Healing Potion')
  end
  
  if GetCVar("nameplateShowEnemies") == '0' then
    SetCVar("nameplateShowEnemies", 1)
  end
     
  if GetItemCooldown(5512) == 0 and player.health.effective < 30 then
    macro('/use Healthstone')
  end
  
  if castable(SB.Exhilaration) and player.health.effective < 20 then
    return cast_with_queue(SB.Exhilaration)
  end
  
  local cast_regen = player.power.focus.regen * gcd_duration()
  local gcd_regen_rule = player.power.focus.actual + cast_regen < player.power.focus.max
  local kill_command_regen_rule = player.power.focus.actual + cast_regen < player.power.focus.max
  local next_wi_bomb_pheromone = GetSpellBookItemName('Wildfire Bomb') == 'Pheromone Bomb'
  local next_wi_bomb_volatile = GetSpellBookItemName('Wildfire Bomb') == 'Volatile Bomb'
  local next_wi_bomb_shrapnel = GetSpellBookItemName('Wildfire Bomb') == 'Shrapnel Bomb'
  local mb_rs_cost = is_available(SB.MongooseBite) and cost(SB.MongooseBite) or cost(SB.RaptorStrike)
  
  local in_5_range = target.in_range(SB.RaptorStrike)
  local in_40_range = target.in_range(SB.WildfireBomb)
  local in_50_range = target.in_range(SB.KillCommandSurvival)
  local in_60_range = target.in_range(SB.KillCommandSurvival)
  local in_raptor_strike_range = in_5_range or in_40_range and player.buff(SB.AspectoftheEagle).up
  local enemies_in_melee = enemies.count(function (unit)
    return unit.alive and unit.in_range(SB.RaptorStrike)
  end)
  
  --actions.st+=/fury_of_the_eagle,interrupt_if=(cooldown.wildfire_bomb.full_recharge_time<gcd&talent.ruthless_marauder|!talent.ruthless_marauder)
  if player.spell(SB.FuryoftheEagle).current then
    if enemies_in_melee < 3 and ( spell(SB.WildfireBomb).full_recharge_time < gcd_duration() and is_available(SB.RuthlessMarauder) or not is_available(SB.RuthlessMarauder) ) then
      --allow rotation
    else
      return
    end
  end
  
  if modifier.lalt and castable(SB.Misdirection) then
    if tank.exists and tank.alive and tank ~= player and tank.castable(SB.Misdirection) then
      return cast_with_queue(SB.Misdirection, tank)
    elseif UnitExists('focus') and not UnitCanAttack('player', 'focus') and not UnitIsDeadOrGhost('focus') then
      return cast_with_queue(SB.Misdirection, 'focus')
    elseif pet.exists and pet.alive then
      return cast_with_queue(SB.Misdirection, 'pet')
    end
  end
  
  if pet.exists and pet.alive and pet.health.percent < 50 and castable(SB.MendPet) then
    return cast_with_queue(SB.MendPet)
  end
  
  local nearest_target = enemies.match(function (unit)
    return unit.alive and unit.combat and unit.distance <= 5
  end)
  
  if (not target.exists or target.distance > 5) and nearest_target and nearest_target.name then
    macro('/target ' .. nearest_target.name)
  end
  
  if not (target.enemy and target.alive) then return end
  
  if player.debuff(SB.Burst).count >= 2 and target.time_to_die < player.debuff(SB.Burst).remains then
    return
  end
  
  macro('/startattack')
  macro('/petattack')
  
--  if modifier.lalt and target.castable(SB.Harpoon) then
--    return cast_with_queue(SB.Harpoon, target)
--  end
  
  if modifier.lcontrol then
    if castable(SB.TarTrap) then
      return cast_with_queue(SB.TarTrap, "player")
    end
    
    if in_5_range and spell(SB.TarTrap).cooldown > 0 and castable(SB.WingClip) and target.debuff(SB.TarTrapDebuff).down and target.debuff(SB.WingClip).down then
      return cast_with_queue(SB.WingClip, target)
    end
  end
  
  if modifier.lshift then
    if castable(SB.BindingShot) then
      return cast_with_queue(SB.BindingShot, "player")
    end
    
    if castable(SB.HighExplosiveTrap) then
      return cast_with_queue(SB.HighExplosiveTrap, "player")
    end
  end
  
  if toggle('dispell', false) and castable(SB.TranquilizingShot) and has_buff_to_steal_or_purge(purge_target) and purge_target.in_range(SB.TranquilizingShot) then
    return cast_with_queue(SB.TranquilizingShot, purge_target)
  end
  
  if toggle('interrupts', false) and interrupt_target.interrupt(75) then
    if castable(SB.Muzzle) and interrupt_target.in_range(SB.Muzzle) then
      cast_with_queue(SB.Muzzle, interrupt_target)
    end
    
    if pet.exists and pet.alive and castable(SB.Intimidation) then
      cast_with_queue(SB.Intimidation, interrupt_target)
    end
  end
    
  local function use_items()    
    local start, duration, enable = GetInventoryItemCooldown("player", 13)
    local trinket_id = GetInventoryItemID("player", 13)
    if trinket_13 and enable == 1 and start == 0 then
      macro('/use 13')
    end
    
    start, duration, enable = GetInventoryItemCooldown("player", 14)
    trinket_id = GetInventoryItemID("player", 14)
    if trinket_14 and enable == 1 and start == 0 then
      macro('/use 14')
    end
  end
   
  local function cds()
--actions.cds=blood_fury,if=buff.coordinated_assault.up|buff.spearhead.up|!talent.spearhead&!talent.coordinated_assault
--actions.cds+=/harpoon,if=talent.terms_of_engagement.enabled&focus<focus.max
--actions.cds+=/ancestral_call,if=buff.coordinated_assault.up|buff.spearhead.up|!talent.spearhead&!talent.coordinated_assault
--actions.cds+=/fireblood,if=buff.coordinated_assault.up|buff.spearhead.up|!talent.spearhead&!talent.coordinated_assault
--actions.cds+=/lights_judgment
--actions.cds+=/bag_of_tricks,if=cooldown.kill_command.full_recharge_time>gcd
--actions.cds+=/berserking,if=buff.coordinated_assault.up|buff.spearhead.up|!talent.spearhead&!talent.coordinated_assault|time_to_die<13
--actions.cds+=/muzzle
--actions.cds+=/potion,if=target.time_to_die<25|buff.coordinated_assault.up|buff.spearhead.up|!talent.spearhead&!talent.coordinated_assault
--actions.cds+=/use_item,name=algethar_puzzle_box,use_off_gcd=1,if=gcd.remains>gcd.max-0.1
--actions.cds+=/use_item,name=manic_grieftorch,use_off_gcd=1,if=gcd.remains>gcd.max-0.1&!buff.spearhead.up
--actions.cds+=/use_items,use_off_gcd=1,if=gcd.remains>gcd.max-0.1&!buff.spearhead.up
    use_items()
--actions.cds+=/aspect_of_the_eagle,if=target.distance>=6
    if not in_5_range and in_40_range and castable(SB.AspectoftheEagle) then
      cast_with_queue(SB.AspectoftheEagle)
    end
  end
  
  local function st()
--actions.st=kill_shot,if=buff.coordinated_assault_empower.up
    if in_40_range and castable(SB.KillShotSurvival) and player.buff(SB.CoordinatedAssaultEmpowerBuff).up then
      return cast_with_queue(SB.KillShotSurvival, target)
    end

--actions.st+=/wildfire_bomb,if=talent.spearhead&cooldown.spearhead.remains<2*gcd&full_recharge_time<gcd
--|talent.bombardier&(cooldown.coordinated_assault.remains<gcd&cooldown.fury_of_the_eagle.remains|buff.coordinated_assault.up&buff.coordinated_assault.remains<2*gcd)
--|full_recharge_time<gcd
--|prev.fury_of_the_eagle&set_bonus.tier31_2pc
--|buff.contained_explosion.remains&(next_wi_bomb.pheromone&dot.pheromone_bomb.refreshable|next_wi_bomb.volatile&dot.volatile_bomb.refreshable|next_wi_bomb.shrapnel&dot.shrapnel_bomb.refreshable)
--|cooldown.fury_of_the_eagle.remains<gcd&full_recharge_time<gcd&set_bonus.tier31_2pc
--|(cooldown.fury_of_the_eagle.remains<gcd&talent.ruthless_marauder&set_bonus.tier31_2pc)&!raid_event.adds.exists
    if in_40_range and castable(SB.WildfireBomb) and ( 
      ( is_available(SB.Spearhead) and spell(SB.Spearhead).cooldown_without_gcd < 2 * gcd_duration() and spell(SB.WildfireBomb).full_recharge_time < gcd_duration() ) 
      or ( is_available(SB.Bombardier) and ( spell(SB.CoordinatedAssault).cooldown_without_gcd < gcd_duration() and spell(SB.FuryoftheEagle).cooldown_without_gcd > 0 ) or ( player.buff(SB.CoordinatedAssaultBuff).up and player.buff(SB.CoordinatedAssaultBuff).remains < 2 * gcd_duration() ) )
      or spell(SB.WildfireBomb).full_recharge_time < gcd_duration()
      or spell(SB.FuryoftheEagle).lastcast and set_bonus_tier31_2pc
      or ( player.buff(SB.ContainedExplosionBuff).up and ( next_wi_bomb_pheromone and target.debuff(SB.PheromoneBombDebuff).refreshable or next_wi_bomb_volatile and target.debuff(SB.VolatileBombDebuff).refreshable or next_wi_bomb_shrapnel and target.debuff(SB.ShrapnelBombDebuff).refreshable ) )
      or ( spell(SB.FuryoftheEagle).cooldown_without_gcd < gcd_duration() and spell(SB.WildfireBomb).full_recharge_time < gcd_duration() and set_bonus_tier31_2pc )
      or ( spell(SB.FuryoftheEagle).cooldown_without_gcd < gcd_duration() and is_available(SB.RuthlessMarauder) and set_bonus_tier31_2pc )
      ) then
      return cast_with_queue(SB.WildfireBomb, target)
    end


--actions.st+=/death_chakram,if=focus+cast_regen<focus.max
--|talent.spearhead&!cooldown.spearhead.remains&cooldown.fury_of_the_eagle.remains
--|talent.bombardier&!cooldown.fury_of_the_eagle.remains
    if in_40_range and castable(SB.DeathChakram) and ( gcd_regen_rule or is_available(SB.Spearhead) and spell(SB.Spearhead).ready and spell(SB.FuryoftheEagle).cooldown_without_gcd > 0 or is_available(SB.Bombardier) and spell(SB.FuryoftheEagle).ready ) then
      return cast_with_queue(SB.DeathChakram, target)
    end

--actions.st+=/mongoose_bite,if=prev.fury_of_the_eagle
    if in_raptor_strike_range and castable(SB.MongooseBite) and is_available(SB.MongooseBite) and spell(SB.FuryoftheEagle).lastcast then
      return cast_with_queue(SB.MongooseBite, target)
    end

--actions.st+=/use_item,name=djaruun_pillar_of_the_elder_flame,if=!talent.fury_of_the_eagle|talent.spearhead

--actions.st+=/fury_of_the_eagle,interrupt_if=(cooldown.wildfire_bomb.full_recharge_time<gcd&talent.ruthless_marauder|!talent.ruthless_marauder),if=(!raid_event.adds.exists&set_bonus.tier31_2pc|raid_event.adds.exists&raid_event.adds.in>40&set_bonus.tier31_2pc)
    if in_5_range and castable(SB.FuryoftheEagle) and set_bonus_tier31_2pc and ( target.boss or not target.boss and target.time_to_die > 4 ) then
      return cast_with_queue(SB.FuryoftheEagle)
    end

--actions.st+=/spearhead,if=focus+action.kill_command.cast_regen>focus.max-10&(cooldown.death_chakram.remains|!talent.death_chakram)
    if in_50_range and castable(SB.Spearhead) then
      return cast_with_queue(SB.Spearhead, target)
    end

--actions.st+=/kill_command,target_if=min:bloodseeker.remains,if=full_recharge_time<gcd&focus+cast_regen<focus.max&(buff.deadly_duo.stack>2|talent.flankers_advantage&buff.deadly_duo.stack>1|buff.spearhead.remains&dot.pheromone_bomb.remains)
    if in_50_range and pet.exists and pet.alive and castable(SB.KillCommandSurvival) and spell(SB.KillCommandSurvival).full_recharge_time < gcd_duration() and gcd_regen_rule and ( player.buff(SB.DeadlyDuoBuff).count > 2 or is_available(SB.FlankersAdvantage) and player.buff(SB.DeadlyDuoBuff).count > 1 or player.buff(SB.SpearheadBuff).up and target.debuff(SB.PheromoneBombDebuff).up )  then
      return cast_with_queue(SB.KillCommandSurvival, target)
    end

--actions.st+=/mongoose_bite,if=active_enemies=1&target.time_to_die<focus%(variable.mb_rs_cost-cast_regen)*gcd|buff.mongoose_fury.up&buff.mongoose_fury.remains<gcd|buff.spearhead.remains
    if in_raptor_strike_range and castable(SB.MongooseBite) and is_available(SB.MongooseBite) and ( enemies_in_melee == 1 and target.time_to_die < (player.power.focus.actual % mb_rs_cost - cast_regen) * gcd_duration() or player.buff(SB.MongooseFuryBuff).up and player.buff(SB.MongooseFuryBuff).remains < gcd_duration() or player.buff(SB.SpearheadBuff).up ) then
      return cast_with_queue(SB.MongooseBite, target)
    end

--actions.st+=/kill_shot,if=!buff.coordinated_assault.up&!buff.spearhead.up
    if in_40_range and castable(SB.KillShotSurvival) and player.buff(SB.CoordinatedAssaultBuff).down and player.buff(SB.SpearheadBuff).down then
      return cast_with_queue(SB.KillShotSurvival, target)
    end

--actions.st+=/kill_command,target_if=min:bloodseeker.remains,if=full_recharge_time<gcd&focus+cast_regen<focus.max&dot.pheromone_bomb.remains&talent.fury_of_the_eagle&cooldown.fury_of_the_eagle.remains>gcd
    if in_50_range and pet.exists and pet.alive and castable(SB.KillCommandSurvival) and spell(SB.KillCommandSurvival).full_recharge_time < gcd_duration() and gcd_regen_rule and target.debuff(SB.PheromoneBombDebuff).up and is_available(SB.FuryoftheEagle) and spell(SB.FuryoftheEagle).cooldown_without_gcd > gcd_duration() then
      return cast_with_queue(SB.KillCommandSurvival, target)
    end

--actions.st+=/raptor_strike,if=active_enemies=1&target.time_to_die<focus%(variable.mb_rs_cost-cast_regen)*gcd
    if in_raptor_strike_range and castable(SB.RaptorStrike) and not is_available(SB.MongooseBite) and enemies_in_melee == 1 and target.time_to_die < player.power.focus.actual % (mb_rs_cost - cast_regen) * gcd_duration() then
      return cast_with_queue(SB.RaptorStrike, target)
    end

--actions.st+=/serpent_sting,target_if=min:remains,if=!dot.serpent_sting.ticking&target.time_to_die>7&!talent.vipers_venom
    if in_40_range and castable(SB.SerpentSting) and target.debuff(SB.SerpentSting).down and target.time_to_die > 7 and not is_available(SB.VipersVenom) then
      return cast_with_queue(SB.SerpentSting, target)
    end

--actions.st+=/fury_of_the_eagle,if=equipped.djaruun_pillar_of_the_elder_flame&buff.seething_rage.up&buff.seething_rage.remains<3*gcd&(!raid_event.adds.exists|active_enemies>1)|raid_event.adds.exists&raid_event.adds.in>40&buff.seething_rage.up&buff.seething_rage.remains<3*gcd
--actions.st+=/use_item,name=djaruun_pillar_of_the_elder_flame,if=talent.coordinated_assault|talent.fury_of_the_eagle&cooldown.fury_of_the_eagle.remains<5

--actions.st+=/mongoose_bite,if=talent.alpha_predator&buff.mongoose_fury.up&buff.mongoose_fury.remains<focus%(variable.mb_rs_cost-cast_regen)*gcd
--|equipped.djaruun_pillar_of_the_elder_flame&buff.seething_rage.remains&active_enemies=1
--|next_wi_bomb.pheromone&cooldown.wildfire_bomb.remains<focus%(variable.mb_rs_cost-cast_regen)*gcd&set_bonus.tier31_2pc
    if in_raptor_strike_range and castable(SB.MongooseBite) and is_available(SB.MongooseBite) and ( is_available(SB.AlphaPredator) and player.buff(SB.MongooseFuryBuff).remains < player.power.focus.actual % (mb_rs_cost - cast_regen) * gcd_duration() 
      or next_wi_bomb_pheromone and spell(SB.FuryoftheEagle).cooldown_without_gcd < player.power.focus.actual % (mb_rs_cost - cast_regen) * gcd_duration() and set_bonus_tier31_2pc ) then
      return cast_with_queue(SB.MongooseBite, target)
    end

--actions.st+=/flanking_strike,if=focus+cast_regen<focus.max
    if target.distance <= 5 and target.castable(SB.FlankingStrike) and gcd_regen_rule then
      return cast_with_queue(SB.FlankingStrike, target)
    end

--actions.st+=/stampede
    if in_40_range and castable(SB.Stampede) then
      return cast_with_queue(SB.Stampede, target)
    end

--actions.st+=/coordinated_assault,if=(!talent.coordinated_kill&target.health.pct<20&(!buff.spearhead.remains&cooldown.spearhead.remains|!talent.spearhead)|talent.coordinated_kill&(!buff.spearhead.remains&cooldown.spearhead.remains|!talent.spearhead))&(!raid_event.adds.exists|raid_event.adds.in>90)
    if in_5_range and castable(SB.CoordinatedAssault) and pet.exists and pet.alive and toggle('cooldowns', false) and ( not is_available(SB.CoordinatedKill) and target.health.percent < 20 and ( player.buff(SB.SpearheadBuff).down and spell(SB.Spearhead).cooldown_without_gcd > 0 or not is_available(SB.Spearhead) ) or is_available(SB.CoordinatedKill) and (player.buff(SB.SpearheadBuff).down and spell(SB.Spearhead).cooldown_without_gcd > 0 or not is_available(SB.Spearhead) ) ) then
      return cast_with_queue(SB.CoordinatedAssault)
    end

--actions.st+=/wildfire_bomb,if=next_wi_bomb.pheromone&focus<variable.mb_rs_cost&set_bonus.tier31_2pc
    if in_40_range and castable(SB.WildfireBomb) and next_wi_bomb_pheromone and player.power.focus.actual < mb_rs_cost and set_bonus_tier31_2pc then
      return cast_with_queue(SB.WildfireBomb, target)
    end

--actions.st+=/kill_command,target_if=min:bloodseeker.remains,if=full_recharge_time<gcd&focus+cast_regen<focus.max&(cooldown.flanking_strike.remains|!talent.flanking_strike)
    if in_50_range and pet.exists and pet.alive and castable(SB.KillCommandSurvival) and spell(SB.KillCommandSurvival).full_recharge_time < gcd_duration() and gcd_regen_rule and ( spell(SB.FlankingStrike).cooldown_without_gcd > 0 or not is_available(SB.FlankingStrike) ) then
      return cast_with_queue(SB.KillCommandSurvival, target)
    end

--actions.st+=/serpent_sting,target_if=min:remains,if=refreshable&!talent.vipers_venom
    if in_40_range and castable(SB.SerpentSting) and target.debuff(SB.SerpentSting).refreshable and not is_available(SB.VipersVenom) then
      return cast_with_queue(SB.SerpentSting, target)
    end

--actions.st+=/mongoose_bite,if=dot.shrapnel_bomb.ticking
    if in_raptor_strike_range and castable(SB.MongooseBite) and is_available(SB.MongooseBite) and target.debuff(SB.ShrapnelBombDebuff).up then
      return cast_with_queue(SB.MongooseBite, target)
    end

--actions.st+=/wildfire_bomb,if=raid_event.adds.in>cooldown.wildfire_bomb.full_recharge_time-(cooldown.wildfire_bomb.full_recharge_time%3.5)&(!dot.wildfire_bomb.ticking&focus+cast_regen<focus.max|active_enemies>1)
    if in_40_range and castable(SB.WildfireBomb) and ( target.debuff(SB.WildfireBombDebuff).down and target.debuff(SB.PheromoneBombDebuff).down and target.debuff(SB.VolatileBombDebuff).down and target.debuff(SB.ShrapnelBombDebuff).down and gcd_regen_rule or enemies_in_melee > 1 ) then
      return cast_with_queue(SB.WildfireBomb, target)
    end

--actions.st+=/mongoose_bite,target_if=max:debuff.latent_poison.stack,if=buff.mongoose_fury.up
    if in_raptor_strike_range and castable(SB.MongooseBite) and is_available(SB.MongooseBite) and player.buff(SB.MongooseFuryBuff).up then
      return cast_with_queue(SB.MongooseBite, target)
    end

--actions.st+=/steel_trap
    if target.distance <= 5 and castable(SB.SteelTrap) then
      return cast_with_queue(SB.SteelTrap, player)
    end

--actions.st+=/explosive_shot,if=talent.ranger&(!raid_event.adds.exists|raid_event.adds.in>28)
    if in_40_range and castable(SB.ExplosiveShot) and is_available(SB.Ranger) then
      return cast_with_queue(SB.ExplosiveShot, target)
    end

--actions.st+=/fury_of_the_eagle,if=(!raid_event.adds.exists|raid_event.adds.exists&raid_event.adds.in>40)
--actions.st+=/mongoose_bite
    if in_raptor_strike_range and castable(SB.MongooseBite) and is_available(SB.MongooseBite) then
      return cast_with_queue(SB.MongooseBite, target)
    end
    
--actions.st+=/raptor_strike,target_if=max:debuff.latent_poison.stack
    if in_raptor_strike_range and castable(SB.RaptorStrike) and not is_available(SB.MongooseBite) then
      return cast_with_queue(SB.RaptorStrike, target)
    end

--actions.st+=/kill_command,target_if=min:bloodseeker.remains,if=focus+cast_regen<focus.max
    if in_50_range and pet.exists and pet.alive and castable(SB.KillCommandSurvival) and gcd_regen_rule then
      return cast_with_queue(SB.KillCommandSurvival, target)
    end

--actions.st+=/coordinated_assault,if=!talent.coordinated_kill&time_to_die>140
    if in_5_range and castable(SB.CoordinatedAssault) and pet.exists and pet.alive and toggle('cooldowns', false) and not is_available(SB.CoordinatedKill) and target.time_to_die > 140 then
      return cast_with_queue(SB.CoordinatedAssault)
    end
  end
  
  local function cleave()
--actions.cleave=kill_shot,if=buff.coordinated_assault_empower.up&talent.birds_of_prey
    if in_40_range and castable(SB.KillShotSurvival) and player.buff(SB.CoordinatedAssaultEmpowerBuff).up and is_available(SB.BirdsofPrey) then
      return cast_with_queue(SB.KillShotSurvival, target)
    end
    
--actions.cleave+=/death_chakram,if=cooldown.death_chakram.duration=45
    if in_40_range and castable(SB.DeathChakram) and spell(SB.DeathChakram).cooldown_duration == 45 then
      return cast_with_queue(SB.DeathChakram, target)
    end

--actions.cleave+=/wildfire_bomb
    if in_40_range and castable(SB.WildfireBomb) then
      return cast_with_queue(SB.WildfireBomb, target)
    end
    
--actions.cleave+=/stampede
    if in_40_range and castable(SB.Stampede) then
      return cast_with_queue(SB.Stampede, target)
    end

--actions.cleave+=/coordinated_assault,if=(cooldown.fury_of_the_eagle.remains|!talent.fury_of_the_eagle)
    if in_5_range and castable(SB.CoordinatedAssault) and pet.exists and pet.alive and toggle('cooldowns', false) and ( spell(SB.FuryoftheEagle).cooldown_without_gcd > 0 or not is_available(SB.FuryoftheEagle) ) then
      return cast_with_queue(SB.CoordinatedAssault)
    end

--actions.cleave+=/explosive_shot
    if in_40_range and castable(SB.ExplosiveShot) then
      return cast_with_queue(SB.ExplosiveShot, target)
    end

--actions.cleave+=/carve,if=cooldown.wildfire_bomb.full_recharge_time>spell_targets%2
    if in_5_range and castable(SB.Carve) and spell(SB.WildfireBomb).full_recharge_time > enemies_in_melee % 2 then
      return cast_with_queue(SB.Carve)
    end

--actions.cleave+=/use_item,name=djaruun_pillar_of_the_elder_flame
--actions.cleave+=/fury_of_the_eagle,if=cooldown.butchery.full_recharge_time>cast_time&raid_event.adds.exists|!talent.butchery
    if in_5_range and castable(SB.FuryoftheEagle) and ( spell(SB.Butchery).full_recharge_time > spell(SB.FuryoftheEagle).castingtime or not is_available(SB.Butchery) ) and ( target.boss or not target.boss and target.time_to_die > 4 ) then
      return cast_with_queue(SB.FuryoftheEagle)
    end

--actions.cleave+=/butchery,if=raid_event.adds.exists
--actions.cleave+=/butchery,if=(full_recharge_time<gcd|dot.shrapnel_bomb.ticking&(dot.internal_bleeding.stack<2|dot.shrapnel_bomb.remains<gcd|raid_event.adds.remains<10))&!raid_event.adds.exists
    if in_5_range and castable(SB.Butchery) then
      return cast_with_queue(SB.Butchery)
    end

--actions.cleave+=/fury_of_the_eagle,if=!raid_event.adds.exists
    if in_5_range and castable(SB.FuryoftheEagle) and ( target.boss or not target.boss and target.time_to_die > 4 ) then
      return cast_with_queue(SB.FuryoftheEagle)
    end

--actions.cleave+=/carve,if=dot.shrapnel_bomb.ticking
    if in_5_range and castable(SB.Carve) and target.debuff(SB.ShrapnelBombDebuff).up then
      return cast_with_queue(SB.Carve)
    end

--actions.cleave+=/butchery,if=(!next_wi_bomb.shrapnel|!talent.wildfire_infusion)
--actions.cleave+=/mongoose_bite,target_if=max:debuff.latent_poison.stack,if=debuff.latent_poison.stack>8
    if in_raptor_strike_range and castable(SB.MongooseBite) and is_available(SB.MongooseBite) and target.debuff(SB.LatentPoisonDebuff).count > 8 then
      return cast_with_queue(SB.MongooseBite, target)
    end

--actions.cleave+=/raptor_strike,target_if=max:debuff.latent_poison.stack,if=debuff.latent_poison.stack>8
    if in_raptor_strike_range and castable(SB.RaptorStrike) and not is_available(SB.MongooseBite) and target.debuff(SB.LatentPoisonDebuff).count > 8 then
      return cast_with_queue(SB.RaptorStrike, target)
    end
    
--actions.cleave+=/kill_command,target_if=min:bloodseeker.remains,if=focus+cast_regen<focus.max&full_recharge_time<gcd
    if in_50_range and pet.exists and pet.alive and castable(SB.KillCommandSurvival) and gcd_regen_rule and spell(SB.KillCommandSurvival).full_recharge_time < gcd_duration() then
      return cast_with_queue(SB.KillCommandSurvival, target)
    end

--actions.cleave+=/flanking_strike,if=focus+cast_regen<focus.max
    if target.distance <= 5 and target.castable(SB.FlankingStrike) and gcd_regen_rule then
      return cast_with_queue(SB.FlankingStrike, target)
    end

--actions.cleave+=/carve
    if in_5_range and castable(SB.Carve) then
      return cast_with_queue(SB.Carve)
    end
    
--actions.cleave+=/kill_shot,if=!buff.coordinated_assault.up
    if in_40_range and castable(SB.KillShotSurvival) and player.buff(SB.CoordinatedAssaultBuff).down then
      return cast_with_queue(SB.KillShotSurvival, target)
    end

--actions.cleave+=/steel_trap,if=focus+cast_regen<focus.max
    if target.distance <= 5 and castable(SB.SteelTrap) and gcd_regen_rule then
      return cast_with_queue(SB.SteelTrap, player)
    end
    
--actions.cleave+=/spearhead
    if in_50_range and castable(SB.Spearhead) then
      return cast_with_queue(SB.Spearhead, target)
    end

--actions.cleave+=/mongoose_bite,target_if=min:dot.serpent_sting.remains,if=buff.spearhead.remains
    if in_raptor_strike_range and castable(SB.MongooseBite) and is_available(SB.MongooseBite) and player.buff(SB.SpearheadBuff).up then
      return cast_with_queue(SB.MongooseBite, target)
    end
    
--actions.cleave+=/serpent_sting,target_if=min:remains,if=refreshable&target.time_to_die>12&(!talent.vipers_venom|talent.hydras_bite)
    if in_40_range and castable(SB.SerpentSting) and target.debuff(SB.SerpentSting).refreshable and target.time_to_die > 12 and ( not is_available(SB.VipersVenom) or is_available(SB.HydrasBite) ) then
      return cast_with_queue(SB.SerpentSting, target)
    end

--actions.cleave+=/mongoose_bite,target_if=min:dot.serpent_sting.remains
    if in_raptor_strike_range and castable(SB.MongooseBite) and is_available(SB.MongooseBite) then
      return cast_with_queue(SB.MongooseBite, target)
    end
    
--actions.cleave+=/raptor_strike,target_if=min:dot.serpent_sting.remains
    if in_raptor_strike_range and castable(SB.RaptorStrike) and not is_available(SB.MongooseBite) then
      return cast_with_queue(SB.RaptorStrike, target)
    end
  end
  
  if in_60_range and castable(SB.HuntersMark) and target.debuff(SB.HuntersMark).down and target.health.percent > 95 then
    return cast_with_queue(SB.HuntersMark, target)
  end
  
  if toggle('cooldowns', false) then
    cds()
  end
  
  if enemies_in_melee < 3 or enemies_in_melee > 2 and not toggle('multitarget', false) then
    return st()
  end
    
  if enemies_in_melee > 2 and toggle('multitarget', false) then
    return cleave()
  end
end

local function resting()
--  flare_up = false
--  tar_trap_up = false
--  trinket_14_overlay()
--  wild_spirits_overlay()
  
  if modifier.lalt and castable(SB.Misdirection) then
    if tank.exists and tank.alive and tank ~= player and tank.castable(SB.Misdirection) then
      return cast_with_queue(SB.Misdirection, tank)
    elseif UnitExists('focus') and not UnitCanAttack('player', 'focus') and not UnitIsDeadOrGhost('focus') then
      return cast_with_queue(SB.Misdirection, 'focus')
    elseif pet.exists and pet.alive then
      return cast_with_queue(SB.Misdirection, 'pet')
    end
  end
  
  if pet.exists and pet.alive and pet.health.percent < 50 and castable(SB.MendPet) then
    return cast_with_queue(SB.MendPet)
  end
end

local function interface()
  local ww_gui = {
    key = 'sv_nikopol',
    title = 'Survival by Nikopol',
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
      { type = 'rule' },   
      { type = 'text', text = 'Healing Settings' },
      { key = 'healing_potion', type = 'checkbox', text = 'Refreshing Healing Potion', desc = 'Use Refreshing Healing Potion when below 10% health', default = false },
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
  spec = bxhnz7tp5bge7wvu.rotation.classes.hunter.survival,
  name = 'sv_nikopol',
  label = 'Survival by Nikopol',
  combat = combat,
  resting = resting,
  interface = interface
})
