/**
* FFA
*
* Free For All game mode, kill everyone.
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT

#define MAX_SPAWN_AREAS             1
#define MAX_SPAWN_POINTS            13
#define MAX_SPAWN_POINTS_PACKAGE    12

#define BATTLE_ZONE_DISTANCE    250.0
#define BATTLE_ZONE_CENTER      {662.0, -546.0, 16.0}

// Variables

new timer[2];

// Includes

#include <a_samp>
#include <streamer>

#include "../../include/common"
#include "../../include/spawn"
#include "../../include/spawn-package"
#include "../../include/battle-zone"
#include "../../include/first-blood"

// Callbacks

public OnFilterScriptInit()
{
    print("\n > FFA filterscript by Amir Savand.\n");

    // Setup spawns
    AddSpawn(0,  0, 649.40, -508.63, 16.33,  41.96);
    AddSpawn(0,  1, 713.51, -544.55, 16.33, 356.63);
    AddSpawn(0,  2, 668.93, -587.77, 16.33,  84.95);
    AddSpawn(0,  3, 658.15, -626.69, 16.33, 358.68);
    AddSpawn(0,  4, 604.02, -578.80, 16.63, 349.47);
    AddSpawn(0,  5, 614.17, -603.33, 22.72, 277.53);
    AddSpawn(0,  6, 667.91, -572.94, 20.64,  62.29);
    AddSpawn(0,  7, 695.36, -541.94, 21.33,  62.43);
    AddSpawn(0,  8, 653.29, -515.28, 22.83, 143.88);
    AddSpawn(0,  9, 641.95, -610.75, 16.33,   0.58);
    AddSpawn(0, 10, 714.54, -575.03, 16.33, 352.83);
    AddSpawn(0, 11, 729.35, -474.28, 16.33, 145.05);
    AddSpawn(0, 12, 697.26, -456.75, 16.33,  160.9);

    // Setup package spawns
    AddPackageSpawn(0,  0, 663.67, -547.40, 16.33);
    AddPackageSpawn(0,  1, 620.53, -566.96, 29.29);
    AddPackageSpawn(0,  2, 675.93, -469.65, 22.57);
    AddPackageSpawn(0,  3, 690.70, -517.95, 19.25);
    AddPackageSpawn(0,  4, 651.74, -554.52, 22.14);
    AddPackageSpawn(0,  5, 604.66, -579.69, 16.63);
    AddPackageSpawn(0,  6, 720.00, -466.40, 16.34);
    AddPackageSpawn(0,  7, 622.47, -552.66, 21.15);
    AddPackageSpawn(0,  8, 655.51, -564.84, 16.33);
    AddPackageSpawn(0,  9, 671.42, -519.63, 23.83);
    AddPackageSpawn(0, 10, 638.89, -518.87, 17.87);
    AddPackageSpawn(0, 11, 681.32, -600.05, 16.18);

    // Setup players
    for (new i = 0; i < MAX_PLAYERS; i++)
        SetupPlayer(i);

    // Timers
    timer[0] = SetTimer("RespawnPackage", 60000, 1);
    timer[1] = SetTimer("CheckPlayerBattleZoneDistance", 5000, 1);
}

public OnFilterScriptExit()
{
    // Kill timers
    KillTimers(timer, sizeof(timer));
}

public OnPlayerConnect(playerid)
{
    SetupPlayer(playerid);
}

public OnPlayerRequestClass(playerid, classid)
{
    // Set player and camera to selection point
    SetPlayerPos(playerid, 681.66, -474.55, 16.53);
    SetPlayerFacingAngle(playerid, 180.0);
    SetPlayerCameraPos(playerid, 686.34, -477.57, 16.33);
    SetPlayerCameraLookAt(playerid, 681.66, -474.55, 16.53);
}

public OnPlayerSpawn(playerid)
{
    // Initial player again (if not already)
    if (GetPlayerTeam(playerid) != NO_TEAM)
        SetupPlayer(playerid);

    // Spawn player to random location
    RespawnPlayer(playerid);
}

public OnPlayerDeath(playerid, killerid, reason)
{
    // First blood
    CheckFirstBlood(killerid);
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
    // Check for package
    CheckPackage(playerid, pickupid);
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
    // Random color and no team
    SetPlayerColor(playerid, playerColors[Ran(0, sizeof(playerColors))]);
    SetPlayerTeam(playerid, NO_TEAM);
}
