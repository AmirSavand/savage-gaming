/**
* Gang Skins
*
* Loads skins of each gang
* Should be included in OnGameModeInit
* Requires gangSkinsPos[][]
*
* by Amir Savand
*/

    // Gang skins
    new gangSkins[] = {
        102, 104,
        106, 107,
        108, 109,
        115, 116
    };

    // Add player classes
    for (new i; i < sizeof(gangSkins); i++)
    {
        AddPlayerClass(gangSkins[i], 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    }
