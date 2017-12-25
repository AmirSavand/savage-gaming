/**
* Cars
*
* Handle vehicle adding, removing, saving and loading.
* Saves vehicle model, engine, mods, etc...
*
* by Amir Savand
*/

// Defines

#define FILTERSCRIPT

#define RESPAWN_DELAY       60
#define RESPAWN_DELAY_ADMIN 10

#define DIALOG_CARS         200

#define TYPE_DISCARD        0
#define TYPE_FREE           1
#define TYPE_PURCHASE       2
#define TYPE_PURCHASE_ONCE  3

#define MAX_COMP_SLOTS      14
#define MAX_COMP_LENGTH     5
#define MAX_COMP_STRING     100

#define MAX_COLOR_SLOTS     3
#define MAX_COLOR_LENGTH    5
#define MAX_COLOR_STRING    50

#define CAR_SELL_FACTOR     0.5

// Includes

#include <a_samp>
#include <a_mysql>
#include <sscanf>
#include <zcmd>
#include <getvehiclecolor>

#include "../include/common"

// Variables

enum iCar
{
    uid,
    type,
    model,
    engine,
    comp[MAX_COMP_SLOTS],
    color[MAX_COLOR_SLOTS],

    owner,
    price,

    id,
    Float:pos[4],

    colorsRaw[MAX_COLOR_STRING],
    compsRaw[MAX_COMP_STRING] // Raw components separated by space
}

new Car[MAX_VEHICLES][iCar];

new adminCar[MAX_PLAYERS] = -1;

new MySQL:db;

new ps;

new bool:loaded = false;

new static freeCarModels[] = {
    400, 401, 405, 410, 412, 419, 422, 426, 436, 439, 
    445, 467, 474, 475, 492, 491, 496, 518, 526,
    529, 534, 542, 549, 567, 566, 576, 587, 602
};

// Callbacks

public OnFilterScriptInit()
{
    print("\n > Cars filterscript by Amir Savand.\n");

    // Connect to database
    #include "../include/connect-database"

    // Load all vehicles
    InitializeCars();
    return 1;
}

public OnFilterScriptExit()
{
    DestroyCars();
    return 1;
}

public OnGameModeInit()
{
    InitializeCars();
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    // Destroy admin car
    DestroyVehicle(adminCar[playerid]);
    return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
    // Got into a car
    if (newstate == PLAYER_STATE_DRIVER)
    {
        // Get index
        new car = GetCarIndex(PVI);

        // Check db car
        if (car == -1) return 1;

        // Car is owned
        if (Car[car][owner] > 0)
        {
            // Owned by player
            if (Car[car][owner] == GetPVarInt(playerid, "id"))
                return 1;

            // Owned by another player
            AlertPlayerDialog(playerid, "Owned Vehicle", "This vehicle is owned by another player.");
            RemovePlayerFromVehicle(playerid);
            return 1;
        }

        // Car is available to purchase
        if (Car[car][type] == TYPE_PURCHASE || Car[car][type] == TYPE_PURCHASE_ONCE)
        {
            // Show purchase dialog
            new str[500]; format(str, sizeof(str), "You can buy this vehicle for {00FF00}$%i", Car[car][price]);
            ShowPlayerDialog(playerid, DIALOG_CARS, DIALOG_STYLE_MSGBOX, "Buy Vehicle", str, "{00FF00}Buy", "Cancel");
        }
    }
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem)
{
    // Purchase dialog
    if (dialogid == DIALOG_CARS)
    {
        new car = GetCarIndex(PVI);

        // Wants to buy
        if (response)
        {
            // Has enough money?
            if (!HasEnoughMoney(playerid, Car[car][price]))
            {
                // No money, remove and alert
                RemovePlayerFromVehicle(playerid);
                AlertPlayerText(playerid, "~r~~h~not enough money");
            }

            // Purchase car
            else 
            {
                // Take money from player
                GivePlayerMoney(playerid, -Car[car][price]);

                // Update ownership
                Car[car][owner] = GetPVarInt(playerid, "id");

                // Restore car engine and repair
                SetVehicleHealth(PVI, Car[car][engine]);
                RepairVehicle(PVI);

                // Update to db if purchased permanently (not one time car)
                if (Car[car][type] != TYPE_PURCHASE_ONCE)
                    UpdateCar(car);

                // Event
                CallRemoteFunction("OnPlayerPurchaseVehicle", "ii", playerid, PVI);
            }
        }

        // Cancel, remove from car
        else RemovePlayerFromVehicle(playerid);
    }
}

