/**
* SG
*
* Savage Gaming gamemode that works with minigame filterscripts.
*
* by Amir Savand
*/

// Defines

#define MAX_RANDOM_PACKAGES                 4
#define MAX_DROP_MONEY                      1000
#define MAX_RANK                            22

#define DROP_MONEY_PICKUPS                  10
#define DROP_MONEY_AMOUNT                   5

#define RANDOM_PACKAGE_CASH                 0
#define RANDOM_PACKAGE_AR                   1
#define RANDOM_PACKAGE_RPG                  2
#define RANDOM_PACKAGE_RANDOM_ITEM          3

#define RANDOM_PACKAGE_AMOUNT_CASH          500
#define RANDOM_PACKAGE_AMOUNT_ARMOR         200
#define RANDOM_PACKAGE_AMOUNT_RPG           4
#define RANDOM_PACKAGE_AMOUNT_RANDOM_ITEM   2

#define KILL_STREAK_MINIGUN                 100
#define KILL_STREAK_MINIGUN_2               150
#define KILL_STREAK_RPG                     20
#define KILL_STREAK_RPG_2                   40
#define KILL_STREAK_MONEY                   3000
#define KILL_STREAK_MONEY_2                 5000

#define KILL_REWARD                         100
#define KILL_REWARD_DOUBLE                  400
#define KILL_REWARD_FIRST_BLOOD             900

#define RANK_COST_FACTOR                    5000 + 10000

#define COOL_TEXTDRAW_TIME                  5

#define TIME_SERVER_UPDATE                  200

#define MODE_FREEROAM                       1
#define MODE_FFA                            2
#define MODE_TDM                            3
#define MODE_CTF                            4

// Includes

#include <a_samp>
#include <streamer>
#include <sscanf>
#include <zcmd>

// Includes

#include "../include/common"

#include "../include/commands"

#include "../include/mapicons"

#include "../include/gang-skins"

#include "../include/rank"

#include "../include/player-label"

#include "../include/engine-textdraw"

#include "../include/speed-textdraw"

#include "../include/title-textdraw"

#include "../include/cool-textdraw"

#include "../include/kill-streak"

#include "../include/drop-money"

// Variables

new firstBloodPlayer = INVALID_PLAYER_ID; // Used to show player reward

// Main

main()
{
    print("\n > Starting Savage Gaming gamemode by Amir Savand.\n");
}

// Callbacks

public OnGameModeInit()
{
    // Game mode functions
    SetGameModeText("Freeroam FFA TDM CTF");
    AllowInteriorWeapons(false);
    EnableStuntBonusForAll(false);
    ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);
    DisableInteriorEnterExits();
    UsePlayerPedAnims();

    // Gang Skins
    AddGangSkins();

    // Gamemode timer
    SetTimer("OnServerUpdate", TIME_SERVER_UPDATE, 1);

    // Title Textdraw
    SetupTitleTextdraw("Savage Gaming");

    // Mapicons
    SetupMapicons(1000.0);
    return 1;
}

public OnPlayerConnect(playerid)
{
    // Announce player is joining
    SendDeathMessage(INVALID_PLAYER_ID, playerid, 200);

    // Initial text draw
    SetupEngineTextdraw(playerid);
    SetupSpeedTextdraw(playerid);
    SetupPlayerCoolTextdraw(playerid);

    // Player label
    SetupPlayerLabel(playerid, "...");

    // Show player recent changes
    cmd_update(playerid);
    return 1;
}

public OnPlayerDisconnect(playerid)
{
    // Announce player is leaving
    SendDeathMessage(INVALID_PLAYER_ID, playerid, 201);
    return 1;
}

