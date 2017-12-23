/**
* Player Commands
*
* by Amir Savand
*/

CMD:pm(playerid, params[])
{
    new str[200], mStr[500], targetid;

    if (!sscanf(params, "us[144]", targetid, str))
        return AlertPlayerError(playerid, "> Command usage: /pm [player] [message]");

    if (!IsPlayerConnected(targetid) || targetid == playerid)
        return AlertPlayerError(playerid, "> Player not found");

    // Announce sender
    format(mStr, sizeof(mStr), "> Sent to %s: {FFFFFF}%s", GetName(targetid), str);
    AlertPlayerSuccess(playerid, mStr);

    // Announce reciever
    format(mStr, sizeof(mStr), "> PM recieved from %s (%i): {FFFFFF}%s", GetName(playerid), playerid, str);
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
    return 1;
}