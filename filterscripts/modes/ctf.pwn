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

#define FLAG_CAPTURE_REWARD         2000

#define SPAWN_WEAPON_SNIPER_AMMO    20

#define MAX_SPAWN_AREAS             1
#define MAX_SPAWN_POINTS            5
#define MAX_SPAWN_POINTS_PACKAGE    10

#define BATTLE_ZONE_DISTANCE        250.0
#define BATTLE_ZONE_CENTER          {-2466.7, 2331.6, 4.8}

// Variables

new const Float:flagPos[3] = {-2537.0, 2363.0, 5.0};

new flagMapicon;
new flagPickup;
new flagBearer = -1;

new timer[2];

// Includes

#include <a_samp>
#include <streamer>

#include "../../include/common"
#include "../../include/spawn"
#include "../../include/spawn-package"
#include "../../include/first-blood"
#include "../../include/battle-zone"

// Variables

enum iPlayerBase
{
    spawnIndex,
    pickup,
    mapicon
}

new playerBase[MAX_PLAYERS][iPlayerBase];

// Callbacks

public OnFilterScriptInit()
{
    print("\n > CTF filterscript by Amir Savand.\n");

    // Setup spawns
    AddSpawn(0, 0, -2340.13, 2338.19,  4.98,  90.0);
    AddSpawn(0, 1, -2353.10, 2416.39,  6.98,  57.0);
    AddSpawn(0, 2, -2487.24, 2516.73, 18.06, 180.0);
    AddSpawn(0, 3, -2390.86, 2215.17,  4.98,  67.0);
    AddSpawn(0, 4, -2266.13, 2390.00,  4.96,  90.0);

    // Setup package spawns
    AddPackageSpawn(0, 0, -2547.01, 2347.51, 15.47);
    AddPackageSpawn(0, 1, -2435.28, 2350.40,  4.96);
    AddPackageSpawn(0, 2, -2489.29, 2342.86, 14.11);
    AddPackageSpawn(0, 3, -2521.19, 2293.36,  4.98);
    AddPackageSpawn(0, 4, -2584.35, 2316.15, 14.68);
    AddPackageSpawn(0, 5, -2636.53, 2351.99,  8.51);
    AddPackageSpawn(0, 6, -2466.03, 2249.16,  4.79);
    AddPackageSpawn(0, 7, -2547.16, 2269.94,  5.04);
    AddPackageSpawn(0, 8, -2510.23, 2515.90, 18.78);
    AddPackageSpawn(0, 9, -2431.35, 2403.68, 21.03);

    // Setup players
    for (new i = 0; i < MAX_PLAYERS; i++)
        SetupPlayer(i);

    // Setup timers
    timer[0] = SetTimer("RespawnPackage", 60000, 1);
    timer[1] = SetTimer("CheckPlayerBattleZoneDistance", 5000, 1);

    // Setup flag
    CreateFlag();
}

public OnFilterScriptExit()
{
    // Kill and destroy
    KillTimers(timer, sizeof(timer));
    DestroyFlag();
}

public OnPlayerConnect(playerid)
{
    SetupPlayer(playerid);
}

public OnPlayerRequestClass(playerid, classid)
{
    // Set player and camera to selection point
    SetPlayerPos(playerid, -2655.40, 2146.68, 67.47);
    SetPlayerFacingAngle(playerid, 139.0);
    SetPlayerCameraPos(playerid, -2660.04, 2141.32, 70.3);
    SetPlayerCameraLookAt(playerid, -2655.40, 2146.68, 67.47);
}

public OnPlayerSpawn(playerid)
{
    // Setup player again (if not already)
    if (GetPlayerTeam(playerid) != NO_TEAM)
        SetupPlayer(playerid);

    // Spawn player to random location and store index
    playerBase[playerid][spawnIndex] = RespawnPlayer(playerid);

    // Give sniper
    GivePlayerWeapon(playerid, WEAPON_SNIPER, SPAWN_WEAPON_SNIPER_AMMO);
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
    CheckFirstBlood(killerid, playerid);

    // Spawn to random location
    RespawnPlayer(playerid);
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
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
    // Check for package
    CheckPackage(playerid, pickupid);

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

public OnPlayerStateChange(playerid, newstate, oldstate)
{
    // Flag bearer can not be in any vehicle
    if (IsPlayerInAnyVehicle(playerid) && flagBearer == playerid)
    {
        // Alert and remove from car
        AlertPlayerDialog(playerid, "Info", "You can not get in any vehicle when bearing flag.");
        RemovePlayerFromVehicle(playerid);
    }
}

// Events

forward OnPlayerAttemptToUseItem(playerid, item, itemName[]);
public  OnPlayerAttemptToUseItem(playerid, item, itemName[])
{
    // Flag bearer can not use skydive
    if (isequal(itemName, "Sky Dive") && flagBearer == playerid)
    {
        // Alert
        AlertPlayerDialog(playerid, "Info", "You can not get in any vehicle when bearing flag.");
        return 0;
    }
    return 1;
}

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
    // Random color
    SetPlayerColor(playerid, playerColors[Ran(0, sizeof(playerColors))]);
}

CreatePlayerBase(playerid)
{
    // Destroy to recreate
    DestroyPlayerBase(playerid);

    // Spawn pos
    new Float:pos[4]; pos = spawn[spawnArea][playerBase[playerid][spawnIndex]];

    // Store player base
    playerBase[playerid][pickup]  = CreateDynamicPickup(19135, 1, pos[0], pos[1], pos[2]);
    playerBase[playerid][mapicon] = CreateDynamicMapIcon(pos[0], pos[1], pos[2], 0, cYellow, -1, -1, playerid, 2000, MAPICON_GLOBAL);
}

DestroyPlayerBase(playerid)
{
    // Destroy player base pickup and mapicon
    DestroyDynamicPickup(playerBase[playerid][pickup]);
    DestroyDynamicMapIcon(playerBase[playerid][mapicon]);

    playerBase[playerid][pickup] = 0;
    playerBase[playerid][mapicon] = 0;
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
    flagMapicon = 0;
}
