/**
* Debug
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT

// Includes

#include <a_samp>
#include <zcmd>

#include "../include/common"

// Callbacks

public OnFilterScriptInit()
{
    print("\n > Debug filterscript by Amir Savand.\n");
}

// Commands

CMD:myteam(playerid)
{
    printf("[debug] Player %i team is %i", playerid, GetPlayerTeam(playerid));
    return 1;
}

CMD:pos(playerid, params[])
{
    IMPORT_PLAYER_POS;
    if (IsPlayerInAnyVehicle(playerid))
    	GetVehicleZAngle(PVI, pPos[3]);
    printf("[debug] Position (%s): %f, %f, %f, %f", params, pPos[0], pPos[1], pPos[2], pPos[3]);
    return 1;
}

CMD:armor(playerid)
{
    SetPlayerArmour(playerid, 200);
    return 1;
}
