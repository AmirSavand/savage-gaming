/**
* Kill Streak
*
* Player kill streak handler.
* Kill streak is called on each kill streaks (5, 10, 15, ...)
* Requires: playerKillStreak[MAX_PLAYERS]
*           CheckPlayerKillStreak() from OnPlayerDeath()
*
* by Amir Savand
*/

// Functions

ResetPlayerKillStreak(playerid)
{
    playerKillStreak[playerid] = 0;
}

CheckPlayerKillStreak(playerid)
{
    // Increase kill streak
    playerKillStreak[playerid]++;

    // If more than 3 kills
    if (playerKillStreak[playerid] >= 3)
    {
        // Trigger event
        CallRemoteFunction("OnPlayerKillStreak", "ii", playerid, playerKillStreak);
    }
}
