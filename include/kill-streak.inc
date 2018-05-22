/**
* Kill Streak
*
* Player kill streak and double kill handler
* Check OnPlayerKillStreak() OnPlayerDoubleKill() to handle rewards
* Check OnPlayerKillStreakEnded() to announce ending kill streak
* Call CheckPlayerKillStreak() from OnPlayerDeath()
*
* Events: OnPlayerKillStreakEnded(playerid, killerid, killStreak)
*
* by Amir Savand
*/

// Defines

#define TIME_DOUBLE_KILL 5

// Variables

new playerKillStreak[MAX_PLAYERS]; // Used for kill streak

new playerLastKill[MAX_PLAYERS]; // Used for double kill

// Functions

CheckPlayerKillStreak(playerid, killedid)
{
    // Increase kill streak
    playerKillStreak[playerid]++;

    // If more than 3 kills
    if (playerKillStreak[playerid] >= 3)
    {
        // Event
        CallRemoteFunction("OnPlayerKillStreak", "ii", playerid, playerKillStreak);
    }

    // Check for double kill
    if (gettime() - playerLastKill[playerid] <= TIME_DOUBLE_KILL)
    {
        // Event
        CallRemoteFunction("OnPlayerDoubleKill", "i", playerid);

        // Reset so player won't double kill 2 times
        playerLastKill[playerid] = 0;
    }

    // Save last kill time
    playerLastKill[playerid] = gettime();

    // If killed player had a kill streak
    if (playerKillStreak[killedid] >= 3)
    {
        // Event (killedid's kill streak ended by playerid)
        CallRemoteFunction("OnPlayerKillStreakEnded", "iii", killedid, playerid, playerKillStreak[killedid]);
    }

    // Reset killed kill streak
    ResetPlayerKillStreak(killedid);
}

ResetPlayerKillStreak(playerid)
{
    // Set counter to 0
    playerKillStreak[playerid] = 0;
}
