/**
* Chase
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT

#define STATUS_STOP              0
#define STATUS_FIND              1
#define STATUS_START             2

#define TIME_MIN                 8
#define TIME_MAX                 16
#define TIME_FAIL                24

#define REWARD                   8000
#define REWARD_FAIL              1000

#define DISTANCE_MIN             18
#define DISTANCE_MAX             60

#define MAX_SPAWN_AREAS          1
#define MAX_SPAWN_POINTS         5

// Variables

new const Float:checkpoints[][3] = {
    { 960.38, -1318.27, 13.14},
    { 813.22, -1318.99, 13.25},
    { 800.18, -1162.99, 23.24},
    { 940.26, -1182.86, 19.57},
    {1055.76, -1248.47, 14.99},
    {1194.41, -1296.96, 13.16},
    {1289.68, -1408.04, 12.93},
    {1302.80, -1527.00, 13.16},
    {1294.43, -1692.86, 13.16},
    {1455.53, -1734.26, 13.16},
    {1566.82, -1852.55, 13.16},
    {1727.55, -1817.54, 13.14},
    {1823.82, -1805.37, 13.17},
    {1959.20, -1807.32, 13.16},
    {2037.06, -1934.65, 13.11},
    {2189.94, -1897.42, 13.36},
    {2232.59, -1750.34, 13.17},
    {2447.51, -1734.79, 13.31}
};

// Includes

#include <a_samp>
#include <zcmd>
#include <sscanf>
#include <streamer>

#include "../../include/common"
#include "../../include/spawn"

// Variables

new status;
new target;
new checkpoint;
new cp;
new cpTime;
new fails;
new playerFails[MAX_PLAYERS];

new timer;

// Callbacks

public OnFilterScriptInit()
{
    print("\n > Chase filterscript by Amir Savand.\n");

    // Setup spawns
    AddSpawn(0, 0, 1026.32, -1341.26, 13.72, 134.93);
    AddSpawn(0, 1,  973.90, -1309.28, 13.38, 221.93);
    AddSpawn(0, 2, 1045.17, -1313.86, 13.54, 154.81);
    AddSpawn(0, 3, 1015.14, -1334.92, 13.54, 174.99);
    AddSpawn(0, 4,  986.97, -1387.31, 13.61, 327.50);

    // Setup players
    for (new i = 0; i < MAX_PLAYERS; i++)
        SetupPlayer(i);

    // Setup timer
    timer = SetTimer("OnUpdate", 1000, true);
}

public OnFilterScriptExit()
{
    KillTimer(timer);
}

public OnPlayerConnect(playerid)
{
    SetupPlayer(playerid);
}

public OnPlayerRequestClass(playerid, classid)
{
    // Set player and camera to selection point
    SetPlayerPos(playerid, 1039.28, -1343.81, 29.45);
    SetPlayerFacingAngle(playerid, 320.0);
    SetPlayerCameraPos(playerid, 1055.36, -1327.60, 33.38);
    SetPlayerCameraLookAt(playerid, 1039.28, -1343.81, 29.45);
}

public OnPlayerSpawn(playerid)
{
    // Spawn player to random location
    RespawnPlayer(playerid);

    // Rest weapons
    ResetPlayerWeapons(playerid);
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
    // Target got in a vehicle (chase status: finding)
    if (playerid == target && newstate == PLAYER_STATE_DRIVER && status == STATUS_FIND)
    {
        // Change status to started
        status = STATUS_START;

        // Update all players
        for (new i; i < MAX_PLAYERS; i++)
        {
            // Target
            if (i == target)
            {
                // Show info
                AlertPlayerDialog(i, "Objective", "Drive to all checkpoints.\nWait between 8 to 16 seconds for each checkpoint.");

                // Show checkpoint
                ShowCheckpoint(i);
            }

            // Chasers
            else
            {
                // Show info
                AlertPlayerDialog(i, "Objective", "Target got in a vehicle!\nChase the target and keep distance.");
            }
        }
    }   
}

public OnPlayerEnterCheckpoint(playerid)
{
    // Handle checkpoints
    ShowCheckpoint(playerid);
}

// Events

forward OnModeChange(mode, area);
public  OnModeChange(mode, area)
{
    if (IsValidIndex(area, MAX_SPAWN_AREAS))
    {
        SetSpawnArea(area);
    }
}

// Functions

SetupPlayer(playerid)
{
    // Random color and same team
    SetPlayerColor(playerid, playerColors[Ran(0, sizeof(playerColors))]);
    SetPlayerTeam(playerid, 1);
}

StartChase(targetid)
{
    // At least 1 player online and chase is stopped
    if (CountPlayers() && status == STATUS_STOP)
    {
        // Start and set target
        status = STATUS_FIND;
        target = targetid;

        // Alert target
        AlertPlayerDialog(target, "Info", "You're the target!\nFind a vehicle.");

        // Respawn everyone
        for (new i; i < MAX_PLAYERS; i++)
            OnPlayerSpawn(i);
    }
}

StopChase(bool:victory)
{
    if (victory)
    {
        // Pay target
        new payment = REWARD - (REWARD_FAIL * fails);

        // Reward and alert target
        GivePlayerMoney(target, payment);
        AlertPlayerText(target, sprintf("~w~Reward: ~y~%i", payment));

        // Event
        CallRemoteFunction("OnChaseFinish", "iii", target, fails, payment);

        // Pay others
        for (new i; i < MAX_PLAYERS; i++)
        {
            // Not target
            if (i == target) continue;

            // Pay chaser
            payment = REWARD - (REWARD_FAIL * playerFails[i]);

            // Reward and alert
            GivePlayerMoney(i, payment);
            AlertPlayerText(i, sprintf("~w~Reward: ~y~%i", payment));
        }
    }

    else
    {
        // Event
        CallRemoteFunction("OnChaseFail", "i", target);
    }

    // Reset variables
    status = STATUS_STOP;
    target = INVALID_PLAYER_ID;
    fails = 0;
    cpTime = 0;
    cp = 0;

    for (new i; i < MAX_PLAYERS; i++)
        playerFails[i] = 0;
}

ShowCheckpoint(playerid)
{
    // Player is target
    if (playerid == target)
    {
        // Destroy checkpoint
        DestroyDynamicCP(checkpoint);

        // If not initial checkpoint
        if (cp)
        {
            // Was not on time (failed)
            if (cpTime > TIME_MAX || cpTime < TIME_MIN)
            {
                // Increase fail count
                fails++;

                // Alert too soon/late
                if (cpTime < TIME_MIN) AlertPlayerText(playerid, "~r~~h~Too Soon");
                else AlertPlayerText(playerid, "~r~~h~Too Late");
            }

            // Was on time, alert
            else AlertPlayerText(playerid, "~y~Good");
        }

        // Last checkpoint
        if (cp == sizeof(checkpoints))
        {
            // Stop chase by victory
            StopChase(true);
        }

        // More checkpoints left
        else
        {
            // Show next checkpoint
            checkpoint = CreateDynamicCP(checkpoints[cp][0], checkpoints[cp][1], checkpoints[cp][2], 2, -1, -1, playerid, 1000);

            // Reset checkpoint time
            cpTime = 0;

            // If not initial
            if (cp)
            {
                // Check distance of others
                for (new i; i < MAX_PLAYERS; i++)
                {
                    // If chaser
                    if (i != playerid)
                    {
                        // Get distance
                        IMPORT_PLAYER_POS;
                        new Float:distance = GetPlayerDistanceFromPoint(i, pPos[0], pPos[1], pPos[2]);

                        // Too close
                        if (distance < DISTANCE_MIN)
                        {
                            // Fail and alert
                            playerFails[i]++;
                            AlertPlayerText(i, "~r~~h~Too close");
                        }

                        // Too far
                        else if (distance > DISTANCE_MAX)
                        {
                            // Fail and alert
                            playerFails[i]++;
                            AlertPlayerText(i, "~r~~h~Too far");
                        }

                        // Good distance
                        else AlertPlayerText(i, "~y~Good");
                    }
                }
            }
            
            // Increase to next checkpoint
            cp++;
        }
    }
}

// Forward

forward OnUpdate();
public  OnUpdate()
{
    // Chase started
    if (status == STATUS_START)
    {
        // Increase target CP reach time
        cpTime++;

        // If took too long
        if (cpTime > TIME_FAIL)
        {
            // End chase by fail
            StopChase(false);
        }
    }
}

// Commands

CMD:start(playerid, params[])
{
    if (!GetPlayerAdmin(playerid))
        return 0;

    // Check params
    new targetid;
    if (sscanf(params, "u", targetid))
        return AlertPlayerDialog(playerid, "Command Usage", "/start [player]");

    // Start
    StartChase(targetid);
    return 1;
}
