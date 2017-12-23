/**
* FFA
*
* Free For All game mode, kill everyone.
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT

// Variables

new const Float:playerSpawns[][4] = {
    {649.40, -508.63, 16.33, 41.96},
    {713.51, -544.55, 16.33, 356.63},
    {668.93, -587.77, 16.33, 84.95},
    {658.15, -626.69, 16.33, 358.68},
    {604.02, -578.80, 16.63, 349.47},
    {614.17, -603.33, 22.72, 277.53},
    {667.91, -572.94, 20.64, 62.29},
    {695.36, -541.94, 21.33, 62.43},
    {653.29, -515.28, 22.83, 143.88},
    {641.95, -610.75, 16.33, 0.58},
    {714.54, -575.03, 16.33, 352.83},
    {729.35, -474.28, 16.33, 145.05},
    {697.26, -456.75, 16.33, 160.99}
};

new const Float:randomPackageSpawns[][3] = {
    {663.67, -547.40, 16.33},
    {620.53, -566.96, 29.29},
    {675.93, -469.65, 22.57},
    {690.70, -517.95, 19.25},
    {651.74, -554.52, 22.14},
    {604.66, -579.69, 16.63},
    {720.00, -466.40, 16.34},
    {622.47, -552.66, 21.15},
    {655.51, -564.84, 16.33},
    {671.42, -519.63, 23.83},
    {638.89, -518.87, 17.87},
    {681.32, -600.05, 16.18}
};

// Includes

#include <a_samp>
#include <streamer>

#include "../../include/common"
#include "../../include/random-package.inc"

// Callbacks

public OnFilterScriptInit()
{
    print("\n > FFA filterscript by Amir Savand.\n");

    // Initial all players
    for (new i = 0; i < MAX_PLAYERS; i++)
        InitialPlayer(i);

    // Start spawning random packages
    SetTimer("SpawnRandomPackage", 60000, 1);
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
    SetPlayerPos(playerid, 681.66, -474.55, 16.53);
    SetPlayerFacingAngle(playerid, 180.0);
    SetPlayerCameraPos(playerid, 686.34, -477.57, 16.33);
    SetPlayerCameraLookAt(playerid, 681.66, -474.55, 16.53);
    return 1;
}

public OnPlayerSpawn(playerid)
{
    // Initial player again (if not already)
    if (GetPlayerTeam(playerid) != NO_TEAM)
        InitialPlayer(playerid);

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

// Functions

InitialPlayer(playerid)
{
    // Random color and no team
    SetPlayerColor(playerid, playerColors[Ran(0, sizeof(playerColors))]);
    SetPlayerTeam(playerid, NO_TEAM);
}
