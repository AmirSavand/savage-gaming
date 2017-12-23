/**
* Connect Database
*
* Should be included in an Init function
* Requires: MySQL:db
* Need to call mysql_close(db) on script exit.
* Need to change password for security
*
* by Amir Savand
*/

    // Allow mysql duplicate
    mysql_global_options(DUPLICATE_CONNECTIONS, true);

    // Connect and broadcast
    db = mysql_connect("localhost", "sg", "password", "sg");

    // Failed
    if (mysql_errno() != 0) print(" > Failed to connect to database.");
