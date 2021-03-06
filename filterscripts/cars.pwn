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

#define MAX_VEHICLE_UIDS    5000

#define MAX_COMP_SLOTS      14
#define MAX_COMP_LENGTH     5
#define MAX_COMP_STR        100

#define MAX_COLOR_SLOTS     3
#define MAX_COLOR_LENGTH    5
#define MAX_COLOR_STR       50

#define CAR_SELL_FACTOR     0.9

// Includes

#include <a_samp>
#include <a_mysql>
#include <sscanf2>
#include <zcmd>
#include <getvehiclecolor>

#include "../include/common"
#include "../include/database"

// Variables

enum iCar
{
    type,
    model,
    engine,
    comp[MAX_COMP_SLOTS],
    color[MAX_COLOR_SLOTS],
    bool:exists,

    owner,
    price,

    id,
    Float:pos[4],

    // Raw components separated by space
    colorsRaw[MAX_COLOR_STR],
    compsRaw[MAX_COMP_STR]
}

new Car[MAX_VEHICLE_UIDS][iCar];

new adminCar[MAX_PLAYERS] = -1;

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
    SetupDatabase();

    // Load all vehicles
    SetupCars();
    return 1;
}

public OnFilterScriptExit()
{
    DestroyCars();
    CloseDatabase();
    return 1;
}

