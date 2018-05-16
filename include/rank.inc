/**
* Rank
*
* Purchase and upgrade to next rank for players.
* Requires ranks[] (money per rank starting with 0)
*
* by Amir Savand
*/

// Functions

CanPlayerUpgradeRank(playerid)
{
    // Next rank to upgrade
    new nextRank = GetPVarInt(playerid, "rank") + 1;

    // Is there a next rank?
    if (nextRank >= sizeof(ranks))
        return -1;

    // Money required for next rank
    new nextRankMoney = ranks[nextRank];

    // Has enough money
    return HasEnoughMoney(playerid, nextRankMoney);
}

UpgradePlayerRank(playerid)
{
    // Can upgrade
    if (!CanPlayerUpgradeRank(playerid))
    {
        // If not enough money, alert
        if (CanPlayerUpgradeRank(playerid) != -1)
            AlertPlayerText(playerid, "~r~~h~not enough money");

        // Stop upgrading
        else AlertPlayerText(playerid, "~r~~h~upgrade not available");
        return 0;
    }

    // Get rank
    new rank = GetPVarInt(playerid, "rank");

    // Upgrade player rank
    SetPVarInt(playerid, "rank", rank + 1);

    // Get money
    GivePlayerMoney(playerid, -ranks[rank + 1]);

    // Event
    CallRemoteFunction("OnPlayerRankUp", "iii", playerid, rank + 1, -ranks[rank + 1]);    
    return 1;
}