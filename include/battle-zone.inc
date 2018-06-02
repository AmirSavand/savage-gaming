/**
* Battle zone
*
* Check if player is out of battle zone and report.
* Check OnPlayerLeaveBattleZone(playerid, Float:distance, Float:safedistance, Float:center[3]).
*
* Requires: BATTLE_ZONE_CENTER {0.0, 0.0, 0.0}, BATTLE_ZONE_DISTANCE 200.0
*
* by Amir Savand
*/

// Functions

forward CheckPlayerBattleZoneDistance();
public  CheckPlayerBattleZoneDistance()
{
    // Safe distance and center
    new Float:center[3] = BATTLE_ZONE_CENTER;
    new Float:safedistance = BATTLE_ZONE_DISTANCE;

    // Check all players
    for (new i; i < MAX_PLAYERS; i++)
    {
        // Check connected
        if (!IsPlayerConnected(i))
            continue;

        // Get distance
        new Float:distance = GetPlayerDistanceFromPoint(i, center[0], center[1], center[2]);

        // Check distance
        if (distance > safedistance)
        {
            // Call remote
            CallRemoteFunction("OnPlayerLeaveBattleZone", "ifff", i, distance, safedistance, center);
        }
    }
}