public OnPlayerSpawn(playerid)
{
    // Rankup available?
    if (CanPlayerUpgradeRank(playerid))
    {
        // Let player know about it
        new str[200]; str = sprintf("Type /rankup to pay for upgrade to next rank.\n\nUpgrade cost: {00FF00}$%i", GetPlayerNextRankCost(playerid));
        AlertPlayerDialog(playerid, "{00FF00}New Rank Available", str);
    }

    // Fix default -$100
    GivePlayerMoney(playerid, 100);

    // Update player label
    UpdatePlayerLabel(playerid, sprintf("{FF00FF}Rank %i", GetPVarInt(playerid, "rank")));
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    // Send death message (reason)
    SendDeathMessage(killerid, playerid, reason);

    // Killed by a player
    if (killerid != INVALID_PLAYER_ID)
    {
        // Reward and heal killer
        GivePlayerMoney(killerid, KILL_REWARD);
        SetPlayerHealth(killerid, 100);

        // Show killer money if not just drew first blood (handled else where)
        if (firstBloodPlayer != killerid)
            AlertPlayerText(killerid, sprintf("~g~~h~+%i", KILL_REWARD));

        // Reset first blood (used for showing)
        firstBloodPlayer = INVALID_PLAYER_ID;

        // Kill streak handling
        CheckPlayerKillStreak(killerid, playerid);
    }

    // Drop cash
    DropMoneyFromPlayer(playerid);
    return 1;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
    if (!success)
        return AlertPlayerText(playerid, "~r~~h~Command not found");
    return 1;
}

public OnPlayerClickMap(playerid, Float:fX,  Float:fY, Float:fZ)
{
    // Check admin
    if (GetPlayerAdmin(playerid) >= 5)
    {
        // Move player
        if (!IsPlayerInAnyVehicle(playerid))
            SetPlayerPos(playerid, fX, fY, fZ);

        // Move car
        else SetVehiclePos(PVI, fX, fY, fZ);
    }
    return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart)
{
    // Damage from another player
    if (issuerid != INVALID_PLAYER_ID)
    {
        // If not burning
        if (weaponid != WEAPON_FLAMETHROWER)
        {
            // Hit sound (ding)
            PlayerPlaySound(issuerid, 17802, 0, 0, 0);
        }

        // Extra damage multiplier
        new Float:multiplier = 1;

        // Extra damage for each weapon
        switch (weaponid)
        {
            // Assault
            case WEAPON_M4:             multiplier = 1.2;
            case WEAPON_AK47:           multiplier = 1.2;
            case WEAPON_MP5:            multiplier = 1.5;

            // Snipers
            case WEAPON_SNIPER:         multiplier = 1.5;
            case WEAPON_RIFLE:          multiplier = 2;

            // Shotguns
            case WEAPON_SHOTGSPA:       multiplier = 1.5;
            case WEAPON_SHOTGUN:        multiplier = 3;
            
            // Pistols
            case WEAPON_SILENCED:       multiplier = 2;
            case WEAPON_DEAGLE:         multiplier = 1.5;
            
            // Other
            case WEAPON_ROCKETLAUNCHER: multiplier = 1.5;
        }

        // Headshot
        if (bodypart == 9)
        {
            // Double damage
            multiplier = multiplier * 2;
        }

        // Deal extra damage to player
        GivePlayerDamage(playerid, amount * multiplier);
    }
    return 1;
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
    // Pickup cash
    CheckPlayerMoneyDropPickup(playerid, pickupid);
    return 1;
}

// Public functions

forward OnServerUpdate();
public  OnServerUpdate()
{
    // For all players
    for (new i; i < MAX_PLAYERS; i++)
    {
        // Set money as score
        SetPlayerScore(i, GetPlayerMoney(i));

        // Update textdraw
        UpdateEngineTextdraw(i);
        UpdateSpeedTextdraw(i);
    }
}

forward OnPlayerGetItem(playerid, itemName[], amount);
public  OnPlayerGetItem(playerid, itemName[], amount)
{
    // Alert player
    AlertPlayerDialog(playerid, "Info", sprintf("{DDDDFF}You've got an item: {FFFF00}%s {DDDDFF}(x%i)", itemName, amount));
}

