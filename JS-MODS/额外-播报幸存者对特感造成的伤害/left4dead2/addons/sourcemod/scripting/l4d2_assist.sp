#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法

#include <sourcemod>
#include <sdktools>
#include <sdktools>
#include <multicolors>

#define PLUGIN_VERSION "1.9"

#define IsSurvivor(%0) (GetClientTeam(%0) == 2)
#define IsWitch(%0) (g_bIsWitch[%0])
#define MAXENTITIES 2048
#define CVAR_FLAGS			FCVAR_NOTIFY

ConVar g_hCvarAllow, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
ConVar g_hTankOnly;
ConVar g_hCvarMPGameMode;


char Temp2[] = ", ";
char Temp3[] = " (";
char Temp4[] = " dmg)";
char Temp5[] = "\x05";
char Temp6[] = "\x01";
int Damage[MAXPLAYERS+1][MAXPLAYERS+1];
bool g_bIsWitch[MAXENTITIES];// Membership testing for fast witch checking
bool g_bShouldAnnounceWitchDamage[MAXENTITIES];
int	g_iOffset_Incapacitated = 0; // Used to check if tank is dying
bool g_bTankOnly;
int ZOMBIECLASS_TANK;
int g_iLastTankHealth[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "L4D1/2 Assistance System",
	author = "[E]c & Max Chu, SilverS & ViRaGisTe & HarryPotter",
	description = "Show assists made by survivors",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=123811"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test == Engine_Left4Dead )
	{
		ZOMBIECLASS_TANK = 5;
	}
	else if( test == Engine_Left4Dead2 )
	{
		ZOMBIECLASS_TANK = 8;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}

public void OnPluginStart()
{
	g_iOffset_Incapacitated = FindSendPropInfo("Tank", "m_isIncapacitated");
	
	g_hCvarAllow = CreateConVar("sm_assist_enable", "1", "If 1, Enables this plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarModes =		CreateConVar(	"sm_assist_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all)", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"sm_assist_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none)", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"sm_assist_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together", CVAR_FLAGS );
	g_hTankOnly = CreateConVar("sm_assist_tank_only", "1", "If 1, only show damage done to Tank",CVAR_FLAGS, true, 0.0, true, 1.0);
	
	g_hCvarMPGameMode 	= FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hTankOnly.AddChangeHook(ConVarChanged_Cvars);
	
	AutoExecConfig(true, "l4d2_assist");
}

public void OnPluginEnd()
{
	ResetPlugin();
}

bool g_bMapStarted;
public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
}

// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bTankOnly = g_hTankOnly.BoolValue;
}

bool g_bCvarAllow;
void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		ResetPlugin();
		g_bCvarAllow = true;
		HookEvents();
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		ResetPlugin();
		g_bCvarAllow = false;
		UnhookEvents();
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}

// ====================================================================================================
//					EVENTS
// ====================================================================================================
void HookEvents()
{
	HookEvent("player_hurt", Event_Player_Hurt);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("round_start", Event_Round_Start);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("witch_spawn", Event_WitchSpawn);
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("map_transition", 		Event_RoundEnd,		EventHookMode_PostNoCopy); //戰役過關到下一關的時候 (沒有觸發round_end)
	HookEvent("mission_lost", 			Event_RoundEnd,		EventHookMode_PostNoCopy); //戰役滅團重來該關卡的時候 (之後有觸發round_end)
	HookEvent("finale_vehicle_leaving", Event_RoundEnd,		EventHookMode_PostNoCopy); //救援載具離開之時  (沒有觸發round_end)
}

void UnhookEvents()
{
	UnhookEvent("player_hurt", Event_Player_Hurt);
	UnhookEvent("player_death", Event_Player_Death);
	UnhookEvent("round_start", Event_Round_Start);
	UnhookEvent("player_incapacitated", Event_PlayerIncapacitated);
	UnhookEvent("witch_spawn", Event_WitchSpawn);
	UnhookEvent("tank_spawn", Event_TankSpawn);
	UnhookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
	UnhookEvent("map_transition", 		Event_RoundEnd,		EventHookMode_PostNoCopy); //戰役過關到下一關的時候 (沒有觸發round_end)
	UnhookEvent("mission_lost", 			Event_RoundEnd,		EventHookMode_PostNoCopy); //戰役滅團重來該關卡的時候 (之後有觸發round_end)
	UnhookEvent("finale_vehicle_leaving", Event_RoundEnd,		EventHookMode_PostNoCopy); //救援載具離開之時  (沒有觸發round_end)
}

public Action Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast) 
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int witchid = event.GetInt("attackerentid");
	if (!IsWitch(witchid)||
	!g_bShouldAnnounceWitchDamage[witchid]					// Prevent double print on witch incapping 2 players (rare)
	) return;

	if(!victim || !IsClientInGame(victim)) return;
	
	int health = GetEntityHealth(witchid);
	if (health < 0) health = 0;
	CPrintToChatAll("\x01★ \x04%N \x01反被 \x04女巫(剩余\x04%d\x01HP) \x01制服", victim, health);			
