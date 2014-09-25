#pragma semicolon 1
#include <clientprefs>
#include <cstrike>
#include <sourcemod>

/** Client cookie handles **/
Handle g_teamNameCookie = INVALID_HANDLE;
Handle g_teamFlagCookie = INVALID_HANDLE;
#define TEAM_NAME_LENGTH 128
#define TEAM_FLAG_LENGTH 4

#include "include/pugsetup.inc"
#include "pugsetup/generic.sp"


public Plugin:myinfo = {
    name = "CS:GO PugSetup: team names module",
    author = "splewis",
    description = "Sets team names/flags on game going live",
    version = PLUGIN_VERSION,
    url = "https://github.com/splewis/csgo-pug-setup"
};

public OnPluginStart() {
    LoadTranslations("common.phrases");
    RegAdminCmd("sm_name", Command_Name, ADMFLAG_CHANGEMAP, "Sets a team name/flag to go with a player: sm_name <player> <teamname> <teamflag>, use quotes for the team name if it includes a space!");
    RegAdminCmd("sm_listnames", Command_ListNames, ADMFLAG_CHANGEMAP, "Lists all players' and their team names/flag, if they have one set.");
    g_teamNameCookie = RegClientCookie("pugsetup_teamname", "Pugsetup team name", CookieAccess_Protected);
    g_teamFlagCookie = RegClientCookie("pugsetup_teamflag", "Pugsetup team flag (2-letter country code)", CookieAccess_Protected);
}

public OnGoingLive() {
    Handle ctNames = CreateArray(TEAM_NAME_LENGTH);
    Handle ctFlags = CreateArray(TEAM_FLAG_LENGTH);
    Handle tNames = CreateArray(TEAM_NAME_LENGTH);
    Handle tFlags = CreateArray(TEAM_FLAG_LENGTH);

    FillPotentialNames(CS_TEAM_CT, ctNames, ctFlags);
    FillPotentialNames(CS_TEAM_T, tNames, tFlags);

    int choice = -1;
    char name[TEAM_NAME_LENGTH];
    char flag[TEAM_FLAG_LENGTH];

    if (GetArraySize(ctNames) > 0) {
        choice = GetArrayRandomIndex(ctNames);
        GetArrayString(ctNames, choice, name, sizeof(name));
        GetArrayString(ctFlags, choice, flag, sizeof(flag));
        SetTeamInfo(CS_TEAM_CT, name, flag);
    }

    if (GetArraySize(tNames) > 0) {
        choice = GetArrayRandomIndex(tNames);
        GetArrayString(tNames, choice, name, sizeof(name));
        GetArrayString(tFlags, choice, flag, sizeof(flag));
        SetTeamInfo(CS_TEAM_T, name, flag);
    }

    CloseHandle(ctNames);
    CloseHandle(ctFlags);
    CloseHandle(tNames);
    CloseHandle(tFlags);
}

public Action:Command_ListNames(client, args) {
    int count = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsPlayer(i) && AreClientCookiesCached(i)) {
            char name[TEAM_NAME_LENGTH];
            char flag[TEAM_FLAG_LENGTH];
            GetClientCookie(i, g_teamNameCookie, name, sizeof(name));
            GetClientCookie(i, g_teamFlagCookie, flag, sizeof(flag));
            if (!StrEqual(name, "")) {
                ReplyToCommand(client, "%N: %s (%s)", i, name, flag);
                count++;
            }
        }
    }
    if (count == 0)
        ReplyToCommand(client, "Nobody has a team name/flag set.");
}

public Action:Command_Name(client, args) {
    char arg1[128];
    char arg2[128];
    char arg3[128];
    if (args >= 3 && GetCmdArg(1, arg1, sizeof(arg1)) && GetCmdArg(2, arg2, sizeof(arg2)) && GetCmdArg(3, arg3, sizeof(arg3))) {
        int target = FindTarget(client, arg1, true, false);
        if (IsPlayer(target)) {
            SetClientCookie(target, g_teamNameCookie, arg2);
            SetClientCookie(target, g_teamFlagCookie, arg3);
        }
    } else {
        ReplyToCommand(client, "Usage: sm_name <player> <team name> <team flag code>");
    }

    return Plugin_Handled;
}

public void FillPotentialNames(int team, Handle names, Handle flags) {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsPlayer(i) && GetClientTeam(i) == team && AreClientCookiesCached(i)) {
            char name[TEAM_NAME_LENGTH];
            char flag[TEAM_FLAG_LENGTH];
            GetClientCookie(i, g_teamNameCookie, name, sizeof(name));
            GetClientCookie(i, g_teamFlagCookie, flag, sizeof(flag));

            if (StrEqual(name, ""))
                continue;

            PushArrayString(names, name);
            PushArrayString(flags, flag);
        }
    }
}

public void SetTeamInfo(int team, char name[], char flag[]) {
    int team_int = (team == CS_TEAM_CT) ? 1 : 2;
    ServerCommand("mp_teamname_%d %s", team_int, name);
    ServerCommand("mp_teamflag_%d %s", team_int, flag);
}