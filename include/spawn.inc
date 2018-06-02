/**
* Spawn
*
* Spawn manager resposible for respawning players and managing multiple spawn areas.
*
* Requires: MAX_SPAWN_POINTS (1), MAX_SPAWN_AREAS (1)
*
* by Amir Savand
*/

// Variables

new Float:spawn[MAX_SPAWN_POINTS][MAX_SPAWN_AREAS][4];

// Functions

AddSpawn(area, point, Float:x, Float:y, Float:z, Float:a)
{
    spawn[area][point][0] = x;
    spawn[area][point][1] = y;
    spawn[area][point][2] = z;
    spawn[area][point][3] = a;
}

SpawnPlayerInArea(playerid, area)
{
    new p = Ran(0, MAX_SPAWN_POINTS);
    MovePlayer(playerid, spawn[area][p][0], spawn[area][p][1], spawn[area][p][2], spawn[area][p][3]);
}
