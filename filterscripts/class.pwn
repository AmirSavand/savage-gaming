/**
* Class
*
* Weapon class and selection for players.
* Call GivePlayerClassWeapons() to give player ammo of current class.
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT

#define DIALOG_CLASSES              400

#define DEATH_PICKUP_AMMO_FACTOR    0.3

// Includes

#include <a_samp>
#include <a_mysql>
#include <streamer>
#include <sscanf>
#include <zcmd>

#include "../../include/common"

// Variables

new const classNames[][] = {
    "Assault",  "Assault (2)",  "Assault (3)",
    "Engineer", "Engineer (2)", "Engineer (3)",
    "Sniper",   "Sniper (2)"
};

new const classGuns[][] = {
    // Assault
    {WEAPON_M4,        50, WEAPON_TEC9,     100, WEAPON_GRENADE,    2},
    {WEAPON_AK47,      80, WEAPON_UZI,      100, WEAPON_MOLTOV,     2},
    {WEAPON_MP5,       50, WEAPON_DEAGLE,     6, WEAPON_GRENADE,    1},
    // Engineer
    {WEAPON_SHOTGSPA,  40, WEAPON_DEAGLE,    15, WEAPON_GRENADE,    2},
    {WEAPON_SAWEDOFF,  40, WEAPON_TEC9,     100, WEAPON_GRENADE,    2},
    {WEAPON_SHOTGUN,   30, WEAPON_TEC9,     100, WEAPON_GRENADE,    2},
    // Sniper
    {WEAPON_SNIPER,     6, WEAPON_SILENCED,  20, WEAPON_MOLTOV,     1},
    {WEAPON_RIFLE,     10, WEAPON_DEAGLE,    14, WEAPON_MOLTOV,     1}
};

new deathPickup[MAX_PLAYERS];

new playerClass[MAX_PLAYERS] = -1;

// Callbacks

public OnFilterScriptInit()
{
    print("\n > Class filterscript by Amir Savand.\n");
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if (dialogid == DIALOG_CLASSES && response)
    {
        // Get current class before setting new class
        new currentClass = playerClass[playerid];

        // Set new weapon class
        playerClass[playerid] = listitem;

        // If didn't have a class, give class weapon
        if (currentClass < 0)
        {
            // Remove all current weapons
            ResetPlayerWeapons(playerid);

            // Give weapons of selected class
            GivePlayerClassWeapons(playerid, 1);
        }

        // Already had a weapon class, give weapons on spawn
        else
        {
            // Tell player about it
            AlertPlayerDialog(playerid, "Info", "Class will change next time you spawn!");
        }
    }
}

public OnPlayerSpawn(playerid)
{
    // If has class
    if (playerClass[playerid] > -1)
    {
        // Rearm player with class weapons
        GivePlayerClassWeapons(playerid, 1);
    }

    // No class selected
    else
    {
        // Force selection
        ShowPlayerClasses(playerid);
    }
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    // Position
    IMPORT_PLAYER_POS;

    // Respawn death pickup
    DestroyDynamicPickup(deathPickup[playerid]);
    deathPickup[playerid] = CreateDynamicPickup(1254, 1, pPos[0], pPos[1], pPos[2]);
    return 1;
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
    // For all player pickups
    for (new i; i < MAX_PLAYERS; i++)
    {
        // Death pickup
        if (deathPickup[i] == pickupid)
        {
            // Give a little ammo of current class
            GivePlayerClassWeapons(playerid, DEATH_PICKUP_AMMO_FACTOR);
            
            // Destroy death pickup
            DestroyDynamicPickup(deathPickup[i]);
            deathPickup[i] = 0;

            // Alert player
            AlertPlayerText(playerid, "~b~~h~+AMMO");

            // Fire event
            CallRemoteFunction("OnPlayerPickupDeathPickup", "i", playerid);
            break;
        }
    }
}

// Functions

ShowPlayerClasses(playerid)
{
    // Dialog string with head
    new str[2000] = "CLASS\tPRIMARY\tSECONDARY\tLETHAL\n";

    // Show all classes
    for (new i; i < sizeof(classNames); i++)
    {
        // Add class detail to classes dialog
        strcat(str, sprintf("{FFFF00}%s\t{00FF00}%s {BBBBBB}%i\t{00FF00}%s {BBBBBB}%i\t{00FF00}%s {BBBBBB}%i\n",
            classNames[i], GetGunName(classGuns[i][0]), classGuns[i][1], GetGunName(classGuns[i][2]), classGuns[i][3], GetGunName(classGuns[i][4]), classGuns[i][5]));
    }

    // Show dialog
    ShowPlayerDialog(playerid, DIALOG_CLASSES, DIALOG_STYLE_TABLIST_HEADERS, "{00FFFF}Weapon Class", str, "Select", "Close");
}

// Public functions

forward GivePlayerClassWeapons(playerid, Float:multiplier);
public  GivePlayerClassWeapons(playerid, Float:multiplier)
{
    // Multiplier is factor if not given
    if (multiplier == 0)
        multiplier = DEATH_PICKUP_AMMO_FACTOR;

    // Get player class
    new c = playerClass[playerid];

    // Give guns and ammo based on multiplier (multiplier is used for ammo pickups)
    GivePlayerWeapon(playerid, classGuns[c][4], floatround(classGuns[c][5] * multiplier, floatround_floor));
    GivePlayerWeapon(playerid, classGuns[c][2], floatround(classGuns[c][3] * multiplier));
    GivePlayerWeapon(playerid, classGuns[c][0], floatround(classGuns[c][1] * multiplier));
}

forward GivePlayerPrimaryAmmo(playerid, Float:multiplier);
public  GivePlayerPrimaryAmmo(playerid, Float:multiplier)
{
    // Class
    new c = playerClass[playerid];

    // Give player ammo of current class
    GivePlayerWeapon(playerid, classGuns[c][0], floatround(classGuns[c][1] * multiplier));
}

forward GivePlayerSecondaryAmmo(playerid, Float:multiplier);
public  GivePlayerSecondaryAmmo(playerid, Float:multiplier)
{
    // Class
    new c = playerClass[playerid];

    // Give player ammo of current class
    GivePlayerWeapon(playerid, classGuns[c][2], floatround(classGuns[c][3] * multiplier));
}

forward GivePlayerLethalAmmo(playerid, ammo);
public  GivePlayerLethalAmmo(playerid, ammo)
{
    // Class
    new c = playerClass[playerid];

    // Give player ammo of current class
    GivePlayerWeapon(playerid, classGuns[c][4], ammo);
}

// Commands

CMD:class(playerid)
{
    // Show class selection
    ShowPlayerClasses(playerid);
    return 1;
}
