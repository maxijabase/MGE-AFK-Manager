#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <autoexecconfig>
#include <mge>

#undef REQUIRE_PLUGIN
#include <afk_manager>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.0.0"

bool g_bAFKMLoaded;
Handle g_hWarnTimer[MAXPLAYERS + 1];
int g_iAFKStartTime[MAXPLAYERS + 1];

ConVar g_hCvarRemoveTime;
ConVar g_hCvarWarnInterval;
ConVar g_hCvarImmunityFlag;

char g_sImmunityFlag[32];
int g_iRemoveTime;
int g_iWarnInterval;

public Plugin myinfo = {
  name = "[MGE] AFK Manager", 
  author = "ampere", 
  description = "Removes AFK players from MGE arenas.", 
  version = PLUGIN_VERSION, 
  url = "http://github.com/maxijabase"
};

public void OnPluginStart() {
  AutoExecConfig_SetCreateFile(true);
  AutoExecConfig_SetFile("mge_afk");
  
  g_hCvarRemoveTime = AutoExecConfig_CreateConVar("sm_mge_afk_remove_time", "60", "Total AFK seconds before a player is removed from their arena. [DEFAULT: 60]", FCVAR_NONE, true, 1.0);
  g_hCvarWarnInterval = AutoExecConfig_CreateConVar("sm_mge_afk_warn_interval", "10", "Seconds between AFK warnings to arena players. [DEFAULT: 10]", FCVAR_NONE, true, 1.0);
  g_hCvarImmunityFlag = AutoExecConfig_CreateConVar("sm_mge_afk_immunity_flag", "", "Admin flag(s) that grant immunity to MGE AFK removal. Leave blank to disable.");
  
  AutoExecConfig_CleanFile();
  AutoExecConfig_ExecuteFile();
  
  g_hCvarRemoveTime.AddChangeHook(OnCvarChanged);
  g_hCvarWarnInterval.AddChangeHook(OnCvarChanged);
  g_hCvarImmunityFlag.AddChangeHook(OnCvarChanged);
  
  CacheConVars();
}

public void OnCvarChanged(ConVar cvar, const char[] oldvalue, const char[] newvalue) {
  CacheConVars();
}

void CacheConVars() {
  g_iRemoveTime = g_hCvarRemoveTime.IntValue;
  g_iWarnInterval = g_hCvarWarnInterval.IntValue;
  g_hCvarImmunityFlag.GetString(g_sImmunityFlag, sizeof(g_sImmunityFlag));
}

public void OnAllPluginsLoaded() {
  g_bAFKMLoaded = LibraryExists("afkmanager");
}

public void OnLibraryAdded(const char[] name) {
  if (StrEqual(name, "afkmanager")) {
    g_bAFKMLoaded = true;
  }
}

public void OnLibraryRemoved(const char[] name) {
  if (StrEqual(name, "afkmanager")) {
    g_bAFKMLoaded = false;
    for (int i = 1; i <= MaxClients; i++) {
      StopWarnTimer(i);
    }
  }
}

public void OnClientDisconnect(int client) {
  StopWarnTimer(client);
}

public void AFKM_OnClientStartAFK(int client) {
  if (!MGE_IsPlayerInArena(client)) {
    return;
  }
  StartWarnTimer(client);
}

public void AFKM_OnClientEndAFK(int client) {
  StopWarnTimer(client);
}

public void MGE_OnPlayerArenaAdded(int client, int arena_index, int slot) {
  if (!g_bAFKMLoaded || !AFKM_IsClientAFK(client)) {
    return;
  }
  StartWarnTimer(client);
}

public void MGE_OnPlayerArenaRemoved(int client, int arena_index) {
  StopWarnTimer(client);
}

void StartWarnTimer(int client) {
  if (HasRemoveImmunityFlag(client)) {
    return;
  }
  StopWarnTimer(client);
  g_iAFKStartTime[client] = GetTime();
  
  int afkTime = AFKM_GetClientAFKTime(client);
  if (afkTime > 0) {
    g_iAFKStartTime[client] -= afkTime;
  }
  
  g_hWarnTimer[client] = CreateTimer(float(g_iWarnInterval), Timer_WarnPlayer, GetClientUserId(client), TIMER_REPEAT);
}

void StopWarnTimer(int client) {
  g_hWarnTimer[client] = null;
  g_iAFKStartTime[client] = 0;
}

Action Timer_WarnPlayer(Handle timer, int userid) {
  int client = GetClientOfUserId(userid);
  if (client == 0) {
    return Plugin_Stop;
  }
  
  if (g_hWarnTimer[client] != timer) {
    return Plugin_Stop;
  }
  
  if (!g_bAFKMLoaded || !AFKM_IsClientAFK(client)) {
    g_hWarnTimer[client] = null;
    return Plugin_Stop;
  }
  
  if (!MGE_IsPlayerInArena(client) || HasRemoveImmunityFlag(client)) {
    g_hWarnTimer[client] = null;
    return Plugin_Stop;
  }
  
  int elapsed = GetTime() - g_iAFKStartTime[client];
  int remaining = g_iRemoveTime - elapsed;
  
  if (remaining <= 0) {
    PrintToChat(client, "[MGE] You have been removed from the arena for being AFK.");
    MGE_RemovePlayerFromArena(client);
    g_hWarnTimer[client] = null;
    return Plugin_Stop;
  }
  
  PrintToChat(client, "[MGE] You are AFK. You will be removed from the arena in %d seconds.", remaining);
  return Plugin_Continue;
}

bool HasRemoveImmunityFlag(int client) {
  if (g_sImmunityFlag[0] == '\0') {
    return false;
  }
  int iUserFlagBits = GetUserFlagBits(client);
  return (iUserFlagBits & (ReadFlagString(g_sImmunityFlag) | ADMFLAG_ROOT)) > 0;
}
