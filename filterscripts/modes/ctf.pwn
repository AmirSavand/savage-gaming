/**
* CTF
*
* Capture The Flag mode, take the flag and return it to base, kill everyone in the proccess.
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT

#define FLAG_CAPTURE_REWARD  2000
#define FLAG_CAPTURE_SOUND  50004

// Variables

new const Float:playerSpawns[][4] = {
    {-2340.13, 2338.19,  4.98,  90.0},
    {-2353.10, 2416.39,  6.98,  57.0},
    {-2487.24, 2516.73, 18.06, 180.0},
    {-2390.86, 2215.17,  4.98,  67.0},
    {-2266.13, 2390.00,  4.96,  90.0}
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

new const Float:flagPos[3] = {-2536.94, 2363.24, 4.98};

new flagMapicon;
new flagPickup;
new flagBearer = -1;

// Includes

#include <a_samp>
#include <streamer>

#include "../../include/common"
#include "../../include/random-package.inc"

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
        InitialPlayer(i);

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
    InitialPlayer(playerid);
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
        InitialPlayer(playerid);

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
        CreateFlag(playerid);
    }
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
    // Random package
    if (pickupid == randomPackage)
    {
        // Destroy it and its mapicon
        DestroyDynamicPickup(randomPackage);
        DestroyDynamicMapIcon(randomPackageMapicon);

        randomPackage = 0;

        // Call remote so gamemode will handle it
        CallRemoteFunction("OnPlayerPickupRandomPackage", "i", playerid);
    }

    // Flag pickup
    else if (pickupid == flagPickup)
    {
        // Destroy the flag and create player base
        DestroyFlag();
        CreatePlayerBase(playerid);

        // Store bearer
        flagBearer = playerid;

        // Announce captured
        AlertPlayersText(FPlayerText(playerid, "~r~~h~", "~w~captured flag"));
    }

    // Base pickup
    else if (flagBearer != -1)
    {
        // For all players
        for (new i; i < MAX_PLAYERS; i++)
        {
            // Is base pickup
            if (playerBase[i][pickup] == pickupid)
            {
                // Reward player
                GivePlayerMoney(playerid, FLAG_CAPTURE_REWARD);
                AlertPlayerText(playerid, "~g~~h~+2000");
                PlayerPlaySound(playerid, FLAG_CAPTURE_SOUND, 0, 0, 0);

                // Announce players
                AlertPlayers(FPlayer(playerid, "returned the {FF0000}Flag!"));

                // Recreate the flag and destroy base
                DestroyPlayerBase(playerid);
                CreateFlag();
            }
        }
    }
}

// Functions

InitialPlayer(playerid)
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
    playerBase[playerid][mapicon] = CreateDynamicMapIcon(pos[0], pos[1], pos[2], 0, cYellow, -1, -1, playerid, 1000, MAPICON_GLOBAL);
}

DestroyPlayerBase(playerid)
{
    // Destroy player base pickup and mapicon
    DestroyDynamicPickup(playerBase[playerid][pickup]);
    DestroyDynamicMapIcon(playerBase[playerid][mapicon]);
}

CreateFlag(onplayerid = INVALID_PLAYER_ID)
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
        AlertPlayersText("~w~flag dropped");
    }

    // Create the flag pickup and mapicon
    flagPickup  = CreateDynamicPickup(19306, 1, pos[0], pos[1], pos[2]);
    flagMapicon = CreateDynamicMapIcon(pos[0], pos[1], pos[2], 19, 0, -1, -1, -1, 1000, MAPICON_GLOBAL);
}

DestroyFlag()
{
    // Destroy flag pickup and mapicon
    DestroyDynamicPickup(flagPickup);
    DestroyDynamicMapIcon(flagMapicon);

    flagPickup = 0;
    flagMapicon = 0;
}