public OnVehicleSpawn(vehicleid)
{
    // Index
    new i = GetCarIndex(vehicleid);

    // Check db
    if (i == -1) return 1;

    // Destroy if type is discard
    if (Car[i][type] == TYPE_DISCARD)
        DestroyVehicle(vehicleid);

    // Reset ownership if type is purchase once
    if (Car[i][type] == TYPE_PURCHASE_ONCE)
        Car[i][owner] = 0;

    // Load engine
    SetPlayerHealth(vehicleid, Car[i][engine]);

    // Load mods
    InitializeCarMods(i);
    return 1;
}

public OnEnterExitModShop(playerid, enterexit, interiorid)
{
    // Exited mod shop
    if (enterexit == 0)
    {
        // Index
        new i = GetCarIndex(PVI);

        // Check db
        if (i == -1) return;

        // Update for purchaseable cars (not one time only)
        if (Car[i][type] != TYPE_PURCHASE) return;

        // Save mods
        UpdateCar(i);
    }
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
    // Index
    new i = GetCarIndex(vehicleid);

    // Check db
    if (i == -1) return;

    // Update for purchaseable cars (not one time only)
    if (Car[i][type] != TYPE_PURCHASE) return;

    // Update paint job
    Car[i][color][2] = paintjobid;
}

// Public functions

forward OnPlayerUseItem(playerid, item, itemName[]);
public  OnPlayerUseItem(playerid, item, itemName[])
{
    // Repair car and is in a car
    if (isequal("Car Tools", itemName))
    {
        // Set health to saved engine
        SetVehicleHealth(PVI, Car[GetCarIndex(PVI)][engine]);
    }
}

// Functions

DestroyCars() // Destroy all db and admin cars
{
    // Destroy all db cars
    for (new i; i < MAX_VEHICLES; i++)
        DestroyVehicle(Car[i][id]);

    // Destroy all admin cars
    for (new i; i < MAX_PLAYERS; i++)
        DestroyVehicle(adminCar[i]);
}

InitializeCars() // Fetch all cars from db and store data in Car[][]
{
    // Don't load if already loaded
    if (loaded) return;

    // Destroy cars if already loaded
    DestroyCars();

    // Get all cars from db
    new Cache:cache = mysql_query(db, "SELECT * FROM cars LIMIT 2000");

    // For each car
    for (new i; i < cache_num_rows(); i++)
    {
        cache_get_value_name_int(i, "id",     Car[i][uid]);
        cache_get_value_name_int(i, "type",   Car[i][type]);
        cache_get_value_name_int(i, "owner",  Car[i][owner]);
        cache_get_value_name_int(i, "price",  Car[i][price]);
        cache_get_value_name_int(i, "model",  Car[i][model]);
        cache_get_value_name_int(i, "engine", Car[i][engine]);

        cache_get_value_name_float(i, "x", Car[i][pos][0]);
        cache_get_value_name_float(i, "y", Car[i][pos][1]);
        cache_get_value_name_float(i, "z", Car[i][pos][2]);
        cache_get_value_name_float(i, "a", Car[i][pos][3]);

        // Load raw car data
        new comps[MAX_COMP_STRING];
        new colors[MAX_COLOR_STRING];
        cache_get_value_name(i, "comps",  comps);
        cache_get_value_name(i, "colors", colors);
        format(Car[i][compsRaw],  MAX_COMP_STRING,  "%s", comps);
        format(Car[i][colorsRaw], MAX_COLOR_STRING, "%s", colors);

        InitializeCar(i);
    }

    // Get pool size
    ps = cache_num_rows();
    cache_delete(cache);
}

InitializeCar(i) // Create car and load data (color, mods, engine, etc...)
{
    // Check db
    if (i == -1) return 0;

    // Destroy car if exists
    DestroyVehicle(Car[i][id]);

    // Setup components and colors
    new comps[MAX_COMP_SLOTS][MAX_COMP_LENGTH];
    new colors[MAX_COLOR_SLOTS][MAX_COLOR_LENGTH];

    // Make a list out of em
    strexplode(comps, Car[i][compsRaw], " ");
    strexplode(colors, Car[i][colorsRaw], " ");

    // Store each component and color in its slot
    for (new c; c < MAX_COMP_SLOTS;  c++) Car[i][comp][c]  = strval(comps[c]);
    for (new c; c < MAX_COLOR_SLOTS; c++) Car[i][color][c] = strval(colors[c]);

    // Create vehicle
    Car[i][id] = CreateVehicle(GetCarModel(i), Car[i][pos][0], Car[i][pos][1], Car[i][pos][2], Car[i][pos][3], -1, -1, RESPAWN_DELAY);

    // Set engine
    SetVehicleHealth(Car[i][id], Car[i][engine]);

    // Components
    InitializeCarMods(i);

    // Return its db id
    return Car[i][id];
}

