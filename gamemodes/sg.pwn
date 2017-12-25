/**
* SG
*
* Savage Gaming gamemode that works with minigame filterscripts
*
* by Amir Savand
*/

// Defines

#define MAX_RANDOM_PACKAGES         4

#define RANDOM_PACKAGE_CASH         0
#define RANDOM_PACKAGE_HP_AR        1
#define RANDOM_PACKAGE_RPG          2
#define RANDOM_PACKAGE_RANDOM_ITEM  3

#define KILL_STREAK_MINIGUN         150
#define KILL_STREAK_MONEY           1000
#define KILL_STREAK_RPG             20
#define KILL_STREAK_GRENADE         40

#define TIME_DOUBLE_KILL            5
#define TIME_SERVER_UPDATE          500

#define MODE_FFA                    1
#define MODE_TDM                    2

// Includes

#include <a_samp>
#include <streamer>
#include <sscanf>
#include <zcmd>

#include "../include/common"

// Variables

new Text:titleTextdrawText;
new titleTextDraw[50] = "Savage Gaming";

new PlayerText:engineTextdraw[MAX_PLAYERS][2];

new playerKillStreak[MAX_PLAYERS]; // Used for kill streak rewards
new playerLastKill[MAX_PLAYERS]; // Used for double kill reward

new ranks[] = { // Money per rank upgrade
         0,
     10000,  15000,  18000,  22000,
     25000,  28000,  30000,  35000,
     40000,  42000,  45000,  48000,
     50000,  60000,  70000,  80000,
     90000, 100000, 120000, 150000,
    180000, 200000, 250000, 300000
};

// Main

main()
{
    print("\n > Starting Savage Gaming gamemode by Amir Savand.\n");
}

// Callbacks

public OnGameModeInit()
{
    // Game mode functions
    SetGameModeText("FFA TDM");
    AllowInteriorWeapons(false);
    EnableStuntBonusForAll(false);
    ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);
    DisableInteriorEnterExits();
    UsePlayerPedAnims();

    // Gamemode timer
    SetTimer("OnServerUpdate", TIME_SERVER_UPDATE, 1);

    // Gang Skins
    #include "../include/gang-skins"

    // Title Textdraw
    #include "../include/title-textdraw"
    return 1;
}

public OnPlayerConnect(playerid)
{
    // Announce player is joining
    SendDeathMessage(INVALID_PLAYER_ID, playerid, 200);

    // Show text title
    TextDrawShowForPlayer(playerid, titleTextdrawText);

    // Initial text draw
    InitialPlayerEngineTextdraw(playerid);
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
    // Reset kill streak
    ResetPlayerKillStreak(playerid);

    // Alert player if upgrade available
    if (CanPlayerUpgradeRank(playerid))
        AlertPlayerText(playerid, "~p~~h~/rankup available");

    // Fix default -$100
    GivePlayerMoney(playerid, 100);
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    // Send death message (reason)
    SendDeathMessage(killerid, playerid, reason);

    // If not sucide
    if (killerid != INVALID_PLAYER_ID)
    {
        // Reward and heal killer
        AlertPlayerText(killerid, "~g~~h~+100");
        GivePlayerMoney(killerid, 100);
        SetPlayerHealth(killerid, 100);

        // Kill streak handling
        CheckPlayerKillStreak(killerid);

        // Check for double kill
        if (gettime() - playerLastKill[killerid] < TIME_DOUBLE_KILL)
        {
            // Show player 2x kill money
            AlertPlayerText(killerid, "~g~~h~+200");
            GivePlayerMoney(killerid, 100);

            // Alert players
            AlertPlayers(FPlayer(killerid, "performed a {FF0000}Double Kill!"));
        }

        // Save last kill time
        playerLastKill[killerid] = gettime();
    }
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
        // Set position
        if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
            SetPlayerPos(playerid, fX, fY, fZ);

        // Set vehicle position
        else SetVehiclePos(PVI, fX, fY, fZ);
    }
    return 1;
}

public OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid, bodypart)
{
    // Hit sound (ding) if not flame
    if (weaponid != WEAPON_FLAMETHROWER)
        PlayerPlaySound(playerid, 17802, 0.0, 0.0, 0.0);

    // Extra damage multiplier
    new Float:multiplier = 1;

    // Extra damage for each weapon
    switch (weaponid)
    {
        case WEAPON_SNIPER:   multiplier = 2;
        case WEAPON_RIFLE:    multiplier = 2;
        case WEAPON_SHOTGUN:  multiplier = 2;
        case WEAPON_SILENCED: multiplier = 2;
        case WEAPON_DEAGLE:   multiplier = 2;
    }

    // Double damage if headshot
    if (bodypart == 9)
        multiplier = multiplier * 2;

    // Deal extra damage to player
    if (damagedid != INVALID_PLAYER_ID)
        GivePlayerDamage(damagedid, amount * multiplier);
    return 0;
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
        UpdatePlayerEngineTextdraw(i);
    }
}

