#define PLUGIN_VERSION			"1.5.6"


/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Gear Transfer
*	Author	:	SilverShot
*	Version	:	1.5.6
*	Descrp	:	Survivor bots can automatically pickup and give items. Players can switch, grab or give items.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=137616

========================================================================================
	Change Log:

*	1.5.6
	- Added cvar 'l4d_gear_transfer_modes_off' to turn off the plugin on certain game modes.
	- Fixed deleting grenade spawns which give infinite items.

*	1.5.5
	- Changed the bot allow cvars (as requested by LTR.2) so you can specify which items bots auto give/grab.

*	1.5.4
	- Another attempt to fix 'm_humanSpectatorUserID' errors.
	- Added chat notifications block from round start the same as vocalize block.

*	1.5.3
	- Changed the previous check to make sure the netclass is 'SurvivorBot', should stop all related errors.

*	1.5.2
	- Added check for 'bebop_bot_fakeclient' which caused errors.
	- Removed the -attack2 after shoves thanks to Valve patching some client commands.

*	1.5.1
	- Added IsVisibleTo for player to player transfers (stops transfers through walls!)
	- Fixed auto give transferring directly after a player to player transfer.

*	1.5.0
	- Optimized a lot code.
	- Fixed allow cvars not restricting their correct items.
	- Added cvar 'l4d_gear_transfer_modes' to disable auto give/grab in listed game modes.
	- Added cvar 'l4d_gear_transfer_timer_item' to specify how often the auto grab item list updates.
	- Added delay to auto give when switching items with bots.
	- Added vocalize block for 60 seconds from round start.
	- Added check for translation file.
	- Added finale_vehicle_leaving event to disable auto give/grab.
	- Added notifications for auto give/grab when 'l4d_gear_transfer_notify' is enabled.
	- Removed hint text when l4d_gear_transfer_notify set to 2. Now only shows chat notifications.

*	1.4.11
	- Added ("-attack2") to stop shoving after successful transfer.
	- Added FCVAR_DONTRECORD flag to the version cvar.

*	1.4.10
	- Fixed 'switch' translation being given the wrong weapon name.
	- Changed weapon name text colour to yellow.

*	1.4.9
	- Fixed player_shoved transfers not working because of a missing exclamation mark!

*	1.4.8
	- Fixed Infected receiving items.

*	1.4.7
	- Optimized auto give a little.

*	1.4.6
	- Re-added FileExists check for scenes, now using Valve's Filesystem!
	- Small changes.

*	1.4.5
	- Re-added player_shoved event to transfer items.
	- Removed FileExists check from scenes, now vocalizes L4D1 characters!

*	1.4.4
	- Fixed creating dupe grenades when throwing.

*	1.4.3
	- Fixed AutoTimer rubbish!
	- Stopped auto give/grab when survivor is incapped/reviving.

*	1.4.2
	- Small fixes.

*	1.4.1
	- Added diplaying transfers in chat messages with translations.
	- Changed some vocalize parts for The Sacrifice update.

*	1.4.0.1
	- Fixed disabling shove transfers with first aid.

*	1.4.0
	- Officially supports the first Left4Dead!
	- Added check so bots will not auto grab "projectile" grenades.
	- Added check so bots will not auto grab items who have owners.
	- Added cvars to allow/disallow bots to auto give/grab certain items.
	- Changed cvars to comply with releasing guidelines.
	- Idle players no longer treated as bots.

*	1.3.0
	- Small changes to auto grab.

*	1.2.9
	- Disabled transfers with incapacitated players.
	- Fixed disabling auto give/grab in versus.
	- Changed the fix for auto grab creating two grenades again.
	- Removed player_shoved event, reload+shove transfer from OnPlayerRunCmd.

*	1.2.8
	- Changed the fix for auto grab creating two grenades.

*	1.2.7
	- Fixed auto grab creating two grenades!
	- Delaying all bots for 3 seconds after they receive an item.

*	1.2.6
	- Optimized code.
	- TraceFilter added on survivors so they don't block transfers.

*	1.2.5
	- Delayed bots auto give for 3 seconds after they are given an item.

*	1.2.4
	- Fixed auto give when sb_all_bot_team.

*	1.2.3
	- Added weapon_given hook to stop pills/adrenaline being given back!

*	1.2.2
	- Minor changes.

*	1.2.1
	- Added adrenaline and pain pills to transfers. You can only use the reload key to switch.
	- Added cvars to allow/disallow the above transfers.
	- Added vocalize on first aid kit transfers.

*	1.2.0
	- Renamed more appropriately to "Gear Transfer".
	- Added defibrillators, first aid kits, explosive and incendiary rounds to transfers.
	- Added cvars to allow/disallow the transfer of certain items.
	- Changed the transfer being triggered by the Use key to the Reload key.
	- Disabled auto give/grab in versus games (as they should be full with players!).

*	1.1.2
	- Removed HookSingleEntityOutput, which was causing crashes.

*	1.1.1
	- Some fixes.

*	1.1
	- Added AtomicStryker's Vocalize with scenes.

*	1.03
	- Removed Vocalize stuff.

*	1.02
	- Changed things AtomicStryker suggested.

*	1.0.1
	- Fixed UnhookEvent error.
	- Added check in case of over 64 grenades.

*	1.0
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "DJ_WEST" for "[L4D/L4D2] Grenade Transfer"
	http://forums.alliedmods.net/showthread.php?t=122293

*	Thanks to "AtomicStryker" for "[L4D & L4D2] Boomer Splash Damage"
	http://forums.alliedmods.net/showthread.php?t=98794

*	Thanks to "Crimson_Fox" for "[L4D2] Weapon Unlock"
	http://forums.alliedmods.net/showthread.php?t=114296

*	Thanks to "AtomicStryker" for "L4D2 Vocalize ANYTHING"
	http://forums.alliedmods.net/showthread.php?t=122270

======================================================================================*/


#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS				FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define ITEMZ					64							// How many items we store
#define SOUND_BIGREWARD			"UI/BigReward.wav"			// Give
#define SOUND_LITTLEREWARD		"UI/LittleReward.wav"		// Receive


// Cvar variables
static bool:g_bAllowAdr, bool:g_bAllowDef, bool:g_bAllowExp, bool:g_bAllowFir, bool:g_bAllowInc, bool:g_bAllowMol, bool:g_bAllowPil, bool:g_bAllowPip,
	bool:g_bAllowVom, bool:g_bAutoGive, bool:g_bAutoGrab, g_iBotAdr, g_iBotDef, g_iBotExp, g_iBotFir, g_iBotInc, g_iBotMol, g_iBotPil, g_iBotPip, g_iBotVom,
	bool:g_bEnable, Float:g_fDistGive, Float:g_fDistGrab, g_iMethod, bool:g_bNotify, bool:g_bSounds, Float:g_fTimerAuto, Float:g_fTimerItem, bool:g_bHooked;

// Cvar handles
static Handle:g_hAllowAdr, Handle:g_hAllowDef, Handle:g_hAllowExp, Handle:g_hAllowFir, Handle:g_hAllowInc, Handle:g_hAllowMol,Handle:g_hAllowPil,
	Handle:g_hAllowPip, Handle:g_hAllowVom, Handle:g_hBotAdr, Handle:g_hBotDef, Handle:g_hBotExp, Handle:g_hBotFir, Handle:g_hBotInc, Handle:g_hBotMol,
	Handle:g_hBotPil, Handle:g_hBotPip, Handle:g_hBotVom, Handle:g_hAutoGrab, Handle:g_hAutoGive, Handle:g_hDistGrab, Handle:g_hDistGive,
	Handle:g_hEnable, Handle:g_hMethod, Handle:g_hNotify, Handle:g_hModes, Handle:g_hModesOff, Handle:g_hSounds, Handle:g_hTimerAuto, Handle:g_hTimerItem;

// Game's convar handles
static Handle:g_hMPGameMode;

// Timer handles
static Handle:g_hAutoGiveGrab, Handle:g_hGetItemSpawn, Handle:g_hBlockVocalize, Handle:g_hGiveBlocked;

