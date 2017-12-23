/**
* Engine Textdraw
*
* Vehicle engine status on screen (textdraw)
* Requires: PlayerText:engineTextdraw[MAX_PLAYERS][2]
*
* by Amir Savand
*/

InitialPlayerEngineTextdraw(playerid)
{
    engineTextdraw[playerid][0] = CreatePlayerTextDraw(playerid, 558.463317, 388.916717, "Engine");
    PlayerTextDrawLetterSize(playerid, engineTextdraw[playerid][0], 0.337000, 1.689999);
    PlayerTextDrawAlignment(playerid, engineTextdraw[playerid][0], 3);
    PlayerTextDrawColor(playerid, engineTextdraw[playerid][0], -5963521);
    PlayerTextDrawSetOutline(playerid, engineTextdraw[playerid][0], 1);
    PlayerTextDrawBackgroundColor(playerid, engineTextdraw[playerid][0], 255);
    PlayerTextDrawFont(playerid, engineTextdraw[playerid][0], 3);
    PlayerTextDrawSetProportional(playerid, engineTextdraw[playerid][0], 1);

    engineTextdraw[playerid][1] = CreatePlayerTextDraw(playerid, 560.000000, 388.916717, " ");
    PlayerTextDrawLetterSize(playerid, engineTextdraw[playerid][1], 0.434999, 1.689999);
    PlayerTextDrawAlignment(playerid, engineTextdraw[playerid][1], 1);
    PlayerTextDrawColor(playerid, engineTextdraw[playerid][1], -1);
    PlayerTextDrawSetOutline(playerid, engineTextdraw[playerid][1], 1);
    PlayerTextDrawBackgroundColor(playerid, engineTextdraw[playerid][1], 1131775);
    PlayerTextDrawFont(playerid, engineTextdraw[playerid][1], 3);
    PlayerTextDrawSetProportional(playerid, engineTextdraw[playerid][1], 1);
}

UpdatePlayerEngineTextdraw(playerid)
{
    // Is in any vehicle to show textdraw for
    if (IsPlayerInAnyVehicle(playerid))
    {
        // Show textdraw
        TogglePlayerEngineTextdraw(playerid, true);

        // Get engine status
        new Float: engine; GetVehicleHealth(GetPlayerVehicleID(playerid), engine);
        new dhp = floatround(engine)/10; if (dhp == 99) dhp++;
        new str[50]; format(str, sizeof(str),":_%i", dhp);

        // Update textdraw
        PlayerTextDrawSetString(playerid, engineTextdraw[playerid][1], str);
    }

    // Not in any vehicle, hide textdraw
    else TogglePlayerEngineTextdraw(playerid, false);
}

TogglePlayerEngineTextdraw(playerid, bool:toggle = true)
{
    if (toggle)
    {
        PlayerTextDrawShow(playerid, engineTextdraw[playerid][0]);
        PlayerTextDrawShow(playerid, engineTextdraw[playerid][1]);
    }

    else
    {
        PlayerTextDrawHide(playerid, engineTextdraw[playerid][0]);
        PlayerTextDrawHide(playerid, engineTextdraw[playerid][1]);
    }
}