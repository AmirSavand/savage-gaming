/**
* Common
*
* by Amir Savand
*/

//
// Global
//

#include <strlib>

//
// Script defines
//

#define PRESSED(%0) (((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
#define HOLDING(%0) ((newkeys & (%0)) == (%0))

#undef  MAX_PLAYERS
#define MAX_PLAYERS 200

//
// Colors defines
//

#define cRed        0xFF0000FF
#define cGreen      0x11FF00FF
#define cBlue       0x1100FFFF
#define cYellow     0xFFFF00FF
#define cMagenta    0xFF00FFFF
#define cCyan       0x11FFFFFF
#define cPink       0xFF0084FF
#define cPurple     0xDE00DEFF
#define cVoilet     0x5D1FFFFF
#define cOrange     0xFF9700FF
#define cGrey       0xDDDDDDFF
#define cDGrey      0xBBBBBBFF

//
// Player defines
//

#define PVI                         GetPlayerVehicleID(playerid)
#define IMPORT_PLAYER_POS           new Float: pPos[4]; GetPlayerPos(playerid, pPos[0], pPos[1], pPos[2]); GetPlayerFacingAngle(playerid, pPos[3])
#define IMPORT_PLAYER_POS_FROM_P    new Float: pPos[4]; GetPlayerPos(p,        pPos[0], pPos[1], pPos[2]); GetPlayerFacingAngle(p,        pPos[3])
#define IMPORT_PLAYER_POS_AS_TARGET new Float: tPos[4]; GetPlayerPos(target,   tPos[0], tPos[1], tPos[2]); GetPlayerFacingAngle(playerid, tPos[3])

//
// Variables
//

new const stock carNames[212][MAX_PLAYER_NAME] = {
    "Landstalker","Bravura","Buffalo","Linerunner","Pereniel","Sentinel","Dumper","Firetruck","Trashmaster","Stretch","Manana","Infernus",
    "Voodoo","Pony","Mule","Cheetah","Ambulance","Leviathan","Moonbeam","Esperanto","Taxi","Washington","Bobcat","Mr Whoopee","BF Injection",
    "Hunter","Premier","Enforcer","Securicar","Banshee","Predator","Bus","Rhino","Barracks","Hotknife","Trailer","Previon","Coach","Cabbie",
    "Stallion","Rumpo","RC Bandit","Romero","Packer","Monster","Admiral","Squalo","Seasparrow","Pizzaboy","Tram","Trailer","Turismo","Speeder",
    "Reefer","Tropic","Flatbed","Yankee","Caddy","Solair","Berkley's RC Van","Skimmer","PCJ-600","Faggio","Freeway","RC Baron","RC Raider",
    "Glendale","Oceanic","Sanchez","Sparrow","Patriot","Quad","Coastguard","Dinghy","Hermes","Sabre","Rustler","ZR3 50","Walton","Regina",
    "Comet","BMX","Burrito","Camper","Marquis","Baggage","Dozer","Maverick","News Chopper","Rancher","FBI Rancher","Virgo","Greenwood",
    "Jetmax","Hotring","Sandking","Blista Compact","Police Maverick","Boxville","Benson","Mesa","RC Goblin","Hotring Racer A","Hotring Racer B",
    "Bloodring Banger","Rancher","Super GT","Elegant","Journey","Bike","Mountain Bike","Beagle","Cropdust","Stunt","Tanker","RoadTrain",
    "Nebula","Majestic","Buccaneer","Shamal","Hydra","FCR-900","NRG-500","HPV1000","Cement Truck","Tow Truck","Fortune","Cadrona","FBI Truck",
    "Willard","Forklift","Tractor","Combine","Feltzer","Remington","Slamvan","Blade","Freight","Streak","Vortex","Vincent","Bullet","Clover",
    "Sadler","Firetruck","Hustler","Intruder","Primo","Cargobob","Tampa","Sunrise","Merit","Utility","Nevada","Yosemite","Windsor","Monster A",
    "Monster B","Uranus","Jester","Sultan","Stratum","Elegy","Raindance","RC Tiger","Flash","Tahoma","Savanna","Bandito","Freight","Trailer",
    "Kart","Mower","Duneride","Sweeper","Broadway","Tornado","AT-400","DFT-30","Huntley","Stafford","BF-400","Newsvan","Tug","Trailer A","Emperor",
    "Wayfarer","Euros","Hotdog","Club","Trailer B","Trailer C","Andromada","Dodo","RC Cam","Launch","Police Car LSPD","Police Car SFPD",
    "Police Car LVPD","Police Ranger","Picador","S.W.A.T. Van","Alpha","Phoenix","Glendale","Sadler","Luggage Trailer A","Luggage Trailer B",
    "Stair Trailer","Boxville","Farm Plow","Utility Trailer"
};

