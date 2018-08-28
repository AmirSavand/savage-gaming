/**
* Rank
*
* Purchase and upgrade to next rank for players.
*
* Events: OnPlayerRankUp(playerid, rank, cost)
* Requires: RANK_COST_FACTOR (10000), MAX_RANK (20)
*
* by Amir Savand
*/

// Functions

GetPlayerNextRankCost(playerid)
{
    return (1 + GetPVarInt(playerid, "rank")) * RANK_COST_FACTOR;
}

bool:IsPlayerAtMaxRank(playerid)
{
    return GetPVarInt(playerid, "rank") >= MAX_RANK;
}

bool:CanPlayerUpgradeRank(playerid)
{
    // Check max rank
    if (IsPlayerAtMaxRank(playerid))
        return false;

    // Check money
    if (!HasEnoughMoney(playerid, GetPlayerNextRankCost(playerid)))
        return false;

    // Good to upgrade
    return true;
}

UpgradePlayerRank(playerid)
{
    // Can upgrade?
    if (!CanPlayerUpgradeRank(playerid))
    {
        // Not enough money
        if (!HasEnoughMoney(playerid, GetPlayerNextRankCost(playerid)))
            return AlertPlayerText(playerid, "~r~~h~not enough money");

        // At max rank
        return AlertPlayerDialog(playerid, "Info", "You're at max rank!");
    }

    // Get rank and cost of next rank
    new rank = GetPVarInt(playerid, "rank");
    new cost = GetPlayerNextRankCost(playerid);

    // Upgrade player rank
    SetPVarInt(playerid, "rank", rank + 1);

    // Make payment
    GivePlayerMoney(playerid, -cost);

    // Event
    CallRemoteFunction("OnPlayerRankUp", "iii", playerid, rank + 1, cost);
    return 1;
}