// Variables
static bool:g_bBlockVocalize, bool:g_bGiveBlocked, bool:g_bModeOff, bool:g_bModeOffAuto, bool:g_bRoundOver, bool:g_bTranslation;

// Item variables
static bool:g_bHasTransferred[64], g_iItemCount, g_iItemSpawnID[ITEMZ], Float:g_fItemSpawn_XYZ[ITEMZ][3];


// Items to transfer
static const String:g_Pickups[9][] =
{
	"weapon_molotov", "weapon_pipe_bomb", "weapon_vomitjar", "weapon_first_aid_kit", "weapon_pain_pills", "weapon_adrenaline",
	"weapon_upgradepack_explosive", "weapon_upgradepack_incendiary", "weapon_defibrillator"
};

// Vocalize for Left 4 Dead 2
static const String:g_Coach[8][] =
{
	"takepipebomb01", "takepipebomb02", "takepipebomb03", "takemolotov01", "takemolotov02", "takefirstaid01", "takefirstaid02", "takefirstaid03"
};
static const String:g_Ellis[15][] =
{
	"takepipebomb01", "takepipebomb02", "takepipebomb03", "takemolotov01", "takemolotov02", "takemolotov03", "takemolotov04", "takemolotov05",
	"takemolotov06", "takemolotov07", "takemolotov08", "takefirstaid01", "takefirstaid02", "takefirstaid03", "takefirstaid04" 
};
static const String:g_Nick[9][] =
{
	"takepipebomb01", "takepipebomb02", "takemolotov01", "takemolotov02", "takefirstaid01", "takefirstaid02", "takefirstaid03", "takefirstaid04", 
	"takefirstaid05"
};
static const String:g_Rochelle[9][] =
{
	"takepipebomb01", "takepipebomb02", "takemolotov01", "takemolotov02", "takemolotov03", "takemolotov04", "takefirstaid01", "takefirstaid02",
	"takefirstaid03"
};

// Vocalize for Left 4 Dead
static const String:g_Bill[10][] =
{
	"TakePipeBomb01", "TakePipeBomb02", "TakePipeBomb03", "TakePipeBomb04", "TakeMolotov01", "TakeMolotov02", "TakeMolotov03", "TakeFirstAid01",
	"TakeFirstAid02", "TakeFirstAid03"
};
static const String:g_Francis[12][] =
{
	"TakePipeBomb01", "TakePipeBomb02", "TakePipeBomb03", "TakePipeBomb04", "TakePipeBomb05", "TakeMolotov01", "TakeMolotov02", "TakeMolotov03",
	"TakeFirstAid01", "TakeFirstAid02", "TakeFirstAid03", "TakeFirstAid04"
};
static const String:g_Louis[10][] =
{
	"TakePipeBomb01", "TakePipeBomb02", "TakePipeBomb03", "takepipebomb05", "TakeMolotov01", "TakeMolotov02", "TakeMolotov03", "TakeFirstAid01",
	"TakeFirstAid02", "TakeFirstAid03"
};
static const String:g_Zoey[10][] =
{
	"TakePipeBomb02", "takepipebomb04", "TakeMolotov02", "takemolotov04", "takemolotov05", "takemolotov07", "TakeFirstAid01", "TakeFirstAid02",
	"TakeFirstAid03", "takefirstaid05"
};



public Plugin:myinfo =
{
	name = "[L4D & L4D2] 电脑给予",
	author = "SilverShot汉化者:心动",
	description = "Survivor bots can automatically pickup and give items. Players can switch, grab or give items.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=137616"
}



