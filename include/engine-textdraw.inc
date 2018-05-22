/**
* Engine Textdraw
*
* Vehicle engine status on screen for players (textdraw)
*
* by Amir Savand
*/

// Variables

new PlayerText:engineTextdraw[MAX_PLAYERS][2]; // Text - Value

// Functions

SetupEngineTextdraw(playerid)
{
    engineTextdraw[playerid][0] = CreatePlayerTextDraw(playerid, 558, 390, "Engine");
    PlayerTextDrawLetterSize(playerid, engineTextdraw[playerid][0], 0.337, 1.69);
    PlayerTextDrawAlignment(playerid, engineTextdraw[playerid][0], 3);
    PlayerTextDrawColor(playerid, engineTextdraw[playerid][0], -5963521);
    PlayerTextDrawSetOutline(playerid, engineTextdraw[playerid][0], 1);
    PlayerTextDrawBackgroundColor(playerid, engineTextdraw[playerid][0], 255);
    PlayerTextDrawFont(playerid, engineTextdraw[playerid][0], 3);
    PlayerTextDrawSetProportional(playerid, engineTextdraw[playerid][0], 1);

    engineTextdraw[playerid][1] = CreatePlayerTextDraw(playerid, 560, 390, " ");
    PlayerTextDrawLetterSize(playerid, engineTextdraw[playerid][1], 0.434999, 1.69);
    PlayerTextDrawAlignment(playerid, engineTextdraw[playerid][1], 1);
    PlayerTextDrawColor(playerid, engineTextdraw[playerid][1], -1);
    PlayerTextDrawSetOutline(playerid, engineTextdraw[playerid][1], 1);
    PlayerTextDrawBackgroundColor(playerid, engineTextdraw[playerid][1], 1131775);
    PlayerTextDrawFont(playerid, engineTextdraw[playerid][1], 3);
    PlayerTextDrawSetProportional(playerid, engineTextdraw[playerid][1], 1);
}

UpdateEngineTextdraw(playerid)
{
    // Is in any vehicle to show textdraw for
    if (IsPlayerInAnyVehicle(playerid))
    {
        // Show textdraw
        TogglePlayerEngineTextdraw(playerid, true);

        // Update textdraw and show current engine status
        PlayerTextDrawSetString(playerid, engineTextdraw[playerid][1], sprintf(":_%i", floatround(GetVehicleEngine(PVI) / 10)));
    }

    // Not in any vehicle, hide textdraw
    else TogglePlayerEngineTextdraw(playerid, false);
}

TogglePlayerEngineTextdraw(playerid, bool:toggle = true)
{
    // Show
    if (toggle)
    {
        PlayerTextDrawShow(playerid, engineTextdraw[playerid][0]);
        PlayerTextDrawShow(playerid, engineTextdraw[playerid][1]);
    }

    // Hide
    else
    {
        PlayerTextDrawHide(playerid, engineTextdraw[playerid][0]);
        PlayerTextDrawHide(playerid, engineTextdraw[playerid][1]);
    }
}