/**
* Speed Textdraw
*
* Vehicle speed (km/h) on screen for players (textdraw)
*
* by Amir Savand
*/

// Variables

new PlayerText:speedTextdraw[MAX_PLAYERS][2]; // Text - Value

// Functions

SetupSpeedTextdraw(playerid)
{
    speedTextdraw[playerid][0] = CreatePlayerTextDraw(playerid, 558.463317, 370.915618, "Speed");
    PlayerTextDrawLetterSize(playerid, speedTextdraw[playerid][0], 0.368000, 1.701666);
    PlayerTextDrawAlignment(playerid, speedTextdraw[playerid][0], 3);
    PlayerTextDrawColor(playerid, speedTextdraw[playerid][0], 16777215);
    PlayerTextDrawSetOutline(playerid, speedTextdraw[playerid][0], 1);
    PlayerTextDrawBackgroundColor(playerid, speedTextdraw[playerid][0], 255);
    PlayerTextDrawFont(playerid, speedTextdraw[playerid][0], 3);
    PlayerTextDrawSetProportional(playerid, speedTextdraw[playerid][0], 1);

    speedTextdraw[playerid][1] = CreatePlayerTextDraw(playerid, 560.000000, 371.015625, " ");
    PlayerTextDrawLetterSize(playerid, speedTextdraw[playerid][1], 0.434999, 1.689999);
    PlayerTextDrawAlignment(playerid, speedTextdraw[playerid][1], 1);
    PlayerTextDrawColor(playerid, speedTextdraw[playerid][1], -1);
    PlayerTextDrawSetOutline(playerid, speedTextdraw[playerid][1], 1);
    PlayerTextDrawBackgroundColor(playerid, speedTextdraw[playerid][1], 1131775);
    PlayerTextDrawFont(playerid, speedTextdraw[playerid][1], 3);
    PlayerTextDrawSetProportional(playerid, speedTextdraw[playerid][1], 1);

}

UpdateSpeedTextdraw(playerid)
{
    // Is in any vehicle to show textdraw for
    if (IsPlayerInAnyVehicle(playerid))
    {
        // Show textdraw
        TogglePlayerSpeedTextdraw(playerid, true);

        // Update textdraw and show current speed
        PlayerTextDrawSetString(playerid, speedTextdraw[playerid][1], sprintf(":_%i", floatround(GetVehicleSpeed(PVI))));
    }

    // Not in any vehicle, hide textdraw
    else TogglePlayerSpeedTextdraw(playerid, false);
}

TogglePlayerSpeedTextdraw(playerid, bool:toggle = true)
{
    // Show
    if (toggle)
    {
        PlayerTextDrawShow(playerid, speedTextdraw[playerid][0]);
        PlayerTextDrawShow(playerid, speedTextdraw[playerid][1]);
    }

    // Hide
    else
    {
        PlayerTextDrawHide(playerid, speedTextdraw[playerid][0]);
        PlayerTextDrawHide(playerid, speedTextdraw[playerid][1]);
    }
}