// ======================================================================================
//			P L U G I N   S T A R T
// ======================================================================================
public OnPluginStart()
{
	// Game check.
	decl String:s_Path[PLATFORM_MAX_PATH];
	GetGameFolderName(s_Path, PLATFORM_MAX_PATH);

	if( StrContains(s_Path, "left4dead", false) == -1 )
		SetFailState("Gear Transfer only supports Left4Dead 1 & 2");

	// Translations	
	BuildPath(Path_SM, s_Path, PLATFORM_MAX_PATH, "%s", "translations/gear_transfer.phrases.txt");
	if( FileExists(s_Path) )
	{
		LoadTranslations("gear_transfer.phrases");
		g_bTranslation = true;
	}
	else
	{
		g_bTranslation = false;
	}

	// Cvars
	g_hAllowAdr = CreateConVar(	"l4d_gear_transfer_allow_adr",	"1",		"0=关闭, 1=开启 兴奋剂转移.",									CVAR_FLAGS);
	g_hAllowDef = CreateConVar(	"l4d_gear_transfer_allow_def",	"1",		"0=关闭, 1=开启 电击器转移.",								CVAR_FLAGS);
	g_hAllowExp = CreateConVar(	"l4d_gear_transfer_allow_exp",	"1",		"0=关闭, 1=开启 高爆子弹盒转移.",							CVAR_FLAGS);
	g_hAllowFir = CreateConVar(	"l4d_gear_transfer_allow_fir",	"1",		"0=关闭, 1=开启 医疗包转移.",								CVAR_FLAGS);
	g_hAllowInc = CreateConVar(	"l4d_gear_transfer_allow_inc",	"1",		"0=关闭, 1=开启 燃烧子弹盒转移.",							CVAR_FLAGS);
	g_hAllowMol = CreateConVar(	"l4d_gear_transfer_allow_mol",	"1",		"0=关闭, 1=开启 燃烧弹转移.",									CVAR_FLAGS);
	g_hAllowPil = CreateConVar(	"l4d_gear_transfer_allow_pil",	"1",		"0=关闭, 1=开启 药丸转移.",									CVAR_FLAGS);
	g_hAllowPip = CreateConVar(	"l4d_gear_transfer_allow_pip",	"1",		"0=关闭, 1=开启 土质转移.",									CVAR_FLAGS);
	g_hAllowVom = CreateConVar(	"l4d_gear_transfer_allow_vom",	"1",		"0=关闭, 1=开启 胆汁瓶转移.",									CVAR_FLAGS);
	g_hAutoGive = CreateConVar(	"l4d_gear_transfer_auto_give",	"1",		"0=关闭, 1=开启 电脑自动给予物品.",			CVAR_FLAGS);
	g_hAutoGrab = CreateConVar(	"l4d_gear_transfer_auto_grab",	"1",		"0=关闭, 1=开启 电脑自动选择附近目标.",				CVAR_FLAGS);
	g_hBotAdr = CreateConVar(	"l4d_gear_transfer_bot_adr",	"1",		"0=关闭, 1=两种都可以 2=电脑可以给予, 3=电脑可以拿兴奋剂.",					CVAR_FLAGS);
	g_hBotDef = CreateConVar(	"l4d_gear_transfer_bot_def",	"1",		"0=关闭, 1=两种都可以 2=电脑可以给予, 3=电脑可以拿电击器.",				CVAR_FLAGS);
	g_hBotExp = CreateConVar(	"l4d_gear_transfer_bot_exp",	"1",		"0=关闭, 1=两种都可以 2=电脑可以给予, 3=电脑可以拿高爆子弹盒.",			CVAR_FLAGS);
	g_hBotFir = CreateConVar(	"l4d_gear_transfer_bot_fir",	"1",		"0=关闭, 1=两种都可以 2=电脑可以给予, 3=电脑可以拿医疗包.",				CVAR_FLAGS);
	g_hBotInc = CreateConVar(	"l4d_gear_transfer_bot_inc",	"1",		"0=关闭, 1=两种都可以 2=电脑可以给予, 3=电脑可以拿燃烧子弹盒.",				CVAR_FLAGS);
	g_hBotMol = CreateConVar(	"l4d_gear_transfer_bot_mol",	"1",		"0=关闭, 1=两种都可以 2=电脑可以给予, 3=电脑可以拿燃烧弹.",					CVAR_FLAGS);
	g_hBotPil = CreateConVar(	"l4d_gear_transfer_bot_pil",	"1",		"0=关闭, 1=两种都可以 2=电脑可以给予, 3=电脑可以拿药丸.",					CVAR_FLAGS);
	g_hBotPip = CreateConVar(	"l4d_gear_transfer_bot_pip",	"1",		"0=关闭, 1=两种都可以 2=电脑可以给予, 3=电脑可以拿土质炸弹.",					CVAR_FLAGS);
	g_hBotVom = CreateConVar(	"l4d_gear_transfer_bot_vom",	"1",		"0=关闭, 1=两种都可以 2=电脑可以给予, 3=电脑可以拿胆汁瓶.",					CVAR_FLAGS);
	g_hDistGive = CreateConVar(	"l4d_gear_transfer_dist_give",	"150.0",	"电脑自动给予玩家物品范围.",									CVAR_FLAGS);
	g_hDistGrab = CreateConVar(	"l4d_gear_transfer_dist_grab",	"200.0",	"电脑自动搜索物品范围.",					CVAR_FLAGS);
	g_hEnable = CreateConVar(	"l4d_gear_transfer_enabled",	"1",		"0=关闭, 1=开启. 开启插件.",									CVAR_FLAGS);
	g_hMethod = CreateConVar(	"l4d_gear_transfer_method",		"2",		"0=仅能用鼠标右键转移, 1=仅能用装子弹的键(R)转移, 2=两种方法都可以转移物品.",	CVAR_FLAGS);
	g_hModes = CreateConVar(	"l4d_gear_transfer_modes",		"versus",	"禁止插件这些模式中转移物品.",						CVAR_FLAGS);
	g_hModesOff = CreateConVar(	"l4d_gear_transfer_modes_off",	"",			"禁止插件这些模式中运行.",										CVAR_FLAGS);
	g_hNotify = CreateConVar(	"l4d_gear_transfer_notify",		"1",		"0=关闭, 1=开启转移提示.",			CVAR_FLAGS);
	g_hSounds = CreateConVar(	"l4d_gear_transfer_sounds",		"1",		"0=关闭, 1=开启转移时声音提示.",				CVAR_FLAGS);
	g_hTimerAuto = CreateConVar("l4d_gear_transfer_timer",		"1.0",		"多少秒进行检查并让电脑给予玩家物品.",	CVAR_FLAGS, true, 0.5, true, 10.0);
	g_hTimerItem = CreateConVar("l4d_gear_transfer_timer_item",	"5.0",		"多少秒更新物品位置并自动交换物品.",					CVAR_FLAGS, true, 5.0, true, 30.0);
	CreateConVar("l4d_gear_transfer_version", PLUGIN_VERSION, "插件版本.", CVAR_FLAGS|FCVAR_DONTRECORD);
	AutoExecConfig(true, "l4d_gear_transfer");

	// Current cvars
	GetCvarsA();
	GetCvarsB();
	GetCvarsC();

	// Cvars hooks
	HookConVarChange(g_hAllowAdr, ConVarChanged_CvarAllow);
	HookConVarChange(g_hAllowDef, ConVarChanged_CvarAllow);
	HookConVarChange(g_hAllowExp, ConVarChanged_CvarAllow);
	HookConVarChange(g_hAllowFir, ConVarChanged_CvarAllow);
	HookConVarChange(g_hAllowMol, ConVarChanged_CvarAllow);
	HookConVarChange(g_hAllowInc, ConVarChanged_CvarAllow);
	HookConVarChange(g_hAllowPil, ConVarChanged_CvarAllow);
	HookConVarChange(g_hAllowPip, ConVarChanged_CvarAllow);
	HookConVarChange(g_hAllowVom, ConVarChanged_CvarAllow);
	HookConVarChange(g_hAutoGive, ConVarChanged_Cvar);
	HookConVarChange(g_hAutoGrab, ConVarChanged_Cvar);
	HookConVarChange(g_hBotAdr, ConVarChanged_CvarBot);
	HookConVarChange(g_hBotDef, ConVarChanged_CvarBot);
	HookConVarChange(g_hBotExp, ConVarChanged_CvarBot);
	HookConVarChange(g_hBotFir, ConVarChanged_CvarBot);
	HookConVarChange(g_hBotMol, ConVarChanged_CvarBot);
	HookConVarChange(g_hBotInc, ConVarChanged_CvarBot);
	HookConVarChange(g_hBotPil, ConVarChanged_CvarBot);
	HookConVarChange(g_hBotPip, ConVarChanged_CvarBot);
	HookConVarChange(g_hBotVom, ConVarChanged_CvarBot);
	HookConVarChange(g_hDistGive, ConVarChanged_Cvar);
	HookConVarChange(g_hDistGrab, ConVarChanged_Cvar);
	HookConVarChange(g_hEnable, ConVarChanged_Enable);
	HookConVarChange(g_hMethod, ConVarChanged_Cvar);
	HookConVarChange(g_hNotify, ConVarChanged_Cvar);
	HookConVarChange(g_hSounds, ConVarChanged_Cvar);
	HookConVarChange(g_hTimerAuto, ConVarChanged_Cvar);
	HookConVarChange(g_hTimerItem, ConVarChanged_Cvar);

	// Hook mp_gamemde to disable auto give/grab in versus
	g_hMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hMPGameMode, Cvar_GameMode);
	HookConVarChange(g_hModes, Cvar_GameMode);
	HookConVarChange(g_hModesOff, Cvar_GameMode);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	InitPlugin();
}


public OnMapStart()
{
	PrecacheSound(SOUND_LITTLEREWARD);
	PrecacheSound(SOUND_BIGREWARD);
}


InitPlugin()
{
	// Reset array
	for( new i = 0; i < ITEMZ; i++ )
		ResetItemArray(i);

	IsModeBlocked();

	// Start auto give/grab. Do not allow auto give/grab in specified modes mode.
	if( g_bEnable && !g_bModeOff && !g_bModeOffAuto && !g_bRoundOver )
	{
		HookEvents();
		MakeTimers();
	}
}



// ======================================================================================
//					C V A R   C H A N G E
// ======================================================================================
public ConVarChanged_Enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bEnable = GetConVarBool(g_hEnable);

	if( g_bEnable )
	{
		HookEvents();
		MakeTimers();
	}
	else
	{
		UnhookEvents();
	}
}


public ConVarChanged_CvarAllow(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetCvarsA();
}


public ConVarChanged_CvarBot(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetCvarsB();
}


public ConVarChanged_Cvar(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetCvarsC();

	if( g_bAutoGive || g_bAutoGrab )
		MakeTimers();
}


public Cvar_GameMode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	IsModeBlocked();
	MakeTimers();
}



// ======================================================================================
//					G E T   C V A R S
// ======================================================================================
GetCvarsA()
{
	g_bAllowAdr = GetConVarBool(g_hAllowAdr);
	g_bAllowDef = GetConVarBool(g_hAllowDef);
	g_bAllowExp = GetConVarBool(g_hAllowExp);
	g_bAllowFir = GetConVarBool(g_hAllowFir);
	g_bAllowInc = GetConVarBool(g_hAllowInc);
	g_bAllowMol = GetConVarBool(g_hAllowMol);
	g_bAllowPil = GetConVarBool(g_hAllowPil);
	g_bAllowPip = GetConVarBool(g_hAllowPip);
	g_bAllowVom = GetConVarBool(g_hAllowVom);
}


GetCvarsB()
{
	g_iBotAdr = GetConVarInt(g_hBotAdr);
	g_iBotDef = GetConVarInt(g_hBotDef);
	g_iBotExp = GetConVarInt(g_hBotExp);
	g_iBotFir = GetConVarInt(g_hBotFir);
	g_iBotInc = GetConVarInt(g_hBotInc);
	g_iBotMol = GetConVarInt(g_hBotMol);
	g_iBotPil = GetConVarInt(g_hBotPil);
	g_iBotPip = GetConVarInt(g_hBotPip);
	g_iBotVom = GetConVarInt(g_hBotVom);
}


