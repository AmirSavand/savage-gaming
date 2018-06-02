/**
* FFA
*
* Free For All game mode, kill everyone.
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT

#define BATTLE_ZONE_DISTANCE    250.0
#define BATTLE_ZONE_CENTER      {662.0, -546.0, 16.0}

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

new timer[2];

// Includes

#include <a_samp>
#include <streamer>

#include "../../include/common"
#include "../../include/random-package"
#include "../../include/battle-zone"
#include "../../include/first-blood"

// Callbacks

public OnFilterScriptInit()
{
    print("\n > FFA filterscript by Amir Savand.\n");

    // Initial all players
    for (new i = 0; i < MAX_PLAYERS; i++)
        SetupPlayer(i);

    // Timers
    timer[0] = SetTimer("SpawnRandomPackage", 60000, 1);
    timer[1] = SetTimer("CheckPlayerBattleZoneDistance", 5000, 1);
    return 1;
}

public OnFilterScriptExit()
{
    // Kill timers
    KillTimers(timer, sizeof(timer));
}

public OnPlayerConnect(playerid)
{
    SetupPlayer(playerid);
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
        SetupPlayer(playerid);

    // Spawn player to random location
    new i = Ran(0, sizeof(playerSpawns));
    MovePlayer(playerid, playerSpawns[i][0], playerSpawns[i][1], playerSpawns[i][2], playerSpawns[i][3]);
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    // First blood
    CheckFirstBlood(killerid);
    return 1;
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
    // Check for package
    CheckRandomPackage(playerid, pickupid);
}

// Functions

SetupPlayer(playerid)
{
    // Random color and no team
    SetPlayerColor(playerid, playerColors[Ran(0, sizeof(playerColors))]);
    SetPlayerTeam(playerid, NO_TEAM);
}
