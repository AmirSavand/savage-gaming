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

#define VEHICLE_RESPAWN				4

#define SURVIVAL_REWARD				500

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

new playerCar[MAX_PLAYERS];

new timer;

// Includes

#include "../../include/common"
#include "../../include/spawn"
#include "../../include/spawn-package"

// Callbacks

public OnFilterScriptInit()
{
    print("\n > Crashers filterscript by Amir Savand.\n");

	// Setup spawns
	AddSpawn(0, 0, -2051.56, -118.69, 35.0, 178.2);
	AddSpawn(0, 1, -2020.96, -131.68, 35.0, 153.3);
	AddSpawn(0, 2, -2021.20, -196.85, 35.0,  87.5);
	AddSpawn(0, 3, -2019.42, -274.43, 35.0,  24.7);
	AddSpawn(0, 4, -2053.26, -270.94, 35.0,   3.3);
	AddSpawn(0, 5, -2087.53, -266.67, 35.0, 334.8);
	AddSpawn(0, 6, -2090.18, -191.61, 35.0, 271.7);
	AddSpawn(0, 7, -2085.86, -119.35, 35.0, 205.3);

	// Setup package spawns
	AddPackageSpawn(0, 0, -2018.58, -141.22, 34.88);
	AddPackageSpawn(0, 1, -2015.91, -180.49, 34.89);
	AddPackageSpawn(0, 2, -2018.58, -221.76, 34.87);
	AddPackageSpawn(0, 3, -2022.45, -272.43, 34.88);
	AddPackageSpawn(0, 4, -2052.76, -268.20, 34.88);
	AddPackageSpawn(0, 5, -2087.91, -260.73, 34.88);
	AddPackageSpawn(0, 6, -2089.27, -217.23, 34.87);
	AddPackageSpawn(0, 7, -2089.09, -144.68, 34.88);
	AddPackageSpawn(0, 8, -2055.72, -126.34, 34.87);

    // Setup players
    for (new i = 0; i < MAX_PLAYERS; i++)
        SetupPlayer(i);

    // Setup timer
    timer = SetTimer("RespawnPackage", 60000, 1);
}

public OnFilterScriptExit()
{
    KillTimer(timer);

    // Destroy cars
    for (new i; i < MAX_PLAYERS; i++)
    	DestroyVehicle(playerCar[i]);
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
    // Check for package
    CheckPackage(playerid, pickupid);
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
			DestroyVehicle(vehicleid);
		}
	}
}

public OnPlayerDeath(playerid)
{
	// Trigger event
	CallRemoteFunction("OnPlayerCrashedInCrashers", "i", playerid);

	// Check all other players
	for (new i; i < MAX_PLAYERS; i++)
	{
		// If not the same player
		if (i != playerid)
		{
			// Reward other player
			GivePlayerMoney(i, SURVIVAL_REWARD);

			// Trigger event
			CallRemoteFunction("OnPlayerSurvivedCrashers", "ii", i, SURVIVAL_REWARD);
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
        SetPackageSpawnArea(area);
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

    // Random car model
    new model = Ran(0, sizeof(models));

    // Player spawn point and area (short)
    new a = spawnArea, p = spawnpoint;

    // Create player car
    playerCar[playerid] = CreateVehicle(models[model], spawn[a][p][0], spawn[a][p][1], spawn[a][p][2], spawn[a][p][3], -1, -1, VEHICLE_RESPAWN);
    PutPlayerInVehicle(playerid, playerCar[playerid], 0);
}
