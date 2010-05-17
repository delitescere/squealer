# Squealer

## Usage
See lib/example_squeal.rb for the example squeal.

To run standalone, simply make your data squeal thusly:

`ruby example_squeal.rb`

where the squeal script includes a `require 'squealer'`.

## Warning
Squealer is for _standalone_ operation. DO NOT use it directly from within your Ruby application. To make the DSL easy to use, we alter some core types:

* `FalseClass#to_i` - You'll be storing booleans as a `tinyint(1)`, or similar. `false` is `0`.
* `Hash#method_missing` - You prefer dot notation. JSON uses dot notation. You are importing from a data store which represents collections as arrays of hashmaps. Dot notation for navigating those collections is convenient. If you use a field name that happens to be a method on Hash you will have to use index notation. (e.g. `kitten.toys` is good, however `kitten.freeze` is not good. Use `kitten['freeze']` instead.)
* `NilClass#each` - As you are importing from schemaless repositories and you may be trying to iterate on fields that contain embedded collections, if a specific parent does not contain one of those child collections, the driver will be returning `nil` as the value for that field. Having `NilClass#each` return a `[]` for a nil is convenient, semantically correct in this context, and removes the need for many `nil` checks in the block you provide to `Object#assign`
* `Object` - `#import`, `#export`, `#target`, and `#assign` "keywords" are provided for convenience
* `Time#to_s` - As you are exporting to a SQL database, we represent your timestamp in a format that it will parse unequivocally (MongoDB stores all temporal data as a timestamp)
* `TrueClass#to_i` - You'll be storing booleans as a `tinyint(1)`, or similar. `true` is `1`.

## It is a data mapper, it doesn't use one.
Squealer doesn't use your application classes. It doesn't use your ActiveRecord models. It doesn't use mongoid (as awesome as that is), or mongomapper. It's an ETL tool. It could even be called a HRM (Hashmap-Relational-Mapper), but only in hushed tones in the corner boothes of dark pubs. It directly uses the Ruby driver for MongoDB and the Ruby driver for mySQL.

## Databases supported
For now, this is specifically for _MongoDB_ exporting to _mySQL_.

## Deprecation Warning
Since version 1.1, the primary key value is inferred from the source document `_id` field based on the `Object#target` `table_name` argument matching the name of a variable holding the source document, `row_id` is no longer a parameter on `Object#target`. It will be invalid in version 1.3 and above.

## Notes
The target SQL database _must_ have no foreign keys (because it can't rely on the primary key values and referential integrity is the responsibility of the source data store or the application that uses it).

The target SQL database must use a primary key of `char(24)`. For now, we've assumed that column name is `id`. Each record's `id` value will get the source document `_id` value.

It is assumed the target data will be quite denormalized - particularly that the hierarchy keys for embedded documents are flattened. This means that a document from `office.room.box` will be exported to a record containing the `id` for `office`, the `id` for `room` and the `id` for `box`.

It is assumed no indexes are present in the target database table (performance drag). You may want to create indexes for pulling data out of the database Squealer exports to. Run a SQL DDL script on your mySQL database after squealing to add the indexes. You should drop the indexes before squealing again.

The target row is inserted, or updated if present. We are using MySQL `INSERT ... UPDATE ON DUPLICATE KEY` extended syntax to achieve this for now. This allows an event-driven update of exported data (e.g. through redis queues) as well as a bulk batch process.

