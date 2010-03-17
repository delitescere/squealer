# Squealer

For now, this is specifically for MongoDB exporting to mySQL with the assumption that the data will be heavily denormalized.

The target SQL database must have no foreign keys.

The target SQL database must use a primary key of char(16) with value of the MongoDB id.

It is assumed no indexes are present in the target database table.

The target row is inserted, or updated if present. We are using MySQL INSERT ... UPDATE ON DUPLICATE KEY extended syntax to achieve this for now. This allows an event-driven update of exported data as well as a bulk batch process.


