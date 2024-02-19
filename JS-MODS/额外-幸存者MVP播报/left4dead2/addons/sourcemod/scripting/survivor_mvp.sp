#pragma semicolon 1
#pragma newdecls required

// 头文件
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>
#include "treeutil\treeutil.sp"

#define CVAR_FLAG FCVAR_NOTIFY

enum struct PlayerInfo
{
	int totalDamage;
	int siCount;
	int ciCount;
	int ffCount;
	int gotFFCount;
	int headShotCount;
	void init()
	{
		this.totalDamage = this.siCount = this.ciCount = this.ffCount = this.gotFFCount = this.headShotCount = 0;
	}
} 
PlayerInfo playerInfos[MAXPLAYERS + 1];

static int failCount = 0;
static bool g_bHasPrint = false, g_bHasPrintDetails = false;
static char mapName[64];

public Plugin myinfo = 
{
	name 			= "Survivor Mvp & Round Status",
	author 			= "夜羽真白",
	description 	= "生还者 MVP 统计",
	version 		= "1.0.1.0",
	url 			= "https://steamcommunity.com/id/saku_ra/"
}

ConVar
	g_hAllowShowMvp,
	g_hWhichTeamToShow,
	g_hAllowShowSi,
	g_hAllowShowCi,
	g_hAllowShowFF,
	g_hAllowShowTotalDmg,
	g_hAllowShowAccuracy,mvp_allow_show
	g_hAllowShowFailCount,
	g_hAllowShowDetails;

