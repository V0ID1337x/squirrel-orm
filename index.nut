/**
 * PROD CODE
 */
function require(filename) {
    // TODO: add second inclusion prevention
    return dofile(filename + ".nut", true);
}

const UNDEFINED = "UNDEFINED";

ORM <- {
    Trait = {}
};

/**
 * TESTING CODE
 */

require("json");

function dbg(data) {
    ::print("[debug] " + json.encode(data) + "\n");
}

require("./Account");
require("./Query");

table_data <- {};
table_data["tbl_accounts"] <- [null, null, { _uid = 2, _entity = "Account",  username = "User", password = "123345" }];

database <- {};
database["select * from tbl_accounts where id = 2"] <- table_data["tbl_accounts"][2];

function simple_sql_query(query) {
    dbg("[running query] " + query);
    return database[query];
}

function run_external_db_request(query, callback) {
    callback(null, [simple_sql_query(query)]);
}

// type 1 (almost plain query)
ORM.Query("select * from @Account where id = :id")
    .setParameter("id", 2)
    .getSingleResult(function(err, result) {
        dbg(result);
    });

// Account.findAll();

// type 2 (entity manager/repository)
// local result = Account:findOneBy({ id = 2 });
// local acc = Account({ username = "test", password = "123123" }).save(function(err, result) {
// });

local a = { _uid = 2, b = null, };
::print("_ui" in a);