InitializeCarMods(i) // Initial all car mods (comps, colors, paintjob, etc...)
{
    // Check db
    if (i == -1) return 0;

    // For all saved component slots
    for (new c; c < MAX_COMP_SLOTS; c++)
    {
        // Add component from slot
        if (Car[i][comp][c] > 0) AddVehicleComponent(Car[i][id], Car[i][comp][c]);
    }

    // Load the color and paintjob
    ChangeVehicleColor(Car[i][id], GetCarColor(i, 0), GetCarColor(i, 1));
    ChangeVehiclePaintjob(Car[i][id], Car[i][color][2]);
    return 1;
}

GetCarModel(index) // Get the model of the car but return a random if it's 0
{
    // Random model
    if (Car[index][model] == 0)
        return freeCarModels[Ran(0, sizeof(freeCarModels))];

    // Original model
    return Car[index][model];
}

GetCarColor(index, colorIndex) // Get car color and return a random if it's -1
{
    // Random model
    if (Car[index][color][colorIndex] == -1)
        return Ran(0, 128);

    // Original model
    return Car[index][color][colorIndex];
}

GetCarIndex(vehicleid) // Find the index of the car
{
    // Find car id in cars
    for (new i; i <= ps; i++)
    {
        // Return index
        if (Car[i][id] == vehicleid)
        {
            return i;
        }
    }
    // Not found
    return -1;
}

UpdateCar(index) // Save all car data to database (except position)
{
    new qry[1000], i = index;

    // If db car
    if (index == -1)
        return 0;

    // If for one time purchase, reset owner
    if (Car[i][type] == TYPE_PURCHASE_ONCE) Car[i][owner] = 0;

    // Get components
    UpdateCarMods(index);

    // Update database
    mysql_format(db, qry, sizeof(qry), "UPDATE cars SET type=%i, owner=%i, price=%i, engine=%i, comps='%s', colors='%s' WHERE id=%i",
        Car[i][type], Car[i][owner], Car[i][price], Car[i][engine], Car[i][compsRaw], Car[i][colorsRaw], Car[i][uid]);
    mysql_query(db, qry, false);
    return 1;
}

UpdateCarMods(index) // Update all car mods to variable (comps, colors, etc...)
{
    // Reset car components and colors string
    strdel(Car[index][compsRaw],  0, MAX_COMP_STRING);
    strdel(Car[index][colorsRaw], 0, MAX_COLOR_STRING);

    // Update colors (paintjob gets updated by callback)
    GetVehicleColor(Car[index][id], Car[index][color][0], Car[index][color][1]);

    // For all components
    for (new c; c < MAX_COMP_SLOTS; c++)
    {
        // Store component in raw string
        Car[index][comp][c] = GetVehicleComponentInSlot(Car[index][id], c);
        format(Car[index][compsRaw], MAX_COMP_STRING, "%s%i ", Car[index][compsRaw], Car[index][comp][c]);
    }

    // For all colors
    for (new c; c < 3; c++)
    {
        // Store colors in raw string
        format(Car[index][colorsRaw], MAX_COLOR_STRING, "%s%i ", Car[index][colorsRaw], Car[index][color][c]);
    }
}

// Commands

CMD:addcar(playerid, params[]) // Create a db car in current position (model is optional)
{
    // Check admin
    if (GetPlayerAdmin(playerid) <= 2)
        return 0;

    new mod;

    // If mod is not given (random mod)
    if (sscanf(params, "i", mod)) mod = 0;

    // Get player position
    IMPORT_PLAYER_POS;

    // Insert car to db
    new qry[1000];
    mysql_format(db, qry, sizeof(qry), "INSERT INTO cars (model, x, y, z, a) VALUES (%i, %f, %f, %f, %f)", mod, pPos[0], pPos[1], pPos[2], pPos[3]);
    new Cache:cache = mysql_query(db, qry);

    // Increase pool size
    ps++;

    // Store car data
    Car[ps][uid]    = cache_insert_id();
    Car[ps][model]  = mod;
    Car[ps][type]   = TYPE_FREE;
    Car[ps][owner]  = 0;
    Car[ps][price]  = 0;
    Car[ps][engine] = 1000;

    Car[ps][pos][0] = pPos[0];
    Car[ps][pos][1] = pPos[1];
    Car[ps][pos][2] = pPos[2];
    Car[ps][pos][3] = pPos[3];

    // Create the car
    InitializeCar(ps);
    cache_delete(cache);
    return 1;
}

