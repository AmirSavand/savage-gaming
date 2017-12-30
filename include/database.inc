/**
* Connect Database
*
* Should be included in an Init function
* Need to change password for security
* Need to call CloseDatabase() on script exit.
*
* by Amir Savand
*/

// Variables

new MySQL:db;

// Functions

InitialDatabase()
{
    // Allow mysql duplicate
    mysql_global_options(DUPLICATE_CONNECTIONS, true);

    // Connect and broadcast
    db = mysql_connect("localhost", "sg", "password", "sg");

    // Failed
    if (mysql_errno() != 0) print(" > Failed to connect to database.");
}

CloseDatabase()
{
    // Close connection
    mysql_close(db);
}
