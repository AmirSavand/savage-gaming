/**
* Gang Skins
*
* Gang skins for player classes.
*
* by Amir Savand
*/

new gangSkins[] = {
    102, 104,
    106, 107,
    108, 109,
    115, 116
};

SetupGangSkins()
{
    // For all gang skins
    for (new i; i < sizeof(gangSkins); i++)
    {
        // Add skin class
        AddPlayerClass(gangSkins[i], 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    }
}