forward OnPlayerPickupRandomPackage(playerid);
public  OnPlayerPickupRandomPackage(playerid)
{
    // Get random index from packages
    new package = Ran(0, MAX_RANDOM_PACKAGES);

    // Message
    new msg[60];    

    // Give player random package
    switch(package)
    {
        case RANDOM_PACKAGE_CASH: // Cash
        {
            GivePlayerMoney(playerid, 500);
            msg = "~g~~h~+500";
        }
        case RANDOM_PACKAGE_HP_AR: // HP and armour
        {
            SetPlayerArmour(playerid, 100);
            SetPlayerHealth(playerid, 100);
            msg = "~b~~h~Armour ~r~~h~Health";
        }
        case RANDOM_PACKAGE_RPG: // RPG
        {
            GivePlayerWeapon(playerid, WEAPON_ROCKETLAUNCHER, 2);
            msg = "~b~~h~RPG";
        }
        case RANDOM_PACKAGE_RANDOM_ITEM: // Random item
        {
            CallRemoteFunction("GivePlayerRandomItem", "i", playerid);
            msg = "~b~~h~Random Item";
        }
    }

    // Alert player
    AlertPlayerText(playerid, msg);

    // Collect message
    AlertPlayers(FPlayer(playerid, "collected random pacakge!"));
}

forward OnPlayerPurchaseVehicle(playerid, vehicleid);
public  OnPlayerPurchaseVehicle(playerid, vehicleid)
{
    // Purchase message
    new str[100]; format(str, sizeof(str), "purchased {FFFF00}%s!", GetCarName(vehicleid));

    // Alert everyone
    AlertPlayers(FPlayer(playerid, str));
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
            str = "got {FF0000}Minigun {DDDDDD}from 5x kills streak.";
        }
        case 10: // Money
        {
            GivePlayerMoney(playerid, KILL_STREAK_MONEY);
            AlertPlayerText(playerid, "~g~~h~+1000");
            str = "got {00FF00}$1,000 {DDDDDD}from 10x kills streak.";
        }
        case 15: // Grenade
        {
            GivePlayerWeapon(playerid, WEAPON_GRENADE, KILL_STREAK_GRENADE);
            AlertPlayerText(playerid, "~b~~h~RPG");
            str = "got many {FF0000}Grenades {DDDDDD}from 15x kills streak.";
        }
        case 20: // Jetpack
        {
            SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
            AlertPlayerText(playerid, "~b~~h~JETPACK");
            str = "got {FF0000}Jetpack {DDDDDD}from 20x kills streak.";
        }
        case 30: // RPG
        {
            GivePlayerWeapon(playerid, WEAPON_ROCKETLAUNCHER, KILL_STREAK_GRENADE);
            AlertPlayerText(playerid, "~b~~h~RPG");
            str = "got {FF0000}RPG {DDDDDD}from 30x kills streak.";
        }
    }

    // If got a kill streak
    if (str[0])
    {
        // Announce
        AlertPlayers(FPlayer(playerid, str));
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

// Commands

CMD:rankup(playerid)
{
    // Upgrade to next rank
    UpgradePlayerRank(playerid);
    return 1;
}

// Admin Command

CMD:mode(playerid, params[])
{
    // Check admin
    if (GetPlayerAdmin(playerid) < 5)
        return 0;

    // Check params
    new mode;
    if (sscanf(params, "i", mode))
        return AlertPlayerError(playerid, "> Command usage: /mode [mode]");

    // Unload modes
    SendRconCommand("unloadfs modes/tdm");
    SendRconCommand("unloadfs modes/ffa");

    // Load mode
    switch (mode)
    {
        case MODE_FFA: SendRconCommand("loadfs modes/ffa");
        case MODE_TDM: SendRconCommand("loadfs modes/tdm");
    }

    // For all players
    for (new i; i < MAX_PLAYERS; i++)
    {
        // Kill em
        SetPlayerHealth(playerid, 0);
    }
    return 1;
}

// Includes

#include "../include/player-commands"

#include "../include/admin-commands"

#include "../include/rank"

#include "../include/engine-textdraw"

#include "../include/kill-streak"