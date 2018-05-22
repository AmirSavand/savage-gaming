/**
* Cool Textdraw
*
* Some cool textdraws with different styles for players.
*
* Requirements: COOL_TEXTDRAW_TIME (5)
*
* by Amir Savand
*/

// Defines

#define COOL_TEXTDRAW_BOTTOM 0

// Variables

new PlayerText:coolTextdraw[MAX_PLAYERS][5];
new coolTextdrawTimer[MAX_PLAYERS][5];

// Functions

SetupPlayerCoolTextdraw(playerid)
{
    coolTextdraw[playerid][COOL_TEXTDRAW_BOTTOM] = CreatePlayerTextDraw(playerid, 320.0, 320.0, "_~n~_~n~_");
    PlayerTextDrawLetterSize(playerid, coolTextdraw[playerid][COOL_TEXTDRAW_BOTTOM], 0.4, 2.0);
    PlayerTextDrawTextSize(playerid, coolTextdraw[playerid][COOL_TEXTDRAW_BOTTOM], 640.0, 640.0);
    PlayerTextDrawAlignment(playerid, coolTextdraw[playerid][COOL_TEXTDRAW_BOTTOM], 2);
    PlayerTextDrawColor(playerid, coolTextdraw[playerid][COOL_TEXTDRAW_BOTTOM], -1);
    PlayerTextDrawUseBox(playerid, coolTextdraw[playerid][COOL_TEXTDRAW_BOTTOM], 1);
    PlayerTextDrawBoxColor(playerid, coolTextdraw[playerid][COOL_TEXTDRAW_BOTTOM], 90);
    PlayerTextDrawSetOutline(playerid, coolTextdraw[playerid][COOL_TEXTDRAW_BOTTOM], 0);
    PlayerTextDrawBackgroundColor(playerid, coolTextdraw[playerid][COOL_TEXTDRAW_BOTTOM], 255);
    PlayerTextDrawFont(playerid, coolTextdraw[playerid][COOL_TEXTDRAW_BOTTOM], 1);
    PlayerTextDrawSetProportional(playerid, coolTextdraw[playerid][COOL_TEXTDRAW_BOTTOM], 1);
    PlayerTextDrawSetShadow(playerid, coolTextdraw[playerid][COOL_TEXTDRAW_BOTTOM], 1);
}

ShowPlayerCoolTextdraw(playerid, text[], type = COOL_TEXTDRAW_BOTTOM, time = COOL_TEXTDRAW_TIME)
{
    // Check player
    if (!IsPlayerConnected(playerid)) {
        return;
    }

    // Update textdraw
    PlayerTextDrawSetString(playerid, coolTextdraw[playerid][type], sprintf("_~n~%s~n~_", text));
    PlayerTextDrawShow(playerid, coolTextdraw[playerid][type]);

    // Reset timer
    KillTimer(coolTextdrawTimer[playerid][type]);
    coolTextdrawTimer[playerid][type] = SetTimerEx("HidePlayerCoolTextdraw", time * 1000, 0, "ii", playerid, type);
}

ShowPlayersCoolTextdraw(text[], type = COOL_TEXTDRAW_BOTTOM, time = COOL_TEXTDRAW_TIME)
{
    for (new i; i < MAX_PLAYERS; i++)
    {
        ShowPlayerCoolTextdraw(i, text, type, time);
    }
}

forward HidePlayerCoolTextdraw(playerid, type);
public  HidePlayerCoolTextdraw(playerid, type)
{
    PlayerTextDrawHide(playerid, coolTextdraw[playerid][type]);
}
