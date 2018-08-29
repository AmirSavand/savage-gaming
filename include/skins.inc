/**
* Skins
*
* Skin with groups.
*
* Requires: MAX_GROUP_SKINS (100)
*
* by Amir Savand
*/

// Variables

new const gangSkins[8] = {
    102, 104, 106, 107, 108, 109, 115, 116
};

new const armySkins[3] = {
    285, 286, 287
};

// Functions

bool:IsSkinFromGroup(skin, const group[], const len = sizeof(group))
{
    // For all skins in group
    for (new i; i < len; i++)
    {
        // Matches the skin
        if (group[i] == skin)
        {
            printf("Skin %i (%i) is in group %i", skin, group[i], group);
            return true;
        }
    }

    // Not in group
    return false;
}

SetupGangSkins()
{
    // Add all skins in group
    for (new i; i < sizeof(gangSkins); i++)
        AddPlayerClass(gangSkins[i], 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
}


SetupArmySkins()
{
    // Add all skins in group
    for (new i; i < sizeof(armySkins); i++)
        AddPlayerClass(armySkins[i], 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
}

