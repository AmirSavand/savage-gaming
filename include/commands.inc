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
    new str[200], mStr[500], target;

    if (!sscanf(params, "us[144]", target, str))
        return AlertPlayerDialog(playerid, "Command Usage", "/pm [player] [message]");

    if (!IsPlayerConnected(target) || target == playerid)
        return AlertPlayerText(playerid, "~r~~h~Player not found");

    // Announce sender
    format(mStr, sizeof(mStr), "> PM to %s: {FFFFFF}%s", GetName(target), str);
    AlertPlayerSuccess(playerid, mStr);

    // Announce reciever
    format(mStr, sizeof(mStr), "> PM from %s (%i): {FFFFFF}%s", GetName(playerid), playerid, str);
    AlertPlayerSuccess(target, mStr);
    return 1;
}

CMD:money(playerid, params[])
{
    new target, amount;

    if (sscanf(params, "ui", target, amount))
        return AlertPlayerDialog(playerid, "Command Usage", "/money [player] [amount]");

    if (!IsPlayerConnected(target) || target == playerid)
        return AlertPlayerText(playerid, "Player not found");

    if (amount < 1 || amount > GetPlayerMoney(playerid) || GetPlayerMoney(playerid) < 1)
        return AlertPlayerText(playerid, "~r~~h~You don't have that much money");

    // Announce sender
    AlertPlayerDialog(playerid, "Info", sprintf("{DDDDFF}Sent {00FF00}$%i {DDDDFF}to {00FF00}%s", amount, GetName(target)));
    GivePlayerMoney(playerid, -amount);

    // Announce reciever
    AlertPlayerDialog(playerid, "Info", sprintf("{DDDDFF}Recieved {00FF00}$%i {DDDDFF}from {00FF00}%s", amount, GetName(playerid)));
    GivePlayerMoney(target, amount);
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
    new target;
    if (sscanf(params, "u", target))
        return AlertPlayerDialog(playerid, "Command Usage", "/telto [player]");

    // Check player
    if (!IsPlayerConnected(target))
        return AlertPlayerText(playerid, "~r~~h~Player is not connected");

    // Teleport player
    IMPORT_PLAYER_POS_AS_TARGET;
    SetPlayerPos(playerid, tPos[0]+1, tPos[1]+1, tPos[2]+2);
    SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(target));
    SetPlayerInterior(playerid, GetPlayerInterior(target));
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
        return AlertPlayerDialog(playerid, "Command Usage", "/getmoney [amount]");

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
    new target, amount;
    if (sscanf(params, "ui", target, amount))
        return AlertPlayerDialog(playerid, "Command Usage", "/addmoney [player] [amount]");

    // Add money to target
    GivePlayerMoney(target, amount);

    // Announce
    AlertPlayersDialog("Info", FPlayer(target, sprintf("recieved {00FF00}$%i {DDDDFF}from server.", amount), ""));
    return 1;
}

CMD:setname(playerid, params[]) // Set player name
{
    // Check admin
    if (GetPlayerAdmin(playerid) < 5)
        return 0;

    // Check params
    new target, name[MAX_PLAYER_NAME];
    if (sscanf(params, "us", target, name))
        return AlertPlayerDialog(playerid, "Command Usage", "/setname [player] [name]");

    // Announce
    AlertPlayers(FPlayer(target, sprintf("name changed to {00FF00}%s", name)));

    // Change target name
    SetPlayerName(target, name);

    // Event
    CallRemoteFunction("OnPlayerChangeName", "is", target, name);
    return 1;
}
