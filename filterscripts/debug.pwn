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