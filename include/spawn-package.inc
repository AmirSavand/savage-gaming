/**
* Package
*
* Collectable packages spawn (works like spawn.inc).
*
* Requires: MAX_SPAWN_POINTS_PACKAGE (1), MAX_SPAWN_AREAS (1)
* Events: OnPlayerCollectPackage(playerid)
*
* by Amir Savand
*/

// Variabels

new Float:packageSpawn[MAX_SPAWN_AREAS][MAX_SPAWN_POINTS_PACKAGE][3];
new packageSpawnArea;
new package[2]; // Pickup - Mapicon

// Functions

CheckPackage(playerid, pickupid)
{
    // If random package
    if (pickupid == package[0])
    {
        // Destroy it and its mapicon
        DestroyDynamicPickup(package[0]);
        DestroyDynamicMapIcon(package[1]);
        package[0] = 0;
        package[1] = 0;

        // Trigger event
        CallRemoteFunction("OnPlayerCollectPackage", "i", playerid);
    }
}

AddPackageSpawn(area, point, Float:x, Float:y, Float:z)
{
    packageSpawn[area][point][0] = x;
    packageSpawn[area][point][1] = y;
    packageSpawn[area][point][2] = z;
}

stock SetPackageSpawnArea(area)
{
    packageSpawnArea = area;
}

// Forwards

forward RespawnPackage();
public  RespawnPackage()
{
    // Setup area and point
    new p = Ran(0, MAX_SPAWN_POINTS_PACKAGE);
    new a = packageSpawnArea;

    // Destroy pickup and mapicon
    DestroyDynamicPickup(package[0]);
    DestroyDynamicMapIcon(package[1]);

    // Spawn random package pickup and mapicon
    package[0] = CreateDynamicPickup(19057, 1, packageSpawn[a][p][0], packageSpawn[a][p][1], packageSpawn[a][p][2]);
    package[1] = CreateDynamicMapIcon(packageSpawn[a][p][0], packageSpawn[a][p][1], packageSpawn[a][p][2], 25, 0, -1, -1, -1, 2000, MAPICON_GLOBAL);
}
