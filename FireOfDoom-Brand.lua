-----SCRIPT CONFIG-------
local combokey = 0x20 ---// SPACEBAR
local harasskey = 0x43 ---// C
local clearkey = 0x56 ---// V
---combo spells usage---
local comboq = true
local combow = true
local comboe = true
local combor = true
---harass spells usage---
local harassq = true
local harassw = true
local harasse = true
---clear spells usage---
local clearq = true
local clearw = true
local cleare = true
--------------------------

require 'GeometryLib'
local FiredEnemies = {}, {}
local target, tsrange, LastAA = nil, 1200, 0
local Q = {
	slot = myHero.spellbook:Spell(SpellSlot.Q),
	ready = function() return myHero.spellbook:CanUseSpell(0) == 0 end,
	range = 1050,
	pred = {
		delay = 0.25,
		width = 70,
		speed = 1550,
		collision = true,
	},
}
local W = {
	slot = myHero.spellbook:Spell(SpellSlot.W),
	ready = function() return myHero.spellbook:CanUseSpell(1) == 0 end,
	range = 900,
	pred = {
		delay = 0.75,
		radius = 250,
		speed = math.huge,
		boundingRadiusMod = 0,
		collision = false,
	},
}
local E = {
	slot = myHero.spellbook:Spell(SpellSlot.E),
	ready = function() return myHero.spellbook:CanUseSpell(2) == 0 end,
	range = 625,
}
local R = {
	slot = myHero.spellbook:Spell(SpellSlot.R),
	ready = function() return myHero.spellbook:CanUseSpell(3) == 0 end,
	range = 775,
}

function OnLoad()
	AddEvent(Events.OnTick, OnTick)
	AddEvent(Events.OnBuffGain, OnGainBuff) 
	AddEvent(Events.OnBuffLost, OnRemoveBuff) 
	AddEvent(Events.OnBasicAttack, OnBasicAttack)
	AddEvent(Events.OnDraw, OnDraw)
end

function OnTick()
	if Q.ready() then
		tsrange = Q.range
	elseif not Q.ready() and W.ready() then
		tsrange = W.range
	elseif not W.ready() and R.ready() then
		tsrange = R.range
	elseif not R.ready() and E.ready() then
		tsrange = E.range
	end
	target = GetTarget(tsrange)
	if IsKeyDown(combokey) then 
		Orbwalk()
		Combo()
	end
	if IsKeyDown(harasskey) then 
		Orbwalk()
		Harass()
	end
	if IsKeyDown(clearkey) then 
		Orbwalk()
		Clear()
	end
end

function OnGainBuff(unit, buff)
	if unit.team ~= myHero.enemy and not unit.isDead and buff and buff.isValid and buff.scriptBaseBuff.name == "BrandAblaze" then
		FiredEnemies[unit.networkId] = unit
	end
end

function OnRemoveBuff(unit, buff)
	if unit and FiredEnemies[unit.networkID] and buff and buff.scriptBaseBuff.name == "BrandAblaze" then
		FiredEnemies[unit.networkId] = nil
	end
end

function Combo()
	if not ValidTarget(target) then return end
	if comboq and Q.ready() then
		CastQ(target)
	end
	if combow and W.ready() then
		CastW(target)
	end
	if comboe and E.ready() then
		CastE(target)
	end
	if combor and R.ready() then
		local dmg = math.floor(GetDmg(target, "Q")) + math.floor(GetDmg(target, "W")) + math.floor(GetDmg(target, "E")) + math.floor(GetDmg(target, "R"))
		if target.health < dmg then
			CastR(target)
		end
	end
end

function Harass()
	if not ValidTarget(target) then return end
	if harassq and Q.ready() then
		CastQ(target)
	end
	if harassw and W.ready() then
		CastW(target)
	end
	if harasse and E.ready() then
		CastE(target)
	end
end

function Clear()
	for i, minion in pairs(ObjectManager:GetEnemyMinions()) do
		if ValidTarget(minion, 1300) then
			if clearq and GetDistance(minion, myHero) <= Q.range then
				CastQ(minion)
			end
			if clearw and GetDistance(minion, myHero) <= W.range then
				local Pos, Hit = GetBestCircleFarmPosition(W.range, W.pred.radius, ObjectManager:GetEnemyMinions())
				if Pos and Hit >= 3 and GetDistance(Pos) < W.range then 
					myHero.spellbook:CastSpell(1, D3DXVECTOR3(Pos.x, Pos.y, Pos.z))	
				end
			end
			if cleare and GetDistance(minion, myHero) <= E.range and FiredEnemies[minion.networkId] then
				CastE(minion)
			end
		end
	end
end

