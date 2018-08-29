/**
* First Blood
*
* Check for first blood.
*
* Events: OnPlayerFirstBlood(playerid, killedid)
*
* by Amir Savand
*/


// Variables

new firstBlood = INVALID_PLAYER_ID;

// Functions

CheckFirstBlood(playerid, killedid)
{
    // Check for first blood and player
    if (firstBlood == INVALID_PLAYER_ID && IsPlayerConnected(playerid))
    {
        // Set first blood
        firstBlood = playerid;

        // Event
        CallRemoteFunction("OnPlayerFirstBlood", "ii", playerid, killedid);
    }
}
