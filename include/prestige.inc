/**
* Prestige
*
* Upgrade prestige level if at max rank.
*
* Events: OnPlayerPrestige(playerid, prestige)
* Requires: rank.inc, MAX_PRESTIGE (5)
*
* by Amir Savand
*/

// Functions

bool:IsPlayerAtMaxPrestige(playerid)
{
    return GetPVarInt(playerid, "prestige") >= MAX_PRESTIGE;
}

bool:CanPlayerUpgradePrestige(playerid)
{
    // Check max prestige
    if (IsPlayerAtMaxPrestige(playerid))
        return false;

    // Check max rank
    if (!IsPlayerAtMaxRank(playerid))
        return false;

    // Good to upgrade
    return true;
}

UpgradePlayerPrestige(playerid)
{
    // Can upgrade?
    if (!CanPlayerUpgradePrestige(playerid))
    {
        // At max prestige
        if (IsPlayerAtMaxPrestige(playerid))
            return AlertPlayerDialog(playerid, "Info", "You are at max prestige level!");

        // Not at max rank
        return AlertPlayerDialog(playerid, "Info", "You must be at max rank!");
    }

    // Reset rank to 0
    SetPVarInt(playerid, "rank", 0);
    
    // Upgrade to next prestige
    SetPVarInt(playerid, "prestige", GetPVarInt(playerid, "prestige") + 1);

    // Event
    CallRemoteFunction("OnPlayerPrestige", "ii", playerid, GetPVarInt(playerid, "prestige"));
    return 1;
}

GetPlayerPrestige(playerid)
{
    return GetPVarInt(playerid, "prestige");
}
