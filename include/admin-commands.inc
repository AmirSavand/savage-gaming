/**
* Admin Commands
*
* by Amir Savand
*/

CMD:clear(playerid) // Clear chat section
{
    if (!GetPlayerAdmin(playerid))
        return 0;

    for (new i = 0; i < 20; i++)
        SendClientMessageToAll(1, " ");

    return 1;
}

CMD:jetpack(playerid) // Get Jetpack
{
    // Check admin
    if (!GetPlayerAdmin(playerid))
        return 0;

    // Give jetpack
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
    return 1;
}

CMD:telto(playerid, params[]) // Teleport to a player
{
    // Check admin
    if (!GetPlayerAdmin(playerid))
        return 0;

    // Check params
    new targetid;
    if (sscanf(params, "u", targetid))
        return AlertPlayerError(playerid, "> Command usage: /telto [player]");

    // Check player
    if (!IsPlayerConnected(targetid))
        return AlertPlayerText(playerid, "~r~~h~Player is not connected");

    // Teleport player
    IMPORT_PLAYER_POS_AS_TARGET;
    SetPlayerPos(playerid, tPos[0]+1, tPos[1]+1, tPos[2]+2);
    SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));
    SetPlayerInterior(playerid, GetPlayerInterior(targetid));
    return 1;
}

CMD:giveguns(playerid) // Give guns to a player
{
    // Check admin
    if (GetPlayerAdmin(playerid) < 5)
        return 0;

    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        GivePlayerWeapon(i, WEAPON_UZI, 500);
        GivePlayerWeapon(i, WEAPON_AK47, 150);
    }

    return 1;
}

CMD:getmoney(playerid, params[]) // Get money
{
    // Check admin
    if (!GetPlayerAdmin(playerid))
        return 0;

    // Check params
    new amount;
    if (sscanf(params, "i", amount))
        return AlertPlayerError(playerid, "> Command usage: /getmoney [amount]");

    // Give money
    GivePlayerMoney(playerid, amount);
    return 1;
}