new const stock playerColors[] = {
    0x7FFFD4FF, 0xFFE4C4FF, 0x8A2BE2FF,
    0x5F9EA0FF, 0xD2691EFF, 0xFF7F50FF,
    0x6495EDFF, 0x008B8BFF, 0x006400FF,
    0xFF6347FF, 0xFF8C00FF, 0x483D8BFF,
    0xFF1493FF, 0xDAA520FF, 0xADFF2FFF,
    0xFF69B4FF, 0xF08080FF, 0x808000FF,
    0xA0522DFF
};

//
// Script stocks
//

stock Ran(min, max)
{
    return random(max - min) + min;
}

stock Log(string[], const fileLocation[] = "log.txt")
{
    new File:logFile = fopen(fileLocation, io_append);
    new logStr[2000];

    new _year, _month, _day, _hour, _minute, _second;
    getdate(_year, _month, _day);
    gettime(_hour, _minute, _second);

    format(logStr,sizeof(logStr),"[%i/%i/%i - %02d:%02d:%02d] %s\r\n", _year, _month, _day, _hour, _minute, _second, string);
    fwrite(logFile, logStr);
    fclose(logFile);
    return 1;
}

stock bool:IsValidIndex(size, index)
{
    return index > 0 && index < size;
}

stock GetStringNumber(preString[], reward)
{
    new str[128];
    format(str, sizeof(str), "%s%i", preString, reward);
    return str;
}

stock KillTimers(timers[], len)
{
    // For all timers
    for (new t; t < len; t++)
    {
        // Kill timer
        KillTimer(timers[t]);
    }
}

stock Float:GetDistanceBetweenPoints(Float:rx1, Float:ry1, Float:rz1, Float:rx2, Float:ry2, Float:rz2)
{
    return floatadd(floatadd(floatsqroot(floatpower(floatsub(rx1,rx2),2)),floatsqroot(floatpower(floatsub(ry1,ry2),2))),floatsqroot(floatpower(floatsub(rz1,rz2),2)));
}

//
// Formats
//

stock FPlayer(playerid, string[], pre[] = "> ")
{
    new str[500];
    format(str, sizeof(str), "%s{00FF00}%s {DDDDFF}%s", pre, GetName(playerid), string);
    return str;
}

stock FPlayerText(playerid, string[], color[] = "~g~~h~")
{
    new str[200];
    format(str, sizeof(str), "%s%s ~w~%s", color, GetName(playerid), string);
    return str;
}

//
// Player stocks
//

stock GetPlayerAdmin(playerid)
{
    return GetPVarInt(playerid, "admin");
}

stock GetName(playerid)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    return name;
}

stock Float:GetHealth(playerid)
{
    new Float:health;
    GetPlayerHealth(playerid, health);
    return health;
}

stock Float:GetArmour(playerid)
{
    new Float:armour;
    GetPlayerArmour(playerid, armour);
    return armour;
}

stock GetGunName(weaponid)
{
    new weaponName[MAX_PLAYER_NAME];
    GetWeaponName(weaponid, weaponName, sizeof(weaponName));
    return weaponName;
}

stock GetCarName(vehicleid)
{
    new str[MAX_PLAYER_NAME];
    new index = GetVehicleModel(vehicleid) - 400;

    if (index < 0 || index > sizeof(carNames))
        return str;

    format(str, sizeof(str), "%s", carNames[index]);
    return str;
}

stock bool:HasEnoughMoney(playerid, amount = 0)
{
    return GetPlayerMoney(playerid) >= amount;
}

stock SetPlayerMoney(playerid, amount = 0)
{
    ResetPlayerMoney(playerid);
    return GivePlayerMoney(playerid, amount);
}

stock MovePlayer(playerid, Float:x, Float:y, Float:z, Float:a)
{
    SetPlayerPos(playerid, x, y, z);
    SetPlayerFacingAngle(playerid, a);
    SetCameraBehindPlayer(playerid);
    return 1;
}

stock SetPlayerWeaponSkills(playerid, skill)
{
    for (new i; i < 11; i++)
        SetPlayerSkillLevel(playerid, i, skill);

    return 1;
}

