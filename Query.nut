/**
 * Class for creating and executing SQL queries
 * Examples:
 *     Query("select * from @MyEntity").getResult()
 *     Query("select p.id, d.size from tbl_p p left join tbl_d d on d.id = p.size_id where p.id = :id").setParameter('id', 15).getSingleResult()
 *     Query("delete from @MyEntity").execute()
 */
class ORM.Query {

    /**
     * Field stores current raw query
     * @type {string}
     */
    __raw = null;

    /**
     * Fild stores current compiled query
     * @type {[type]}
     */
    __compiled = null;

    /**
     * Field with table of predefined
     * regex expressions for matching in parse method
     * @type {Object}
     */
    __regex = {
        entityName = regexp("@[A-Za-z_]+"),
        parameters = regexp(":[A-Za-z_]+")
    };

    /**
     * Field storage for matched data after parse method
     * (storing named entities and parameters)
     * @type {Object}
     */
    __matched = null;

    constructor (queryString) {
        // fill in default data
        this.__matched = {
            entities = {},
            parameters = {}
        };

        // save plain raw query string
        this.__raw = queryString;

        // start parsing, and
        // throw errors if any found
        this.__parse(queryString);
    }

    /**
     * Method tries to parse raw query
     * throws error if entities, matched in query was not found in global namespace
     * @param  {string} queryString
     */
    function __parse(queryString) {
        // search for entity names in query
        local previousPosition = 0;
        while (true) {
            local results = this.__regex.entityName.search(
                queryString, previousPosition
            );

            if (!results) break;

            // extract entity name
            local entityName = queryString.slice(results.begin + 1, results.end);

            try {
                // extract entity class by name
                local entityClass = compilestring("return " + entityName + ";")();

                // save it to local storage
                this.__matched.entities[entityName] <- entityClass;
            } catch (e) {
                throw "ORM.Query: tried to access to non-declared entity: " + entityName
                     + "\n in query: " + this.__raw;
            }

            previousPosition = results.end;
        }

        // search for params in query
        previousPosition = 0;
        while (true) {
            local results = this.__regex.parameters.search(
                queryString, previousPosition
            );

            if (!results) break;

            // extract parameter name
            local paramName = queryString.slice(results.begin + 1, results.end);

            // save it to local storage
            this.__matched.parameters[paramName] <- UNDEFINED;

            previousPosition = results.end;
        }
    }

    /**
     * Sets a value binded to parameter name
     * throws error if parameter was not created
     * @param {string} name
     * @param {mixed} value
     */
    function setParameter(name, value) {
        // TODO: add validation and escaping to "value"

        try {
            this.__matched.parameters[name] = value;
        } catch (e) {
            throw "ORM.Query: tried to populate unregistered parameter: " + name
                 + "\n in query: " + this.__raw;
        }

        return this;
    }

    /**
     * Replace occurances of "search" to "replace" in the "subject"
     * @param  {string} search
     * @param  {string} replace
     * @param  {string} subject
     * @return {string}
     */
    function __strreplace(search, replace, subject) {
        local string = "";
        local first = subject.find(search[0].tochar());
        local last = (typeof first == "null" ? null : subject.find(
            search[(search.len()-1)].tochar(), first
        ));

        if (typeof first == "null" || typeof last == "null") return false;

        for (local i = 0; i < subject.len(); i++) {
            if (i >= first && i <= last) {
                if (i == first) string = format("%s%s", string, replace.tostring());
            } else { 
                string = format("%s%s", string, subject[i].tochar());
            }
        }

        return string;
    }

    /**
     * Compile raw query into baked query
     * (ready to be sent to dbms)
     * @param {bool} recomplie force recompilation
     * @return {string}
     */
    function compile(recompile = false) {
        // return exsting if no forced recompilation
        if (!recompile && this.__compiled != null) {
            return this.__compiled;
        }

        local query = this.__raw;

        // itrate over entities
        foreach (index, value in this.__matched.entities) {
            if (value.table == UNDEFINED) throw "ORM.Query: couldn't find configured table name for: " + index;

            // replace data to table names
            query = this.__strreplace("@" + index, value.table, query);
        }

        // iterate over parameters
        foreach (index, value in this.__matched.parameters) {
            if (value == UNDEFINED) throw "ORM.Query: you didn't provided data for parameter: " + index;

            // replace data to table names
            query = this.__strreplace(":" + index, value, query);
        }

        // save compiled version
        this.__compiled = query;

        return query;
    }

    /**
     * Function proxyies hydration of given data
     * to a specific entity hydrator
     * @return {ORM.Entity|mixed} Created and hydrated (populated with given data) entity or mixed data
     */
    function hydrate(data) {
        // return empty if empty, lol
        if (data.len() < 0) return data;

        // just proxy data if no special keys
        // (custom select fields case)
        if (!"_uid" in data || !"_entity" in data) return data;

        // extract entity class by name
        local entityClass = compilestring("return " + data._entity + ";")();

        // proxy hydration to entity class
        return entityClass.hydrate(data);
    }

    /**
     * Run query without processing the result
     * @param  {Function} callback
     */
    function execute(callback) {
        local query = this.compile();

        ORM.Driver.query(query, function(err, results) {
            return callback(err, err ? false : true);
        });

        return this;
    }

    /**
     * Run query with processing the result for a single entity
     * @param  {Function} callback
     */
    function getSingleResult(callback) {
        local self = this;
        local query = this.compile();

        ORM.Driver.query(query, function(err, results) {
            if (err) return callback(err, null);

            // extract and hydrate data
            local result = results[0];
            local hydrated = self.hydrate(result);

            // return it
            callback(null, hydrated);
        });

        return this;
    }

    /**
     * Run query with processing the result for a array of entities
     * @param  {Function} callback
     */
    function getResult(callback) {
        local self = this;
        local query = this.compile();

        ORM.Driver.query(query, function(err, results) {
            if (err) return callback(err, null);

            local hydrated = [];

            // iterate over data and hydrate it
            foreach (idx, data in results) {
                hydrated.push(self.hydrate(data));
            }

            // return it
            callback(null, hydrated);
        });

        return this;
    }
}
