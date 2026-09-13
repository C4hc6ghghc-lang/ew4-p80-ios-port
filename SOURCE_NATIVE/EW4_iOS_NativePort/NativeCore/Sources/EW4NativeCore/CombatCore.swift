import Foundation

public struct CombatUnitSnapshot: Sendable {
    public var grade: Int
    public var hp: Int
    public var maxHP: Int
    public var forceFullFormation: Bool
    public init(grade:Int,hp:Int,maxHP:Int,forceFullFormation:Bool=false){self.grade=grade;self.hp=hp;self.maxHP=maxHP;self.forceFullFormation=forceFullFormation}
}

public struct CombatStat: Sendable {
    public var type: String
    public var minAttack: Int
    public var maxAttack: Int
    public init(type:String,minAttack:Int=1,maxAttack:Int=1){self.type=type;self.minAttack=minAttack;self.maxAttack=maxAttack}
}

public struct CombatCommander: Sendable {
    public var infantry:Int=0,cavalry:Int=0,artillery:Int=0,warship:Int=0,fort:Int=0
    public var skills:Set<Int>=[]
    public init(infantry:Int=0,cavalry:Int=0,artillery:Int=0,warship:Int=0,fort:Int=0,skills:Set<Int>=[]){self.infantry=infantry;self.cavalry=cavalry;self.artillery=artillery;self.warship=warship;self.fort=fort;self.skills=skills}
}

public struct AttackInterval: Equatable, Sendable { public let min:Int; public let max:Int }
public struct SkillIntervalBonus: Equatable, Sendable { public let lower:Int; public let upper:Int }
public struct DamageBounds: Sendable {
    public let min,max,attackMin,attackMax,mastery,coefficient,masteryCoefficient,fixedBonus,skillLower,skillUpper:Int
}
public struct DamageResult: Sendable {
    public let bounds:DamageBounds
    public let value:Int
    public let attackTactic:Bool
    public let defenseTactic:Bool
    public let totalReduction:Int
    public let notes:[String]
}

public struct DamageOptions: Sendable {
    public var attacker:CombatUnitSnapshot
    public var attackerStat:CombatStat
    public var attackerCommander:CombatCommander?
    public var defenderStat:CombatStat
    public var defenderCommander:CombatCommander?
    public var isCounter=false
    public var isPlayerAttacker=false
    public var attackerIsFort=false
    public var defenderIsFort=false
    public var fixedBonus=0,flatBonus=0,lowerBonus=0,upperBonus=0
    public var attackerMorale=0,defenderMorale=0,defenderTrainingDefense=0
    public var attackerEmbarked=false
    public var terrainReduction=0,installationReduction=0,buildingReduction=0,countryReduction=0
    public var defenderHasConstruction=false
    public init(attacker:CombatUnitSnapshot,attackerStat:CombatStat,attackerCommander:CombatCommander?=nil,defenderStat:CombatStat=CombatStat(type:"infantry"),defenderCommander:CombatCommander?=nil){self.attacker=attacker;self.attackerStat=attackerStat;self.attackerCommander=attackerCommander;self.defenderStat=defenderStat;self.defenderCommander=defenderCommander}
}

public enum CombatCore {
    public static let playerAttackIntervalBonus=4
    public static let attackTacticChance=0.10
    public static let defenseTacticChance=0.10

    private static func clamp(_ v:Int,_ a:Int,_ b:Int)->Int{max(a,min(b,v))}
    public static func hasSkill(_ commander:CombatCommander?,_ id:Int)->Bool{commander?.skills.contains(id) ?? false}

    public static func skillIntervalBonus(_ commander:CombatCommander?, statType:String)->SkillIntervalBonus{
        var lower=0,upper=0
        switch statType {
        case "infantry": if hasSkill(commander,13){lower += 1}; if hasSkill(commander,12){upper += 1}
        case "cavalry": if hasSkill(commander,11){lower += 1}; if hasSkill(commander,10){upper += 1}
        case "artillery": if hasSkill(commander,7){lower += 1}; if hasSkill(commander,8){upper += 1}
        default: break
        }
        return .init(lower:lower,upper:upper)
    }

