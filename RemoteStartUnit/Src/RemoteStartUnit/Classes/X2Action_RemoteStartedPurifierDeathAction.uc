//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_RemoteStartedPurifierDeathAction extends X2Action_ExplodingPurifierDeathAction;

simulated function name GetAssociatedAbilityName()
{
	return 'PurifierRemoteStartExplosion';
}