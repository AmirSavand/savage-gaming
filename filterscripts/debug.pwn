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

#include "../../include/common"

// Callbacks

public OnFilterScriptInit()
{
    print("\n > Debug filterscript by Amir Savand.\n");
    return 1;
}

// Commands

CMD:myteam(playerid)
{
    printf("[debug] Player %i team is %i", playerid, GetPlayerTeam(playerid));
    return 1;
}

CMD:mypos(playerid)
{
    IMPORT_PLAYER_POS;
    printf("[debug] Player %i pos: %f %f %f %f", playerid, pPos[0], pPos[1], pPos[2], pPos[3]);
    return 1;
}
