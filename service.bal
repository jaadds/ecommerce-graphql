import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/graphql;
import ballerina/sql;

type ItemRecord record {
    @sql:Column {name: "item_id"}
    int itemID;
    @sql:Column {name: "item_name"}
    string itemName;
    @sql:Column {name: "item_description"}
    string itemDesc;
    @sql:Column {name: "item_image"}
    string itemImage;
    @sql:Column {name: "includes"}
    string includes;
    @sql:Column {name: "intended_for"}
    string intendedFor;
    @sql:Column {name: "color"}
    string color;
    @sql:Column {name: "material"}
    string material;
    @sql:Column {name: "price"}
    decimal price;
};

type Catalog record {
    readonly int itemID;
    string itemName;
    string itemDesc;
    string itemImage;
    decimal price;
    StockDetails stockDetails;
};

type StockDetails record {
    string includes;
    string intendedFor;
    string color;
    string material;
};

configurable string USER = ?;
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable int PORT = ?;
configurable string DATABASE = ?;
//new code
mysql:Client mysqlEp = check new (host = HOST, user = USER, password = PASSWORD, database = DATABASE, port = PORT);

public distinct service class CatalogData {
    private final readonly & Catalog catalogRecord;

    function init(Catalog catalogRecord) {
        self.catalogRecord = catalogRecord.cloneReadOnly();
    }

    resource function get itemID() returns int {
        return self.catalogRecord.itemID;
    }

    resource function get itemName() returns string {
        return self.catalogRecord.itemName;
    }

    resource function get itemDesc() returns string {
        return self.catalogRecord.itemDesc;
    }

    resource function get itemImage() returns string {
        return self.catalogRecord.itemImage;
    }
}

# A service representing a network-accessible GraphQL API
# #test
service / on new graphql:Listener(8080) {

    # A resource for generating greetings
    # Example query:
    # query GreetWorld{ 
    # greeting(name: "World") 
    # }
    # Curl command: 
    # curl -X POST -H "Content-Type: application/json" -d '{"query": "query GreetWorld{ greeting(name:\"World\") }"}' http://localhost:8090
    #
    # + return - string name with greeting message or error
    resource function get catalogs() returns Catalog[]|error {
        return getAllItems();
    }

}

function getAllItems() returns Catalog[]|error {
    Catalog[] catalogs = [];
    stream<ItemRecord, error?> resultStream =  mysqlEp->query(
        `SELECT * FROM items i, stock s where i.item_id=s.item_id`
    );
    check from ItemRecord item in resultStream
        do {
            Catalog catalog = ({
                itemID: item.itemID,
                itemName: item.itemName,
                itemDesc: item.itemDesc,
                itemImage: item.itemImage,
                price: item.price,
                stockDetails: {
                    includes: item.includes,
                    intendedFor: item.intendedFor,
                    color: item.color,
                    material: item.material
                }
            });
            catalogs.push(catalog);
        };
    check resultStream.close();
    return catalogs;
}