//	CPrintToChatAll("\x01★ \x04女巫 \x01还剩 \x04%d\x01HP", health);

		
	g_bShouldAnnounceWitchDamage[witchid] = false;
}

public Action Event_Round_Start(Event event, const char[] name, bool dontBroadcast) 
{
	ResetPlugin();
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	ResetPlugin();
}

public Action Event_Player_Hurt(Event event, const char[] name, bool dontBroadcast) 
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if(victim == attacker || !attacker || !IsClientInGame(attacker)) return;
	if(!victim || !IsClientInGame(victim)) return;
	
	if(IsSurvivor(attacker) && GetClientTeam(victim) == 3 )
	{
		int DamageHealth = event.GetInt("dmg_health");
		if (GetEntProp(victim, Prop_Send, "m_zombieClass") == ZOMBIECLASS_TANK)
		{
			if(!IsTankDying(victim))
			{
				Damage[attacker][victim] += DamageHealth;
				g_iLastTankHealth[victim] = event.GetInt("health");
			}
		}
		else 		
			Damage[attacker][victim] += DamageHealth;
	}
}

public Action Event_Player_Death(Event event, const char[] name, bool dontBroadcast) 
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if(!victim || !IsClientInGame(victim)) return;
	
	if (attacker == 0)
	{
		int witchid = event.GetInt("attackerentid");
		if (IsWitch(witchid) && g_bShouldAnnounceWitchDamage[witchid])  // Prevent double print on witch incapping 2 players (rare)
		{
			int health = GetEntityHealth(witchid);
			if (health < 0) health = 0;
			CPrintToChatAll("\x01★ \x04%N \x01反被 \x04女巫 \x01制服", victim);			
			CPrintToChatAll("\x01★ \x04女巫 \x01还剩 \x04%d\x01HP", health);
			g_bShouldAnnounceWitchDamage[witchid] = false;
			return;
		}
	}
	if (attacker && IsClientInGame(attacker) && IsSurvivor(attacker) && GetClientTeam(victim) == 3)
	{

		if(GetEntProp(victim, Prop_Send, "m_zombieClass") == ZOMBIECLASS_TANK)
		{
			Damage[attacker][victim] += g_iLastTankHealth[victim];
		}
		else
		{
			if(g_bTankOnly == true)
			{
				ClearDmgSI(victim);
				return;
			}
		}
		
		char MsgAssist[512];
		bool start = true;
		bool AssistFlag = false;
		char sName[MAX_NAME_LENGTH], sTempMessage[64];
		for (int i = 1; i <= MaxClients; i++)
		{
			if (Damage[i][victim] > 0)
			{
				if (i != attacker && IsClientInGame(i) && IsSurvivor(i))
				{
					AssistFlag = true;
					
					if(start == false)
						StrCat(MsgAssist, sizeof(MsgAssist), Temp2);
					
					GetClientName(i, sName, sizeof(sName));
					FormatEx(sTempMessage, sizeof(sTempMessage), "%s%s%s%s%i%s", Temp5,sName,Temp6,Temp3,Damage[i][victim],Temp4);
					StrCat(MsgAssist, sizeof(MsgAssist), sTempMessage);
					start = false;
				}
			}
		}
		PrintToChatAll("\x01★ \x03%N\x01 击杀 \x04%N\x01(%d HP)", attacker, victim, Damage[attacker][victim]);		
		if (AssistFlag == true) 
		{
			PrintToChatAll("\x05\x01 助攻: %s", MsgAssist);
		}
	}
	
	ClearDmgSI(victim);
}

public Action Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	int witchid = event.GetInt("witchid");
	g_bIsWitch[witchid] = true;
	g_bShouldAnnounceWitchDamage[witchid] = true;
}

public void OnEntityDestroyed(int entity)
{
	if( entity > 0 && IsValidEdict(entity) )
	{
		char strClassName[64];
		GetEdictClassname(entity, strClassName, sizeof(strClassName));
		if(strcmp(strClassName, "witch") == 0)	
		{
			g_bIsWitch[entity] = false;
			g_bShouldAnnounceWitchDamage[entity] = false;
		}
	}
}

public Action Event_TankSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	g_iLastTankHealth[client] = GetClientHealth(client);
	
}

void ResetPlugin()
{
	for (int i = 0; i <= MaxClients; i++)
	{
		for (int j = 1; j <= MaxClients; j++)
		{
			Damage[i][j] = 0;
		}
	}
	for (int i = MaxClients + 1; i < MAXENTITIES; i++) g_bIsWitch[i] = false;
}

bool IsTankDying(int tankclient)
{
	return view_as<bool>(GetEntData(tankclient, g_iOffset_Incapacitated));
}

void ClearDmgSI(int victim)
{
	for (int i = 0; i <= MaxClients; i++)
	{
		Damage[i][victim] = 0;
	}
}

public GetEntityHealth(client)
{
	return GetEntProp(client, Prop_Data, "m_iHealth");
}