GetCvarsC()
{
	g_bAutoGive = GetConVarBool(g_hAutoGive);
	g_bAutoGrab = GetConVarBool(g_hAutoGrab);
	g_fDistGive = GetConVarFloat(g_hDistGive);
	g_fDistGrab = GetConVarFloat(g_hDistGrab);
	g_bEnable = GetConVarBool(g_hEnable);
	g_iMethod = GetConVarInt(g_hMethod);
	g_bNotify = GetConVarBool(g_hNotify);
	g_bSounds = GetConVarBool(g_hSounds);
	g_fTimerAuto = GetConVarFloat(g_hTimerAuto);
	g_fTimerItem = GetConVarFloat(g_hTimerItem);
}



// ======================================================================================
//					H O O K   E V E N T S
// ======================================================================================
HookEvents()
{
	if( !g_bHooked )
	{
		HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("finale_vehicle_leaving", Event_RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("spawner_give_item", Event_SpawnerGiveItem);
		HookEvent("weapon_fire", Event_WeaponFire);
		HookEvent("weapon_given", Event_WeaponGiven);
		HookEvent("player_shoved", Event_PlayerShoved);
		g_bHooked = true;
	}
}


UnhookEvents()
{
	if( g_bHooked )
	{
		UnhookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("finale_vehicle_leaving", Event_RoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("spawner_give_item", Event_SpawnerGiveItem);
		UnhookEvent("weapon_fire", Event_WeaponFire);
		UnhookEvent("weapon_given", Event_WeaponGiven);
		UnhookEvent("player_shoved", Event_PlayerShoved);
		g_bHooked = false;
	}
}



// ======================================================================================
//					E V E N T  -  S T A R T  /  E N D
// ======================================================================================
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bRoundOver = false;
	InitPlugin();

	// Vocalize block
	if( g_bEnable && !g_bModeOff && (g_bAutoGive || g_bAutoGrab) )
	{
		if( g_hBlockVocalize != INVALID_HANDLE )
			CloseHandle(g_hBlockVocalize);
		g_hBlockVocalize = INVALID_HANDLE;

		g_hBlockVocalize = CreateTimer(60.0, tmrUnblockVocalize);
		g_bBlockVocalize = true;
	}
}


public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bRoundOver = true;

	if( g_hAutoGiveGrab != INVALID_HANDLE )
		CloseHandle(g_hAutoGiveGrab);
	g_hAutoGiveGrab = INVALID_HANDLE;
	
	if( g_hGetItemSpawn != INVALID_HANDLE )
		CloseHandle(g_hGetItemSpawn);
	g_hGetItemSpawn = INVALID_HANDLE;
}



// ======================================================================================
//					E V E N T  -  S P A W N E R   G I V E   I T E M
// ======================================================================================
public Action:Event_SpawnerGiveItem(Handle:event, const String:name[], bool:dontBroadcast)
// Delete the last item picked up from a weapon_spawn to stop bots auto grabbing nothing!
{
	if( !g_bAutoGrab )					// Bug only with auto grab
		return;

	new ent = GetEventInt(event, "spawner");
	new flag = GetEntProp(ent, Prop_Data, "m_spawnflags");
	if( flag & (1<<3) ) return;	// Infinite ammo
	new value = GetEntProp(ent, Prop_Data, "m_itemCount");
	if( value > 1 )	return;		// We only need to delete if theres 1 item at the spawn

	decl String:s_EdictClassName[32];
	GetEdictClassname(ent, s_EdictClassName, sizeof(s_EdictClassName));	// Item name

	for( new i = 0; i < 3; i++ )
	{
		if( StrContains(s_EdictClassName, g_Pickups[i], false) != -1 )			// Item must be a grenade
			AcceptEntityInput(ent, "kill");
	}
}



// ======================================================================================
//					E V E N T  -  W E A P O N    F I R E
// ======================================================================================
// This event stops duplicate grenades being created when someone throws and tries to transfer
public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( IsFakeClient(client) || GetClientTeam(client) != 2 )
		return;

	decl String:sWeapon[10];
	GetEventString(event, "weapon", sWeapon, 10);

	if( StrEqual(sWeapon, "pipe_bomb") || StrEqual(sWeapon, "molotov") || StrEqual(sWeapon, "vomitjar") )
	{
		g_bHasTransferred[client] = true;
		CreateTimer(2.0, tmrResetTransfer, client);
	}
}



// ======================================================================================
//					E V E N T  -  P I L L S  /  A D R E N   G I V E N
// ======================================================================================
// This event stops pills/adren being auto grabbed by bots after you have given to them
public Action:Event_WeaponGiven(Handle:event, const String:name[], bool:dontBroadcast)
{
	new i_Weapon = GetEventInt(event, "weapon");

	if( i_Weapon == 15 || i_Weapon == 23 )
	{
		new i_UserID = GetClientOfUserId(GetEventInt(event, "giver"));
		if( IsFakeClient(i_UserID) )
			return;

		if( g_bAutoGive )
		{
			g_bGiveBlocked = true;
			if( g_hGiveBlocked != INVALID_HANDLE )
				CloseHandle(g_hGiveBlocked);
			g_hGiveBlocked = CreateTimer(5.0, tmrResetGive);
		}
	}
}



// ======================================================================================
//					E V E N T  -  P L A Y E R   S H O V E D
// ======================================================================================
public Action:Event_PlayerShoved(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	if( g_iMethod == 1 ) // Reload key only
		return;

	new i_Victim = GetClientOfUserId(GetEventInt(h_Event, "userid"));
	if( GetClientTeam(i_Victim) != 2 || !IsPlayerAlive(i_Victim) )
		return;

	new i_Attacker = GetClientOfUserId(GetEventInt(h_Event, "attacker"));
	if( IsFakeClient(i_Attacker) || g_bHasTransferred[i_Attacker] ) // They just transferred
		return;

	TransferItem(i_Attacker, i_Victim, true);
}



// ======================================================================================
//					O N   P L A Y E R   R U N   C M D
// ======================================================================================
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if( !g_bEnable || g_bModeOff || g_bRoundOver || IsFakeClient(client) || GetClientTeam(client) != 2 )
		return;

	new bool:b_FromShove;

	if( buttons & IN_RELOAD )
	{
		if( g_iMethod == 0 ) // 0 = Shove key only
			return;
	}
	if( buttons & IN_ATTACK2 )
	{
		if( g_iMethod == 1 ) // 1 = Reload key only
			return;

		b_FromShove = true;
	}

	if( buttons & IN_RELOAD || buttons & IN_ATTACK2 )
	{
		if( g_bHasTransferred[client] )						// They just transferred, return
			return;

		new target = GetClientAimTarget(client, true);		// They must be able at an alive survivor

		if( target < 1 || GetClientTeam(target) != 2 || !IsPlayerAlive(target) )
			return;

		decl Float:f_Client[3], Float:f_Target[3], Float:f_Distance;

		GetClientAbsOrigin(client, f_Client);			// Get attacker position
		GetClientAbsOrigin(target, f_Target);			// Get target position
		f_Distance = GetVectorDistance(f_Client, f_Target);

		if( f_Distance <= g_fDistGive && IsVisibleTo(f_Client, f_Target) )		// They are within range and visible
			TransferItem(client, target, b_FromShove);
	}
}