public void OnPluginStart()
{
	g_hAllowShowMvp = CreateConVar("mvp_allow_show", "1", "是否允许显示 MVP 数据统计", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hWhichTeamToShow = CreateConVar("mvp_witch_team_show", "0", "0=所有，1=旁观者，2=生还者，3=感染者", CVAR_FLAG, true, 0.0, true, 3.0);
	g_hAllowShowSi = CreateConVar("mvp_allow_show_si", "1", "是否允许显示击杀感染者信息", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hAllowShowCi = CreateConVar("mvp_allow_show_ci", "1", "是否允许显示击杀丧尸信息", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hAllowShowFF = CreateConVar("mvp_allow_show_ff", "1", "是否允许显示友伤信息", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hAllowShowTotalDmg = CreateConVar("mvp_allow_show_damage", "1", "是否允许显示总伤害信息", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hAllowShowAccuracy = CreateConVar("mvp_allow_show_acc", "1", "是否允许显示准确度信息", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hAllowShowFailCount = CreateConVar("mvp_show_fail_count", "1", "是否在团灭时显示团灭次数", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hAllowShowDetails = CreateConVar("mvp_show_details", "1", "是否在过关或团灭时显示各项 MVP 数据", CVAR_FLAG, true, 0.0, true, 1.0);
	// HookEvents
	HookEvent("player_death", siDeathHandler);
	HookEvent("infected_death", ciDeathHandler);
	HookEvent("player_hurt", playerHurtHandler);
	/* HookEvent("infected_hurt", ciHurtHandler); */
	HookEvent("round_start", roundStartHandler);
	HookEvent("round_end", roundEndHandler);
	HookEvent("map_transition", roundEndHandler);
	HookEvent("mission_lost", missionLostHandler);
	HookEvent("finale_vehicle_leaving", roundEndHandler);
	// RegConsoleCmd
	RegConsoleCmd("sm_mvp", showMvpHandler);
}

public void OnMapStart()
{
	g_bHasPrint = g_bHasPrintDetails = false;
	char nowMapName[64] = {'\0'};
	GetCurrentMap(nowMapName, sizeof(nowMapName));
	if (strcmp(mapName, NULL_STRING) == 0 || strcmp(mapName, nowMapName) != 0)
	{
		failCount = 0;
		strcopy(mapName, sizeof(mapName), nowMapName);
	}
	clearStuff();
}

public Action showMvpHandler(int client, int args)
{
	if (!g_hAllowShowMvp.BoolValue)
	{
		ReplyToCommand(client, "[MVP]当前生还者 MVP 统计数据已禁用");
		return Plugin_Handled;
	}
	if (IsValidClient(client))
	{
		if (GetClientTeam(client) == TEAM_SPECTATOR && (g_hWhichTeamToShow.IntValue != 0 && g_hWhichTeamToShow.IntValue != 1))
		{
			PrintToChat(client, "\x04[MVP]\x01当前生还者 MVP 统计数据不允许向旁观者显示");
			return Plugin_Handled;
		}
		else if (GetClientTeam(client) == TEAM_SURVIVOR && (g_hWhichTeamToShow.IntValue != 0 && g_hWhichTeamToShow.IntValue != 2))
		{
			PrintToChat(client, "\x04[MVP]\x01当前生还者 MVP 统计数据不允许向生还者显示");
			return Plugin_Handled;
		}
		else if (GetClientTeam(client) == TEAM_INFECTED && (g_hWhichTeamToShow.IntValue != 0 && g_hWhichTeamToShow.IntValue != 3))
		{
			PrintToChat(client, "\x04[MVP]\x01当前生还者 MVP 统计数据不允许向感染者显示");
			return Plugin_Handled;
		}
		printMvpStatus(client);
		if (g_hAllowShowDetails.BoolValue) { printDetails(client); }
	}
	else if (client == 0)
	{
		printMvpStatusToServer();
		printDetails(0);
	}
	return Plugin_Continue;
}

// 击杀特感
public void siDeathHandler(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid")), attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidClient(victim) || !IsValidClient(attacker) || GetClientTeam(victim) != TEAM_INFECTED || GetClientTeam(attacker) != TEAM_SURVIVOR) { return; }
	if (GetInfectedClass(victim) < ZC_SMOKER || GetInfectedClass(victim) > ZC_CHARGER) { return; }
	playerInfos[attacker].siCount++;
	if (event.GetBool("headshot")) { playerInfos[attacker].headShotCount++; }
}

// 击杀丧尸
public void ciDeathHandler(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidSurvivor(attacker)) { return; }
	playerInfos[attacker].ciCount++;
	if (event.GetBool("headshot")) { playerInfos[attacker].headShotCount++; }
}

// 造成伤害
public void playerHurtHandler(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid")), attacker = GetClientOfUserId(event.GetInt("attacker")), damage = event.GetInt("dmg_health");
	if (IsValidSurvivor(attacker) && IsValidSurvivor(victim))
	{
		playerInfos[attacker].ffCount += damage;
		playerInfos[victim].gotFFCount += damage;
	}
	else if (IsValidSurvivor(attacker) && IsValidInfected(victim) && GetInfectedClass(victim) >= ZC_SMOKER && GetInfectedClass(victim) <= ZC_CHARGER) { playerInfos[attacker].totalDamage += damage; }
}
// 对丧尸造成的伤害也算总伤害
/* public void ciHurtHandler(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker")), damage = event.GetInt("amount");
	if (IsValidSurvivor(attacker)) { playerInfos[attacker].totalDamage += damage; }
} */

public void roundStartHandler(Event event, const char[] name, bool dontBroadcast)
{
	g_bHasPrint = g_bHasPrintDetails = false;
	char nowMapName[64] = {'\0'};
	GetCurrentMap(nowMapName, sizeof(nowMapName));
	if (strcmp(mapName, NULL_STRING) == 0 || strcmp(mapName, nowMapName) != 0)
	{
		failCount = 0;
		strcopy(mapName, sizeof(mapName), nowMapName);
	}
	clearStuff();
}

public void missionLostHandler(Event event, const char[] name, bool dontBroadcast)
{
	if (g_hAllowShowMvp.BoolValue && !g_bHasPrint)
	{
		roundEndPrintMvpStatus();
		if (g_hAllowShowDetails.BoolValue && !g_bHasPrintDetails)
		{
			roundEndPrintDetails();
			g_bHasPrintDetails = true;
		}
		g_bHasPrint = true;
	}
	if (g_hAllowShowFailCount.BoolValue) { PrintToChatAll("\x04[!] \x05这是你们第%d次团灭，请继续努力", ++failCount); }
	clearStuff();
}

public void roundEndHandler(Event event, const char[] name, bool dontBroadcast)
{
	if (g_hAllowShowMvp.BoolValue && !g_bHasPrint)
	{
		roundEndPrintMvpStatus();
		if (g_hAllowShowDetails.BoolValue && !g_bHasPrintDetails)
		{
			roundEndPrintDetails();
			g_bHasPrintDetails = true;
		}
		g_bHasPrint = true;
	}
	clearStuff();
}

// 方法
void clearStuff()
{
	for (int i = 1; i <= MaxClients; i++) { playerInfos[i].init(); }
}

void roundEndPrintMvpStatus()
{
	switch (g_hWhichTeamToShow.IntValue)
	{
		case 0:
		{
			printMvpStatus();
		}
		case 1:
		{
			for (int i = 1; i <= MaxClients; i++) { if (IsValidClient(i) && GetClientTeam(i) == TEAM_SPECTATOR) { printMvpStatus(i); } }
		}
		case 2:
		{
			for (int i = 1; i <= MaxClients; i++) { if (IsValidClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) { printMvpStatus(i); } } 
		}
		case 3:
		{
			for (int i = 1; i <= MaxClients; i++) { if (IsValidClient(i) && GetClientTeam(i) == TEAM_INFECTED) { printMvpStatus(i); } }
		}
	}
}

void roundEndPrintDetails()
{
	switch (g_hWhichTeamToShow.IntValue)
	{
		case 0:
		{
			printDetails();
		}
		case 1:
		{
			for (int i = 1; i <= MaxClients; i++) { if (IsValidClient(i) && GetClientTeam(i) == TEAM_SPECTATOR) { printDetails(i); } }
		}
		case 2:
		{
			for (int i = 1; i <= MaxClients; i++) { if (IsValidClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) { printDetails(i); } } 
		}
		case 3:
		{
			for (int i = 1; i <= MaxClients; i++) { if (IsValidClient(i) && GetClientTeam(i) == TEAM_INFECTED) { printDetails(i); } }
		}
	}
}

void printMvpStatus(int client = -1)
{
	static int playerCount, i;
	playerCount = 0;
	int[] players = new int[MaxClients + 1];
	for (i = 1; i <= MaxClients; i++) { if (IsValidSurvivor(i)) { players[playerCount++] = i; } }
	SortCustom1D(players, playerCount, sortByDamageFunction);
	// Do Fomat
	if (IsValidClient(client)) { PrintToChat(client, "\x04[生还者 MVP 统计]"); }
	else { PrintToChatAll("\x04[生还者 MVP 统计]"); }
	for (i = 0; i < playerCount; i++)
	{
		char buffer[64] = {'\0'}, toPrint[128] = {'\0'};
		if (g_hAllowShowSi.BoolValue)
		{
			FormatEx(buffer, sizeof(buffer), "\x04特感\x05%d ", playerInfos[players[i]].siCount);
			StrCat(toPrint, sizeof(toPrint), buffer);
		}
		if (g_hAllowShowCi.BoolValue)
		{
			FormatEx(buffer, sizeof(buffer), "\x04丧尸\x05%d ", playerInfos[players[i]].ciCount);
			StrCat(toPrint, sizeof(toPrint), buffer);
		}
		if (g_hAllowShowTotalDmg.BoolValue)
		{
			FormatEx(buffer, sizeof(buffer), "\x04伤害\x05%d ", playerInfos[players[i]].totalDamage);
			StrCat(toPrint, sizeof(toPrint), buffer);
		}
		if (g_hAllowShowFF.BoolValue)
		{
			FormatEx(buffer, sizeof(buffer), "\x04黑/被黑\x05%d/%d ", playerInfos[players[i]].ffCount, playerInfos[players[i]].gotFFCount);
			StrCat(toPrint, sizeof(toPrint), buffer);
		}
		if (g_hAllowShowAccuracy.BoolValue)
		{
			float accuracy = playerInfos[players[i]].siCount + playerInfos[players[i]].ciCount == 0 ? 0.0 : float(playerInfos[players[i]].headShotCount) / float(playerInfos[players[i]].siCount + playerInfos[players[i]].ciCount);
			FormatEx(buffer, sizeof(buffer), "\x04爆头率\x05%.0f%% ", accuracy * 100.0);
			StrCat(toPrint, sizeof(toPrint), buffer);
		}
		FormatEx(buffer, sizeof(buffer), "\x04%N", players[i]);
		StrCat(toPrint, sizeof(toPrint), buffer);
		if (IsValidClient(client)) { PrintToChat(client, "%s", toPrint); }
		else { PrintToChatAll("%s", toPrint); }
	}
}

void printMvpStatusToServer()
{
	static int playerCount, i;
	playerCount = 0;
	int[] players = new int[MaxClients + 1];
	for (i = 1; i <= MaxClients; i++) { if (IsValidSurvivor(i)) { players[playerCount++] = i; } }
	SortCustom1D(players, playerCount, sortByDamageFunction);
	// Do Fomat
	PrintToServer("[生还者 MVP 统计]");
	for (i = 0; i < playerCount; i++)
	{
		char buffer[64] = {'\0'}, toPrint[128] = {'\0'};
		if (g_hAllowShowSi.BoolValue)
		{
			FormatEx(buffer, sizeof(buffer), "特感：%d ", playerInfos[players[i]].siCount);
			StrCat(toPrint, sizeof(toPrint), buffer);
		}
		if (g_hAllowShowCi.BoolValue)
		{
			FormatEx(buffer, sizeof(buffer), "丧尸：%d ", playerInfos[players[i]].ciCount);
			StrCat(toPrint, sizeof(toPrint), buffer);
		}
		if (g_hAllowShowTotalDmg.BoolValue)
		{
			FormatEx(buffer, sizeof(buffer), "伤害：%d ", playerInfos[players[i]].totalDamage);
			StrCat(toPrint, sizeof(toPrint), buffer);
		}
		if (g_hAllowShowFF.BoolValue)
		{
			FormatEx(buffer, sizeof(buffer), "黑/被黑：%d/%d ", playerInfos[players[i]].ffCount, playerInfos[players[i]].gotFFCount);
			StrCat(toPrint, sizeof(toPrint), buffer);
		}
		if (g_hAllowShowAccuracy.BoolValue)
		{
			float accuracy = playerInfos[players[i]].siCount + playerInfos[players[i]].ciCount == 0 ? 0.0 : float(playerInfos[players[i]].headShotCount) / float(playerInfos[players[i]].siCount + playerInfos[players[i]].ciCount);
			FormatEx(buffer, sizeof(buffer), "爆头率：%.0f%% ", accuracy * 100.0);
			StrCat(toPrint, sizeof(toPrint), buffer);
		}
		FormatEx(buffer, sizeof(buffer), "%N", players[i]);
		StrCat(toPrint, sizeof(toPrint), buffer);
		PrintToServer("%s", toPrint);
	}
}

void printDetails(int client = -1)
{
	int siMVP = 1, ciMVP = 1, ffMVP = 1, gotFFMVP = 1;
	int siTotal = playerInfos[1].siCount, ciTotal = playerInfos[1].ciCount, ffTotal = playerInfos[1].ffCount, gotFFTotal = playerInfos[1].gotFFCount;
	for (int i = 2; i <= MaxClients; i++)
	{
		if (playerInfos[i].siCount > playerInfos[siMVP].siCount) { siMVP = i; }
		if (playerInfos[i].ciCount > playerInfos[ciMVP].ciCount) { ciMVP = i; }
		if (playerInfos[i].ffCount > playerInfos[ffMVP].ffCount) { ffMVP = i; }
		if (playerInfos[i].gotFFCount > playerInfos[gotFFMVP].gotFFCount) { gotFFMVP = i; }
		siTotal += playerInfos[i].siCount;
		ciTotal += playerInfos[i].ciCount;
		ffTotal += playerInfos[i].ffCount;
		gotFFTotal += playerInfos[i].gotFFCount;
	}
	float siPercent = siTotal == 0 ? 0.0 : float(playerInfos[siMVP].siCount) / float(siTotal);
	float ciPercent = ciTotal == 0 ? 0.0 : float(playerInfos[ciMVP].ciCount) / float(ciTotal);
	float ffPercent = ffTotal == 0 ? 0.0 : float(playerInfos[ffMVP].ffCount) / float(ffTotal);
	float gotFFPercent = gotFFTotal == 0 ? 0.0 : float(playerInfos[gotFFMVP].gotFFCount) / float(gotFFTotal);
	if (IsValidClient(client))
	{
		siTotal == 0 ? PrintToChat(client, "\x04[特感杀手] \x05本局暂无特感击杀") : PrintToChat(client, "\x04[特感杀手]\x05%N \x04击杀：\x05%d/%d \x04[\x05%.0f%%\x04]", siMVP, playerInfos[siMVP].siCount, siTotal, siPercent * 100.0);
		ciTotal == 0 ? PrintToChat(client, "\x04[清尸狂人]\x05本局暂无丧尸击杀") : PrintToChat(client, "\x04[清尸狂人]\x05%N \x04击杀：\x05%d/%d \x04[\x05%.0f%%\x04]", ciMVP, playerInfos[ciMVP].ciCount, ciTotal, ciPercent * 100.0);
		ffTotal == 0 ? PrintToChat(client, "\x04[持枪特感]\x05大家都没有黑枪，没有友伤的世界达成了") : PrintToChat(client, "\x04[持枪特感]\x05%N \x04黑枪：\x05%d/%d \x04[\x05%.0f%%\x04]", ffMVP, playerInfos[ffMVP].ffCount, ffTotal, ffPercent * 100.0);
		if (ffTotal > 0) { PrintToChat(client, "\x04[被黑冤种]\x05%N \x04被黑：\x05%d/%d \x04[\x05%.0f%%\x04]", gotFFMVP, playerInfos[gotFFMVP].gotFFCount, gotFFTotal, gotFFPercent * 100.0); }
		return;
	}
	if (client == 0)
	{
		siTotal == 0 ? PrintToServer("[特感杀手]本局暂无特感击杀") : PrintToServer("[特感杀手]%N 击杀：%d/%d [%.0f%%]", siMVP, playerInfos[siMVP].siCount, siTotal, siPercent * 100.0);
		ciTotal == 0 ? PrintToServer("[清尸狂人]本局暂无丧尸击杀") : PrintToServer("[清尸狂人]%N 击杀：%d/%d [%.0f%%]", ciMVP, playerInfos[ciMVP].ciCount, ciTotal, ciPercent * 100.0);
		ffTotal == 0 ? PrintToServer("[持枪特感]大家都没有黑枪，没有友伤的世界达成了") : PrintToServer("[持枪特感]%N 黑枪：%d/%d [%.0f%%]", ffMVP, playerInfos[ffMVP].ffCount, ffTotal, ffPercent * 100.0);
		if (ffTotal > 0) { PrintToServer("[被黑冤种]%N 被黑：%d/%d [%.0f%%]", gotFFMVP, playerInfos[gotFFMVP].gotFFCount, gotFFTotal, gotFFPercent * 100.0); }
		return;
	}
	siTotal == 0 ? PrintToChatAll("\x04[特感杀手]\x05本局暂无特感击杀") : PrintToChatAll("\x04[特感杀手]\x05%N \x04击杀：\x05%d/%d \x04[\x05%.0f%%\x04]", siMVP, playerInfos[siMVP].siCount, siTotal, siPercent * 100.0);
	ciTotal == 0 ? PrintToChatAll("\x04[清尸狂人]\x05本局暂无丧尸击杀") : PrintToChatAll("\x04[清尸狂人]\x05%N \x04击杀：\x05%d/%d \x04[\x05%.0f%%\x04]", ciMVP, playerInfos[ciMVP].ciCount, ciTotal, ciPercent * 100.0);
	ffTotal == 0 ? PrintToChatAll("\x04[持枪特感]\x05大家都没有黑枪，没有友伤的世界达成了") : PrintToChatAll("\x04[持枪特感]\x05%N \x04黑枪：\x05%d/%d \x04[\x05%.0f%%\x04]", ffMVP, playerInfos[ffMVP].ffCount, ffTotal, ffPercent * 100.0);
	if (ffTotal > 0) { PrintToChatAll("\x04[被黑冤种]\x05%N \x04被黑：\x05%d/%d \x04[\x05%.0f%%\x04]", gotFFMVP, playerInfos[gotFFMVP].gotFFCount, gotFFTotal, gotFFPercent * 100.0); }
}

int sortByDamageFunction(int o1, int o2, const int[] array, Handle hndl)
{
	float o1Acc = float(playerInfos[o1].headShotCount) / float(playerInfos[o1].siCount + playerInfos[o1].ciCount);
	float o2Acc = float(playerInfos[o2].headShotCount) / float(playerInfos[o2].siCount + playerInfos[o2].ciCount);
	return playerInfos[o1].totalDamage > playerInfos[o2].totalDamage ? -1 : o1Acc > o2Acc ? -1 : o1Acc == o2Acc ? o1 > o2 ? -1 : o1 == o2 ? 0 : 1 : 1;
}