/**
* Commands
*
* Player commands that work for most gamemodes, admin commands included.
*
* by Amir Savand
*/

// Player commands

CMD:pm(playerid, params[])
{
    new str[200], mStr[500], targetid;

    if (!sscanf(params, "us[144]", targetid, str))
        return AlertPlayerError(playerid, "> Command usage: /pm [player] [message]");

    if (!IsPlayerConnected(targetid) || targetid == playerid)
        return AlertPlayerError(playerid, "> Player not found");

    // Announce sender
    format(mStr, sizeof(mStr), "> PM to %s: {FFFFFF}%s", GetName(targetid), str);
    AlertPlayerSuccess(playerid, mStr);

    // Announce reciever
    format(mStr, sizeof(mStr), "> PM from %s (%i): {FFFFFF}%s", GetName(playerid), playerid, str);
    AlertPlayerSuccess(targetid, mStr);
    return 1;
}

CMD:money(playerid, params[])
{
    new str[200], targetid, amount;

    if (sscanf(params, "ui", targetid, amount))
        return AlertPlayerError(playerid, "> Command usage: /money [player] [amount]");

    if (!IsPlayerConnected(targetid) || targetid == playerid)
        return AlertPlayerError(playerid, "> Player not found");

    if (amount < 1 || amount > GetPlayerMoney(playerid) || GetPlayerMoney(playerid) < 1)
        return AlertPlayerError(playerid, "> You don't have that much money");

    // Announce sender
    format(str, sizeof(str), "> You sent $%i to %s", amount, GetName(targetid));
    AlertPlayerSuccess(playerid, str);
    GivePlayerMoney(playerid, -amount);

    // Announce reciever
    format(str, sizeof(str), "> %s (%i) sent you $%i", GetName(playerid), playerid, amount);
    AlertPlayerSuccess(targetid, str);
    GivePlayerMoney(targetid, amount);
    return 1;
}

CMD:killme(playerid)
{
    // Don't kill if dead
    if (GetPlayerState(playerid) == PLAYER_STATE_WASTED) return 0;

    // Kill player
    SetPlayerHealth(playerid, 0);
    SetPlayerArmour(playerid, 0);
    return 1;
}

// Admin commands

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

CMD:addmoney(playerid, params[]) // Add money (from server)
{
    // Check admin
    if (GetPlayerAdmin(playerid) < 5)
        return 0;

    // Check params
    new targetid, amount;
    if (sscanf(params, "ui", targetid, amount))
        return AlertPlayerError(playerid, "> Command usage: /addmoney [player] [amount]");

    // Add money to target
    GivePlayerMoney(targetid, amount);

    // Alert sender and reciever
    AlertPlayers(FPlayer(targetid, sprintf("recieved {00FF00}$%i {DDDDDD}from server.", amount)));
    return 1;
}

CMD:setname(playerid, params[]) // Set player name
{
    // Check admin
    if (GetPlayerAdmin(playerid) < 5)
        return 0;

    // Check params
    new targetid, name[MAX_PLAYER_NAME];
    if (sscanf(params, "us", targetid, name))
        return AlertPlayerError(playerid, "> Command usage: /setname [player] [name]");

    // Announce
    AlertPlayers(FPlayer(targetid, sprintf("name changed to {00FF00}%s", name)));

    // Change target name
    SetPlayerName(targetid, name);

    // Event
    CallRemoteFunction("OnPlayerChangeName", "i", playerid);
    return 1;
}