// ======================================================================================
//					T R A N S F E R   I T E M
// ======================================================================================
TransferItem(i_Attacker, i_Victim, bool:b_FromShove)
{
	// Don't allow transfers while incapped
	if( IsReviving(i_Attacker) || IsIncapped(i_Attacker) || IsReviving(i_Victim) || IsIncapped(i_Victim) )
		return;

	// Declare variables
	new i, i_Slot,
	bool:HoldingGrenade,		// Attacker is holding a grenade
	bool:HoldingMedSlot,		// Attacker is holding pain pills / adrenaline
	bool:HoldingSpecial,		// Attacker is holding medkit, defib or upgrade ammo
	bool:AttackerHolding,		// Attacker has item in hand
	bool:AttackerGrenade,		// Attacker has a grenade
	bool:AttackerSpecial,		// Attacker has first aid, defib or upgrade ammo
	bool:AttackerMedSlot,		// Attacker has pain pills or adrenaline
	bool:VictimGrenade,			// Bot has a grenade
	bool:VictimSpecial,			// Bot has first aid, defib or upgrade ammo
	bool:VictimMedSlot,			// Bot has pain plls or adrenaline
	bool:VictimIsFake;
	decl String:s_Weapon[40],	// Player weapon
	String:s_BotsItem[40],		// Temp string
	String:s_BotGrenade[40],	// Bot molotov/pipebomb/vomitjar
	String:s_BotSpecial[40],	// Bot firstaidkit/defib/incendiary/explosive
	String:s_BotMedSlot[40];	// Bot pain pills/adrenaline


	// Fill variables
	if( IsFakeClient(i_Victim) )
		VictimIsFake = true;

	GetClientWeapon(i_Attacker, s_Weapon, sizeof(s_Weapon));
	i = GetItemNumber(s_Weapon);

	if( i >= 0 && i <= 2 )
		HoldingGrenade = true;
	else if( i == 4 || i == 5 )
		HoldingMedSlot = true;
	else if( i == 3 || i >= 6 )
		HoldingSpecial = true;

	if( i != -1 )
		AttackerHolding = true;						// Switch, give

	if( b_FromShove && i == 3 )						// Don't allow medkits to be transferred from shoves, so they can heal others!
		return;

	i = GetPlayerWeaponSlot(i_Attacker, 2);			// Attacker has grenade
	if( i != -1 )
		AttackerGrenade = true;

	i = GetPlayerWeaponSlot(i_Attacker, 3);			// Attacker has special
	if( i != -1 )
		AttackerSpecial = true;

	i = GetPlayerWeaponSlot(i_Attacker, 4);			// Attacker has MedSlot
	if( i != -1 )
		AttackerMedSlot = true;

	i = GetPlayerWeaponSlot(i_Victim, 2);			// Victim grenade
	if( i != -1 )
	{
		GetEdictClassname(i, s_BotGrenade, sizeof(s_BotGrenade));
		VictimGrenade = true;
	}

	i = GetPlayerWeaponSlot(i_Victim, 3);			// Victim special
	if( i != -1 )
	{
		GetEdictClassname(i, s_BotSpecial, sizeof(s_BotSpecial));
		VictimSpecial = true;
	}

	i = GetPlayerWeaponSlot(i_Victim, 4);			// Victim MedSlot
	if( i != -1 )
	{
		GetEdictClassname(i, s_BotMedSlot, sizeof(s_BotMedSlot));
		VictimMedSlot = true;
	}


	// ########## GIVE ##########  -  If player with an item has shoved a survivor without an item, transfer
	if( AttackerHolding )
	{
		if( HoldingGrenade && AttackerGrenade && !VictimGrenade
		|| HoldingSpecial && AttackerSpecial && !VictimSpecial
		|| HoldingMedSlot && AttackerMedSlot && !VictimMedSlot )
		{
			// Don't allow humans to transfer after giving, and bots to transfer after receiving
			g_bHasTransferred[i_Attacker] = true;
			CreateTimer(1.0, tmrResetTransfer, i_Attacker);

			if( !AllowedToTransfer(s_Weapon) )
				return;

			if( HoldingMedSlot )
			{
				if( b_FromShove )	// Don't transfer pills/adren from shoves, the game already does this!
					return;
				i_Slot = 4;
			}
			else if( HoldingGrenade )
			{
				i_Slot = 2;
			}
			else
			{
				i_Slot = 3;
			}

			if( VictimIsFake && g_bAutoGive )
			{
				g_bGiveBlocked = true;
				if( g_hGiveBlocked != INVALID_HANDLE )
					CloseHandle(g_hGiveBlocked);
				g_hGiveBlocked = CreateTimer(5.0, tmrResetGive);
			}

			if( g_bSounds )
			{
				PlaySound(i_Victim, SOUND_LITTLEREWARD);
				PlaySound(i_Attacker, SOUND_BIGREWARD);
			}

			StripWeapon(i_Attacker, i_Slot);
			// SIMT(s_Weapon, i_Attacker, i_Victim);
			GiveItem(i_Victim, s_Weapon);
			Vocalize(i_Victim, s_Weapon);

			if( g_bNotify && g_bTranslation && !g_bBlockVocalize )
				CPrintToChatAll("\x05%N \x01%t \x04%t \x01%t \x05%N", i_Attacker, "Gave", s_Weapon, "To", i_Victim);

			return;
		}
	}


	if( VictimIsFake && !HasSpectator(i_Victim) )
	{
		// ########## SWITCH ##########  -  If player with an item has shoved a bot also with an item, switch!
		if( AttackerHolding )
		{
			if( HoldingGrenade && AttackerGrenade && VictimGrenade
			|| HoldingSpecial && AttackerSpecial && VictimSpecial
			|| HoldingMedSlot && AttackerMedSlot && VictimMedSlot )
			{
				if( !AllowedToTransfer(s_Weapon) )		// Is the client allowed to switch this item
					return;

				g_bHasTransferred[i_Attacker] = true;
				CreateTimer(1.0, tmrResetTransfer, i_Attacker);

				if( HoldingMedSlot )
				{
					s_BotsItem = s_BotMedSlot;
					i_Slot = 4;
				}
				else if( HoldingGrenade && AttackerGrenade && VictimGrenade )
				{
					s_BotsItem = s_BotGrenade;
					i_Slot = 2;
				}
				else if( HoldingSpecial && AttackerSpecial && VictimSpecial )
				{
					s_BotsItem = s_BotSpecial;
					i_Slot = 3;
				}

				if( !AllowedToTransfer(s_BotsItem) )
					return;

				if( g_bAutoGive )
				{
					g_bGiveBlocked = true;
					if( g_hGiveBlocked != INVALID_HANDLE )
						CloseHandle(g_hGiveBlocked);
					g_hGiveBlocked = CreateTimer(5.0, tmrResetGive);
				}

				StripWeapon(i_Attacker, i_Slot);
				StripWeapon(i_Victim, i_Slot);
				GiveItem(i_Attacker, s_BotsItem);
				GiveItem(i_Victim, s_Weapon);
				Vocalize(i_Attacker, s_BotsItem);

				// Switch to previous weapon to stop the bug where Molotovs appear with Pipe particles and vice versa.
				ClientCommand(i_Attacker, "lastinv");

				if( g_bSounds )
				{
					PlaySound(i_Victim, SOUND_LITTLEREWARD);
					PlaySound(i_Attacker, SOUND_BIGREWARD);
				}

				if( g_bNotify && g_bTranslation && !g_bBlockVocalize )
				{
					CPrintToChatAll("\x05%N \x01%t \x04%t \x01%t \x05%N", i_Attacker, "Switched", s_Weapon, "With", i_Victim);
					CPrintToChatAll("\x05%N \x01%t \x04%t \x01%t \x05%N", i_Victim, "Gave", s_BotsItem, "To", i_Attacker);
				}

				return;
			}
		}


		// ########## GRAB ##########  -  If player with no grenade has shoved a bot with a grenade, transfer
		if( !AttackerGrenade && VictimGrenade
		|| !AttackerSpecial && VictimSpecial
		|| !AttackerMedSlot && VictimMedSlot )
		{

			g_bHasTransferred[i_Attacker] = true;
			CreateTimer(1.0, tmrResetTransfer, i_Attacker);

			if( !AttackerMedSlot && VictimMedSlot )
			{
				s_BotsItem = s_BotMedSlot;
				i_Slot = 4;
			}
			else if( !AttackerGrenade && VictimGrenade )
			{
				s_BotsItem = s_BotGrenade;
				i_Slot = 2;
			}
			else if( !AttackerSpecial && VictimSpecial )
			{
				s_BotsItem = s_BotSpecial;
				i_Slot = 3;
			}

			if( !AllowedToTransfer(s_BotsItem) )
				return;

			if( g_bSounds )
				PlaySound(i_Attacker, SOUND_LITTLEREWARD); // Received item

			StripWeapon(i_Victim, i_Slot);
			// SIMT(s_BotsItem, i_Victim, i_Attacker);
			GiveItem(i_Attacker, s_BotsItem);
			Vocalize(i_Attacker, s_BotsItem);

			if( g_bNotify && g_bTranslation && !g_bBlockVocalize )
				CPrintToChatAll("\x05%N \x01%t \x04%t \x01%t \x05%N", i_Attacker, "Grabbed", s_BotsItem, "From", i_Victim);

			return;
		}
	}
}



