/**
* Regeneration
*
* Player hp/armour regeneration over time.
*
* by Amir Savand
*/

// Functions

RegeneratePlayer(playerid, amount = 10, bool:health = true, bool:armour = false)
{
    // Get healt and armour
    new Float:hp = GetHealth(playerid);
    new Float:ar = GetArmour(playerid);

    // Check health is not max and can regenerate
    if (hp != 100 && health)
        SetPlayerHealth(playerid, hp + amount);

    // Check health is max, armour is not max and can regenerate
    else if (ar != 100 && armour && hp >= 100)
        SetPlayerArmour(playerid, ar + amount);

    // Maximum 100
    ClampPlayerHealthAndArmour(playerid, amount);
}

ClampPlayerHealthAndArmour(playerid, limit)
{
    // Get healt and armour
    new Float:hp = GetHealth(playerid);
    new Float:ar = GetArmour(playerid);

    // Clamp health
    if (100 > hp > hp + limit)
        SetPlayerHealth(playerid, 100);

    // Clamp armour
    if (100 > ar > ar + limit)
        SetPlayerArmour(playerid, 100);
}
