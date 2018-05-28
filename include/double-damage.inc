/**
* Double Damage
*
* Double damage for player for a duration.
*
* Requirements: DOUBLE_DAMAGE_DURATION (10000)
*
* by Amir Savand
*/

// Variables

new bool:playerDoubleDamage[MAX_PLAYERS];
new playerDoubleDamageTimer[MAX_PLAYERS];

// Functions

SetPlayerDoubleDamage(playerid, duration = DOUBLE_DAMAGE_DURATION)
{
    playerDoubleDamage[playerid] = true;
    KillTimer(playerDoubleDamageTimer[playerid]);
    playerDoubleDamageTimer[playerid] = SetTimerEx("ResetPlayerDoubleDamage", duration, 1, "i", playerid);
}

stock ResetPlayersDoubleDamage()
{
    for (new i; i < MAX_PLAYERS; i++)
    {
        ResetPlayerDoubleDamage(i);
    }
}

bool:IsPlayerDoubleDamage(playerid)
{
    return playerDoubleDamage[playerid];
}

forward ResetPlayerDoubleDamage(playerid);
public  ResetPlayerDoubleDamage(playerid)
{
    playerDoubleDamage[playerid] = false;
    KillTimer(playerDoubleDamageTimer[playerid]);
}
