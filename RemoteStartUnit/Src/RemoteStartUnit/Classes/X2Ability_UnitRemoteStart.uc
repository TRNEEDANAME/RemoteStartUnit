class X2Ability_UnitRemoteStart extends X2Ability config(UniteRemoteStart);

struct UnitRemoteStartEntry
{
	var name AbilityName;
	var name Unit;
	var float Radius;
	var WeaponDamageValue Damage;
	var int EnvDamage;
};

var config array<UnitRemoteStartEntry> UnitRemoteStartEntries;
var config int UnitRemoteStartActionPointCost;
var config bool UnitRemoteStartConsumeAllActionPoints;
var config int UnitRemoteStartAmmoCost;
var config int UnitRemoteStartCooldown;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local UnitRemoteStartEntry UnitEntry;
	
	Templates.AddItem(CreateUnitRemoteStartExplosion());

	foreach default.UnitRemoteStartEntries(UnitEntry)
	{
		Templates.AddItem(CreateUnitRemoteStart(UnitEntry));
	}
	
	return Templates;
}

static function bool GetRemoteStartEntryForUnit(name UnitTemplateName, out UnitRemoteStartEntry UnitEntry)
{
	foreach default.UnitRemoteStartEntries(UnitEntry)
	{
		if (UnitEntry.Unit == UnitTemplateName)
		{
			return true;
		}
	}

	return false;
}

static function name GetRemoteStartAbilityNameForUnit(name UnitTemplateName)
{
	return GetRemoteStartAbilityNameForUnitBySource(UnitTemplateName, 'UnitRemoteStart');
}

static function name GetRemoteStartAbilityNameForUnitBySource(name UnitTemplateName, optional name SourceAbilityName)
{
	local UnitRemoteStartEntry UnitEntry;
	local string AbilityNameString;

	if (GetRemoteStartEntryForUnit(UnitTemplateName, UnitEntry))
	{
		if (SourceAbilityName == '')
		{
			return '';
		}

		AbilityNameString = string(SourceAbilityName) $ "_" $ string(UnitTemplateName) $ "_UnitRemoteStart";
		return name(AbilityNameString);
	}

	return '';
}

static function name GetRemoteStartTriggerEventName(name SourceAbilityName)
{
	if (SourceAbilityName == '')
	{
		return 'UnitRemoteStart';
	}

	return name("UnitRemoteStart_" $ string(SourceAbilityName));
}

static function X2AbilityTemplate CreateUnitRemoteStartExplosion()
{
	local X2AbilityTemplate				Template;
	local X2AbilityCost_ActionPoints	ActionPointCost;
	local X2Effect_TriggerEvent			UnitRemoteStartEvent;
	local X2AbilityCost_Ammo			AmmoCost;
	local X2Effect_Knockback				KnockbackEffect;
	local X2AbilityCooldown				Cooldown;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'UnitRemoteStart');
		
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Offensive;

	Template.SuperConcealmentLoss = 0;
	Template.ConcealmentRule = eConceal_Always;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	Template.AbilityTargetConditions.AddItem(new class'X2Condition_UnitRemoteStartTarget');
	Template.AddShooterEffectExclusions();

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = default.UnitRemoteStartActionPointCost;
	ActionPointCost.bConsumeAllPoints = default.UnitRemoteStartConsumeAllActionPoints;
	Template.AbilityCosts.AddItem(ActionPointCost);

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = default.UnitRemoteStartAmmoCost;
	Template.AbilityCosts.AddItem(AmmoCost);

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.UnitRemoteStartCooldown;
	Template.AbilityCooldown = Cooldown;

	UnitRemoteStartEvent = new class'X2Effect_TriggerEvent';
	UnitRemoteStartEvent.PassTargetAsSource = true;
	UnitRemoteStartEvent.TriggerEventName = GetRemoteStartTriggerEventName('UnitRemoteStart');
	Template.AddTargetEffect(UnitRemoteStartEvent);

	// kill our unit in the same frame, but after the event has triggered
	Template.AddTargetEffect(new class'X2Effect_CyberusDeath');

	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.KnockbackDistance = 2;
	Template.AddTargetEffect(KnockbackEffect);

	Template.bLimitTargetIcons = true;
	Template.DamagePreviewFn = UnitRemoteStartDamagePreview;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.TargetingMethod = class'X2TargetingMethod_UnitRemoteStart';

	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_remotestart";
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.ActivationSpeech = 'RemoteStart';

	return Template;
}

