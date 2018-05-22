/**
* Random Package
*
* Random packages spawn in world.
* Requires variable: Float:randomPackageSpawns[][]
*
* by Amir Savand
*/

// Variabels

new randomPackage;
new randomPackageMapicon;

// Functions

bool:CheckRandomPackage(playerid, pickupid)
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
        return true;
    }
    return false;
}

forward SpawnRandomPackage();
public  SpawnRandomPackage()
{
    // Get random spawn point
    new i = Ran(0, sizeof(randomPackageSpawns));

    // Destroy pickup and mapicon
    DestroyDynamicPickup(randomPackage);
    DestroyDynamicMapIcon(randomPackageMapicon);

    // Spawn random package pickup and mapicon
    randomPackage = CreateDynamicPickup(19057, 1, randomPackageSpawns[i][0], randomPackageSpawns[i][1], randomPackageSpawns[i][2]);
    randomPackageMapicon = CreateDynamicMapIcon(randomPackageSpawns[i][0], randomPackageSpawns[i][1], randomPackageSpawns[i][2], 56, 0, -1, -1, -1, 2000);
}