forward OnPlayerCollectRandomPackage(playerid);
public  OnPlayerCollectRandomPackage(playerid)
{
    // Get random index from packages
    new package = Ran(0, MAX_RANDOM_PACKAGES);

    // If player has minigun and giving RPG
    if (DoesPlayerHaveWeapon(playerid, WEAPON_MINIGUN) && package == RANDOM_PACKAGE_RPG)
    {
        // Give another package
        OnPlayerCollectRandomPackage(playerid);
        return;
    }

    // Give player random package
    switch(package)
    {
        case RANDOM_PACKAGE_CASH: // Cash
        {
            GivePlayerMoney(playerid, RANDOM_PACKAGE_AMOUNT_CASH);
            AlertPlayerText(playerid, sprintf("~g~~h~+%i", RANDOM_PACKAGE_AMOUNT_CASH));
        }
        case RANDOM_PACKAGE_AR  : // Armor
        {
            SetPlayerArmour(playerid, GetArmour(playerid) + RANDOM_PACKAGE_AMOUNT_ARMOR);
            AlertPlayerText(playerid, sprintf("~b~~h~+%i Amour", RANDOM_PACKAGE_AMOUNT_ARMOR));
        }
        case RANDOM_PACKAGE_RPG: // RPG
        {
            GivePlayerWeapon(playerid, WEAPON_ROCKETLAUNCHER, RANDOM_PACKAGE_AMOUNT_RPG);
            AlertPlayerText(playerid, sprintf("~b~~h~+%i RPG", RANDOM_PACKAGE_AMOUNT_RPG));
        }
        case RANDOM_PACKAGE_RANDOM_ITEM: // Random items
        {
            CallRemoteFunction("GivePlayerRandomItem", "iii", playerid, RANDOM_PACKAGE_AMOUNT_RANDOM_ITEM, RANDOM_PACKAGE_AMOUNT_RANDOM_ITEM);
            AlertPlayerText(playerid, sprintf("~y~+%i Random Items", RANDOM_PACKAGE_AMOUNT_RANDOM_ITEM));
        }
    }

    // Announce
    AlertPlayersText(FPlayerText(playerid, "~w~collected ~y~random pacakge"), playerid);
}

forward OnPlayerPurchaseVehicle(playerid, vehicleid);
public  OnPlayerPurchaseVehicle(playerid, vehicleid)
{
    // Announce
    ShowPlayersCoolTextdraw(FPlayerText(playerid, sprintf("purchased ~y~%s", GetCarName(vehicleid))));
}

forward OnPlayerFirstBlood(playerid);
public  OnPlayerFirstBlood(playerid)
{
    // Reward player and announce (show combined money)
    GivePlayerMoney(playerid, KILL_REWARD_DOUBLE);
    AlertPlayerText(playerid, sprintf("~g~~h~+%i", KILL_REWARD + KILL_REWARD_FIRST_BLOOD));

    // Announce
    ShowPlayersCoolTextdraw(FPlayerText(playerid, "~w~drew ~r~~h~First Blood"));

    // Store it so OnPlayerDeath knows
    firstBloodPlayer = playerid;
}

forward OnPlayerDoubleKill(playerid);
public  OnPlayerDoubleKill(playerid)
{
    // Reward player and announce (show combined money)
    GivePlayerMoney(playerid, KILL_REWARD_DOUBLE);
    AlertPlayerText(playerid, sprintf("~g~~h~+%i", KILL_REWARD + KILL_REWARD_DOUBLE));

    // Alert players
    ShowPlayersCoolTextdraw(FPlayerText(playerid, "performed a ~r~~h~Double Kill!"));
}

