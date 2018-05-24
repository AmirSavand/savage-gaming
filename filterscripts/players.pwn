/**
* Players
*
* Handle players loading and saving data
* No password required so it's auto login
*
* Events: OnPlayerLoad(playerid, uid), OnPlayerSave(playerid, uid)
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT

// Includes

#include <a_samp>
#include <a_mysql>

#include "../include/common"
#include "../include/database"

// Callbacks

public OnFilterScriptInit()
{
    print("\n > Players filterscript by Amir Savand.\n");

    SetupDatabase();
    return 1;
}

public OnFilterScriptExit()
{
    // Save all players
    for (new i; i < MAX_PLAYERS; i++)
        SavePlayer(i);

    CloseDatabase();
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    // If not sucide
    if (killerid != INVALID_PLAYER_ID)
    {
        // Increase kills of killer
        SetPVarInt(killerid, "kills", GetPVarInt(killerid, "kills") + 1);
    }
    return 1;
}

public OnPlayerConnect(playerid)
{
    LoadPlayer(playerid);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    SavePlayer(playerid);
    return 1;
}

// Events

forward OnPlayerChangeName(playerid);
public  OnPlayerChangeName(playerid)
{
    SavePlayer(playerid);
    LoadPlayer(playerid);
}

// Functions

LoadPlayer(playerid)
{
    new qry[500];
    mysql_format(db, qry, sizeof(qry), "SELECT * FROM players WHERE name='%e'", GetName(playerid));
    new Cache:cache = mysql_query(db, qry);

    // Register
    if (!cache_num_rows())
    {
        // Insert player
        mysql_format(db, qry, sizeof(qry), "INSERT INTO players SET name='%e'", GetName(playerid));
        mysql_query(db, qry, false);
        SetPVarInt(playerid, "new", 1);
        SetPVarInt(playerid, "rank", 0);
    }

    // Log in
    else
    {
        // Store data
        new id, money, admin, rank, kills;
        cache_get_value_int(0, "id", id);
        cache_get_value_int(0, "money", money);
        cache_get_value_int(0, "admin", admin);
        cache_get_value_int(0, "rank", rank);
        cache_get_value_int(0, "kills", kills);

        // Apply data
        SetPVarInt(playerid, "id", id);
        SetPVarInt(playerid, "admin", admin);
        SetPVarInt(playerid, "rank", rank);
        SetPVarInt(playerid, "kills", kills);

        SetPlayerMoney(playerid, money);
    }

    cache_delete(cache);

    // Event
    CallRemoteFunction("OnPlayerLoad", "ii", playerid, GetPVarInt(playerid, "id"));
}

SavePlayer(playerid)
{
    if (GetPVarInt(playerid, "id") < 1)
        return 0;

    new qry[2000]; mysql_format(db, qry, sizeof(qry), "UPDATE players SET money=%i, rank=%i, kills=%i WHERE id=%i", 
        GetPlayerMoney(playerid), GetPVarInt(playerid, "rank"), GetPVarInt(playerid, "kills"), GetPVarInt(playerid, "id"));
    mysql_tquery(db, qry);

    // Event
    CallRemoteFunction("OnPlayerSave", "ii", playerid, GetPVarInt(playerid, "id"));
    return 1;
}
