/**
* Crashers
*
* Crash enemy vehicle and survive.
*
* Events: OnPlayerSurvivedCrashers(playerid, reward), OnPlayerCrashedInCrashers(playerid)
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT

#define MAX_SPAWN_AREAS             1
#define MAX_SPAWN_POINTS            8
#define MAX_SPAWN_POINTS_PACKAGE    8

#define VEHICLE_RESPAWN             8

#define SURVIVAL_REWARD             250

// Pragma

#pragma unused models

// Includes

#include <a_samp>
#include <streamer>

// Variables

new const models[] = {
    402, 411, 415, 429,
    451, 480, 495, 506,
    535, 541, 560
};

new const Float:powerupSpawns[][3] = {
    {-2043.61, -279.38, 37.64},
    {-2048.32, -104.89, 43.25},
    {-2026.57, -113.15, 38.48},
    {-2085.27, -108.18, 39.88},
    {-2073.38, -106.24, 34.88},
    {-2093.52, -171.19, 41.23},
    {-2086.51, -195.51, 42.30},
    {-2028.77, -193.17, 45.57},
    {-2031.03, -192.66, 44.70},
    {-2050.33, -174.11, 44.68},
    {-2056.28, -181.49, 43.60},
    {-2048.71, -236.49, 46.12}
};

new const powerupName[][][] = { // Name - Label
    {"Nitro",       "~b~~h~Nitro"},
    {"Repair",      "~b~~h~Repair"},
    {"Cash",        "~g~~h~+500"},
    {"Random Item", "~y~~h~Random Item"},
    {"SMG",         "~b~~h~SMG"},
    {"RPG",         "~b~~h~RPG"}
};

new const powerups[][2] = { // Value - Pickup Model
    {1009,  1241},
    {1000,  1240},
    { 500,  1274},
    {   1, 18631},
    { 200,   353},
    {   2,   359}
};

new playerCar[MAX_PLAYERS];

new powerup[3]; // Pickup - Mapicon - Index

// Includes

#include "../../include/common"
#include "../../include/spawn"

// Callbacks

public OnFilterScriptInit()
{
    print("\n > Crashers filterscript by Amir Savand.\n");

    // Setup spawns
    AddSpawn(0, 0, -2047.60, -109.38, 41.0, 180.0);
    AddSpawn(0, 1, -2020.96, -131.68, 35.0, 153.3);
    AddSpawn(0, 2, -2021.20, -196.85, 35.0,  87.5);
    AddSpawn(0, 3, -2019.42, -274.43, 35.0,  24.7);
    AddSpawn(0, 4, -2053.26, -270.94, 35.0,   3.3);
    AddSpawn(0, 5, -2087.53, -266.67, 35.0, 334.8);
    AddSpawn(0, 6, -2090.18, -191.61, 35.0, 271.7);
    AddSpawn(0, 7, -2085.86, -119.35, 35.0, 205.3);

    // Setup players
    for (new i = 0; i < MAX_PLAYERS; i++)
        SetupPlayer(i);

    // Setup powerup
    RespawnPowerup();
}

public OnFilterScriptExit()
{
    // Destroy cars
    for (new i; i < MAX_PLAYERS; i++)
    {
        DestroyVehicle(playerCar[i]);
        playerCar[i] = INVALID_VEHICLE_ID;
    }
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
    new spawnpoint = RespawnPlayer(playerid);

    // Spawn a car for player
    SetupPlayerCar(playerid, spawnpoint);
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
    // Check powerup pickup
    if (pickupid == powerup[0])
    {
        // Short
        new name[100]; strcat(name, powerupName[powerup[2]][0]);
        new value = powerups[powerup[2]][0];

        // Alert player
        AlertPlayerText(playerid, powerupName[powerup[2]][1]);

        // Apply powerup
        if (isequal(name, "Nitro"))
        {
            AddVehicleComponent(PVI, value);
        }
        else if (isequal(name, "Repair"))
        {
            RepairVehicle(PVI);
            SetVehicleHealth(PVI, value);
        }
        else if (isequal(name, "Cash"))
        {
            GivePlayerMoney(playerid, value);
        }
        else if (isequal(name, "Random Item"))
        {
            CallRemoteFunction("GivePlayerRandomItem", "ii", playerid, value);
        }
        else if (isequal(name, "SMG"))
        {
            GivePlayerWeapon(playerid, WEAPON_MP5, value);
            SetPlayerArmedWeapon(playerid, WEAPON_MP5);
        }
        else if (isequal(name, "RPG"))
        {
            GivePlayerWeapon(playerid, WEAPON_ROCKETLAUNCHER, value);
            SetPlayerArmedWeapon(playerid, WEAPON_MP5);
        }

        // Create it again
        RespawnPowerup();
    }
}

public OnVehicleSpawn(vehicleid)
{
    // Check if it's a player car
    for (new i; i < MAX_PLAYERS; i++)
    {
        // Matches player car
        if (vehicleid == playerCar[i])
        {
            // Kill player
            SetPlayerHealth(i, 0);
            AlertPlayerText(i, "~r~~h~Car destroyed");

            // Destroy car
            DestroyVehicle(playerCar[i]);
            playerCar[i] = INVALID_VEHICLE_ID;
        }
    }
}

public OnPlayerDeath(playerid)
{
    // Trigger event
    CallRemoteFunction("OnPlayerCrashedInCrashers", "i", playerid);

    // Check all other players
    for (new otherplayer; otherplayer < MAX_PLAYERS; otherplayer++)
    {
        // If not the same player
        if (otherplayer != playerid)
        {
            // Reward other player
            GivePlayerMoney(otherplayer, SURVIVAL_REWARD);

            // Trigger event
            CallRemoteFunction("OnPlayerSurvivedCrashers", "ii", otherplayer, SURVIVAL_REWARD);
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
    }
}


forward PreventPlayerDropMoneyOnDeath(playerid);
public  PreventPlayerDropMoneyOnDeath(playerid)
{
    return 1;
}

forward PreventPlayerDropAmmoOnDeath(playerid);
public  PreventPlayerDropAmmoOnDeath(playerid)
{
    return 1;
}

// Functions

SetupPlayer(playerid)
{
    // Random color and no team
    SetPlayerColor(playerid, playerColors[Ran(0, sizeof(playerColors))]);
    SetPlayerTeam(playerid, NO_TEAM);
}

SetupPlayerCar(playerid, spawnpoint)
{
    // Destroy player car
    DestroyVehicle(playerCar[playerid]);
    playerCar[playerid] = INVALID_VEHICLE_ID;

    // Random car model
    new model = Ran(0, sizeof(models));

    // Player spawn point and area (short)
    new a = spawnArea, p = spawnpoint;

    // Create player car
    playerCar[playerid] = CreateVehicle(models[model], spawn[a][p][0], spawn[a][p][1], spawn[a][p][2], spawn[a][p][3], -1, -1, VEHICLE_RESPAWN);
    PutPlayerInVehicle(playerid, playerCar[playerid], 0);
}

// Publics

forward RespawnPowerup();
public  RespawnPowerup()
{
    new i = Ran(0, sizeof(powerupSpawns));
    new p = Ran(0, sizeof(powerups));
    
    DestroyDynamicPickup(powerup[0]);
    DestroyDynamicMapIcon(powerup[1]);

    powerup[0] = CreateDynamicPickup(powerups[p][1], 14, powerupSpawns[i][0], powerupSpawns[i][1], powerupSpawns[i][2]);
    powerup[1] = CreateDynamicMapIcon(powerupSpawns[i][0], powerupSpawns[i][1], powerupSpawns[i][2], 0, cCyan);
    powerup[2] = p;
}
