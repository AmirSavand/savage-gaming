/**
* SG
*
* Savage Gaming gamemode that works with minigame filterscripts.
*
* by Amir Savand
*/

// Defines

#define MAX_RANDOM_PACKAGES         4
#define MAX_DROP_MONEY              1000
#define MAX_RANK                    22

#define DROP_MONEY_PICKUPS          10
#define DROP_MONEY_AMOUNT           5

#define RANDOM_PACKAGE_CASH         0
#define RANDOM_PACKAGE_AR           1
#define RANDOM_PACKAGE_RPG          2
#define RANDOM_PACKAGE_RANDOM_ITEM  3

#define KILL_STREAK_MINIGUN         100
#define KILL_STREAK_RPG             20
#define KILL_STREAK_GRENADE         40
#define KILL_STREAK_MONEY           1000
#define KILL_STREAK_MONEY_2         2000

#define KILL_REWARD                 100
#define KILL_REWARD_DOUBLE          300
#define KILL_REWARD_FIRST_BLOOD     300

#define RANK_COST_FACTOR            10000

#define COOL_TEXTDRAW_TIME          5

#define TIME_SERVER_UPDATE          500

#define MODE_FREEROAM               1
#define MODE_FFA                    2
#define MODE_TDM                    3
#define MODE_CTF                    4

// Includes

#include <a_samp>
#include <streamer>
#include <sscanf>
#include <zcmd>

// Includes

#include "../include/common"

#include "../include/commands"

#include "../include/gang-skins"

#include "../include/rank"

#include "../include/player-label"

#include "../include/engine-textdraw"

#include "../include/title-textdraw"

#include "../include/cool-textdraw"

#include "../include/kill-streak"

#include "../include/drop-money"

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
    return 1;
}

public OnPlayerConnect(playerid)
{
    // Announce player is joining
    SendDeathMessage(INVALID_PLAYER_ID, playerid, 200);

    // Initial text draw
    SetupEngineTextdraw(playerid);
    SetupPlayerCoolTextdraw(playerid);

    // Player label
    SetupPlayerLabel(playerid, "...");
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
        new str[500];
        format(str, sizeof(str), "Type /rankup to pay for upgrade to next rank.\n\nUpgrade cost: {00FF00}$%i", GetPlayerNextRankCost(playerid));
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
        AlertPlayerText(killerid, sprintf("~g~~h~+%i", KILL_REWARD));
        GivePlayerMoney(killerid, KILL_REWARD);
        SetPlayerHealth(killerid, 100);

        // Kill streak handling
        CheckPlayerKillStreak(killerid, playerid);
    }

    // Sucide
    else ResetPlayerKillStreak(playerid);

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
    }
}

forward OnPlayerPickupRandomPackage(playerid);
public  OnPlayerPickupRandomPackage(playerid)
{
    // Get random index from packages
    new package = Ran(0, MAX_RANDOM_PACKAGES);

    // If player has minigun and giving RPG
    if (DoesPlayerHaveWeapon(playerid, WEAPON_MINIGUN) && package == RANDOM_PACKAGE_RPG)
    {
        // Give another package
        OnPlayerPickupRandomPackage(playerid);
        return;
    }

    // Give player random package
    switch(package)
    {
        case RANDOM_PACKAGE_CASH: // Cash
        {
            GivePlayerMoney(playerid, 600);
            AlertPlayerText(playerid, "~g~~h~+600");
        }
        case RANDOM_PACKAGE_AR  : // Armor
        {
            SetPlayerArmour(playerid, 200);
            AlertPlayerText(playerid, "~b~~h~+200 Armour");
        }
        case RANDOM_PACKAGE_RPG: // RPG
        {
            GivePlayerWeapon(playerid, WEAPON_ROCKETLAUNCHER, 3);
            AlertPlayerText(playerid, "~b~~h~3 RPG");
        }
        case RANDOM_PACKAGE_RANDOM_ITEM: // Random item
        {
            CallRemoteFunction("GivePlayerRandomItem", "i", playerid);
            AlertPlayerText(playerid, "~b~~h~Random Item");
        }
    }

    // Announce
    AlertPlayersText(FPlayerText(playerid, "~w~collected ~y~~h~random pacakge"));
}

forward OnPlayerPurchaseVehicle(playerid, vehicleid);
public  OnPlayerPurchaseVehicle(playerid, vehicleid)
{
    // Announce
    ShowPlayersCoolTextdraw(FPlayerText(playerid, sprintf("purchased ~y~%s", GetCarName(vehicleid))));
}

forward OnPlayerKillStreak(playerid, killStreak);
public  OnPlayerKillStreak(playerid, killStreak)
{
    // Announce string
    new str[200];

    // Reward player on kill streak
    switch (killStreak)
    {
        case 5: // Minigun
        {
            GivePlayerWeapon(playerid, WEAPON_MINIGUN, KILL_STREAK_MINIGUN);
            AlertPlayerText(playerid, "~b~~h~Minigun");
            str = "got ~r~~h~Minigun ~w~from 5 kill streak.";
        }
        case 10: // Money
        {
            GivePlayerMoney(playerid, KILL_STREAK_MONEY);
            AlertPlayerText(playerid, sprintf("~g~~h~+%i", KILL_STREAK_MONEY));
            str = "got {00FF00}$1000 ~w~from 10 kill streak.";
        }
        case 15: // Grenade
        {
            GivePlayerWeapon(playerid, WEAPON_GRENADE, KILL_STREAK_GRENADE);
            AlertPlayerText(playerid, "~b~~h~RPG");
            str = "got many ~r~~h~Grenades ~w~from 15 kill streak.";
        }
        case 20: // Jetpack
        {
            SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
            AlertPlayerText(playerid, "~b~~h~JETPACK");
            str = "got ~r~~h~Jetpack ~w~from 20 kill streak.";
        }
        case 25: // RPG
        {
            GivePlayerWeapon(playerid, WEAPON_ROCKETLAUNCHER, KILL_STREAK_RPG);
            AlertPlayerText(playerid, "~b~~h~RPG");
            str = "got ~r~~h~RPG ~w~from 25 kill streak.";
        }
        case 30: // Money (2)
        {
            GivePlayerMoney(playerid, KILL_STREAK_MONEY_2);
            AlertPlayerText(playerid, sprintf("~g~~h~+%i", KILL_STREAK_MONEY_2));
            str = "got {00FF00}$2000 ~w~from 30 kill streak.";
        }
    }

    // If got a kill streak
    if (str[0])
    {
        // Announce
        ShowPlayersCoolTextdraw(FPlayerText(playerid, str));
    }
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
    if (isequal(itemName, "Car Tools"))
    {
        // Can't repair car if not in a car
        if (!IsPlayerInAnyVehicle(playerid))
        {
            // Alert
            AlertPlayerText(playerid, "~r~~h~Not in vehicle");
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
    AlertPlayerDialog(playerid, "Alert", "Get back in the battle zone!");
}

forward OnPlayerFirstBlood(playerid);
public  OnPlayerFirstBlood(playerid)
{
    // Reward player and announce (show combined money)
    GivePlayerMoney(playerid, KILL_REWARD_DOUBLE);
    AlertPlayerText(playerid, sprintf("~g~~h~+%i", KILL_REWARD + KILL_REWARD_FIRST_BLOOD));

    // Announce
    ShowPlayersCoolTextdraw(FPlayerText(playerid, "~w~drew ~r~~h~First Blood"));
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
    if (sscanf(params, "i", mode))
        return AlertPlayerError(playerid, "> Command usage: /mode [1-4]");

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
