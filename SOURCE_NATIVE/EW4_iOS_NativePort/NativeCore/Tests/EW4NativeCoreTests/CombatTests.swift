import Testing
@testable import EW4NativeCore

private final class SeqRNG { var values:[Double]; init(_ v:[Double]){values=v}; func next()->Double{values.isEmpty ? 0.5 : values.removeFirst()} }

@Test func playerOverridesParity(){
 #expect(PlayerUnitRules.baseHPBonus==120);#expect(PlayerUnitRules.movementBonus==2)
 #expect(PlayerUnitRules.effectiveBaseHP(strength:80,isPlayer:false)==80);#expect(PlayerUnitRules.effectiveBaseHP(strength:80,isPlayer:true)==200)
 #expect(PlayerUnitRules.effectiveMovement(6,type:"infantry",isPlayer:true)==8);#expect(PlayerUnitRules.effectiveMovement(0,type:"fort",isPlayer:true)==0)
 #expect(PlayerUnitRules.migratedHP(hp:110,maxHP:140,previousAppliedBonus:40,isPlayer:true).hp==190)
}

@Test func attackIntervalAndFormationParity(){
 #expect(CombatCore.effectiveAttackInterval(min:1,max:7,isPlayer:false)==AttackInterval(min:1,max:7))
 #expect(CombatCore.effectiveAttackInterval(min:1,max:7,isPlayer:true)==AttackInterval(min:5,max:11))
 #expect(CombatCore.effectiveAttackInterval(min:1,max:7,lowerBonus:4)==AttackInterval(min:5,max:7))
 #expect(CombatCore.effectiveAttackInterval(min:4,max:6,lowerBonus:5)==AttackInterval(min:9,max:9))
 #expect(CombatCore.skillIntervalBonus(CombatCommander(skills:[13]),statType:"infantry")==SkillIntervalBonus(lower:1,upper:0))
 #expect(CombatCore.formationCoefficient(.init(grade:2,hp:85,maxHP:100),nil,statType:"infantry")==7)
 #expect(CombatCore.formationCoefficient(.init(grade:2,hp:1,maxHP:100),CombatCommander(skills:[15]),statType:"infantry")==7)
}

@Test func damageBoundsParity(){
 let u=CombatUnitSnapshot(grade:0,hp:100,maxHP:100),st=CombatStat(type:"infantry",minAttack:1,maxAttack:7),c=CombatCommander(infantry:3)
 var b=CombatCore.damageBounds(unit:u,stat:st,commander:c);#expect(b.min==20);#expect(b.max==50);#expect(b.coefficient==5)
 b=CombatCore.damageBounds(unit:u,stat:st,commander:c,isPlayer:true);#expect(b.min==40);#expect(b.max==70)
 b=CombatCore.damageBounds(unit:u,stat:st,commander:c,fixedBonus:6);#expect(b.min==26);#expect(b.max==56)
 b=CombatCore.damageBounds(unit:u,stat:st,commander:CombatCommander(infantry:3,skills:[13]));#expect(b.min==25);#expect(b.max==50)
}

@Test func tacticsAndSpecialsParity(){
 let u=CombatUnitSnapshot(grade:0,hp:100,maxHP:100),st=CombatStat(type:"infantry",minAttack:1,maxAttack:7)
 var o=DamageOptions(attacker:u,attackerStat:st,attackerCommander:CombatCommander(infantry:3,skills:[31]));let r1=SeqRNG([0.05]);let a=CombatCore.resolveDamage(o,rng:r1.next);#expect(a.attackTactic);#expect(a.value==a.bounds.max)
 o.isCounter=true;let r2=CombatCore.resolveDamage(o,rng:{0.05});#expect(!r2.attackTactic)
 var d=DamageOptions(attacker:u,attackerStat:st,defenderStat:CombatStat(type:"infantry"),defenderCommander:CombatCommander(skills:[32]));let seq=SeqRNG([0.5,0.5,0.5,0.5,0.5,0.05]);let dr=CombatCore.resolveDamage(d,rng:seq.next);#expect(dr.defenseTactic);#expect(dr.value==1)
 d.isCounter=true;#expect(!CombatCore.resolveDamage(d,rng:{0.05}).defenseTactic)
}

@Test func movementSearchParity(){
 let start=HexCell(q:0,r:0),blocked:Set<HexCell>=[.init(q:1,r:0)]
 let reach=NativeMovementCore.reachable(start:start,maxCost:6,canEnter:{!blocked.contains($0)&&abs($0.q)<5&&abs($0.r)<5},stepCost:{_ in 3})
 #expect(reach[HexCell(q:0,r:1)]==3)
 #expect(reach[HexCell(q:1,r:1)]==6)
 let path=NativeMovementCore.path(start:start,goal:.init(q:1,r:1),maxCost:6,canEnter:{!blocked.contains($0)&&abs($0.q)<5&&abs($0.r)<5},stepCost:{_ in 3})
 #expect(path == [start,.init(q:0,r:1),.init(q:1,r:1)])
}