CMD:delcar(playerid) // Delete the car from db
{
    // Check admin
    if (GetPlayerAdmin(playerid) <= 3)
        return 0;

    // Is in a car
    if (!IsPlayerInAnyVehicle(playerid))
        return AlertPlayerText(playerid, "~r~~h~Not in vehicle");

    new index = GetCarIndex(PVI);

    // If found an index
    if (index == -1)
        return AlertPlayerText(playerid, "~r~~h~Not a database vehicle");

    // Remove free vehicle from database
    new qry[500]; mysql_format(db, qry, sizeof(qry), "DELETE FROM cars WHERE id=%i", Car[index][uid]);
    mysql_tquery(db, qry);

    // Remove vehicle in game
    DestroyVehicle(Car[index][id]);
    return 1;
}

CMD:scar(playerid, params[]) // Spawn admin car (model is optional)
{
    if (!GetPlayerAdmin(playerid)) 
        return 0;

    IMPORT_PLAYER_POS; new carModel;

    // If player is in a vehicle, get angle of vehicle
    if (IsPlayerInAnyVehicle(playerid))
        GetVehicleZAngle(PVI, pPos[3]);

    // Random carModel if not given
    if (sscanf(params, "i", carModel)) carModel = Ran(400, 611);

    // Destroy admin car
    DestroyVehicle(adminCar[playerid]);

    // Create new one
    new vehicleid = CreateVehicle(carModel, 0, 0, 0, 0, Ran(128, 243), Ran(128, 243), RESPAWN_DELAY_ADMIN);

    // Check if actually created
    if (vehicleid > MAX_VEHICLES)
        return AlertPlayerText(playerid, "~r~~h~Bad car model");

    // Put player in car
    SetVehiclePos(vehicleid, pPos[0], pPos[1], pPos[2]);
    SetVehicleZAngle(vehicleid, pPos[3]);
    PutPlayerInVehicle(playerid, vehicleid, 0);

    // Increase pool size
    ps++;

    // Store car id and set to discard
    adminCar[playerid] = vehicleid;
    Car[ps][type] = TYPE_DISCARD;
    return 1;
}

CMD:sellcar(playerid) // Sell current car
{
    // Is in a car
    if (!IsPlayerInAnyVehicle(playerid))
        return AlertPlayerText(playerid, "~r~~h~Not in vehicle");

    // Index
    new i = GetCarIndex(PVI);

    // Is db car
    if (i == -1 || Car[i][type] != TYPE_PURCHASE || Car[i][owner] != GetPVarInt(playerid, "id"))
        return AlertPlayerText(playerid, "~r~~h~Not in your car");

    // Give back some of car money
    GivePlayerMoney(playerid, floatround(Car[i][price] * CAR_SELL_FACTOR));

    // Remove from car
    RemovePlayerFromVehicle(playerid);

    // Reset ownership
    Car[i][owner] = 0;
    AlertPlayerDialog(playerid, "Info", "You'ved soled your vehicle for half of its price!");
    UpdateCar(i);

    // Event
    CallRemoteFunction("OnPlayerSellVehicle", "ii", playerid, PVI);
    return 1;
}

CMD:reloadcars(playerid) // Delete the car from db
{
    // Check admin
    if (GetPlayerAdmin(playerid) <= 5)
        return 0;

    // Reload cars
    loaded = false;
    InitializeCars();

    // Alert
    AlertPlayerText(playerid, "~b~~h~Reloaded cars");
    return 1;
}

CMD:updatecar(playerid) // Update data car to db (see: UpdateCar())
{
    if (!GetPlayerAdmin(playerid)) 
        return 0;

    // Is in a car
    if (!IsPlayerInAnyVehicle(playerid))
        return AlertPlayerText(playerid, "~r~~h~Not in vehicle");

    // Get car index
    new car = GetCarIndex(PVI);
    if (car == -1)
        return AlertPlayerText(playerid, "~r~~h~Not a database vehicle");

    // Update info
    UpdateCar(car);

    AlertPlayerText(playerid, "~p~~b~Car updated");
    return 1;
}

