/**
* Items
*
* Items for players to consume/buy/sell.
* Control item usage via OnPlayerUseItem (return 0 to pervent player from using item)
* Know what item player gets via OnPlayerGetItem
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT

#define DIALOG_ITEMS            300

#define MAX_ITEMS               100

#define RANDOM_ITEM_TIME        10 * 60000
#define RANDOM_ITEM_MIN_PLAYER  2

#define ITEM_HEALTH             1
#define ITEM_ARMOUR             2
#define ITEM_REPAIR             3
#define ITEM_NITROS             4
#define ITEM_PAINTS             5
#define ITEM_SKYDIVE            6

#pragma unused randomItems

// Includes

#include <a_samp>
#include <a_mysql>
#include <sscanf>
#include <zcmd>

#include "../include/common"

// Variables

new const itemNames[][] = {
    "",
    "Medic Box",     "Body Armor",
    "Car Tools",     "Nitros",
    "Special Paint", "Sky Dive"
};

new randomItems[MAX_ITEMS] = {
    0,
    ITEM_HEALTH, ITEM_ARMOUR,
    ITEM_REPAIR, ITEM_NITROS,
    ITEM_PAINTS
};

new playerItem[MAX_PLAYERS][MAX_ITEMS];
new playerItemSelection[MAX_PLAYERS][MAX_ITEMS];
new bool:isPlayerItemLoaded[MAX_PLAYERS];

new MySQL:db;

new randomItemTimer;

// Callbacks

public OnFilterScriptInit()
{
    print("\n > Items filterscript by Amir Savand.\n");

    // Give player items every 10 minutes
    randomItemTimer = SetTimer("GivePlayersRandomItem", RANDOM_ITEM_TIME, true);

    // Connect to database
    #include "../include/connect-database"
    return 1;
}

public OnFilterScriptExit()
{
    // Save all players
    for (new i = 0; i < MAX_PLAYERS; i++)
        SavePlayerItems(i);

    // Kill timers
    KillTimer(randomItemTimer);

    // Close db
    mysql_close(db);
    return 1;
}

public OnPlayerDisconnect(playerid)
{
    SavePlayerItems(playerid);
    return 1;
}

public OnPlayerSpawn(playerid)
{
    new uid = GetPVarInt(playerid, "id");

    // If already loaded
    if (isPlayerItemLoaded[playerid] == true || !uid)
        return 1;

    // Set to loaded
    isPlayerItemLoaded[playerid] = true;

    // Load player
    new qry[500]; mysql_format(db, qry, sizeof(qry), "SELECT item, count FROM items WHERE player=%i", uid);
    mysql_query(db, qry);

    // Add all items
    for (new i; i < cache_num_rows(); i++)
    {
        new item;
        cache_get_value_int(i, "item", item);
        cache_get_value_int(i, "count", playerItem[playerid][item]);
    }
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem)
{
    // Use selected item
    if (response && dialogid == DIALOG_ITEMS)
        UsePlayerItem(playerid, playerItemSelection[playerid][listitem]);
}

// Functions

SavePlayerItems(playerid)
{
    // Get player uid
    new uid = GetPVarInt(playerid, "id");

    // If player has uid
    if (uid < 1) return 0;

    // Delete all player items
    new qry[1000];
    mysql_format(db, qry, sizeof(qry), "DELETE FROM items WHERE player=%i", uid);
    mysql_tquery(db, qry);

    // Update items
    for (new i; i < MAX_ITEMS; i++)
    {
        // If doesn't have this item
        if (playerItem[playerid][i] < 1) continue;

        // Save item and count
        mysql_format(db, qry, sizeof(qry), "INSERT INTO items (player, item, count) values (%i, %i, %i)", uid, i, playerItem[playerid][i]);
        mysql_tquery(db, qry);
    }
    return 1;
}

UsePlayerItem(playerid, item)
{
    // Check if has item
    if (!playerItem[playerid][item] || !item)
        return 0;

    // Decrease item count
    playerItem[playerid][item]--;

    // Call remote
    new usage = CallRemoteFunction("OnPlayerUseItem", "iis", playerid, item, itemNames[item]);

    // Can use
    if (usage != 0)
    {
        // Consume item
        switch (item)
        {
            case ITEM_HEALTH:  SetPlayerHealth(playerid, 100);
            case ITEM_ARMOUR:  SetPlayerArmour(playerid, 100);
            case ITEM_REPAIR:  RepairVehicle(PVI);
            case ITEM_NITROS:  AddVehicleComponent(PVI, 1010);
            case ITEM_PAINTS:  ChangeVehicleColor(PVI, Ran(128, 243), Ran(128, 243));
            case ITEM_SKYDIVE: SkyDivePlayer(playerid);
        }

        // Alert
        AlertPlayerText(playerid, "~b~~h~Item Used");
        return 1;
    }

    // Can't use
    else return 0;
}

bool:HasPlayerAnyItems(playerid)
{
    for (new i; i < MAX_ITEMS; i++)
    {
        if (playerItem[playerid][i] > 0)
        {
            return true;
        }
    }

    return false;
}

// Publics

forward GivePlayerItem(playerid, item, amount);
public  GivePlayerItem(playerid, item, amount)
{
    // Add item
    playerItem[playerid][item] += amount;

    // Alert
    new str[500]; format(str, sizeof(str), "> You've got an item: {FFFF00}%s", itemNames[item]);
    AlertPlayer(playerid, str);

    // Call remote
    CallRemoteFunction("OnPlayerGetItem", "iii", playerid, item, amount);

    // Return amount
    return amount;
}

forward GivePlayerRandomItem(playerid);
public  GivePlayerRandomItem(playerid)
{
    // Random item index
    new item = Ran(1, sizeof(randomItems));

    // Give player the random item
    return GivePlayerItem(playerid, item, 1);
}

forward GivePlayersRandomItem();
public  GivePlayersRandomItem()
{
    // Check min players for random item
    if (CountPlayers() < RANDOM_ITEM_MIN_PLAYER)
        return 0;

    // Give all players random item
    for (new i; i < MAX_PLAYERS; i++)
        GivePlayerRandomItem(i);

    return 1;
}

forward SkyDivePlayer(playerid);
public  SkyDivePlayer(playerid)
{
    // Send player to sky
    IMPORT_PLAYER_POS; SetPlayerPos(playerid, pPos[0] + 100, pPos[1] + 100, pPos[2] + 500);

    // Give parachute
    GivePlayerWeapon(playerid, WEAPON_PARACHUTE, 1);
    SetPlayerArmedWeapon(playerid, WEAPON_PARACHUTE);
    return 1;
}

// Commands

CMD:item(playerid)
{
    // Check items
    if (!HasPlayerAnyItems(playerid))
        return AlertPlayerText(playerid, "~r~~h~You have no items");

    // Dialog string
    new index, str[2000] = "ID\tITEM\tAMOUNT\n";

    // Add all items
    for (new i; i < MAX_ITEMS; i++)
    {
        // If has that item
        if (playerItem[playerid][i] < 1) continue;

        // Add item name and count
        new istr[100]; format(istr, sizeof(istr), "%i\t{FFFF00}%s\t{DDDDDD}%i\n", i, itemNames[i], playerItem[playerid][i]);
        strcat(str, istr);

        // Store item index in menu
        playerItemSelection[playerid][index] = i;
        index++;
    }

    ShowPlayerDialog(playerid, DIALOG_ITEMS, DIALOG_STYLE_TABLIST_HEADERS, "Items", str, "Use", "Close");
    return 1;
}

CMD:giveitem(playerid, params[])
{
    // Check admin
    if (GetPlayerAdmin(playerid) < 5)
        return 0;

    new targetid, item;

    // Check usage
    if (sscanf(params, "ui", targetid, item))
        return AlertPlayerError(playerid, "> Command usage: /giveitem [player] [item]");

    // Check id
    if (!IsValidIndex(sizeof(itemNames), item))
        return AlertPlayerText(playerid, "~r~~h~Invalid item id");

    GivePlayerItem(targetid, item, 1);
    return 1;
}
