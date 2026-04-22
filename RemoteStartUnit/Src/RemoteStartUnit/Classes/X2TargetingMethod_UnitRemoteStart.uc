// near copy of fuse
class X2TargetingMethod_UnitRemoteStart extends X2TargetingMethod_TopDown;

var protected XComGameState_Ability UnitRemoteStartAbility;

function DirectSetTarget(int TargetIndex)
{
	local StateObjectReference UnitRemoteStartRef;
	local XComGameState_Unit TargetUnit;
	local int TargetID;
	local array<TTile> Tiles;

	super.DirectSetTarget(TargetIndex);

	UnitRemoteStartAbility = none;
	TargetID = GetTargetedObjectID();
	if (TargetID != 0)
	{
		TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetID));
		if (TargetUnit != none)
		{
			if (class'X2Condition_UnitRemoteStartTarget'.static.GetAvailableUnitRemoteStart(TargetUnit, UnitRemoteStartRef, Ability.GetMyTemplateName()))
			{
				UnitRemoteStartAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(UnitRemoteStartRef.ObjectID));
				if (UnitRemoteStartAbility != none && UnitRemoteStartAbility.GetMyTemplate().AbilityMultiTargetStyle != none)
				{
					UnitRemoteStartAbility.GetMyTemplate().AbilityMultiTargetStyle.GetValidTilesForLocation(UnitRemoteStartAbility, `XWORLD.GetPositionFromTileCoordinates(TargetUnit.TileLocation), Tiles);	
					DrawAOETiles(Tiles);
				}
			}
		}
	}
}

function Update(float DeltaTime)
{
	local XComGameState_Ability ActualAbility;
	local array<Actor> CurrentlyMarkedTargets;
	local vector NewTargetLocation;
	local XComGameState_Unit TargetUnit;
	local int TargetID;
	
	TargetID = GetTargetedObjectID();
	if (TargetID != 0)
	{
		TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetID));
		if (TargetUnit != none)
		{
			NewTargetLocation = `XWORLD.GetPositionFromTileCoordinates(TargetUnit.TileLocation);
		}
	}

	if(NewTargetLocation != CachedTargetLocation)
	{		
		ActualAbility = Ability;
		Ability = UnitRemoteStartAbility;
		GetTargetedActors(NewTargetLocation, CurrentlyMarkedTargets);
		CheckForFriendlyUnit(CurrentlyMarkedTargets);	
		MarkTargetedActors(CurrentlyMarkedTargets, (!AbilityIsOffensive) ? FiringUnit.GetTeam() : eTeam_None );

		Ability = ActualAbility;
		CachedTargetLocation = NewTargetLocation;
	}
}

function Canceled()
{
	ClearTargetedActors();
	super.Canceled();
}