CMD:setcarpos(playerid) // Change car position to current and save to db
{
    if (!GetPlayerAdmin(playerid)) 
        return 0;

    // Is in a car
    if (!IsPlayerInAnyVehicle(playerid))
        return AlertPlayerText(playerid, "~r~~h~Not in vehicle");

    // Get car index
    new car = GetCarIndex(PVI);
    if (car == -1)
        return AlertPlayerText(playerid, "~r~~h~Not a database vehicle");

    // Get car position
    IMPORT_PLAYER_POS; GetVehicleZAngle(PVI, pPos[3]);

    // Store current position
    Car[car][pos][0] = pPos[0];
    Car[car][pos][1] = pPos[1];
    Car[car][pos][2] = pPos[2];
    Car[car][pos][3] = pPos[3];

    // Update position
    new qry[1000];
    mysql_format(db, qry, sizeof(qry), "UPDATE cars SET x=%f, y=%f, z=%f, a=%f WHERE id=%i", pPos[0], pPos[1], pPos[2], pPos[3], Car[car][uid]);
    mysql_query(db, qry, false);

    AlertPlayerText(playerid, "~p~~b~Position updated");
    return 1;
}

CMD:setcarprice(playerid, params[]) // Change car price and update to db
{
    if (!GetPlayerAdmin(playerid)) 
        return 0;

    // Is in a car
    if (!IsPlayerInAnyVehicle(playerid))
        return AlertPlayerText(playerid, "~r~~h~Not in vehicle");

    // Get price
    new carPrice;
    if (sscanf(params, "i", carPrice))
        return AlertPlayerText(playerid, "~r~~h~You must set price");

    // Index
    new i = GetCarIndex(PVI);
    
    // Check db car
    if (i == -1)
        return AlertPlayerText(playerid, "~r~~h~Not a database vehicle");

    // If not purchaseable, set it
    if (Car[i][type] != TYPE_PURCHASE || Car[i][type] != TYPE_PURCHASE_ONCE)
        Car[i][type] = TYPE_PURCHASE;

    // Set price
    Car[i][price] = carPrice;
    AlertPlayerText(playerid, "~p~~b~Pirce set");

    // Update info
    UpdateCar(i);
    return 1;
}

CMD:setcartype(playerid, params[]) // Change car type and update to db
{
    if (!GetPlayerAdmin(playerid)) 
        return 0;

    // Is in a car
    if (!IsPlayerInAnyVehicle(playerid))
        return AlertPlayerText(playerid, "~r~~h~Not in vehicle");

    // Get car index
    new i = GetCarIndex(PVI);
    if (i == -1)
        return AlertPlayerText(playerid, "~r~~h~Not a database vehicle");

    // Get type
    new carType;
    if (sscanf(params, "i", carType))
        return AlertPlayerText(playerid, "~r~~h~You must set type");

    // Set car type
    Car[i][type] = carType;
    AlertPlayerText(playerid, "~p~~b~Type changed");

    // Update info
    UpdateCar(i);
    return 1;
}

CMD:setcarengine(playerid, params[]) // Change car engine (health) and update to db
{
    if (!GetPlayerAdmin(playerid)) 
        return 0;

    // Is in a car
    if (!IsPlayerInAnyVehicle(playerid))
        return AlertPlayerText(playerid, "~r~~h~Not in vehicle");

    // Get car index
    new i = GetCarIndex(PVI);
    if (i == -1)
        return AlertPlayerText(playerid, "~r~~h~Not a database vehicle");

    // Get engine
    new carEngine;
    if (sscanf(params, "i", carEngine))
        return AlertPlayerText(playerid, "~r~~h~You must set engine");

    // Set car engine
    Car[i][engine] = carEngine;
    SetVehicleHealth(PVI, carEngine);
    AlertPlayerText(playerid, "~p~~b~Engine changed");

    // Update info
    UpdateCar(i);
    return 1;
}

CMD:setcarowner(playerid, params[]) // Change car owner and update to db
{
    if (!GetPlayerAdmin(playerid)) 
        return 0;

    // Is in a car
    if (!IsPlayerInAnyVehicle(playerid))
        return AlertPlayerText(playerid, "~r~~h~Not in vehicle");

    // Get owner
    new carOwner;
    if (sscanf(params, "i", carOwner))
        return AlertPlayerText(playerid, "~r~~h~You must set owner uid");

    // Index
    new i = GetCarIndex(PVI);
    
    // Check db car
    if (i == -1)
        return AlertPlayerText(playerid, "~r~~h~Not a database vehicle");

    // Set owner
    Car[i][owner] = carOwner;
    AlertPlayerText(playerid, "~p~~b~Owner set");

    // Update info
    UpdateCar(i);
    return 1;
}

CMD:blow(playerid) // Blow up car
{
    if (!GetPlayerAdmin(playerid)) 
        return 0;

    // Is in a car
    if (!IsPlayerInAnyVehicle(playerid))
        return AlertPlayerText(playerid, "~r~~h~Not in vehicle");

    // Blow up car
    SetVehicleHealth(PVI, 0);
    AlertPlayerText(playerid, "~p~~b~Run");
    return 1;
}
