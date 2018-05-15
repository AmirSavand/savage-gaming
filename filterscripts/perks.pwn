/**
* Perks
*
* Perks and benefits for players to choose.
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT

#define DIALOG_PERKS    700

#define MAX_PERKS       100

#define INVALID_PERK_ID -1

// Includes

#include <a_samp>
#include <a_mysql>
#include <streamer>
#include <sscanf>
#include <zcmd>

#include "../../include/common"
#include "../../include/database"

// Enum

enum iPerk
{
    name[100],
    addition[50],
    Float:value
};

// Variables

new bool:playerPerks[MAX_PLAYERS][MAX_PERKS];
new bool:isPlayerLoaded[MAX_PLAYERS];

new const perks[][iPerk] = {
    {"More ammo on pickup",             "+0.3",     0.3},
    {"More primary ammo",               "+0.3",     0.3},
    {"More secondary ammo",             "+0.3",     0.3},
    {"More lethal ammo",                "+2",       2.0},
    {"RPG on spawn",                    "+1",       1.0},
    {"HS Rocket on spawn",              "+1",       1.0},
    {"Armor on spawn",                  "+40",     40.0},
    {"Nitro on vehicle purchase",       "x10",   1010.0},
    {"More engine on vehicle purchase", "+100",  1000.0},
    {"Explode on death",                "",         0.0}
};

// Callbacks

public OnFilterScriptInit()
{
    print("\n > Perks filterscript by Amir Savand.\n");

    // Connect to db
    InitialDatabase();
    return 1;
}

public OnFilterScriptExit()
{
    // Save all players perks
    for (new i; i < MAX_PLAYERS; i++)
        SavePlayerPerks(i);

    // Close db
    CloseDatabase();
    return 1;
}

public OnPlayerSpawn(playerid)
{
    // Load up
    LoadPlayerPerks(playerid);

    // Apply perks
    new perk = DoesPlayerHavePerk(playerid, "Armor on spawn");
    if (perk != INVALID_PERK_ID)
        SetPlayerArmour(playerid, GetArmour(playerid) + perks[perk][value]);

    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    // Apply perk
    new perk = DoesPlayerHavePerk(playerid, "Explode on death");
    if (perk != INVALID_PERK_ID)
    {
        // Get positon
        IMPORT_PLAYER_POS;

        // Create explosion
        CreateExplosion(pPos[0], pPos[1], pPos[2], 0, 10.0);
    }
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    // Save player
    SavePlayerPerks(playerid);
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    // Selected a perk
    if (dialogid == DIALOG_PERKS && response)
    {
        // If player reached perks limit (and trying to enable)
        if (CountPlayerPerks(playerid) >= GetPlayerMaxPerks(playerid) && !playerPerks[playerid][listitem])
        {
            // Error player
            AlertPlayerDialog(playerid, "Info", "{FF0000}You can't activate anymore perks!\n{DDDDDD}You need to rank up or deactivate other perks.");
        }

        // Player can activate more perks
        else
        {
            // Toggle perk status
            playerPerks[playerid][listitem] = !playerPerks[playerid][listitem];

            // Show perks again
            ShowPlayerPerks(playerid);
        }
    }
}

// Public functiosn

forward OnPlayerPickupDeathPickup(playerid);
public  OnPlayerPickupDeathPickup(playerid)
{
    // Apply perk
    new perk = DoesPlayerHavePerk(playerid, "More ammo on pickup");

    if (perk != INVALID_PERK_ID)
        CallRemoteFunction("GivePlayerClassWeapons", "if", playerid, perks[perk][value]);
}

forward OnPlayerPurchaseVehicle(playerid, vehicleid);
public  OnPlayerPurchaseVehicle(playerid, vehicleid)
{
    // Apply perk
    new perk;

    perk = DoesPlayerHavePerk(playerid, "More engine on vehicle purchase");
    if (perk != INVALID_PERK_ID)
        SetVehicleHealth(vehicleid, GetVehicleEngine(vehicleid) + perks[perk][value]);

    perk = DoesPlayerHavePerk(playerid, "Nitro on vehicle purchase");
    if (perk != INVALID_PERK_ID)
        AddVehicleComponent(vehicleid, floatround(perks[perk][value]));
}

forward OnPlayerRearmWeaponClass(playerid);
public  OnPlayerRearmWeaponClass(playerid)
{
    // Apply perk
    new perk;

    perk = DoesPlayerHavePerk(playerid, "More primary ammo");
    if (perk != INVALID_PERK_ID)
        CallRemoteFunction("GivePlayerPrimaryAmmo", "if", playerid, perks[perk][value]);

    perk = DoesPlayerHavePerk(playerid, "More secondary ammo");
    if (perk != INVALID_PERK_ID)
        CallRemoteFunction("GivePlayerSecondaryAmmo", "if", playerid, perks[perk][value]);

    perk = DoesPlayerHavePerk(playerid, "More lethal ammo");
    if (perk != INVALID_PERK_ID)
        CallRemoteFunction("GivePlayerLethalAmmo", "ii", playerid, floatround(perks[perk][value]));

    perk = DoesPlayerHavePerk(playerid, "RPG on spawn");
    if (perk != INVALID_PERK_ID)
        GivePlayerWeapon(playerid, WEAPON_ROCKETLAUNCHER, floatround(perks[perk][value]));

    perk = DoesPlayerHavePerk(playerid, "HS Rocket on spawn");
    if (perk != INVALID_PERK_ID)
        GivePlayerWeapon(playerid, WEAPON_HEATSEEKER, floatround(perks[perk][value]));
}

// Functions

SavePlayerPerks(playerid) // Save perks to db
{
    // Get player db id
    new uid = GetPVarInt(playerid, "id");

    // Not db player
    if (!uid) return;

    // Update perks (statuses)
    for (new i; i < sizeof(perks); i++)
    {
        // Save perk and status
        new qry[500];
        mysql_format(db, qry, sizeof(qry), "UPDATE perks SET status=%i WHERE perk=%i AND player=%i", playerPerks[playerid][i], i, uid);
        mysql_query(db, qry, false);
    }
}

LoadPlayerPerks(playerid) // Load perks form db
{
    new uid = GetPVarInt(playerid, "id");

    // If already loaded
    if (isPlayerLoaded[playerid] || !uid)
        return;

    // Set to loaded
    isPlayerLoaded[playerid] = true;

    // Load player
    new qry[500]; mysql_format(db, qry, sizeof(qry), "SELECT perk, status FROM perks WHERE player=%i", uid);
    new Cache:cache = mysql_query(db, qry);

    // Add all perks
    for (new i; i < cache_num_rows(); i++)
    {
        new perk;

        // Store perk and status
        cache_get_value_int(i, "perk", perk);
        cache_get_value_bool(i, "status", playerPerks[playerid][perk]);
    }

    // No perks (not initiated)
    if (cache_num_rows() != sizeof(perks))
    {
        // Delete all perks
        mysql_query(db, sprintf("DELETE FROM perks WHERE player=%i", uid), false);

        // Add all perks (initiate)
        for (new i; i < sizeof(perks); i++)
            mysql_query(db, sprintf("INSERT INTO perks (player, perk, status) VALUES (%i, %i, %i)", uid, i, playerPerks[playerid][i]), false);
    }

    cache_delete(cache);
}

ShowPlayerPerks(playerid) // Perks dialog
{
    // Dialog string
    new str[2000] = "ADDITION\tPERK\tSTATUS\n";

    // Add all perks
    for (new i; i < sizeof(perks); i++)
    {
        // Perk status strings
        new active[20]   = "{00FF00}Active";
        new deactive[20] = "{DDDDDD}Deactive";

        // Add perk detail to dialog string
        strcat(str, sprintf("{00FF00}%s\t{DDDDDD}%s\t%s\n", perks[i][addition], perks[i][name], playerPerks[playerid][i] ? active : deactive));
    }

    // Show perks
    ShowPlayerDialog(playerid, DIALOG_PERKS, DIALOG_STYLE_TABLIST_HEADERS, sprintf("Perks {00FF00}(%i/%i)", CountPlayerPerks(playerid), GetPlayerMaxPerks(playerid)), str, "Toggle", "Close");
}

CountPlayerPerks(playerid) // Number of player's activated perks
{
    // Count
    new count;

    // For all player perks
    for (new i; i < sizeof(perks); i++)
    {
        // If player has it
        if (playerPerks[playerid][i])
        {
            // Count it
            count++;
        }
    }
    return count;
}

GetPlayerMaxPerks(playerid) // Maximum number of perks that player can have (activated)
{
    // Rank
    return GetPVarInt(playerid, "rank");
}

DoesPlayerHavePerk(playerid, perkName[]) // Check if player has this perk
{
    // For all perks
    for (new i; i < sizeof(perks); i++)
    {
        // Matches perk name and perk is activated
        if (isequal(perks[i][name], perkName) && playerPerks[playerid][i])
        {
            // Yes, return the perk id
            return i;
        }
    }

    // Not found
    return INVALID_PERK_ID;
}

// Commands

CMD:perk(playerid) return cmd_perks(playerid);
CMD:perks(playerid)
{
    // Perks dialog
    ShowPlayerPerks(playerid);
    return 1;
}
