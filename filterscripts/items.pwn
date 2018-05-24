/**
* Items
*
* Items for players to consume/buy/sell.
* Allow player to use items via OnPlayerAttemptToUseItem (return 1)
*
* Events: OnPlayerGetItem(playerid, itemName, amount), OnPlayerAttemptToUseItem(playerid, item, itemName[])
* Remotes: GivePlayerRandomItem(playerid, item, amount), GivePlayersRandomItem(item, amount)
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT

#define DIALOG_ITEMS            300

#define MAX_ITEMS               8

#define RANDOM_ITEM_TIME        10 * 60000
#define RANDOM_ITEM_MIN_PLAYER  2

#define ITEM_HEALTH             1
#define ITEM_ARMOUR             2
#define ITEM_REPAIR             3
#define ITEM_NITROS             4
#define ITEM_PAINTS             5
#define ITEM_SKYDIVE            6
#define ITEM_AMMO               7

#pragma unused randomItems

// Includes

#include <a_samp>
#include <a_mysql>
#include <sscanf>
#include <zcmd>

#include "../include/common"
#include "../include/database"

// Variables

new const itemNames[MAX_ITEMS][] = {
    "",
    "Medic Box",
    "Body Armor",
    "Car Tools",
    "Nitros",
    "Special Paint",
    "Sky Dive",
    "Ammo Bag"
};

new const randomItems[] = {
    0,
    ITEM_HEALTH,
    ITEM_ARMOUR,
    ITEM_REPAIR,
    ITEM_NITROS,
    ITEM_PAINTS,
    ITEM_AMMO
};

new playerItem[MAX_PLAYERS][MAX_ITEMS];
new playerItemSelection[MAX_PLAYERS][MAX_ITEMS];

// Callbacks

public OnFilterScriptInit()
{
    print("\n > Items filterscript by Amir Savand.\n");

    // Give player items every 10 minutes
    SetTimerEx("GivePlayersRandomItem", RANDOM_ITEM_TIME, true, "i", 1);

    // Connect to db
    SetupDatabase();
    return 1;
}

public OnFilterScriptExit()
{
    // Save all players
    for (new i = 0; i < MAX_PLAYERS; i++)
        SavePlayerItems(i);

    // Close db
    CloseDatabase();
    return 1;
}

public OnPlayerDisconnect(playerid)
{
    SavePlayerItems(playerid);
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem)
{
    // Use selected item
    if (response && dialogid == DIALOG_ITEMS)
        UsePlayerItem(playerid, playerItemSelection[playerid][listitem]);
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    // Press Y
    if (PRESSED(KEY_YES))
    {
        // Show items
        cmd_items(playerid);
    }
    return 1;
}

// Events

forward OnPlayerLoad(playerid, uid);
public  OnPlayerLoad(playerid, uid)
{
    // Player loaded all database data, load items now
    LoadPlayerItems(playerid);
}

forward OnPlayerSave(playerid, uid);
public  OnPlayerSave(playerid, uid)
{
    // Player saved all database data, save items too
    SavePlayerItems(playerid);
}

// Functions

LoadPlayerItems(playerid)
{
    new uid = GetPVarInt(playerid, "id");

    // Load player
    new qry[500]; mysql_format(db, qry, sizeof(qry), "SELECT item, count FROM items WHERE player=%i", uid);
    new Cache:cache = mysql_query(db, qry);

    // Add all items
    for (new i; i < cache_num_rows(); i++)
    {
        new item;
        cache_get_value_int(i, "item", item);
        cache_get_value_int(i, "count", playerItem[playerid][item]);
    }

    cache_delete(cache);
}

SavePlayerItems(playerid)
{
    // Get player uid
    new uid = GetPVarInt(playerid, "id");
    new qry[1000];

    // If player has uid
    if (!uid) return;

    // Delete all player items
    mysql_query(db, sprintf("DELETE FROM items WHERE player=%i", uid), false);

    // Update items
    for (new i; i < MAX_ITEMS; i++)
    {
        // If doesn't have this item
        if (playerItem[playerid][i] < 1) continue;

        // Save item and count
        mysql_format(db, qry, sizeof(qry), "INSERT INTO items (player, item, count) values (%i, %i, %i)", uid, i, playerItem[playerid][i]);
        mysql_query(db, qry, false);
    }
}

UsePlayerItem(playerid, item)
{
    // Check if has item
    if (!playerItem[playerid][item] || !item)
        return 0;

    // Event
    new usage = CallRemoteFunction("OnPlayerAttemptToUseItem", "iis", playerid, item, itemNames[item]);

    // Can use
    if (usage)
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
            case ITEM_AMMO:    CallRemoteFunction("GivePlayerClassWeapons", "ii", playerid, 0);
        }

        // Decrease item count
        playerItem[playerid][item]--;
        AlertPlayerText(playerid, "~b~~h~Item Used");

        // Event
        CallRemoteFunction("OnPlayerUseItem", "iis", playerid, item, itemNames[item]);
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

    // Call remote
    CallRemoteFunction("OnPlayerGetItem", "isi", playerid, itemNames[item], amount);
}

forward GivePlayerRandomItem(playerid, amount);
public  GivePlayerRandomItem(playerid, amount)
{
    // Random item index
    new item = Ran(1, sizeof(randomItems));

    // Give player the random item
    GivePlayerItem(playerid, item, amount);
}

forward GivePlayersRandomItem(amount);
public  GivePlayersRandomItem(amount)
{
    // Check min players for random item
    if (CountPlayers() < RANDOM_ITEM_MIN_PLAYER)
        return 0;

    // Give all players random item
    for (new i; i < MAX_PLAYERS; i++)
        GivePlayerRandomItem(i, amount);

    return 1;
}

forward SkyDivePlayer(playerid);
public  SkyDivePlayer(playerid)
{
    // Send player to sky
    IMPORT_PLAYER_POS; SetPlayerPos(playerid, pPos[0] + 100, pPos[1] + 100, pPos[2] + 400);

    // Give parachute
    GivePlayerWeapon(playerid, WEAPON_PARACHUTE, 1);
    SetPlayerArmedWeapon(playerid, WEAPON_PARACHUTE);
    return 1;
}

// Commands

CMD:item(playerid) return cmd_items(playerid);
CMD:items(playerid)
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
        return AlertPlayerDialog(playerid, "Command Usage", "/giveitem [player] [item]");

    // Check id
    if (!IsValidIndex(sizeof(itemNames), item))
        return AlertPlayerText(playerid, "~r~~h~Invalid item id");

    GivePlayerItem(targetid, item, 1);
    return 1;
}