    public static func effectiveAttackInterval(min baseMin:Int,max baseMax:Int,isPlayer:Bool=false,flatBonus:Int=0,lowerBonus:Int=0,upperBonus:Int=0)->AttackInterval{
        let player=isPlayer ? playerAttackIntervalBonus : 0
        let lo=baseMin+flatBonus+lowerBonus+player
        let rawHi=baseMax+flatBonus+upperBonus+player
        return .init(min:lo,max:max(lo,rawHi))
    }

    public static func masteryBonus(_ commander:CombatCommander?,statType:String,isFort:Bool=false)->Int{
        guard let c=commander else{return 0};if isFort{return c.fort}
        switch statType{case"infantry":return c.infantry;case"cavalry":return c.cavalry;case"artillery":return c.artillery;case"warship":return c.warship;default:return 0}
    }
    public static func fullFormationCoefficient(_ unit:CombatUnitSnapshot)->Int{clamp(5+clamp(unit.grade,0,2),5,7)}
    public static func formationCoefficient(_ unit:CombatUnitSnapshot,_ commander:CombatCommander?,statType:String)->Int{
        let full=fullFormationCoefficient(unit)
        if unit.forceFullFormation || (statType=="infantry" && hasSkill(commander,15)){return full}
        let ratio=Double(max(0,unit.hp))/Double(max(1,unit.maxHP))
        if full>=7 && ratio>=0.80{return 7};if full>=6 && ratio>=0.65{return 6};if ratio>=0.50{return 5};if ratio>=0.30{return 4};if ratio>=0.15{return 3};if ratio>=0.05{return 2};return 1
    }
    public static func masteryCoefficient(_ unit:CombatUnitSnapshot,_ commander:CombatCommander?,statType:String)->Int{
        if unit.forceFullFormation || (statType=="infantry" && hasSkill(commander,15)){return 5}
        let ratio=Double(max(0,unit.hp))/Double(max(1,unit.maxHP));if ratio>=0.50{return 5};if ratio>=0.30{return 4};if ratio>=0.15{return 3};if ratio>=0.05{return 2};return 1
    }

    public static func damageBounds(unit:CombatUnitSnapshot,stat:CombatStat,commander:CombatCommander?=nil,isPlayer:Bool=false,isFort:Bool=false,fixedBonus:Int=0,flatBonus:Int=0,lowerBonus:Int=0,upperBonus:Int=0)->DamageBounds{
        let skill=skillIntervalBonus(commander,statType:stat.type)
        let interval=effectiveAttackInterval(min:stat.minAttack,max:stat.maxAttack,isPlayer:isPlayer,flatBonus:flatBonus,lowerBonus:lowerBonus+skill.lower,upperBonus:upperBonus+skill.upper)
        let mastery=masteryBonus(commander,statType:stat.type,isFort:isFort), coeff=formationCoefficient(unit,commander,statType:stat.type), masteryCoeff=masteryCoefficient(unit,commander,statType:stat.type)
        let fixed=mastery*masteryCoeff+fixedBonus
        let minDamage=max(1,fixed+coeff*interval.min),maxDamage=max(minDamage,fixed+coeff*interval.max)
        return .init(min:minDamage,max:maxDamage,attackMin:interval.min,attackMax:interval.max,mastery:mastery,coefficient:coeff,masteryCoefficient:masteryCoeff,fixedBonus:fixedBonus,skillLower:skill.lower,skillUpper:skill.upper)
    }

