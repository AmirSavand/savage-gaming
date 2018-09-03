/**
* Objects
*
* Objects manager with in-game editor.
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT

#define Obj Object

#define MAX_OBJECT_UIDS    10000

#define EDITING_OBJECT_UID 0

// Includes

#include <a_samp>
#include <a_mysql>
#include <streamer>
#include <sscanf>
#include <zcmd>

#include "../include/common"
#include "../include/database"

// Variables

enum iObject
{
    id,
    model,
    Float:p[6],
    bool:exists,
    Text3D:label,
}

new Object[MAX_OBJECT_UIDS][iObject];

// Callbacks

public OnFilterScriptInit()
{
    SetupDatabase();
    SetupObjects();
}

public OnFilterScriptExit()
{
    print("\n > Objects filterscript by Amir Savand.\n");

    DestroyObjects();
    CloseDatabase();
}

public OnPlayerEditDynamicObject(playerid, objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
    if (response == EDIT_RESPONSE_FINAL)
    {
        // Insert car to db
        new Cache:cache = mysql_query(db, sprintf(
            "INSERT INTO objects SET model=%i, x=%f, y=%f, z=%f, rx=%f, ry=%f, rz=%f",
            GetDynamicObjectModel(objectid), x, y, z, rx, ry, rz
        ));

        // Short
        new ei = EDITING_OBJECT_UID;

        // Destroy the editing object
        DestroyObject_(ei);

        // Update pos and rot
        Obj[ei][p][0] = x;
        Obj[ei][p][1] = y;
        Obj[ei][p][2] = z;
        Obj[ei][p][3] = rx;
        Obj[ei][p][4] = ry;
        Obj[ei][p][5] = rz;

        // Create object via the new UID (generated)
        SetupObject(cache_insert_id(), true);

        // Free memory
        cache_delete(cache);
    }

    else if (response == EDIT_RESPONSE_CANCEL)
    {
        // Destroy the editing object
        DestroyObject_(EDITING_OBJECT_UID);
    }
}

// Functions

DestroyObjects()
{
    // Destroy all existing objects and their labels
    for (new i; i < MAX_OBJECT_UIDS; i++)
    {
        DestroyObject_(i);
    }
}

DestroyObject_(uid)
{
    Obj[uid][exists] = false;
    DestroyDynamicObject(Obj[uid][id]);
    DestroyDynamic3DTextLabel(Obj[uid][label]);
    Obj[uid][id] = INVALID_OBJECT_ID;
}

SetupObjects()
{
    // Get all objects from db
    new Cache:cache = mysql_query(db, sprintf("SELECT * FROM objects LIMIT %i", MAX_OBJECT_UIDS));

    // For each object
    for (new i; i < cache_num_rows(); i++)
    {
        // Get the UID
        new uid; cache_get_value_name_int(i, "id", uid);

        // Store model
        cache_get_value_name_int(i, "model", Obj[uid][model]);

        // Store position and rotation
        cache_get_value_name_float(i, "x",  Obj[uid][p][0]);
        cache_get_value_name_float(i, "y",  Obj[uid][p][1]);
        cache_get_value_name_float(i, "z",  Obj[uid][p][2]);
        cache_get_value_name_float(i, "rx", Obj[uid][p][3]);
        cache_get_value_name_float(i, "ry", Obj[uid][p][4]);
        cache_get_value_name_float(i, "rz", Obj[uid][p][5]);

        // Create in-game
        SetupObject(uid);
    }

    // Free memory
    cache_delete(cache);
}

SetupObject(uid, bool:fromedit = false)
{
    // Short
    new i = uid, ei = EDITING_OBJECT_UID;

    // It's from the editing object
    if (fromedit)
    {
        // Copy data
        Obj[i][model] = Obj[ei][model];
        Obj[i][p][0] = Obj[ei][p][0];
        Obj[i][p][1] = Obj[ei][p][1];
        Obj[i][p][2] = Obj[ei][p][2];
        Obj[i][p][3] = Obj[ei][p][3];
        Obj[i][p][4] = Obj[ei][p][4];
        Obj[i][p][5] = Obj[ei][p][5];
    }

    // Set to exists
    Obj[i][exists] = true;

    // Create in-game object
    Obj[i][id] = CreateDynamicObject(Obj[i][model], Obj[i][p][0], Obj[i][p][1], Obj[i][p][2], Obj[i][p][3], Obj[i][p][4], Obj[i][p][5]);

    // Create in-game label of the object
    Obj[i][label] = CreateDynamic3DTextLabel(sprintf("%i", i), 0xFF00FF66, Obj[i][p][0], Obj[i][p][1], Obj[i][p][2], 10);
}

stock GetObjectUid(objectid)
{
    for (new i; i < MAX_OBJECT_UIDS; i++)
    {
        if (Obj[i][id] == objectid)
        {
            return i;
        }
    }
    return INVALID_OBJECT_ID;
}


// Commands

CMD:addobj(playerid, params[]) return cmd_addobject(playerid, params);
CMD:addobject(playerid, params[])
{
    // Check admin
    if (!GetPlayerAdmin(playerid))
        return 0;

    // Short
    new uid = EDITING_OBJECT_UID;

    // Check param (model)
    if (sscanf(params, "i", Obj[uid][model]))
        return AlertPlayerDialog(playerid, "Command Usage", "/addobj [model]");

    // Destroy the old editing object (if exists somehow)
    DestroyObject_(uid);

    // Store position and rotation
    GetPlayerPos(playerid, Obj[uid][p][0], Obj[uid][p][1], Obj[uid][p][2]);
    GetPlayerFacingAngle(playerid, Obj[uid][p][5]);

    // Add a bit of offset
    Obj[uid][p][0] += 5;

    // Create the object
    SetupObject(uid);

    // Set to editing
    EditDynamicObject(playerid, Obj[uid][id]);
    return 1;
}

CMD:delobj(playerid, params[]) return cmd_delobject(playerid, params);
CMD:delobject(playerid, params[])
{
    // Check admin
    if (GetPlayerAdmin(playerid) < 5)
        return 0;

    // Check param (uid)
    new uid;
    if (sscanf(params, "i", uid))
        return AlertPlayerDialog(playerid, "Command Usage", "/delobj [uid]");

    // Check if exists (making sure)
    if (!Obj[uid][exists] || Obj[uid][id] == INVALID_OBJECT_ID)
        return AlertPlayerText(playerid, "~r~~h~Object not found");

    // Delete the object from database
    mysql_query(db, sprintf("DELETE FROM objects WHERE id=%i", uid), false);

    // Alert
    AlertPlayerText(playerid, "~g~~h~Object deleted");

    // Destroy the object in-game
    DestroyObject_(uid);
    return 1;
}

CMD:reloadobjs(playerid, params[]) return cmd_reloadobjects(playerid, params);
CMD:reloadobjects(playerid, params[])
{
    // Check admin
    if (!GetPlayerAdmin(playerid))
        return 0;

    // Reload objects from database
    DestroyObjects();
    SetupObjects();
    return 1;
}
