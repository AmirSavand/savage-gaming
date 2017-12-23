/**
* Players
*
* Handle players loading and saving data
* No password required so it's auto login
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT

// Includes

#include <a_samp>
#include <a_mysql>

#include "../include/common"

// Variables

new MySQL:db;

// Callbacks

public OnFilterScriptInit()
{
    print("\n > Players filterscript by Amir Savand.\n");

    // Connect to database
    #include "../include/connect-database"
    return 1;
}

public OnFilterScriptExit()
{
    for (new i = 0; i < MAX_PLAYERS; i++)
        SavePlayer(i);

    mysql_close(db);
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    // If not sucide
    if (killerid != INVALID_PLAYER_ID)
    {
        // Increase kills
        SetPVarInt(playerid, "kills", GetPVarInt(playerid, "kills") + 1);
    }
    return 1;
}

public OnPlayerConnect(playerid)
{
    new qry[500];
    mysql_format(db, qry, sizeof(qry), "SELECT* FROM players WHERE name='%e'", GetName(playerid));
    mysql_query(db, qry);

    // Register
    if (!cache_num_rows())
    {
        // Insert player
        mysql_format(db, qry, sizeof(qry), "INSERT INTO players SET name='%e'", GetName(playerid));
        mysql_tquery(db, qry);
        SetPVarInt(playerid, "new", 1);
        SetPVarInt(playerid, "rank", 1);
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
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    SavePlayer(playerid);
    return 1;
}

// Functions

SavePlayer(playerid)
{
    if (GetPVarInt(playerid, "id") < 1)
        return 0;

    new qry[2000]; mysql_format(db, qry, sizeof(qry), "UPDATE players SET money=%i, rank=%i, kills=%i WHERE name='%e'", 
        GetPlayerMoney(playerid), GetPVarInt(playerid, "rank"), GetPVarInt(playerid, "kills"), GetName(playerid));
    mysql_tquery(db, qry);
    return 1;
}
