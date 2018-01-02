/**
* Drop money
*
* Money drops anywhere like when a player dies.
* To make player pickup cash call CheckPlayerMoneyDropPickup() on pickup.
* To make player drop cash call CheckPlayerMoneyDrop().
*
* by Amir Savand
*/

// Defines

#define MAX_DROP_MONEY      500
#define DROP_MONEY_PICKUPS  10
#define DROP_MONEY_AMOUNT   5

// Variables

new dropMoney[MAX_DROP_MONEY];

// Functions

stock DropMoney(Float:x, Float:y, Float:z, pickups = DROP_MONEY_PICKUPS)
{
    // For all drop money pickups
    for (new i; i < pickups; i++)
    {
        // Random index
        new index = Ran(0, MAX_DROP_MONEY);

        // (Re)Create dropped money pickup
        DestroyDynamicPickup(dropMoney[index]);
        dropMoney[index] = CreateDynamicPickup(1212, 1, x + Ran(-i/2, i/2), y + Ran(-i/2, i/2), z - 0.5);
    }
}

stock DestroyDropMoney()
{
    // For all drop money (index)
    for (new i; i < MAX_DROP_MONEY; i++)
    {
        // Destroy dropped money pickup
        DestroyDynamicPickup(dropMoney[i]);
    }
}

stock bool:IsDropMoneyPickup(pickupid)
{
    // Check all drop money pickups
    for (new i; i < MAX_DROP_MONEY; i++)
    {
        // Check match
        if (pickupid == dropMoney[i]) return true;
    }

    // No match
    return false;
}

stock CheckPlayerMoneyDropPickup(playerid, pickupid, amount = DROP_MONEY_AMOUNT)
{
    // Is dropped money
    if (IsDropMoneyPickup(pickupid))
    {
        // Give player money and destroy pickup
        GivePlayerMoney(playerid, amount);
        DestroyDynamicPickup(pickupid);
        AlertPlayerText(playerid, sprintf("~g~~h~+%i", amount));
        PlayerPlaySound(playerid, 1083, 0, 0, 0);
    }
}

stock DropMoneyFromPlayer(playerid, pickups = DROP_MONEY_PICKUPS)
{
    // Get positon
    IMPORT_PLAYER_POS;

    // Drop money
    DropMoney(pPos[0], pPos[1], pPos[2], pickups);
}