// ======================================================================================
//					A L L O W E D   T O   T R A N S F E R
// ======================================================================================
stock bool:HasSpectator(client)
{
	decl String:sNetClass[12];
	GetEntityNetClass(client, sNetClass, sizeof(sNetClass));

	if( StrEqual(sNetClass, "SurvivorBot") )
	{
		if( !GetEntProp(client, Prop_Send, "m_humanSpectatorUserID") )
			return false;
	}
	return true;
}


stock bool:IsReviving(client)
{
	if( GetEntProp(client, Prop_Send, "m_reviveOwner", 1) > 0 )
		return true;
	return false;
}


stock bool:IsIncapped(client)
{
	if( GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0 )
		return true;
	return false;
}


IsModeBlocked()
{
	decl String:sGameMode[32], String:sGameModes[64];

	GetConVarString(g_hMPGameMode, sGameMode, sizeof(sGameMode));
	GetConVarString(g_hModes, sGameModes, sizeof(sGameModes));
	g_bModeOffAuto = (StrContains(sGameModes, sGameMode) != -1);

	GetConVarString(g_hModesOff, sGameModes, sizeof(sGameModes));
	g_bModeOff = (StrContains(sGameModes, sGameMode) != -1);

	if( g_bModeOff ) 
		UnhookEvents();
	else
	{
		HookEvents();
		MakeTimers();
	}
}


GetItemNumber(String:s_Item[40])
{
	for( new i = 0; i < 9; i++ )
	{
		if( StrContains(s_Item, g_Pickups[i]) != -1 )
			return i;
	}

	return -1;
}


bool:AllowedToTransfer(String:s_Item[40])
{
	new i = GetItemNumber(s_Item);

	switch (i)
	{
		case -1: return false;
		case 0: if( g_bAllowMol ) return true;
		case 1: if( g_bAllowPip ) return true;
		case 2: if( g_bAllowVom ) return true;
		case 3: if( g_bAllowFir ) return true;
		case 4: if( g_bAllowPil ) return true;
		case 5: if( g_bAllowAdr ) return true;
		case 6: if( g_bAllowExp ) return true;
		case 7: if( g_bAllowInc ) return true;
		case 8: if( g_bAllowDef ) return true;
	}

	return false;
}


bool:BotAllowedTransfer(String:s_Item[40], bool:bGive = false)
{
	new i = GetItemNumber(s_Item);

	switch (i)
	{
		case -1: return false;
		case 0: if( g_iBotMol == 1 || g_iBotMol == 2 && bGive || g_iBotMol == 3 && !bGive ) return true;
		case 1: if( g_iBotPip == 1 || g_iBotPip == 2 && bGive || g_iBotPip == 3 && !bGive ) return true;
		case 2: if( g_iBotVom == 1 || g_iBotVom == 2 && bGive || g_iBotVom == 3 && !bGive ) return true;
		case 3: if( g_iBotFir == 1 || g_iBotFir == 2 && bGive || g_iBotFir == 3 && !bGive ) return true;
		case 4: if( g_iBotPil == 1 || g_iBotPil == 2 && bGive || g_iBotPil == 3 && !bGive ) return true;
		case 5: if( g_iBotAdr == 1 || g_iBotAdr == 2 && bGive || g_iBotAdr == 3 && !bGive ) return true;
		case 6: if( g_iBotExp == 1 || g_iBotExp == 2 && bGive || g_iBotExp == 3 && !bGive ) return true;
		case 7: if( g_iBotInc == 1 || g_iBotInc == 2 && bGive || g_iBotInc == 3 && !bGive ) return true;
		case 8: if( g_iBotDef == 1 || g_iBotDef == 2 && bGive || g_iBotDef == 3 && !bGive ) return true;
	}

	return false;
}



// ======================================================================================
//					G I V E   A N   I T E M
// ======================================================================================
GiveItem(client, String:s_Class[40])
{
	new i_Ent = CreateEntityByName(s_Class);

	if( i_Ent == -1 )
	{
		LogError("Failed to create entity '%s' for %N", s_Class, client);
	}
	else
	{
		if( !DispatchSpawn(i_Ent) )
			LogError("Failed to dispatch '%s' for %N", s_Class, client);
		else
			EquipPlayerWeapon(client, i_Ent);
	}
}


StripWeapon(client, i_Slot)
{
	new i_Ent = GetPlayerWeaponSlot(client, i_Slot);

	if( i_Ent != -1 )
	{
		RemovePlayerItem(client, i_Ent);
		AcceptEntityInput(i_Ent, "kill");
	}
}



// ======================================================================================
//					R E S E T   T I M E R S
// ======================================================================================
public Action:tmrResetTransfer(Handle:timer, any:client)
{
	g_bHasTransferred[client] = false;
}


public Action:tmrResetGive(Handle:timer, any:client)
{
	g_hGiveBlocked = INVALID_HANDLE;
	g_bGiveBlocked = false;
}


public Action:tmrUnblockVocalize(Handle:timer)
{
	g_hBlockVocalize = INVALID_HANDLE;
	g_bBlockVocalize = false;
}


ResetItemArray(i)
{
	g_iItemSpawnID[i] = -1;
	g_fItemSpawn_XYZ[i] = Float:{ 0.0, 0.0, 0.0 };
}



// ======================================================================================
//					V O C A L I Z E
// ======================================================================================
Vocalize(i_Client, String:s_Class[40])
{
	// We don't need to vocalize vomitjars, defibs, explosive ammo or incendiary ammo.
	if( g_bBlockVocalize )
		return;

	if( StrEqual(s_Class,"weapon_pain_pills") ) return;
	else if( StrEqual(s_Class,"weapon_adrenaline") ) return;
	else if( StrEqual(s_Class,"weapon_defibrillator") ) return;
	else if( StrEqual(s_Class,"weapon_upgradepack_explosive") ) return;
	else if( StrEqual(s_Class,"weapon_upgradepack_incendiary") ) return;
	else if( StrEqual(s_Class,"weapon_vomitjar") ) return;

	// Declare variables
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];

	// Get survivor model
	GetEntPropString(i_Client, Prop_Data, "m_ModelName", s_Model, 64);

	if( StrEqual(s_Model, "models/survivors/survivor_coach.mdl") ) { Format(s_Model,9,"coach"); i_Type = 1; }
	else if( StrEqual(s_Model, "models/survivors/survivor_gambler.mdl") ) { Format(s_Model,9,"gambler"); i_Type = 2; }
	else if( StrEqual(s_Model, "models/survivors/survivor_mechanic.mdl") ) { Format(s_Model,9,"mechanic"); i_Type = 3; }
	else if( StrEqual(s_Model, "models/survivors/survivor_producer.mdl") ) { Format(s_Model,9,"producer"); i_Type = 4; }
	else if( StrEqual(s_Model, "models/survivors/survivor_namvet.mdl") ) { Format(s_Model,9,"NamVet"); i_Type = 5; }
	else if( StrEqual(s_Model, "models/survivors/survivor_biker.mdl") ) { Format(s_Model,9,"Biker"); i_Type = 6; }
	else if( StrEqual(s_Model, "models/survivors/survivor_manager.mdl") ) { Format(s_Model,9,"Manager"); i_Type = 7; }
	else if( StrEqual(s_Model, "models/survivors/survivor_teenangst.mdl") ) { Format(s_Model,9,"TeenGirl"); i_Type = 8; }
	else { LogError("failed to vocalize %s for %s", s_Class, s_Model); return; }

	// Pipe Bomb
	if( StrEqual(s_Class,"weapon_pipe_bomb") )
	{
		switch (i_Type)
		{
			case 1: i_Max = 2;	// Coach
			case 2: i_Max = 1;	// Nick
			case 3: i_Max = 2;	// Ellis
			case 4: i_Max = 1;	// Rochelle
			case 5: i_Max = 3;	// Bill
			case 6: i_Max = 4;	// Francis
			case 7: i_Max = 3;	// Louis
			case 8: i_Max = 1;	// Zoey
		}
	}

	// Molotov
	else if( StrEqual(s_Class,"weapon_molotov") )
	{
		switch (i_Type)
		{
			case 1: {i_Min = 3; i_Max = 4;}
			case 2: {i_Min = 2; i_Max = 3;}
			case 3: {i_Min = 3; i_Max = 10;}
			case 4: {i_Min = 2; i_Max = 5;}
			case 5: {i_Min = 5; i_Max = 6;}
			case 6: {i_Min = 5; i_Max = 7;}
			case 7: {i_Min = 4; i_Max = 6;}
			case 8: {i_Min = 2; i_Max = 5;}
		}
	}

	// First aid
	else if( StrEqual(s_Class,"weapon_first_aid_kit") )
	{
		switch (i_Type)
		{
			case 1: {i_Min = 5; i_Max = 7;}
			case 2: {i_Min = 4; i_Max = 8;}
			case 3: {i_Min = 11; i_Max = 14;}
			case 4: {i_Min = 6; i_Max = 8;}
			case 5: {i_Min = 7; i_Max = 9;}
			case 6: {i_Min = 8; i_Max = 11;}
			case 7: {i_Min = 7; i_Max = 8;}
			case 8: {i_Min = 6; i_Max = 9;}
		}
	}
	else
	{
		return;
	}

	// Random number
	i_Rand = GetRandomInt(i_Min, i_Max);

	decl String:s_Temp[40];
	// Select random vocalize
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp),"%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp),"%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp),"%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp),"%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp),"%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp),"%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp),"%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp),"%s", g_Zoey[i_Rand]);
	}

	// Create scene location and call
	decl String:s_Scene[64];
	Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
	VocalizeScene(i_Client, s_Scene);
}



