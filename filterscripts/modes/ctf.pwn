/**
* CTF
*
* Capture The Flag mode, take the flag and return it to base, kill everyone in the proccess.
*
* Events: OnPlayerCaptureFlag(playerid), OnPlayerDropFlag(playerid, killerid), OnPlayerReturnFlag(playerid, reward)
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT

#define FLAG_CAPTURE_REWARD  2000

// Variables

new const Float:playerSpawns[][4] = {
    {-2340.13, 2338.19,  4.98,  90.0},
    {-2353.10, 2416.39,  6.98,  57.0},
    {-2487.24, 2516.73, 18.06, 180.0},
    {-2390.86, 2215.17,  4.98,  67.0},
    {-2266.13, 2390.00,  4.96,  90.0}
};

new const Float:randomPackageSpawns[][3] = {
    {-2435.28, 2350.40,  4.96},
    {-2489.29, 2342.86, 14.11},
    {-2521.19, 2293.36,  4.98},
    {-2584.35, 2316.15, 14.68},
    {-2636.53, 2351.99,  8.51},
    {-2466.03, 2249.16,  4.79},
    {-2547.16, 2269.94,  5.04},
    {-2510.23, 2515.90, 18.78},
    {-2431.35, 2403.68, 21.03},
    {-2547.01, 2347.51, 15.47}
};

new const Float:flagPos[3] = {-2537.0, 2363.0, 5.0};

new flagMapicon;
new flagPickup;
new flagBearer = -1;

// Includes

#include <a_samp>
#include <streamer>

#include "../../include/common"
#include "../../include/random-package.inc"
#include "../../include/first-blood.inc"

// Variables

enum iPlayerBase
{
    spawn,
    pickup,
    mapicon
}

new playerBase[MAX_PLAYERS][iPlayerBase];

// Callbacks

public OnFilterScriptInit()
{
    print("\n > CTF filterscript by Amir Savand.\n");

    // Initial all players
    for (new i = 0; i < MAX_PLAYERS; i++)
        SetupPlayer(i);

    // Start spawning random packages
    SetTimer("SpawnRandomPackage", 60000, 1);

    // Initial flag
    CreateFlag();
    return 1;
}

public OnFilterScriptExit()
{
    DestroyFlag();
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
    SetPlayerPos(playerid, -2655.40, 2146.68, 67.47);
    SetPlayerFacingAngle(playerid, 139.0);
    SetPlayerCameraPos(playerid, -2660.04, 2141.32, 70.3);
    SetPlayerCameraLookAt(playerid, -2655.40, 2146.68, 67.47);
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

    // Store spawn index
    playerBase[playerid][spawn] = i;
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    // Destroy player's base (since he's not bearer anymore)
    DestroyPlayerBase(playerid);

    // If player is flag bearer
    if (flagBearer == playerid)
    {
        // Drop flag to player position
        CreateFlag(playerid, killerid);
    }

    // First blood
    CheckFirstBlood(killerid);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    // Destroy properties
    DestroyPlayerBase(playerid);

    // If player is flag bearer
    if (flagBearer == playerid)
    {
        // Drop flag to player position
        CreateFlag(playerid);
    }
    return 1;
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
    // Check for package
    CheckRandomPackage(playerid, pickupid);

    // Flag pickup
    if (pickupid == flagPickup)
    {
        // Destroy the flag and create player base
        DestroyFlag();
        CreatePlayerBase(playerid);

        // Store bearer
        flagBearer = playerid;

        // Event
        CallRemoteFunction("OnPlayerCaptureFlag", "i", playerid);
    }

    // Base pickup
    else if (flagBearer == playerid)
    {
        // For all players
        for (new i; i < MAX_PLAYERS; i++)
        {
            // Is base pickup
            if (playerBase[i][pickup] == pickupid)
            {
                // Reward player
                GivePlayerMoney(playerid, FLAG_CAPTURE_REWARD);

                // Event
                CallRemoteFunction("OnPlayerReturnFlag", "ii", playerid, FLAG_CAPTURE_REWARD);

                // Recreate the flag and destroy base
                DestroyPlayerBase(playerid);
                CreateFlag();
            }
        }
    }
}

// Functions

SetupPlayer(playerid)
{
    // Random color and no team
    SetPlayerColor(playerid, playerColors[Ran(0, sizeof(playerColors))]);
    SetPlayerTeam(playerid, NO_TEAM);
}

CreatePlayerBase(playerid)
{
    // Destroy to recreate
    DestroyPlayerBase(playerid);

    // Spawn pos
    new Float:pos[4]; pos = playerSpawns[playerBase[playerid][spawn]];

    // Store player base
    playerBase[playerid][pickup]  = CreateDynamicPickup(19135, 1, pos[0], pos[1], pos[2]);
    playerBase[playerid][mapicon] = CreateDynamicMapIcon(pos[0], pos[1], pos[2], 0, cYellow, -1, -1, playerid, 2000);
}

DestroyPlayerBase(playerid)
{
    // Destroy player base pickup and mapicon
    DestroyDynamicPickup(playerBase[playerid][pickup]);
    DestroyDynamicMapIcon(playerBase[playerid][mapicon]);

    playerBase[playerid][pickup] = 0;
}

CreateFlag(onplayerid = INVALID_PLAYER_ID, killerid = INVALID_PLAYER_ID)
{
    // Flag position
    new Float:pos[3]; pos = flagPos;
    
    // Reset flag bearer
    flagBearer = -1;

    // Destroy to recreate
    DestroyFlag();

    // Flag on a player's position
    if (onplayerid != INVALID_PLAYER_ID)
    {
        // Set flag pos to player pos
        GetPlayerPos(onplayerid, pos[0], pos[1], pos[2]);
    
        // Announce dropped
        CallRemoteFunction("OnPlayerDropFlag", "ii", onplayerid, killerid);
    }

    // Create the flag pickup and mapicon
    flagPickup  = CreateDynamicPickup(19306, 1, pos[0], pos[1], pos[2]);
    flagMapicon = CreateDynamicMapIcon(pos[0], pos[1], pos[2], 19, 0, -1, -1, -1, 2000);
}

DestroyFlag()
{
    // Destroy flag pickup and mapicon
    DestroyDynamicPickup(flagPickup);
    DestroyDynamicMapIcon(flagMapicon);

    flagPickup = 0;
}