forward OnPlayerKillStreak(playerid, streak);
public  OnPlayerKillStreak(playerid, streak)
{
    // Announce string
    new str[200];

    // Reward player on kill streak
    switch (streak)
    {
        case 5: // Minigun
        {
            GivePlayerWeapon(playerid, WEAPON_MINIGUN, KILL_STREAK_MINIGUN);
            AlertPlayerText(playerid, "~b~~h~Minigun");
            str = sprintf("got ~r~~h~Minigun ~w~from %i kill streak.", streak);
        }
        case 10: // Money
        {
            GivePlayerMoney(playerid, KILL_STREAK_MONEY);
            AlertPlayerText(playerid, sprintf("~g~~h~+%i", KILL_STREAK_MONEY));
            str = sprintf("got ~g~~h~$%i ~w~from %i kill streak.", KILL_STREAK_MONEY, streak);
        }
        case 15: // RPG
        {
            GivePlayerWeapon(playerid, WEAPON_ROCKETLAUNCHER, KILL_STREAK_RPG);
            AlertPlayerText(playerid, "~b~~h~RPG");
            str = sprintf("got ~r~~h~RPG ~w~from %i kill streak.", streak);
        }
        case 20: // Minigun (2)
        {
            GivePlayerWeapon(playerid, WEAPON_MINIGUN, KILL_STREAK_MINIGUN_2);
            AlertPlayerText(playerid, "~b~~h~Minigun");
            str = sprintf("got ~r~~h~Minigun ~w~from %i kill streak.", streak);
        }
        case 25: // Money (2)
        {
            GivePlayerMoney(playerid, KILL_STREAK_MONEY_2);
            AlertPlayerText(playerid, sprintf("~g~~h~+%i", KILL_STREAK_MONEY_2));
            str = sprintf("got ~g~~h~$%i ~w~from %i kill streak.", KILL_STREAK_MONEY_2, streak);
        }
        case 30: // RPG (2)
        {
            GivePlayerWeapon(playerid, WEAPON_ROCKETLAUNCHER, KILL_STREAK_RPG_2);
            AlertPlayerText(playerid, "~b~~h~RPG");
            str = sprintf("got ~r~~h~RPG ~w~from %i kill streak.", streak);
        }
    }

    // If got a kill streak
    if (str[0])
    {
        // Announce
        ShowPlayersCoolTextdraw(FPlayerText(playerid, str));
    }
}

forward OnPlayerKillStreakEnded(playerid, killerid, killStreak);
public  OnPlayerKillStreakEnded(playerid, killerid, killStreak)
{
    // 5 kill streak
    if (killStreak >= 5)
    {
        // Announce
        ShowPlayersCoolTextdraw(FPlayerText(killerid, sprintf("ended ~g~~h~%s's ~r~~h~%ix kill streak", GetName(playerid), killStreak)));
    }
}

forward OnPlayerAttemptToUseItem(playerid, item, itemName[]);
public  OnPlayerAttemptToUseItem(playerid, item, itemName[])
{
    // Using items that required you to be in a car
    if (isequal(itemName, "Car Tools") || isequal(itemName, "Nitros"))
    {
        // Can't repair car if not in a car
        if (!IsPlayerInAnyVehicle(playerid))
        {
            // Alert
            AlertPlayerDialog(playerid, "Info", "You need to be in a vehicle to use this item.");
            return 0;
        }
    }

    // Allow usage
    return 1;
}

forward OnPlayerRankUp(playerid, rank, cost);
public  OnPlayerRankUp(playerid, rank, cost)
{
    // Announce
    ShowPlayersCoolTextdraw(FPlayerText(playerid, sprintf("~w~is now ~p~Rank %i", rank)));
}

forward OnPlayerLeaveBattleZone(playerid, Float:distance, Float:safedistance, Float:center[3]);
public  OnPlayerLeaveBattleZone(playerid, Float:distance, Float:safedistance, Float:center[3])
{
    // Don't effect when player...
    if (IsPlayerSkydiving(playerid) || IsPlayerParachuting(playerid) || !IsPlayerSpawned(playerid)) {
        return;
    }

    // Create exposion and alert player
    IMPORT_PLAYER_POS;
    CreateExplosion(pPos[0] + 1, pPos[1] + 1, pPos[2] + 1, 0, 3.0);
    ShowPlayerCoolTextdraw(playerid, "Get back in the ~r~~h~Battle Zone!");
}

forward OnPlayerCaptureFlag(playerid);
public  OnPlayerCaptureFlag(playerid)
{
    // Announce
    ShowPlayersCoolTextdraw(FPlayerText(playerid, "~w~captured the ~r~~h~Flag"));
}

forward OnPlayerDropFlag(playerid, killerid);
public  OnPlayerDropFlag(playerid, killerid)
{
    // Announce
    ShowPlayersCoolTextdraw(FPlayerText(playerid, "~w~dropped the ~r~~h~Flag"));
}

forward OnPlayerReturnFlag(playerid, reward);
public  OnPlayerReturnFlag(playerid, reward)
{
    // Announce
    ShowPlayersCoolTextdraw(FPlayerText(playerid, "~w~returned the ~r~~h~Flag"));
    AlertPlayerText(playerid, sprintf("~g~~h~+%i", reward));
    PlayerPlaySound(playerid, 50004, 0, 0, 0);
}