// Taken from:
// [Tech Demo] L4D2 Vocalize ANYTHING
// http://forums.alliedmods.net/showthread.php?t=122270
// author = "AtomicStryker"
// ======================================================================================
//					V O C A L I Z E   S C E N E
// ======================================================================================
VocalizeScene(client, String:scenefile[64])
{
	if( !FileExists(scenefile, true) )
	{
		LogError("Specified Scenefile: %s does not exist, aborting", scenefile);
		return;
	}

	new tempent = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(tempent, "SceneFile", scenefile);
	DispatchSpawn(tempent);
	SetEntPropEnt(tempent, Prop_Data, "m_hOwner", client);
	ActivateEntity(tempent);
	AcceptEntityInput(tempent, "Start", client, client);
}


PlaySound(client, const String:s_Sound[32])
	EmitSoundToClient(client, s_Sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);



// ======================================================================================
//					P R I N T   T O   C H A T   A L L
// ======================================================================================
// Taken from:
// http://docs.sourcemod.net/api/index.php?fastload=show&id=151&
CPrintToChatAll(const String:format[], any:...)
{
	decl String:buffer[192];

	for( new i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 2);
			PrintToChat(i, buffer);
		}
	}
}



// ======================================================================================
//					A U T O   G I V E   A N D   G R A B   S T U F F
// ======================================================================================

// ======================================================================================
//					A U T O   G I V E / G R A B   T I M E R S
// ======================================================================================
MakeTimers()
{
	if( !g_bEnable || g_bModeOff || g_bModeOffAuto || g_bRoundOver )
		return;

	if( g_bAutoGive || g_bAutoGrab )
		MakeAutoTimer();

	if( g_bAutoGrab )
		MakeItemTimer();
}


// Auto give / auto grab timers
MakeAutoTimer()
{
	if( g_hAutoGiveGrab != INVALID_HANDLE )
	{
		CloseHandle(g_hAutoGiveGrab);
		g_hAutoGiveGrab = INVALID_HANDLE;
	}

	// Allows the timer to have a dynamic time.
	g_hAutoGiveGrab = CreateTimer(g_fTimerAuto, tmrAutoGiveGrab);
}


public Action:tmrAutoGiveGrab(Handle:timer)
{
	g_hAutoGiveGrab = INVALID_HANDLE;

	if( !g_bEnable || g_bModeOff || g_bModeOffAuto || g_bRoundOver || (!g_bAutoGive && !g_bAutoGrab) )
		return;

	if( g_bAutoGive && !g_bGiveBlocked )
		CreateTimer(0.1, tmrAutoGive, _, TIMER_FLAG_NO_MAPCHANGE);

	if( g_bAutoGrab )
		CreateTimer(0.4, tmrAutoGrab, _, TIMER_FLAG_NO_MAPCHANGE);

	CreateTimer(0.1, tmrMakeAutoTmr, _, TIMER_FLAG_NO_MAPCHANGE);
}


public Action:tmrMakeAutoTmr(Handle:timer)
{
	MakeAutoTimer();
}


// Get item spawn locations timer
MakeItemTimer()
{
	if( g_hGetItemSpawn != INVALID_HANDLE )
	{
		CloseHandle(g_hGetItemSpawn);
		g_hGetItemSpawn = INVALID_HANDLE;
	}

	// Allows the timer to have a dynamic time.
	g_hGetItemSpawn = CreateTimer(g_fTimerItem, tmrGetItemSpawn);
}


public Action:tmrGetItemSpawn(Handle:timer)
{
	g_hGetItemSpawn = INVALID_HANDLE;

	if( !g_bEnable || !g_bModeOff && g_bModeOffAuto || g_bRoundOver || !g_bAutoGrab )
		return;

	CreateTimer(0.1, tmrMakeItemTmr, _, TIMER_FLAG_NO_MAPCHANGE);
	GetItemSpawns();
}


public Action:tmrMakeItemTmr(Handle:timer)
{
	MakeItemTimer();
}


// ======================================================================================
//					G E T   G R E N A D E   S P A W N S
// ======================================================================================
GetItemSpawns()
{
	new i, count, ent = -1, Float:f_Location[3];
	decl String:s_Entity[40];

	// Search for dynamic weapon spawns
	for( i = 0; i < 18; i++ )
	{
		// We need to check for example: weapon_molotov_spawn and weapon_molotov (items at spawn and items dropped)
		if( i < 9 )
			Format(s_Entity, 40, "%s_spawn", g_Pickups[i]);
		else
			Format(s_Entity, 40, "%s", g_Pickups[i-9]);

		if( !BotAllowedTransfer(s_Entity) )
			continue;

		// Find items
		while( (ent = FindEntityByClassname(ent, s_Entity)) != -1 )
		{
			// Do not save non _spawn items which have owners.
			if( i > 8 && GetEntProp(ent, Prop_Send, "m_hOwnerEntity") != -1 )
				continue;

			// Save entity ID and origin.
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", f_Location);
			g_iItemSpawnID[count] = ent;
			g_fItemSpawn_XYZ[count] = f_Location;

			// Increment count but do not exceed ITEMZ limit.
			count++;
			g_iItemCount = count;
			if( count == ITEMZ )
				return;
		}
	}
	g_iItemCount = count;
}



