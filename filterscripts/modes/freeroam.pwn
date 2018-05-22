/**
* Freeroam
*
* Freeroam in the city, hang around, buy cars, collect packages, etc...
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT
#define REGENERATION_AMOUNT     10
#define REGENERATION_INTERVAL   500

// Variables

new const Float:playerSpawns[][4] = {
    {-2029.94, 156.33, 28.83, 271.51},
    {-1955.48, 297.43, 35.46, 128.17},
    {-2089.47, 303.52, 41.07, 251.79},
    {-1969.67, 132.14, 27.68 , 90.33}
};

new const Float:randomPackageSpawns[][3] = {
    {-2023.29, 161.38, 33.93},
    {-1917.22, 239.62, 44.04},
    {-2024.01, 337.07, 40.01},
    {-2060.43, 252.02, 37.93},
    {-2116.37,  -4.07, 35.32},
    {-1973.57, -78.13, 35.68},
    {-1879.32, 300.66, 41.04}
};

// Includes

#include <a_samp>
#include <streamer>

#include "../../include/common"
#include "../../include/regeneration"
#include "../../include/random-package.inc"

// Callbacks

public OnFilterScriptInit()
{
    print("\n > Freeroam filterscript by Amir Savand.\n");

    // Initial all players
    for (new i = 0; i < MAX_PLAYERS; i++)
        SetupPlayer(i);

    // Start spawning random packages
    SetTimer("SpawnRandomPackage", 60000, 1);

    // Regenerate players over time
    SetTimer("RegeneratePlayers", REGENERATION_INTERVAL, 1);
    return 1;
}

public OnPlayerConnect(playerid)
{
    SetupPlayer(playerid);
    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    // Set player and camera to selection point
    SetPlayerPos(playerid, -1971.66, 140.65, 27.68);
    SetPlayerFacingAngle(playerid, 90);
    SetPlayerCameraPos(playerid, -1974.65, 137.84, 27.68);
    SetPlayerCameraLookAt(playerid, -1971.66, 140.65, 27.68);
    return 1;
}

public OnPlayerSpawn(playerid)
{
    // Initial player again (if not already)
    if (GetPlayerTeam(playerid) != NO_TEAM)
        SetupPlayer(playerid);

    // Get random spawn point
    new i = Ran(0, sizeof(playerSpawns));

    // Spawn player to random location
    SetPlayerPos(playerid, playerSpawns[i][0], playerSpawns[i][1], playerSpawns[i][2]);
    SetPlayerFacingAngle(playerid, playerSpawns[i][3]);
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

// Public functions

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
