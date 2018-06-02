/**
* TDM
*
* Team Deathmatch game mode, kill everyone of other team.
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT
#define MAX_TEAMS                   3
#define DIALOG_TEAM                 600
#define BASE_DISTANCE               20

#define MAX_SPAWN_AREAS             1
#define MAX_SPAWN_POINTS            3
#define MAX_SPAWN_POINTS_PACKAGE    9

#define BATTLE_ZONE_DISTANCE        200.0
#define BATTLE_ZONE_CENTER          {-1511.0, 2635.0, 55.0}

// Variables

new const teamColors[MAX_TEAMS] = {
    0x3498DBFF, // Blue
    0xE74C3CFF, // Red
    0x2ECC71FF  // Green
};

new const teamNames[MAX_TEAMS][] = {
    "Blue Team",
    "Red Team",
    "Green Team"
};

new teamMapicons[MAX_TEAMS];
new Text3D:teamLabels[MAX_TEAMS];

new timer[2];

// Includes

#include <a_samp>
#include <zcmd>
#include <streamer>

#include "../../include/common"
#include "../../include/spawn"
#include "../../include/spawn-package"
#include "../../include/battle-zone"
#include "../../include/first-blood"

// Callbacks

public OnFilterScriptInit()
{
    print("\n > TDM filterscript by Amir Savand.\n");

    // Setup spawns
    AddSpawn(0, 0, -1408.23, 2640.41, 55.68,  90.0); // Blue team
    AddSpawn(0, 1, -1516.00, 2535.30, 55.68,   0.0); // Red team
    AddSpawn(0, 2, -1556.42, 2711.65, 55.83, 160.0); // Green team

    // Setup package spawns
    AddPackageSpawn(0, 0, -1438.93, 2614.25, 61.17);
    AddPackageSpawn(0, 1, -1508.78, 2634.49, 55.83);
    AddPackageSpawn(0, 2, -1506.40, 2590.81, 61.83);
    AddPackageSpawn(0, 3, -1519.11, 2564.13, 59.18);
    AddPackageSpawn(0, 4, -1484.42, 2641.93, 62.32);
    AddPackageSpawn(0, 5, -1505.53, 2662.14, 55.83);
    AddPackageSpawn(0, 6, -1433.98, 2662.55, 55.83);
    AddPackageSpawn(0, 7, -1459.96, 2629.39, 58.77);
    AddPackageSpawn(0, 8, -1483.40, 2613.75, 58.78);

    // Setup team bases
    for (new t; t < MAX_TEAMS; t++)
    {
        // Mapicon and label
        teamMapicons[t] = CreateDynamicMapIcon(spawn[0][t][0], spawn[0][t][1], spawn[0][t][2], 58, -1, -1, -1, -1, 1000);
        teamLabels[t]   = CreateDynamic3DTextLabel(teamNames[t], teamColors[t], spawn[0][t][0], spawn[0][t][1], spawn[0][t][2] + 0.5, BASE_DISTANCE);
    }

    // Setup players
    for (new i; i < MAX_PLAYERS; i++)
        SetupPlayer(i);

    // Setup timers
    timer[0] = SetTimer("RespawnPackage", 45000, 1);
    timer[1] = SetTimer("CheckPlayerBattleZoneDistance", 5000, 1);
}

public OnFilterScriptExit()
{
    // Destroy team mapicons and labels
    for (new t = 0; t < MAX_TEAMS; t++)
    {
        DestroyDynamicMapIcon(teamMapicons[t]);
        DestroyDynamic3DTextLabel(teamLabels[t]);
    }

    // Kill
    KillTimers(timer, sizeof(timer));
}

public OnPlayerConnect(playerid)
{
    SetupPlayer(playerid);
}

public OnPlayerRequestClass(playerid, classid)
{
    // Set player and camera to selection point
    SetPlayerPos(playerid, -1534.91, 2659.46, 56.28);
    SetPlayerFacingAngle(playerid, 90.0);
    SetPlayerCameraPos(playerid, -1539.27, 2661.18, 58.0);
    SetPlayerCameraLookAt(playerid, -1534.91, 2659.46, 56.28);
}

public OnPlayerSpawn(playerid)
{
    // Setup player again (if not already)
    if (GetPlayerTeam(playerid) == NO_TEAM)
        SetupPlayer(playerid);

    // Spawn player to team location (with offset)
    RespawnPlayer(playerid, GetPlayerTeam(playerid), Ran(-5, 5), Ran(-5, 5));
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
    // Check for package
    CheckPackage(playerid, pickupid);
}

public OnPlayerDeath(playerid, killerid, reason)
{
    // First blood
    CheckFirstBlood(killerid);
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    // Team dialog
    if (dialogid == DIALOG_TEAM && response)
    {
        // Change team and color
        AssignPlayerTeam(playerid, listitem);
    
        // Kill player
        SetPlayerHealth(playerid, 0);
    }
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
    // Hit player
    if (hittype == BULLET_HIT_TYPE_PLAYER)
    {
        new t = GetPlayerTeam(hitid);

        // Player is in base
        if (GetPlayerDistanceFromPoint(hitid, spawn[0][t][0], spawn[0][t][1], spawn[0][t][2]) <= BASE_DISTANCE)
        {
            // Alert player
            AlertPlayerText(playerid, "~r~~h~Try not to base attack");

            // Prevent damage
            // return 0;
        }
    }
}

// Events

forward OnModeChange(mode, area);
public  OnModeChange(mode, area)
{
    if (IsValidIndex(area, MAX_SPAWN_AREAS))
    {
        SetSpawnArea(area);
        SetPackageSpawnArea(area);
    }
}

// Functions

SetupPlayer(playerid)
{
    // Random team for player
    AssignPlayerTeam(playerid, Ran(0, MAX_TEAMS));
}

AssignPlayerTeam(playerid, team)
{
    // If player is online
    if (!IsPlayerConnected(playerid))
        return;

    // Assign player team
    SetPlayerTeam(playerid, team);
    SetPlayerColor(playerid, teamColors[team]);
}

// Commands

CMD:team(playerid)
{
    // Dialog string with header
    new str[200];

    // For each team
    for (new t; t < MAX_TEAMS; t++)
    {
        // Add team row
        new strTeam[200]; format(strTeam, sizeof(strTeam), "{FFFF00}%s\n", teamNames[t]);
        strcat(str, strTeam);
    }

    // Show team selection dialog
    ShowPlayerDialog(playerid, DIALOG_TEAM, DIALOG_STYLE_LIST, "{00FFFF}Select Team", str, "Join", "Close");
    return 1;
}
