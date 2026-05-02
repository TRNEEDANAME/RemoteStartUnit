//---------------------------------------------------------------------------------------
//  FILE:    X2DLCInfo_RemoteStartUnit.uc
//  AUTHOR:  Iridar / Enhanced Mod Project Template --  26/02/2024
//  PURPOSE: Contains various DLC hooks, with examples on using the most popular ones.
//           Delete this file if you do not end up using it, as every class
//           that extends X2DownloadableContentInfo adds a tiny performance cost.
//---------------------------------------------------------------------------------------

class X2DLCInfo_RemoteStartUnit extends X2DownloadableContentInfo config(UnitRemoteStart);

// Sockets Part 1 of 3: variable for storing a new socket.
// var private SkeletalMeshSocket ExampleSocket;

var config array<name> AbilitiesToCheckForRemoteStartAddition;
var config bool EnableLog;

static event OnPostTemplatesCreated()
{
	local X2AbilityTemplateManager ATMgr;
	local X2CharacterTemplateManager CharMgr;
	local X2DataTemplate DifficultyVariant;
	local X2Ability_UnitRemoteStart.UnitRemoteStartEntry UnitEntry;
	local array<X2DataTemplate> TemplateAllDiffs;
	local int i;
	local name TemplateName;

	ATMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	foreach default.AbilitiesToCheckForRemoteStartAddition(TemplateName) 
	{
		ATMgr.FindDataTemplateAllDifficulties(TemplateName, TemplateAllDiffs);
		for (i = 0; i < TemplateAllDiffs.Length; i++)
		{
			`log("Adding Remote Start ability to " $ TemplateAllDiffs[i].DataName, default.EnableLog, 'RemoteStartUnit');
			AddAbility(X2AbilityTemplate(TemplateAllDiffs[i]).AdditionalAbilities, 'UnitRemoteStart', X2AbilityTemplate(TemplateAllDiffs[i]).DataName);
		}
	}

	CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	foreach class'X2Ability_UnitRemoteStart'.default.UnitRemoteStartEntries(UnitEntry)
	{
		CharMgr.FindDataTemplateAllDifficulties(UnitEntry.Unit, TemplateAllDiffs);
		foreach TemplateAllDiffs(DifficultyVariant)
		{
			PatchCharacterTemplates(DifficultyVariant);
		}
	}
}

static function PatchCharacterTemplates(X2DataTemplate DataTemplate)
{
	local X2CharacterTemplate CharacterTemplate;
	local X2Ability_UnitRemoteStart.UnitRemoteStartEntry UnitEntry;
	local bool bIsTargetUnit;
	local name AbilityToAdd;

	CharacterTemplate = X2CharacterTemplate(DataTemplate);
	if (CharacterTemplate == none)
	{
		return;
	}

	foreach class'X2Ability_UnitRemoteStart'.default.UnitRemoteStartEntries(UnitEntry)
	{
		if (CharacterTemplate.DataName == UnitEntry.Unit)
		{
			`log("Patching template " $ CharacterTemplate.DataName $ " for Remote Start Unit.", default.EnableLog, 'RemoteStartUnit');
			bIsTargetUnit = true;
			break;
		}
	}

	if (!bIsTargetUnit)
	{
		return;
	}

	AbilityToAdd = class'X2Ability_UnitRemoteStart'.static.GetRemoteStartAbilityNameForUnit(CharacterTemplate.DataName);
	`log("Adding Remote Start ability " $ AbilityToAdd $ " to template " $ CharacterTemplate.DataName, default.EnableLog, 'RemoteStartUnit');
	AddAbility(CharacterTemplate.Abilities, AbilityToAdd, CharacterTemplate.DataName);
}

static private function AddAbility(out array<name> TargetAbilities, name AbilityName, name TemplateName)
{
	if (AbilityName == '')
	{
		return;
	}

	if (TargetAbilities.Find(AbilityName) == INDEX_NONE)
	{
		TargetAbilities.AddItem(AbilityName);
	}
}