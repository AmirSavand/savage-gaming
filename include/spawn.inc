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

new Float:spawn[MAX_SPAWN_AREAS][MAX_SPAWN_POINTS][4];
new spawnArea;

// Functions

AddSpawn(area, point, Float:x, Float:y, Float:z, Float:a)
{
    spawn[area][point][0] = x;
    spawn[area][point][1] = y;
    spawn[area][point][2] = z;
    spawn[area][point][3] = a;
}

RespawnPlayer(playerid, point = -1, Float:xOffset = 0.0, Float:yOffset = 0.0)
{
    new p = Ran(0, MAX_SPAWN_POINTS);
    new a = spawnArea;

    if (point == -1) p = point;

    MovePlayer(playerid, spawn[a][p][0] + xOffset, spawn[a][p][1] + yOffset, spawn[a][p][2], spawn[a][p][3]);

    return p;
}

stock SetSpawnArea(area)
{
    spawnArea = area;
}