function CastQ(unit)
	if ValidTarget(unit) and GetDistance(myHero, unit) <= Q.range then
		local x, y = prediction(unit, Q.pred.delay, Q.pred.speed, Q.range, Q.pred.width, Q.pred.collision)
		if x and y >= 2 then
			myHero.spellbook:CastSpell(0, D3DXVECTOR3(x.x, x.y, x.z))			
		end
	end
end

function CastW(unit)
	if ValidTarget(unit) and GetDistance(myHero, unit) <= W.range then
		local x, y = prediction(unit, W.pred.delay, W.pred.speed, W.range, W.pred.radius, W.pred.collision)
		if x and y >= 2 then
			myHero.spellbook:CastSpell(1, D3DXVECTOR3(x.x, x.y, x.z))			
		end				
	end
end

function CastE(unit)
	if ValidTarget(unit) and GetDistance(myHero, unit) <= E.range then
		myHero.spellbook:CastSpell(2, unit.networkId)			
	end
end

function CastR(unit)
	if ValidTarget(unit) and GetDistance(myHero, unit) <= R.range then
		myHero.spellbook:CastSpell(3, unit.networkId)				
	end
end
	
function OnDraw()

end

function GetDmg(unit, spell)
	if spell == "AD" then
		return CalcPhysic(unit, myHero.characterIntermediate.baseAttackDamage) or 0
	elseif spell == "Q" and Q.ready() then
		return CalcMagic(unit, (30 * myHero.spellbook:Spell(Q).level + 50) + (myHero.characterIntermediate.baseAbilityDamage * 0.55)) or 0
	elseif spell == "W" and W.ready() then
		if FiredEnemies[unit.networkId] then
			return CalcMagic(unit, (55 * myHero.spellbook:Spell(W).level + 40) + (myHero.characterIntermediate.baseAbilityDamage * 0.75)) or 0
		else
			return CalcMagic(unit, (45 * myHero.spellbook:Spell(W).level + 30) + (myHero.characterIntermediate.baseAbilityDamage * 0.6)) or 0
		end
	elseif spell == "E" and E.ready() then
		return CalcMagic(unit, (20 * myHero.spellbook:Spell(E).level + 50) + (myHero.characterIntermediate.baseAbilityDamage * 0.35)) or 0
	elseif spell == "R" and R.ready() then
		return CalcMagic(unit, (100 * myHero.spellbook:Spell(R).level) + (myHero.characterIntermediate.baseAbilityDamage * 0.25)) * GetBounces(unit) or 0
	end
end

function CalcMagic(unit, dmg)
	local baseMR = unit.characterIntermediate.spellBlock
	local fMagicPen = myHero.characterIntermediate.flatMagicPenetration
	if baseMR<fMagicPen then return dmg end
	baseMR = baseMR - fMagicPen
	return dmg * (100 / (100 + (baseMR - myHero.characterIntermediate.percentMagicPenetration*baseMR / 100)))
end

function CalcPhysic(unit, dmg)
	local baseArmor = unit.characterIntermediate.armor
	local Lethality = myHero.characterIntermediate.physicalLethality * (0.6 + 0.4 * myHero.experience.level / 18)
	local armorpenprecent = unit.type == myHero.type and myHero.characterIntermediate.percentArmorPenetration or 1
	if baseArmor<Lethality then return dmg end
	baseArmor = baseArmor - Lethality
	return dmg * (100 / (100 + (baseArmor - (armorpenprecent*baseArmor) / 100)))
end

function GetDistanceSqr(p1, p2)
	p2 = p2 or myHero
	p1 = p1.position or p1
	p2 = p2.position or p2
	local dx = p1.x - p2.x
	local dz = p1.z - p2.z
	return dx*dx + dz*dz
end

function GetDistance(p1, p2)
    return math.sqrt(GetDistanceSqr(p1, p2))
end

function ValidTarget(target)
	return target and target.isValid and (target.team ~= myHero.team) and not target.isInvulnerable and not target.isDead and target.isVisible
end

function GetTarget(range)
	for k, v in pairs(ObjectManager:GetEnemyHeroes()) do
		if ValidTarget(v) and GetDistance(v, myHero) < range then
			return v
		end
	end
end

function GetMinion(range)
	for k, v in pairs(ObjectManager:GetEnemyMinions()) do
		if ValidTarget(v) and GetDistance(v, myHero) < range then
			return v
		end
	end
end

