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

SetupDatabase()
{
    // Allow mysql duplicate
    mysql_global_options(DUPLICATE_CONNECTIONS, true);

    // Connect and broadcast
    db = mysql_connect("localhost", "sg", "password", "sg");

    // Failed
    if (mysql_errno() != 0) {
        print(" > Failed to connect to database, exiting...");
        SendRconCommand("exit");
    }
}

CloseDatabase()
{
    // Close connection
    mysql_close(db);
}

stock RegenerateTableAutoIncreasement(table[])
{
    new qry[200];
    mysql_format(db, qry, sizeof(qry), "SET @num := 0;UPDATE %s SET id = @num := (@num+1);ALTER TABLE %s AUTO_INCREMENT =1;", table, table);
    mysql_tquery(db, qry);
}