// ======================================================================================
//					A U T O   K I L L  /  G R A B   S T U F F
// ======================================================================================
// ########## AUTO GIVE ########## - Loop through players and bots to check if they can receive/give items
public Action:tmrAutoGive(Handle:timer)
{
	if( g_bGiveBlocked )
		return;

	// Variables
	new i, i_Slot, client, player, bool:b_ClientGrenade, bool:b_ClientSpecial, bool:b_ClientMedSlot;
	decl Float:f_ClientPos[3], Float:f_PlayerPos[3], Float:f_Distance, String:s_EdictClassName[40];

	// Loop through bots
	for( client = 1; client <= MaxClients; client++ )
	{
		// Make sure client is team survivor and alive
		if( IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && IsFakeClient(client) )
		{
			// Make sure they are a bot and not an idle player. Don't allow transfers when incapped or being revived
			if( !HasSpectator(client) && !IsReviving(client) && !IsIncapped(client) )
			{
				if( GetPlayerWeaponSlot(client, 2) != -1 ) b_ClientGrenade = true; else b_ClientGrenade = false;
				if( GetPlayerWeaponSlot(client, 3) != -1 ) b_ClientSpecial = true; else b_ClientSpecial = false;
				if( GetPlayerWeaponSlot(client, 4) != -1 ) b_ClientMedSlot = true; else b_ClientMedSlot = false;

				if( b_ClientGrenade || b_ClientSpecial || b_ClientMedSlot )
				{
					GetClientEyePosition(client, f_ClientPos);				// Get bot position

					// Loop through the clients
					for( player = 1; player <= MaxClients; player++ )
					{

						// Player in game, human player, alive, team survivor, 
						if( client != player && IsClientInGame(player) && !IsFakeClient(player) && IsPlayerAlive(player) && GetClientTeam(player) == 2 && 
						// Don't allow transfers when incapped or being revived
						!IsReviving(player) && !IsIncapped(player) )
						{

							// player has no item and bot does
							i_Slot = -1;
							if( b_ClientGrenade && GetPlayerWeaponSlot(player, 2) == -1 ) i_Slot = 2;
							else if( b_ClientSpecial && GetPlayerWeaponSlot(player, 3) == -1 ) i_Slot = 3;
							else if( b_ClientMedSlot && GetPlayerWeaponSlot(player, 4) == -1 ) i_Slot = 4;
							else continue;

							i = GetPlayerWeaponSlot(client, i_Slot);	// Get bots item name
							GetEdictClassname(i, s_EdictClassName, sizeof(s_EdictClassName));

							// This item is allowed to be transferred
							if( BotAllowedTransfer(s_EdictClassName, true) )
							{
								GetClientEyePosition(player, f_PlayerPos);					// Position of player
								f_Distance = GetVectorDistance(f_ClientPos, f_PlayerPos);	// Distance between player and bot

								// We're close enough
								if( f_Distance <= g_fDistGive && IsVisibleTo(f_ClientPos, f_PlayerPos) )
								{
									if( g_bSounds ) PlaySound(player, SOUND_LITTLEREWARD);

									StripWeapon(client, i_Slot);
									GiveItem(player, s_EdictClassName);
									Vocalize(player, s_EdictClassName);

									g_bGiveBlocked = true;
									if( g_hGiveBlocked != INVALID_HANDLE )
										CloseHandle(g_hGiveBlocked);
									g_hGiveBlocked = CreateTimer(1.5, tmrResetGive);

									if( g_bNotify && g_bTranslation && !g_bBlockVocalize )
										CPrintToChatAll("\x05%N \x01%t \x04%t \x01%t \x05%N", client, "Gave", s_EdictClassName, "To", player);
									return;
								}
							}
						}
					}
				}
			}
		}
	}
}


// ########## AUTO GRAB ########## - Loop through bot positions and check if they can grab items
public Action:tmrAutoGrab(Handle:timer)
{
	// Variables
	new count, client, ent, i, bool:bContains, bool:b_ClientGrenade, bool:b_ClientSpecial, bool:b_ClientMedSlot;
	decl Float:f_TargetPos[3], Float:f_ClientPos[3], Float:f_Distance, String:s_EdictClassName[40];

	// Loop through the clients
	for( client = 1; client <= MaxClients; client++ )
	{
		// Client in game, alive and a bot on the survivor team. Don't allow transfers when incapped or being revived
		if( IsClientInGame(client) && IsPlayerAlive(client) && IsFakeClient(client) && GetClientTeam(client) == 2 &&
		!IsReviving(client) && !IsIncapped(client) )
		{

			if( GetPlayerWeaponSlot(client, 2) != -1 ) b_ClientGrenade = true; else b_ClientGrenade = false;		// Client has a grenade
			if( GetPlayerWeaponSlot(client, 3) != -1 ) b_ClientSpecial = true; else b_ClientSpecial = false;		// Client has first aid/defib/upgrade ammo
			if( GetPlayerWeaponSlot(client, 4) != -1 ) b_ClientMedSlot = true; else b_ClientMedSlot = false;		// Client has pills/adrenaline
			GetClientEyePosition(client, f_ClientPos);																// Get the bots eye origin

			// They must have an empty slot
			if( !b_ClientGrenade || !b_ClientSpecial || !b_ClientMedSlot )
			{

				// Loop through the known item entities
				for( count = 0; count < g_iItemCount; count++ )
				{

					// Item must be valid
					ent = g_iItemSpawnID[count];
					if( ent != -1 && IsValidEntity(ent) && IsValidEdict(ent) )
					{

						GetEdictClassname(ent, s_EdictClassName, sizeof(s_EdictClassName));

						i = GetItemNumber(s_EdictClassName);
						if( i == -1 )
							continue;

						// Only pick up item if relative slot is empty
						if( !b_ClientGrenade && i <= 2 || !b_ClientSpecial && i == 3
						|| !b_ClientSpecial && i >= 6 || !b_ClientMedSlot && i >= 4 && i <= 5 )
						{
							bContains = false;
							// We must check non _spawn items do not have owners
							if( StrContains(s_EdictClassName, "_spawn") != -1 )
								bContains = true;
							if( !bContains && GetEntProp(ent, Prop_Send, "m_hOwnerEntity") != -1 )
								continue;

							if( StrContains(s_EdictClassName, "projectile") == -1 )
							{
								// Item must be allowed.
								if( BotAllowedTransfer(s_EdictClassName) )
								{
									f_TargetPos = g_fItemSpawn_XYZ[count]; // Item spawn location.
									f_Distance = GetVectorDistance(f_ClientPos, f_TargetPos);

									if( f_Distance <= g_fDistGrab && IsVisibleTo(f_ClientPos, f_TargetPos) )
									{
										if( bContains )
										{
											ReplaceStringEx(s_EdictClassName, sizeof(s_EdictClassName), "_spawn", "");
											new flag = GetEntProp(ent, Prop_Data, "m_spawnflags");
											if( flag & (1<<3) )
											{
												// Unlimited ammo, do nothing.
											}
											else
											{
												new iCount = GetEntProp(ent, Prop_Data, "m_itemCount");
												if( iCount > 1 )
													SetEntProp(ent, Prop_Data, "m_itemCount", iCount -1);
												else
													AcceptEntityInput(ent, "kill");
											}
										}
										else
											AcceptEntityInput(ent, "kill");

										ResetItemArray(count);
										GiveItem(client, s_EdictClassName);
										Vocalize(client, s_EdictClassName);

										if( g_bNotify && g_bTranslation && !g_bBlockVocalize )
											CPrintToChatAll("\x05%N \x01%t \x04%t", client, "Grabbed", s_EdictClassName);
										return;
									}
								}
							}
						}
					}
				}
			}
		}
	}
}



/// ======================================================================================
//					T R A C E   R A Y
// ======================================================================================
// Taken from:
// plugin = "L4D_Splash_Damage"
// author = "AtomicStryker"
static bool:IsVisibleTo(Float:position[3], Float:targetposition[3])
{
	decl Float:vAngles[3], Float:vLookAt[3];
	
	MakeVectorFromPoints(position, targetposition, vLookAt); // compute vector from start to target
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace
	
	// execute Trace
	new Handle:trace = TR_TraceRayFilterEx(position, vAngles, MASK_ALL, RayType_Infinite, _TraceFilter);
	
	new bool:isVisible = false;
	if( TR_DidHit(trace) )
	{
		decl Float:vStart[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint
		
		if( (GetVectorDistance(position, vStart, false) + 25.0 ) >= GetVectorDistance(position, targetposition))
		{
			isVisible = true; // if trace ray length plus tolerance equal or bigger absolute distance, you hit the target
		}
	}
	else
	{
		LogError("Tracer Bug: Player-Zombie Trace did not hit anything, WTF");
		isVisible = true;
	}
	CloseHandle(trace);

	return isVisible;
}


public bool:_TraceFilter(entity, contentsMask)
{
	if( !entity || entity <= MaxClients || !IsValidEntity(entity) ) // dont let WORLD, or invalid entities be hit
	{
		return false;
	}
	return true;
}