// custom condition to support the "Better" death explosion on purifiers
class X2Condition_UnitRemoteStartTarget extends X2Condition;

static function bool GetAvailableUnitRemoteStart(XComGameState_Unit TargetUnit, optional out StateObjectReference UnitRemoteStartTargetAbility, optional name SourceAbilityName)
{
	local StateObjectReference AbilityRef;
	local name AbilityName;
	local name UnitTemplateName;
	local array<StateObjectReference> ExcludeWeapons;
	local XComGameState_Ability AbilityState;
	local XComGameStateHistory History;
	local X2Ability_UnitRemoteStart.UnitRemoteStartEntry UnitEntry;

	// there is bit of an issue involved: we can't kill dead targets,
	// but can't exclude the ability from dead targets because we kill it ourselves before
	// so we'll just add a condition to the remote start ability 
	if (TargetUnit == none || TargetUnit.IsDead())
		return false;

	UnitTemplateName = TargetUnit.GetMyTemplateName();
	if (!class'X2Ability_UnitRemoteStart'.static.GetRemoteStartEntryForUnit(UnitTemplateName, UnitEntry))
		return false;

	History = `XCOMHISTORY;
	if (SourceAbilityName != '')
	{
		AbilityName = class'X2Ability_UnitRemoteStart'.static.GetRemoteStartAbilityNameForUnitBySource(UnitEntry.Unit, SourceAbilityName);
		ExcludeWeapons.Length = 0;
		AbilityRef = TargetUnit.FindAbility(AbilityName);
		while (AbilityRef.ObjectID != 0)
		{
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
			if (AbilityState.CanActivateAbility(TargetUnit) == 'AA_Success')
			{
				UnitRemoteStartTargetAbility = AbilityRef;
				return true;
			}
			ExcludeWeapons.AddItem(AbilityState.SourceWeapon);
			AbilityRef = TargetUnit.FindAbility(AbilityName, , ExcludeWeapons);
		}

		return false;
	}

	AbilityName = class'X2Ability_UnitRemoteStart'.static.GetRemoteStartAbilityNameForUnit(UnitEntry.Unit);
	ExcludeWeapons.Length = 0;
	AbilityRef = TargetUnit.FindAbility(AbilityName);
	while (AbilityRef.ObjectID != 0)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
		if (AbilityState.CanActivateAbility(TargetUnit) == 'AA_Success')
		{
			UnitRemoteStartTargetAbility = AbilityRef;
			return true;
		}
		ExcludeWeapons.AddItem(AbilityState.SourceWeapon);
		AbilityRef = TargetUnit.FindAbility(AbilityName, , ExcludeWeapons);
	}

	return false; 
}

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{ 
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(kTarget);
	if (TargetUnit == none)
		return 'AA_NotAUnit';

	if (TargetUnit.IsDeadFromSpecialDeath())
		return 'AA_TargetHasNoLoot';

	if (GetAvailableUnitRemoteStart(TargetUnit))
		return 'AA_Success';

	return 'AA_TargetHasNoLoot';
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource) 
{ 
	local XComGameState_Unit TargetUnit, SourceUnit;

	TargetUnit = XComGameState_Unit(kTarget);
	SourceUnit = XComGameState_Unit(kSource);
	if (TargetUnit == none || SourceUnit == none)
		return 'AA_NotAUnit';

	if (SourceUnit.IsFriendlyUnit(TargetUnit))
		return 'AA_UnitIsFriendly';

	return 'AA_Success'; 
}