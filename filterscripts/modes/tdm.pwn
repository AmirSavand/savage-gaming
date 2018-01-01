/**
* TDM
*
* Team Deathmatch game mode, kill everyone of other team.
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT
#define MAX_TEAMS           3
#define DIALOG_TEAM         600
#define BASE_DISTANCE       20

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

new const Float:teamSpawns[MAX_TEAMS][4] = {
    {-1408.23, 2640.41, 55.68,  90.0}, // Blue team
    {-1516.00, 2535.30, 55.68,   0.0}, // Red team
    {-1556.42, 2711.65, 55.83, 160.0}  // Green team
};

new const Float:randomPackageSpawns[][3] = {
    {-1438.93, 2614.25, 61.17},
    {-1508.78, 2634.49, 55.83},
    {-1506.40, 2590.81, 61.83},
    {-1519.11, 2564.13, 59.18},
    {-1484.42, 2641.93, 62.32},
    {-1505.53, 2662.14, 55.83},
    {-1433.98, 2662.55, 55.83},
    {-1459.96, 2629.39, 58.77},
    {-1483.40, 2613.75, 58.78}
};

// Includes

#include <a_samp>
#include <zcmd>
#include <streamer>

#include "../../include/common"
#include "../../include/random-package.inc"

// Callbacks

public OnFilterScriptInit()
{
    print("\n > TDM filterscript by Amir Savand.\n");

    // Mapicon for spawn points
    for (new t; t < MAX_TEAMS; t++)
    {
        // Mapicon and label
        teamMapicons[t] = CreateDynamicMapIcon(teamSpawns[t][0], teamSpawns[t][1], teamSpawns[t][2], 58, -1, -1, -1, -1, 1000);
        teamLabels[t]   = CreateDynamic3DTextLabel(teamNames[t], teamColors[t], teamSpawns[t][0], teamSpawns[t][1], teamSpawns[t][2] + 0.5, BASE_DISTANCE);
    }

    // Initial all players for TDM
    for (new i; i < MAX_PLAYERS; i++)
        InitialPlayer(i);

    // Start spawning random packages
    SetTimer("SpawnRandomPackage", 45000, 1);
    return 1;
}

public OnFilterScriptExit()
{
    // Destroy team mapicons and labels
    for (new t = 0; t < MAX_TEAMS; t++)
    {
        DestroyDynamicMapIcon(teamMapicons[t]);
        DestroyDynamic3DTextLabel(teamLabels[t]);
    }
    return 1;
}

public OnPlayerConnect(playerid)
{
    InitialPlayer(playerid);
    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    // Set player and camera to selection point
    SetPlayerPos(playerid, -1534.91, 2659.46, 56.28);
    SetPlayerFacingAngle(playerid, 90.0);
    SetPlayerCameraPos(playerid, -1539.27, 2661.18, 58.0);
    SetPlayerCameraLookAt(playerid, -1534.91, 2659.46, 56.28);
    return 1;
}

public OnPlayerSpawn(playerid)
{
    // Initial player again (if not already)
    if (GetPlayerTeam(playerid) == NO_TEAM)
        InitialPlayer(playerid);

    // Get player team
    new t = GetPlayerTeam(playerid);

    // Random offset of position
    new xo = Ran(-5, 5);
    new yo = Ran(-5, 5);

    // Spawn player to team location with random offset
    SetPlayerPos(playerid, teamSpawns[t][0] + xo, teamSpawns[t][1] + yo, teamSpawns[t][2]);
    SetPlayerFacingAngle(playerid, teamSpawns[t][3]);
    SetCameraBehindPlayer(playerid);
    return 1;
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
    // If random package
    if (pickupid == randomPackage)
    {
        // Destroy it and its mapicon
        DestroyDynamicPickup(randomPackage);
        DestroyDynamicMapIcon(randomPackageMapicon);

        randomPackage = 0;

        // Call remote so gamemode will handle it
        CallRemoteFunction("OnPlayerPickupRandomPackage", "i", playerid);
    }
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

// public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
// {
//     // Hit player
//     if (hittype == BULLET_HIT_TYPE_PLAYER)
//     {
//         new t = GetPlayerTeam(hitid);

//         // Player is in base
//         if (GetPlayerDistanceFromPoint(hitid, teamSpawns[t][0], teamSpawns[t][1], teamSpawns[t][2]) <= BASE_DISTANCE)
//         {
//             // Alert player
//             AlertPlayerText(playerid, "~r~~h~No base attack!");

//             // Prevent damage
//             return 0;
//         }
//     }
 
//     return 1;
// }

// Functions

InitialPlayer(playerid)
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

    // Announce
    new str[100]; format(str, sizeof(str), "joined {FFFF00}%s", teamNames[team]);
    AlertPlayers(FPlayer(playerid, str));
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