    private static func rollInclusive(_ minValue:Int,_ maxValue:Int,_ rng:()->Double)->Int{
        let lo=minValue,hi=max(lo,maxValue),r=min(max(rng(),0),0.999999999999);return lo+Int(floor(r*Double(hi-lo+1)))
    }
    public static func rollDamage(unit:CombatUnitSnapshot,stat:CombatStat,commander:CombatCommander?=nil,isPlayer:Bool=false,isFort:Bool=false,fixedBonus:Int=0,flatBonus:Int=0,lowerBonus:Int=0,upperBonus:Int=0,rng:()->Double={Double.random(in:0..<1)},forceMax:Bool=false)->(bounds:DamageBounds,value:Int){
        let b=damageBounds(unit:unit,stat:stat,commander:commander,isPlayer:isPlayer,isFort:isFort,fixedBonus:fixedBonus,flatBonus:flatBonus,lowerBonus:lowerBonus,upperBonus:upperBonus)
        var dice=0;if forceMax{dice=b.coefficient*b.attackMax}else{for _ in 0..<b.coefficient{dice += rollInclusive(b.attackMin,b.attackMax,rng)}}
        let fixed=b.mastery*b.masteryCoefficient+b.fixedBonus;return(b,max(1,fixed+dice))
    }
    public static func ignoresAvoidance(_ commander:CombatCommander?,statType:String)->Bool{statType=="infantry" ? hasSkill(commander,14) : statType=="cavalry" ? hasSkill(commander,9) : statType=="artillery" ? hasSkill(commander,5) : false}

    public static func resolveDamage(_ options:DamageOptions,rng:()->Double={Double.random(in:0..<1)})->DamageResult{
        let aCmd=options.attackerCommander,dCmd=options.defenderCommander,aStat=options.attackerStat,dStat=options.defenderStat
        let attackTactic=hasSkill(aCmd,31) && !options.isCounter && rng()<attackTacticChance
        let rolled=rollDamage(unit:options.attacker,stat:aStat,commander:aCmd,isPlayer:options.isPlayerAttacker,isFort:options.attackerIsFort,fixedBonus:options.fixedBonus,flatBonus:options.flatBonus,lowerBonus:options.lowerBonus,upperBonus:options.upperBonus,rng:rng,forceMax:attackTactic)
        var value=rolled.value,notes:[String]=[];if attackTactic{notes.append("attack-tactics")}
        value += options.attackerMorale*rolled.bounds.coefficient;if options.defenderMorale<0{value += (-options.defenderMorale)*rolled.bounds.coefficient}
        if options.defenderTrainingDefense>0{value=max(1,value-options.defenderTrainingDefense);notes.append("training-defense-\(options.defenderTrainingDefense)")}
        if options.attackerEmbarked && aStat.type != "warship" && !hasSkill(aCmd,17){value=Int(floor(Double(value)*0.8));notes.append("embarked-penalty")}
        if options.defenderIsFort && hasSkill(aCmd,4){value=Int(floor(Double(value)*1.5));notes.append("spy+50%")}
        var terrain=max(0,options.terrainReduction),installation=max(0,options.installationReduction),building=max(0,options.buildingReduction),country=max(0,options.countryReduction)
        if ignoresAvoidance(aCmd,statType:aStat.type){terrain=0;installation=0;building=0;country=0;notes.append("ignore-avoidance")}else if hasSkill(aCmd,29) && building>0{building=0;notes.append("siegecraft")}
        let mapReduction=options.defenderHasConstruction ? building : max(terrain,installation),totalReduction=clamp(mapReduction+country,0,95)
        if totalReduction>0{value=Int(floor(Double(value)*Double(100-totalReduction)/100.0))}
        if dStat.type=="warship" && hasSkill(dCmd,16){value=Int(floor(Double(value)*0.9));notes.append("helmsman-10%")}
        value=max(1,value)
        let defenseTactic=hasSkill(dCmd,32) && !options.isCounter && rng()<defenseTacticChance
        if defenseTactic{value=1;notes.append("defense-tactics")}
        return .init(bounds:rolled.bounds,value:value,attackTactic:attackTactic,defenseTactic:defenseTactic,totalReduction:totalReduction,notes:notes)
    }
}
