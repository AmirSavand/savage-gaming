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

CanPlayerUpgradeRank(playerid)
{
    // Next rank to upgrade
    new nextRank = GetPVarInt(playerid, "rank") + 1;

    // Is there a next rank?
    if (nextRank >= MAX_RANK)
        return -1;

    // Has enough money for next rank?
    return HasEnoughMoney(playerid, GetPlayerNextRankCost(playerid));
}

UpgradePlayerRank(playerid)
{
    // Can upgrade?
    if (!CanPlayerUpgradeRank(playerid))
    {
        // If not enough money, alert
        if (CanPlayerUpgradeRank(playerid) != -1)
            AlertPlayerText(playerid, "~r~~h~not enough money");

        // Stop upgrading
        else AlertPlayerText(playerid, "~r~~h~upgrade not available");
    }

    // Upgrade
    else
    {
        // Get rank and cost of next rank
        new rank = GetPVarInt(playerid, "rank");
        new cost = GetPlayerNextRankCost(playerid);

        // Upgrade player rank
        SetPVarInt(playerid, "rank", rank + 1);

        // Make payment
        GivePlayerMoney(playerid, -cost);

        // Event
        CallRemoteFunction("OnPlayerRankUp", "iii", playerid, rank + 1, cost);
    }
}