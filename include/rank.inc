/**
* Rank
*
* Purchase and upgrade to next rank for players.
* Requires ranks[]
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

    new rank = GetPVarInt(playerid, "rank");

    // Upgrade player rank
    SetPVarInt(playerid, "rank", rank + 1);

    // Get money
    GivePlayerMoney(playerid, -ranks[rank + 1]);

    // Announce
    new str[200]; format(str, sizeof(str), "> {00FF00}%s {DDDDDD}is now {FF00FF}rank %i", GetName(playerid), rank + 1);
    AlertPlayers(str);
    return 1;
}