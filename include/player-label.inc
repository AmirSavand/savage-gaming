/**
* Player Label
*
* Show a 3D text label above player and manage it easily.
*
* by Amir Savand
*/

// Variables

new Text3D:playerLabel[MAX_PLAYERS];

// Functions

SetupPlayerLabel(playerid, text[])
{
    // Create and attach 3D text
    playerLabel[playerid] = CreateDynamic3DTextLabel(text, cGrey, 0, 0, 0.5, 60, playerid, INVALID_VEHICLE_ID, 1);
}

UpdatePlayerLabel(playerid, text[])
{
    // Update the text
    UpdateDynamic3DTextLabelText(playerLabel[playerid], cGrey, text);
}