// Commands

CMD:rankup(playerid)
{
    // Upgrade to next rank
    UpgradePlayerRank(playerid);
    return 1;
}

CMD:mode(playerid, params[])
{
    // Check admin
    if (GetPlayerAdmin(playerid) < 5)
        return 0;

    // Check params
    new mode;
    if (sscanf(params, "i", mode) || mode < MODE_FREEROAM || mode > MODE_CTF)
        return AlertPlayerDialog(playerid, "Command Usage", "/mode [1-4]\n(Freeroam, FFA, TDM, CTF)");

    // Unload modes
    SendRconCommand("unloadfs modes/freeroam");
    SendRconCommand("unloadfs modes/tdm");
    SendRconCommand("unloadfs modes/ffa");
    SendRconCommand("unloadfs modes/ctf");

    // Load mode
    switch (mode)
    {
        case MODE_FREEROAM: SendRconCommand("loadfs modes/freeroam");
        case MODE_FFA:      SendRconCommand("loadfs modes/ffa");
        case MODE_TDM:      SendRconCommand("loadfs modes/tdm");
        case MODE_CTF:      SendRconCommand("loadfs modes/ctf");
    }

    // For all players
    for (new i; i < MAX_PLAYERS; i++)
    {
        // Kill em
        SetPlayerHealth(i, 0);

        // Force selection
        ForceClassSelection(i);
    }
    return 1;
}

CMD:updates(playerid) return cmd_update(playerid);
CMD:update(playerid)
{
    new str[1000];

    strcat(str, "Ranks now cost 50 percent less ($5,000 for each rank)\n");
    strcat(str, "Sell items by typing /sellitem\n");
    strcat(str, "Added speed indicator (km/h)\n");
    strcat(str, "Added mapicons of Pay n' Sprays and Mod Shops\n");
    strcat(str, "Added new perk: Armor Regeneration\n");
    strcat(str, "First blood now gives $1,000\n");
    strcat(str, "Double kill now gives $500\n");
    strcat(str, "Changed ranks: RPG, HS Rocket, More engine\n");
    strcat(str, "See command and shortcut list by typing /cmd /key\n");
    strcat(str, "See recent updates again by typing /update\n");
    
    AlertPlayerDialog(playerid, "{00FF00}Recent Changes (5-25)", str);
    return 1;
}

CMD:key(playerid) return cmd_keys(playerid);
CMD:keys(playerid)
{
    new keys[1000];

    strcat(keys, "Y -> /items\n");
    strcat(keys, "N -> Not set yet.\n");
    strcat(keys, "H -> Not set yet.\n");

    AlertPlayerDialog(playerid, "Keys", keys);
    return 1;
}

CMD:cmd(playerid) return cmd_cmds(playerid);
CMD:cmds(playerid)
{
    new cmds[1000];

    strcat(cmds, "{00FF00}.:: Global ::.\n\n");
    strcat(cmds, "{DDDDEE}/class /perks /rankup /items /keys /killme /money /updates\n\n");

    strcat(cmds, "{00FF00}.:: Items ::.\n\n");
    strcat(cmds, "{DDDDEE}/items /giveitem /sellitem\n\n");

    AlertPlayerDialog(playerid, "Comamnds", cmds);
    return 1;
}

CMD:acmd(playerid) return cmd_acmds(playerid);
CMD:acmds(playerid)
{
    // Check admin
    if (!GetPlayerAdmin(playerid))
        return 0;

    new cmds[1000];

    strcat(cmds, "{00FF00}.:: Global ::.\n\n");
    strcat(cmds, "{DDDDEE}/clear /jetpack /telto /givemoney /giveguns /setname /setskin\n\n");

    strcat(cmds, "{00FF00}.:: Cars ::.\n\n");
    strcat(cmds, "{DDDDEE}/scar /addcar /delcar /updatecar /setcartype /setcarprice /setcarengine /setcarpos /setcarowner /resetcarowner /blow\n\n");

    strcat(cmds, "{00FF00}.:: Items ::.\n\n");
    strcat(cmds, "{DDDDEE}/giveitem");

    AlertPlayerDialog(playerid, "Admin Comamnds", cmds);
    return 1;
}
