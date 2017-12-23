/**
* Ttile Text Draw
*
* Text draw on top right of screen
* Requires variable: titleTextDraw[] and Text:titleTextdrawText
* Requires on player connect/disconnect to show/hide the text
*
* by Amir Savand
*/

    titleTextdrawText = TextDrawCreate(604.847106, 5.083336, titleTextDraw);
    TextDrawLetterSize(titleTextdrawText, 0.330000, 1.545832);
    TextDrawAlignment(titleTextdrawText, 3);
    TextDrawColor(titleTextdrawText, -5963521);
    TextDrawSetOutline(titleTextdrawText, 1);
    TextDrawBackgroundColor(titleTextdrawText, 255);
    TextDrawFont(titleTextdrawText, 2);
    TextDrawSetProportional(titleTextdrawText, 1);
