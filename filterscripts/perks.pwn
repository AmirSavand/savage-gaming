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
    {"More ammo on pickup",             "+0.4",     0.4},
    {"More primary ammo",               "+0.4",     0.4},
    {"More secondary ammo",             "+0.4",     0.4},
    {"More lethal ammo",                "+2",       2.0},
    {"RPG on spawn",                    "+1",       1.0},
    {"HS Rocket on spawn",              "+2",       2.0},
    {"Armor on spawn",                  "+40",     40.0},
    {"Nitro on vehicle enter",          "x10",   1010.0},
    {"More engine on vehicle purchase", "+100",   100.0},
    {"Spawn with a bike",               "BMX",    481.0}
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
    new uid = GetPVarInt(playerid, "id");

    // If already loaded
    if (isPlayerLoaded[playerid] || !uid)
        return 1;

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

    cache_delete(cache);
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
        if (GetPlayerMaxPerks(playerid) >= CountPlayerPerks(playerid) && !playerPerks[playerid][listitem])
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
        new qry[500]; mysql_format(db, qry, sizeof(qry), "UPDATE perks SET perk=%i, status=%i WHERE player=%i", i, playerPerks[playerid][i], uid);
        mysql_tquery(db, qry);
    }
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

// Commands

CMD:perk(playerid) return cmd_perks(playerid);
CMD:perks(playerid)
{
    // Perks dialog
    ShowPlayerPerks(playerid);
    return 1;
}
