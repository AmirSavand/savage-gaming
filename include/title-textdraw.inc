/**
* Ttile Textdraw
*
* Title or server name on top right of player screen
* Call InitialTitleTextdraw() at OnGameModeInit()
*
* by Amir Savand
*/

// Variables

new Text:titleTextdrawText;

// Functions

InitialTitleTextdraw(text[])
{
    // Create textdraw and set position top right
    titleTextdrawText = TextDrawCreate(604.847106, 5.083336, text);
    TextDrawLetterSize(titleTextdrawText, 0.330000, 1.545832);
    TextDrawAlignment(titleTextdrawText, 3);
    TextDrawColor(titleTextdrawText, -5963521);
    TextDrawSetOutline(titleTextdrawText, 1);
    TextDrawBackgroundColor(titleTextdrawText, 255);
    TextDrawFont(titleTextdrawText, 2);
    TextDrawSetProportional(titleTextdrawText, 1);    
    TextDrawShowForAll(titleTextdrawText);
}