function bool UnitRemoteStartDamagePreview(XComGameState_Ability AbilityState, StateObjectReference TargetRef, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	local XComGameStateHistory History;
	local XComGameState_Ability UnitRemoteStartTargetAbility;
	local XComGameState_Unit TargetUnit;
	local StateObjectReference EmptyRef, UnitRemoteStartRef;

	History = `XCOMHISTORY;
	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(TargetRef.ObjectID));
	if (TargetUnit != none)
	{
		if (class'X2Condition_UnitRemoteStartTarget'.static.GetAvailableUnitRemoteStart(TargetUnit, UnitRemoteStartRef, AbilityState.GetMyTemplateName()))
		{
			UnitRemoteStartTargetAbility = XComGameState_Ability(History.GetGameStateForObjectID(UnitRemoteStartRef.ObjectID));
			if (UnitRemoteStartTargetAbility != None)
			{
				//  pass an empty ref because we assume the ability will use multi target effects.
				UnitRemoteStartTargetAbility.GetDamagePreview(EmptyRef, MinDamagePreview, MaxDamagePreview, AllowsShield);
				return true;
			}
		}
	}
	return false;
}

static function X2AbilityTemplate CreateUnitRemoteStart(UnitRemoteStartEntry UnitEntry)
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;
	local X2AbilityMultiTarget_Radius MultiTarget;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2Effect_ApplyWeaponDamage DamageEffect;
	local X2Effect_KillUnit KillUnitEffect;
	local WeaponDamageValue DamageValue;
	local name TemplateName;

	TemplateName = GetRemoteStartAbilityNameForUnitBySource(UnitEntry.Unit, 'UnitRemoteStart');
	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_purifierdeathexplosion";

	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Offensive;

	// This ability is only valid if there has not been another death explosion on the unit
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.ExcludeDeadFromSpecialDeath = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	// this ability is triggered by the special remote start event that is "shot" on the purifier
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = GetRemoteStartTriggerEventName('UnitRemoteStart');
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_OriginalTarget;
	Template.AbilityTriggers.AddItem(EventListener);

	// Targets the unit so the blast center is its dead body
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityToHitCalc = default.DeadEye;

	// Target everything in this blast radius
	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.fTargetRadius = UnitEntry.Radius;
	Template.AbilityMultiTargetStyle = MultiTarget;

	Template.AddTargetEffect(new class'X2Effect_SetSpecialDeath');

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	UnitPropertyCondition.FailOnNonUnits = false; //The grenade can affect interactive objects, others
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	// Everything in the blast radius receives physical damage
	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageValue = UnitEntry.Damage;
	DamageEffect.EffectDamageValue = DamageValue;
	DamageEffect.EnvironmentalDamageAmount = UnitEntry.EnvDamage;
	Template.AddMultiTargetEffect(DamageEffect);

	// If the unit is alive, kill it
	KillUnitEffect = new class'X2Effect_KillUnit';
	KillUnitEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnEnd);
	KillUnitEffect.EffectName = 'KillUnit';
	KillUnitEffect.DeathActionClass = class'X2Action_ExplodingPurifierDeathAction';
	Template.AddTargetEffect(KillUnitEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = class'X2Ability_Death'.static.DeathExplosion_BuildVisualization;
	Template.MergeVisualizationFn = class'X2Ability_Death'.static.DeathExplostion_MergeVisualization;

	Template.FrameAbilityCameraType = eCameraFraming_Never;

	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.GrenadeLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;
}