function Orbwalk()
	local Target = nil
	if IsKeyDown(combokey) then 
		Target = GetTarget(myHero.characterIntermediate.attackRange)
	elseif IsKeyDown(harasskey) then
		local minion = GetMinion(myHero.characterIntermediate.attackRange)
		if minion and minion.health <= math.floor(GetDmg(minion, "AD")) then
			Target = minion
		else
			Target = GetTarget(myHero.characterIntermediate.attackRange)
		end
	elseif IsKeyDown(clearkey) then
		Target = GetMinion(myHero.characterIntermediate.attackRange)
	end	
	if myHero.canAttack then
		if GetTickCount() + (NetClient.ping / 2) + 25 >= LastAA + (myHero.attackDelay * 1000) then
			if Target ~= nil then
				LastAA = GetTickCount() + NetClient.ping + 100 - (myHero.attackCastDelay * 1000)
				myHero:IssueOrder(GameObjectOrder.AttackUnit,Target)    
			end
		end
	end
	if GetTickCount() + (NetClient.ping / 2) >= LastAA + (myHero.attackCastDelay * 1000) + 90 then
        myHero:IssueOrder(GameObjectOrder.MoveTo,pwHud.hudManager.activeVirtualCursorPos)
    end
end

function OnBasicAttack(Source,Spell)
	if Source.isValid and Source.type == GameObjectType.AIHeroClient and Source.networkId == myHero.networkId  then
		LastAA = GetTickCount() - (NetClient.ping / 2)
	end
end

function CountObjectsNearPos(pos, radius, objects)
    local n = 0
    for i, object in ipairs(objects) do
        if GetDistance(pos, object) <= radius then
            n = n + 1
        end
    end
    return n
end

function GetBestCircleFarmPosition(range, radius, objects)
    local BestPos 
    local BestHit = 0
    for i, object in ipairs(objects) do
		if GetDistance(object) < range then
			local hit = CountObjectsNearPos(object, radius, objects)
			if hit > BestHit then
				BestHit = hit
				BestPos = object
				if BestHit == #objects then
				   break
				end
			end
		end
    end
    return Convert(BestPos), BestHit
end

function TableMerge(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

function GetRAoeNear(unit)
	local obj = TableMerge(ObjectManager:GetEnemyMinions(), ObjectManager:GetEnemyHeroes())
	local obj2 = TableMerge(obj, GetJungleMinions())
	local count = 0
  	for i, target in pairs(obj2) do
  		if not target.name:find("Plant") then
    		if GetDistance(target, unit) < 450 and target.name ~= unit.name then
      			count = count + 1
    		end
    	end
  	end
  	return count
end

function GetBounces(unit)
	local m = GetRAoeNear(unit)
	local bounces = 1
	if m >= 1 then 
		bounces = 3
	end
	return bounces
end

function GetJungleMinions()
	local jungleminions = {}
	local minions = ObjectManager:GetEnemyMinions()
	for i = 1, #minions do
		local minion = minions[i]
		if minion.team == 3 and GetDistance(minion, myHero) < 1200 then
			jungleminions[#jungleminions + 1] = minion
		end
	end
	return jungleminions
end
  
function Convert(pos)
	pos = pos.position or pos
	local x = {['x'] = pos.x, ['y'] = pos.y, ['z'] = pos.z}
	return x
end

function prediction(unit, delay, speed, range, width, collision)
	local hit = 2
	speed = speed or math.huge
	local pathes = unit.aiManagerClient.navPath
	if pathes.isMoving then  
		local pathPot = (unit.characterIntermediate.movementSpeed*((GetDistance(myHero, unit)/speed)+delay))*.99
		local pStart = Vector(unit.position.x, unit.position.y, unit.position.z)
		local pEnd = Vector(pathes.paths[2].x, pathes.paths[2].y, pathes.paths[2].z)
		local iPathDist = GetDistance(pEnd, pStart) 
		if pathPot > iPathDist then
			pathPot = pathPot-iPathDist
		else 
			local v = Vector(pStart) + (Vector(pEnd) - Vector(pStart)):normalized()* pathPot
			if collision and #Collision(myHero, v, width, range) ~= 0 then
				hit = 0
			end
			return v, hit
		end
	else
		if collision and #Collision(myHero, unit, width, range) ~= 0 then
			hit = 0
		end
		return unit.position, hit
	end
end

function Collision(startPos, EndPos, width, range)
	startPos = startPos or myHero
	range = range or 1200
    local minTable = {}
	for index, object in pairs(ObjectManager:GetEnemyMinions()) do
		if object.isValid and not object.dead and GetDistance(object, myHero) < range then
			local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(Convert(startPos), Convert(EndPos), Convert(object))
			if isOnSegment then
				local x = {['x'] = pointSegment.x, ['y'] = myHero.position.y, ['z'] = pointSegment.y}
				if GetDistance(x, object) < object.boundingRadius + width then
					table.insert(minTable, object)
				end
			end
			
		end
    end
    return minTable
end