stock GivePlayerDamage(playerid, Float:amount)
{
    new Float:health = GetHealth(playerid);
    new Float:armour = GetArmour(playerid);

    // Has amour
    if (armour > 0)
    {
        // Will have armour after damage
        if (armour - amount > 0)
        {
            // Reduce armour by damage amount
            return SetPlayerArmour(playerid, floatround(armour - amount));
        }

        // Less armour than damage amount
        else
        {
            // Set to no armour
            SetPlayerArmour(playerid, 0);

            // Reduce amount with armour amount that was removed
            amount -= armour;
        }
    }

    // Reduce health by amount
    SetPlayerHealth(playerid, floatround(health - amount));
    return 1;
}

stock CountPlayers()
{
    new count;

    for (new i; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i))
        {
            count++;
        }
    }

    return count;
}

stock bool:DoesPlayerHaveWeapon(playerid, weaponid)
{
    new ammo, checkweaponid;

    for (new slot; slot <= 12; slot++)
    {
        // Get weapon data in that slot
        if (!GetPlayerWeaponData(playerid, slot, checkweaponid, ammo))
            return false;

        // If has that weapon
        if (checkweaponid == weaponid && ammo > 0)
            return true;
    }

    return false;
}

stock bool:IsPlayerSkydiving(playerid)
{
    return 958 <= GetPlayerAnimationIndex(playerid) <= 962 && GetPlayerWeapon(playerid) == 46 && GetPlayerState(playerid) == PLAYER_STATE_ONFOOT;
}

stock bool:IsPlayerParachuting(playerid)
{
    return 963 <= GetPlayerAnimationIndex(playerid) <= 979 && GetPlayerWeapon(playerid) == 46 && GetPlayerState(playerid) == PLAYER_STATE_ONFOOT;
}

stock bool:IsPlayerSpawned(playerid)
{
    new pState = GetPlayerState(playerid);
    return 0 <= playerid < MAX_PLAYERS && pState != PLAYER_STATE_NONE && pState != PLAYER_STATE_WASTED && pState != PLAYER_STATE_SPECTATING;
}

// For a single player

stock AlertPlayer(playerid, message[])
{
    return SendClientMessage(playerid, cGrey, message);
}

stock AlertPlayerSuccess(playerid, message[])
{
    return SendClientMessage(playerid, cGreen, message);
}

stock AlertPlayerError(playerid, message[])
{
    return SendClientMessage(playerid, cRed, message);
}

stock AlertPlayerText(playerid, message[])
{
    return GameTextForPlayer(playerid, message, 3000, 4);
}

stock AlertPlayerDialog(playerid, title[], message[], dialigid = 0)
{
    return ShowPlayerDialog(playerid, dialigid, DIALOG_STYLE_MSGBOX, title, message, "Ok", "");
}

// For all players

stock AlertPlayers(message[])
{
    return SendClientMessageToAll(cGrey, message);
}

stock AlertPlayersSuccess(message[])
{
    return SendClientMessageToAll(cGreen, message);
}

stock AlertPlayersError(message[])
{
    return SendClientMessageToAll(cRed, message);
}

stock AlertPlayersText(message[], skipplayer = INVALID_PLAYER_ID)
{
    for (new i; i < MAX_PLAYERS; i++)
    {
        if (skipplayer != i)
        {
            AlertPlayerText(i, message);
        }
    }
}

stock AlertPlayersDialog(title[], message[], dialogid = 0)
{
    for (new i; i < MAX_PLAYERS; i++)
    {
        AlertPlayerDialog(i, title, message, dialogid);
    }
}

//
// Vehicle stocks
//

stock GetVehicleDriver(vehicleid)
{
    for (new i; i < MAX_PLAYERS; i++)
    {
        if (GetPlayerState(i) == PLAYER_STATE_DRIVER)
        {
            if (GetPlayerVehicleID(i) == vehicleid)
            {
                return i;
            }
        }
    }
    return INVALID_PLAYER_ID;
}

stock Float:GetVehicleEngine(vehicleid)
{
    new Float: engine;
    GetVehicleHealth(vehicleid, engine);
    return engine;
//
// Weapon stocks
//

stock GetWeaponModel(weaponid)
{
    switch (weaponid)
    {
        case 1     : return 331;
        case 32    : return 372;
        case 46    : return 371;
        case 9     : return 341;
        case 2..8  : return weaponid+331;
        case 10..15: return weaponid+311;
        case 16..18: return weaponid+326;
        case 30, 31: return weaponid+325;
        case 22..29, 33..39, 40..43: 
                     return weaponid+324;
    }
    return 0;
}