public OnGameModeInit()
{
    SetupCars();
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
        new uid = GetCarUID(PVI);
        
        // Car is owned
        if (Car[uid][owner] > 0)
        {
            // Owned by player
            if (Car[uid][owner] == GetPVarInt(playerid, "id"))
                return 1;

            // Owner name to show
            new ownerName[256] = "(Owner is Offline)";

            // Check if owner is online
            for (new p; p < MAX_PLAYERS; p++)
            {
                // If owner of car
                if (IsPlayerConnected(p) && GetPVarInt(p, "id") == Car[uid][owner])
                {
                    // Save name
                    ownerName = sprintf("{00FF00}(%s){DDDDFF}", GetName(p));
                }
            }

            // Owned by another player
            AlertPlayerDialog(playerid, "Info", sprintf("{DDDDFF}Vehicle is owned by another player %s.", ownerName));
            RemovePlayerFromVehicle(playerid);
            return 1;
        }

        // Car is available to purchase
        if (IsCarForPurchase(uid))
        {
            // Show purchase dialog
            new str[500]; str = sprintf("You can buy this vehicle for {00FF00}$%i", Car[uid][price]);
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
        // Car UID
        new uid = GetCarUID(PVI);

        // Wants to buy
        if (response)
        {
            // Has enough money?
            if (!HasEnoughMoney(playerid, Car[uid][price]))
            {
                // No money, remove and alert
                RemovePlayerFromVehicle(playerid);
                AlertPlayerText(playerid, "~r~~h~not enough money");
            }

            // Purchase car
            else 
            {
                // Take money from player
                GivePlayerMoney(playerid, -Car[uid][price]);

                // Update ownership
                Car[uid][owner] = GetPVarInt(playerid, "id");

                // Restore car engine and repair
                RepairVehicle(PVI);
                SetVehicleHealth(PVI, Car[uid][engine]);

                // Update to db if purchased permanently (not one time car)
                if (Car[uid][type] != TYPE_PURCHASE_ONCE)
                    UpdateCar(uid);

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
    new uid = GetCarUID(vehicleid);

    // Check if db car
    if (!uid) return 1;

    // Destroy if type is discard
    if (Car[uid][type] == TYPE_DISCARD)
        DestroyVehicle(vehicleid);

    // Reset ownership if type is purchase once
    if (Car[uid][type] == TYPE_PURCHASE_ONCE)
        Car[uid][owner] = 0;

    // Load engine
    SetPlayerHealth(vehicleid, Car[uid][engine]);

    // Load mods
    SetupCarMods(uid);
    return 1;
}

public OnEnterExitModShop(playerid, enterexit, interiorid)
{
    // Exited mod shop
    if (enterexit == 0)
    {
        new uid = GetCarUID(PVI);

        // Check db and update for purchaseable cars (not one time only cars)
        if (!uid || Car[uid][type] != TYPE_PURCHASE) return;

        // Save mods
        UpdateCar(uid);
    }
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
    new uid = GetCarUID(vehicleid);

    // Check db and update for purchaseable cars (not one time only cars)
    if (!uid || Car[uid][type] != TYPE_PURCHASE) return 1;

    // Store colors
    Car[uid][color][0] = color1;
    Car[uid][color][1] = color2;

    // Store colors as raw
    format(Car[uid][colorsRaw], MAX_COLOR_STR, "%i %i %i", Car[uid][color][0], Car[uid][color][1], Car[uid][color][2]);
    return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
    new uid = GetCarUID(vehicleid);

    // Check db and update for purchaseable cars (not one time only cars)
    if (!uid || Car[uid][type] != TYPE_PURCHASE) return 1;

    // Store paintjob
    Car[uid][color][2] = paintjobid;

    // Store colors as raw
    format(Car[uid][colorsRaw], MAX_COLOR_STR, "%i %i %i", Car[uid][color][0], Car[uid][color][1], Car[uid][color][2]);
    return 1;
}

// Public functions

forward OnPlayerUseItem(playerid, item, itemName[]);
public  OnPlayerUseItem(playerid, item, itemName[])
{
    // Repair car and is in a car
    if (isequal("Car Tools", itemName))
    {
        new uid = GetCarUID(PVI);

        // Set health to saved engine
        if (uid) {
            SetVehicleHealth(PVI, Car[uid][engine]);
        }

    }
}

// Functions

DestroyCars() // Destroy all db and admin cars
{
    // Destroy all db cars
    for (new uid; uid < MAX_VEHICLE_UIDS; uid++)
    {
        Car[uid][exists] = false;
        DestroyVehicle(Car[uid][id]);
    }

    // Destroy all admin cars
    for (new i; i < MAX_PLAYERS; i++)
        DestroyVehicle(adminCar[i]);
}

SetupCars() // Fetch all cars from db and store data in Car[][]
{
    // Don't load if already loaded
    if (loaded) return;

    // Reset admin cars
    for (new i; i < MAX_PLAYERS; i++)
    {
        DestroyVehicle(adminCar[i]);
        adminCar[i] = -1;
    }

    // Destroy cars if already loaded
    DestroyCars();

    // Get all cars from db
    new Cache:cache = mysql_query(db, sprintf("SELECT * FROM cars LIMIT %i", MAX_VEHICLE_UIDS));

    // For each car
    for (new i; i < cache_num_rows(); i++)
    {
        new uid; cache_get_value_name_int(i, "id", uid);

        Car[uid][exists] = true;

        cache_get_value_name_int(i, "type",   Car[uid][type]);
        cache_get_value_name_int(i, "owner",  Car[uid][owner]);
        cache_get_value_name_int(i, "price",  Car[uid][price]);
        cache_get_value_name_int(i, "model",  Car[uid][model]);
        cache_get_value_name_int(i, "engine", Car[uid][engine]);

        cache_get_value_name_float(i, "x", Car[uid][pos][0]);
        cache_get_value_name_float(i, "y", Car[uid][pos][1]);
        cache_get_value_name_float(i, "z", Car[uid][pos][2]);
        cache_get_value_name_float(i, "a", Car[uid][pos][3]);

        // Load raw car data
        new comps[MAX_COMP_STR];
        new colors[MAX_COLOR_STR];
        cache_get_value_name(i, "comps",  comps);
        cache_get_value_name(i, "colors", colors);
        format(Car[uid][compsRaw], MAX_COMP_STR, "%s", comps);
        format(Car[uid][colorsRaw], MAX_COLOR_STR, "%s", colors);

        SetupCar(uid);
    }

    cache_delete(cache);
}

SetupCar(uid) // Create car and load data (color, mods, engine, etc...)
{
    // Check db
    if (!uid || !Car[uid][exists]) return 0;

    // Destroy car if exists
    DestroyVehicle(Car[uid][id]);

    // Setup components and colors
    new comps[MAX_COMP_SLOTS][MAX_COMP_LENGTH];
    new colors[MAX_COLOR_SLOTS][MAX_COLOR_LENGTH];

    // Make a list out of em
    strexplode(comps, Car[uid][compsRaw], " ");
    strexplode(colors, Car[uid][colorsRaw], " ");

    // Store each component and color in its slot
    for (new c; c < MAX_COMP_SLOTS;  c++) Car[uid][comp][c]  = strval(comps[c]);
    for (new c; c < MAX_COLOR_SLOTS; c++) Car[uid][color][c] = strval(colors[c]);

    // Create vehicle
    Car[uid][id] = CreateVehicle(GetCarModel(uid), Car[uid][pos][0], Car[uid][pos][1], Car[uid][pos][2], Car[uid][pos][3], -1, -1, RESPAWN_DELAY);

    // Set engine
    SetVehicleHealth(Car[uid][id], Car[uid][engine]);

    // Components
    SetupCarMods(uid);

    // Return uid
    return uid;
}

SetupCarMods(uid) // Initial all car mods (comps, colors, paintjob, etc...)
{
    if (!uid) return 0;

    // For all saved component slots
    for (new c; c < MAX_COMP_SLOTS; c++)
    {
        // Add component from slot
        if (Car[uid][comp][c] > 0) AddVehicleComponent(Car[uid][id], Car[uid][comp][c]);
    }

    // Load the color and paintjob
    // ChangeVehicleColor(Car[uid][id], Car[uid][color][0], Car[uid][color][1]);
    ChangeVehiclePaintjob(Car[uid][id], Car[uid][color][2]);
    return 1;
}

GetCarModel(uid) // Get the model of the car but return a random if it's 0
{
    // Random model
    if (Car[uid][model] == 0)
        return freeCarModels[Ran(0, sizeof(freeCarModels))];

    // Original model
    return Car[uid][model];
}

GetCarUID(vehicleid) // Find the index/UID of the car
{
    // Loop for all UIDs
    for (new uid; uid < MAX_VEHICLE_UIDS; uid++)
    {
        // If id of car matches the car id and exists
        if (Car[uid][id] == vehicleid && Car[uid][exists])
        {
            return uid;
        }
    }
    // Not found
    return 0;
}

UpdateCar(uid) // Save all car data to database (except position)
{
    new qry[1000], i = uid;

    // If for one time purchase, reset owner
    if (Car[i][type] == TYPE_PURCHASE_ONCE) Car[i][owner] = 0;

    // Get components
    UpdateCarMods(i);

    // Update database
    mysql_format(db, qry, sizeof(qry), "UPDATE cars SET type=%i, model=%i, owner=%i, price=%i, engine=%i, comps='%s', colors='%s' WHERE id=%i",
        Car[i][type], Car[i][model], Car[i][owner], Car[i][price], Car[i][engine], Car[i][compsRaw], Car[i][colorsRaw], i);
    mysql_query(db, qry, false);

    return 1;
}

UpdateCarMods(index) // Update all car mods to variable (comps, colors, etc...)
{
    // Reset car components and colors string
    strdel(Car[index][compsRaw],  0, MAX_COMP_STR);
    strdel(Car[index][colorsRaw], 0, MAX_COLOR_STR);

    // Update colors (paintjob gets updated by callback)
    GetVehicleColor(Car[index][id], Car[index][color][0], Car[index][color][1]);

    // For all components
    for (new c; c < MAX_COMP_SLOTS; c++)
    {
        // Store component in raw string
        Car[index][comp][c] = GetVehicleComponentInSlot(Car[index][id], c);
        format(Car[index][compsRaw], MAX_COMP_STR, "%s%i ", Car[index][compsRaw], Car[index][comp][c]);
    }

    // For all colors
    for (new c; c < 3; c++)
    {
        // Store colors in raw string
        format(Car[index][colorsRaw], MAX_COLOR_STR, "%s%i ", Car[index][colorsRaw], Car[index][color][c]);
    }
}

IsCarForPurchase(index) // Check if vehicle type is for puchase (including once)
{
    // Check type
    return Car[index][type] == TYPE_PURCHASE || Car[index][type] == TYPE_PURCHASE_ONCE;
}

// Commands

CMD:addcar(playerid, params[]) // Create a db car in current position (model is optional)
{
    if (GetPlayerAdmin(playerid) < 5)
        return 0;

    IMPORT_PLAYER_POS; new carModel;

    // If model is not given (random model)
    if (sscanf(params, "i", carModel)) carModel = 0;

    // Get angle if in a car
    if (IsPlayerInAnyVehicle(playerid))
        GetVehicleZAngle(PVI, pPos[3]);

    // Insert car to db
    new Cache:cache = mysql_query(db, sprintf("INSERT INTO cars (model, x, y, z, a) VALUES (%i, %f, %f, %f, %f)", carModel, pPos[0], pPos[1], pPos[2], pPos[3]));

    // Store car data
    new uid = cache_insert_id();
    cache_delete(cache);
    
    Car[uid][exists] = true;
    Car[uid][model]  = carModel;
    Car[uid][type]   = TYPE_FREE;
    Car[uid][owner]  = 0;
    Car[uid][price]  = 0;
    Car[uid][engine] = 1000;

    Car[uid][pos][0] = pPos[0];
    Car[uid][pos][1] = pPos[1];
    Car[uid][pos][2] = pPos[2];
    Car[uid][pos][3] = pPos[3];

    Car[uid][color][0] = -1;
    Car[uid][color][1] = -1;
    Car[uid][color][2] = -1;

    // Create the car
    SetupCar(uid);
    return 1;
}

CMD:delcar(playerid) // Delete the car from db
{
    if (GetPlayerAdmin(playerid) < 5)
        return 0;

    // Is in a car
    if (!IsPlayerInAnyVehicle(playerid))
        return AlertPlayerText(playerid, "~r~~h~Not in vehicle");

    new uid = GetCarUID(PVI);
    if (!uid) return AlertPlayerText(playerid, "~r~~h~Not a database vehicle");

    // Remove free vehicle from database
    new qry[500];
    mysql_format(db, qry, sizeof(qry), "DELETE FROM cars WHERE id=%i", uid);
    mysql_query(db, qry, false);

    // Remove vehicle in game
    DestroyVehicle(Car[uid][id]);

    // Set to deleted
    Car[uid][exists] = false;
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

    // Random car model if not given
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

    // Store admin car
    adminCar[playerid] = vehicleid;
    return 1;
}

CMD:sellcar(playerid) // Sell current car
{
    // Is in a car
    if (!IsPlayerInAnyVehicle(playerid))
        return AlertPlayerText(playerid, "~r~~h~Not in vehicle");

    // UID and sell price
    new uid = GetCarUID(PVI);
    new sellPrice = floatround(Car[uid][price] * CAR_SELL_FACTOR);

    // Is db car
    if (!uid || Car[uid][type] != TYPE_PURCHASE || Car[uid][owner] != GetPVarInt(playerid, "id"))
        return AlertPlayerText(playerid, "~r~~h~Not in your car");

    // Give back some of car money
    GivePlayerMoney(playerid, sellPrice);

    // Remove from car
    RemovePlayerFromVehicle(playerid);

    // Reset ownership
    Car[uid][owner] = 0;
    AlertPlayerDialog(playerid, "Info", sprintf("{00FF00}You've sold your vehicle!\n\n{DDDDDD}Sell price: {00FF00}$%i\n{DDDDDD}Original price: {00FF00}$%i", sellPrice, Car[uid][price]));
    UpdateCar(uid);

    // Event
    CallRemoteFunction("OnPlayerSellVehicle", "ii", playerid, PVI);
    return 1;
}

CMD:reloadcars(playerid) // Delete the car from db
{
    if (GetPlayerAdmin(playerid) < 5)
        return 0;

    // Reload cars
    loaded = false;
    SetupCars();

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

    new uid = GetCarUID(PVI);
    if (!uid) return AlertPlayerText(playerid, "~r~~h~Not a database vehicle");

    // Update info
    UpdateCar(uid);

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

    new uid = GetCarUID(PVI);
    if (!uid) return AlertPlayerText(playerid, "~r~~h~Not a database vehicle");

    // Get car position
    IMPORT_PLAYER_POS; GetVehicleZAngle(PVI, pPos[3]);

    // Store current position
    Car[uid][pos][0] = pPos[0];
    Car[uid][pos][1] = pPos[1];
    Car[uid][pos][2] = pPos[2];
    Car[uid][pos][3] = pPos[3];

    // Update position
    new qry[1000];
    mysql_format(db, qry, sizeof(qry), "UPDATE cars SET x=%f, y=%f, z=%f, a=%f WHERE id=%i", pPos[0], pPos[1], pPos[2], pPos[3], uid);
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

    new uid = GetCarUID(PVI);
    if (!uid) return AlertPlayerText(playerid, "~r~~h~Not a database vehicle");

    // If not purchaseable, set it
    if (Car[uid][type] != TYPE_PURCHASE || Car[uid][type] != TYPE_PURCHASE_ONCE)
        Car[uid][type] = TYPE_PURCHASE;

    // Set price
    Car[uid][price] = carPrice;
    AlertPlayerText(playerid, "~p~~b~Pirce set");

    // Update info
    UpdateCar(uid);
    return 1;
}

CMD:setcartype(playerid, params[]) // Change car type and update to db
{
    if (!GetPlayerAdmin(playerid)) 
        return 0;

    // Is in a car
    if (!IsPlayerInAnyVehicle(playerid))
        return AlertPlayerText(playerid, "~r~~h~Not in vehicle");
    
    new uid = GetCarUID(PVI);
    if (!uid) return AlertPlayerText(playerid, "~r~~h~Not a database vehicle");

    // Get type
    new carType;
    if (sscanf(params, "i", carType))
        return AlertPlayerText(playerid, "~r~~h~You must set type");

    // Set car type
    Car[uid][type] = carType;
    AlertPlayerText(playerid, "~p~~b~Type changed");

    // Reset owner if type is TYPE_PURCHASE_ONCE
    if (carType == TYPE_PURCHASE_ONCE)
        Car[uid][owner] = 0;

    // Update info
    UpdateCar(uid);
    return 1;
}

CMD:setcarmodel(playerid, params[]) // Change car model and update to db
{
    if (!GetPlayerAdmin(playerid)) 
        return 0;

    // Is in a car
    if (!IsPlayerInAnyVehicle(playerid))
        return AlertPlayerText(playerid, "~r~~h~Not in vehicle");

    new uid = GetCarUID(PVI);
    if (!uid) return AlertPlayerText(playerid, "~r~~h~Not a database vehicle");

    // Get model (to set)
    new carModel;
    if (sscanf(params, "i", carModel))
        return AlertPlayerText(playerid, "~r~~h~You must set model");

    // Set car model
    Car[uid][model] = carModel;
    AlertPlayerText(playerid, "~p~~b~Model changed");

    // Update info
    UpdateCar(uid);
    return 1;
}

CMD:setcarengine(playerid, params[]) // Change car engine (health) and update to db
{
    if (!GetPlayerAdmin(playerid)) 
        return 0;

    // Is in a car
    if (!IsPlayerInAnyVehicle(playerid))
        return AlertPlayerText(playerid, "~r~~h~Not in vehicle");

    new uid = GetCarUID(PVI);
    if (!uid) return AlertPlayerText(playerid, "~r~~h~Not a database vehicle");

    // Get engine
    new carEngine;
    if (sscanf(params, "i", carEngine))
        return AlertPlayerText(playerid, "~r~~h~You must set engine");

    // Set car engine
    Car[uid][engine] = carEngine;
    SetVehicleHealth(PVI, carEngine);
    AlertPlayerText(playerid, "~p~~b~Engine changed");

    // Update info
    UpdateCar(uid);
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
    if (sscanf(params, "u", carOwner))
        return AlertPlayerText(playerid, "~r~~h~You must set owner uid");

    new uid = GetCarUID(PVI);
    if (!uid) return AlertPlayerText(playerid, "~r~~h~Not a database vehicle");

    // Set owner
    Car[uid][owner] = GetPVarInt(carOwner, "id");
    AlertPlayerText(playerid, "~p~~b~Owner set");
    UpdateCar(uid);
    return 1;
}

CMD:resetcarowner(playerid, params[]) // Reset car owner and update to db
{
    if (!GetPlayerAdmin(playerid)) 
        return 0;

    // Is in a car
    if (!IsPlayerInAnyVehicle(playerid))
        return AlertPlayerText(playerid, "~r~~h~Not in vehicle");

    new uid = GetCarUID(PVI);
    if (!uid) return AlertPlayerText(playerid, "~r~~h~Not a database vehicle");

    // Set owner
    Car[uid][owner] = 0;
    AlertPlayerText(playerid, "~p~~b~Owner reset");
    UpdateCar(uid);
    return 1;
}

CMD:setcarinfo(playerid, params[]) // Set car info (type, price, engine)
{
    if (!GetPlayerAdmin(playerid)) 
        return 0;

    // Is in a car
    if (!IsPlayerInAnyVehicle(playerid))
        return AlertPlayerText(playerid, "~r~~h~Not in vehicle");
    
    new uid = GetCarUID(PVI);
    if (!uid) return AlertPlayerText(playerid, "~r~~h~Not a database vehicle");

    // Get info
    new carType, carPrice, carEngine;
    if (sscanf(params, "iii", carType, carPrice, carEngine))
        return AlertPlayerText(playerid, "~r~~h~You must set type, price and engine");

    // Set car info
    Car[uid][type]   = carType;
    Car[uid][price]  = carPrice;
    Car[uid][engine] = carEngine;

    // Update car engine
    SetVehicleHealth(PVI, carEngine);
    
    // Reset owner if type is TYPE_PURCHASE_ONCE
    if (carType == TYPE_PURCHASE_ONCE)
        Car[uid][owner] = 0;

    // Alert
    AlertPlayerText(playerid, "~p~~b~Info changed");

    // Update info
    UpdateCar(uid);
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
