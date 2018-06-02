/**
* Freeroam
*
* Freeroam in the city, hang around, buy cars, collect packages, etc...
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT

#define REGENERATION_AMOUNT      10
#define REGENERATION_INTERVAL    500

#define MAX_SPAWN_AREAS          2
#define MAX_SPAWN_POINTS         4
#define MAX_SPAWN_POINTS_PACKAGE 6

// Variables

new timer[2];

// Includes

#include <a_samp>
#include <streamer>

#include "../../include/common"
#include "../../include/regeneration"
#include "../../include/spawn"
#include "../../include/spawn-package"

// Callbacks

public OnFilterScriptInit()
{
    print("\n > Freeroam filterscript by Amir Savand.\n");

    // Setup spawns
    AddSpawn(0, 0, -2029.94,  156.33, 28.83, 271.51);
    AddSpawn(0, 1, -1955.48,  297.43, 35.46, 128.17);
    AddSpawn(0, 2, -2089.47,  303.52, 41.07, 251.79);
    AddSpawn(0, 3, -1969.67,  132.14, 27.68,  90.33);
    AddSpawn(1, 0, -1112.70, -181.35, 14.14, 110.61);
    AddSpawn(1, 1, -1197.75,  -96.14, 14.14, 122.16);
    AddSpawn(1, 2, -1226.93, -150.80, 14.14, 200.24);
    AddSpawn(1, 3, -1254.36,   34.97, 14.14, 138.83);

    // Setup package spawns
    AddPackageSpawn(0, 0, -2023.29,  161.38, 33.93);
    AddPackageSpawn(0, 1, -1917.22,  239.62, 44.04);
    AddPackageSpawn(0, 2, -2060.43,  252.02, 37.93);
    AddPackageSpawn(0, 3, -2116.37,   -4.07, 35.32);
    AddPackageSpawn(0, 4, -1973.57,  -78.13, 35.68);
    AddPackageSpawn(0, 5, -1879.32,  300.66, 41.04);
    AddPackageSpawn(1, 0, -1261.39, -283.17, 13.70);
    AddPackageSpawn(1, 1, -1392.97, -397.40,  5.55);
    AddPackageSpawn(1, 2, -1512.25, -278.83,  5.58);
    AddPackageSpawn(1, 3, -1358.22, -492.00, 13.73);
    AddPackageSpawn(1, 4, -1432.86, -530.40, 13.73);
    AddPackageSpawn(1, 5, -1523.45, -537.89, 13.70);

    // Setup all players
    for (new i = 0; i < MAX_PLAYERS; i++)
        SetupPlayer(i);

    // Setup timers
    timer[0] = SetTimer("RespawnPackage", 45000, 1);
    timer[1] = SetTimer("RegeneratePlayers", REGENERATION_INTERVAL, 1);
}

public OnFilterScriptExit()
{
    KillTimers(timer, sizeof(timer));
}

public OnPlayerConnect(playerid)
{
    SetupPlayer(playerid);
}

public OnPlayerRequestClass(playerid, classid)
{
    // Set player and camera to selection point
    SetPlayerPos(playerid, -1971.66, 140.65, 27.68);
    SetPlayerFacingAngle(playerid, 90);
    SetPlayerCameraPos(playerid, -1974.65, 137.84, 27.68);
    SetPlayerCameraLookAt(playerid, -1971.66, 140.65, 27.68);
}

public OnPlayerSpawn(playerid)
{
    RespawnPlayer(playerid);
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

// Forwards

forward RegeneratePlayers();
public  RegeneratePlayers()
{
    // Regenerate all players
    for (new i; i < MAX_PLAYERS; i++)
        RegeneratePlayer(i, REGENERATION_AMOUNT);
}

// Functions

SetupPlayer(playerid)
{
    // Random color and no team
    SetPlayerColor(playerid, playerColors[Ran(0, sizeof(playerColors))]);
    SetPlayerTeam(playerid, NO_TEAM);
}
