# Squealer

## Warning
Squealer is for standalone operation. Do not use it from within your application. To make the DSL easy to use, we alter `Hash`, `NilClass`, `Object`, and `Time`.

* `Hash#method_missing` - You prefer dot notation. JSON uses dot notation. You are importing from a data store which represents collections as arrays of hashmaps. Dot notation for navigating those collections is convenient. If you use a field name that happens to be a method on Hash you will have to use index notation. (e.g. `kitten.toys` is good, however `kitten.freeze` is not good. Use `kitten['freeze']` instead.)
* `NilClass#each` - As you are importing from schemaless repositories and you may be trying to iterate on fields that contain embedded collections, if a specific parent does not contain one of those child collections, the driver will be returning "nil" as the value for that field. Having `NilClass#each` return a `[]` for a nil is convenient, semantically correct in this context, and removes the need for many nil checks in the block you provide to `Object#assign`
* `Object` - `#import`, `#export`, `#target`, and `#assign` "keywords" are provided for convenience
* `Time#to_s` - As you are exporting to a SQL database, we represent your timestamp in a format that it will parse unequivocally (mongodb stores all temporal data as a timestamp)

To run standalone, simply make your data squeal thusly:

`ruby example_squeal.rb`

where the squeal script requires 'squealer'.

Squealer doesn't use your application classes. It doesn't use your ActiveRecord models. It's an ETL tool. It could even be called a HRM (Hashmap-Relational-Mapper), but only in hushed tones in the corner boothes of dark pubs.

## Databases supported
For now, this is specifically for _MongoDB_ exporting to _mySQL_ with the assumption that the data will be heavily denormalized - particularly that the hierarchy keys for embedded documents are flattened. This means that a document from `office.room.box` will be exported to a record containing the `id` for `office`, the `id` for `room` and the `id` for `box`.

## Notes
The target SQL database must have no foreign keys (because it can't rely on the primary key values and referential integrity is the responsibility of the source data store or the application that uses it).

The target SQL database must use a primary key of char(16) with value of the MongoDB id.

It is assumed no indexes are present in the target database table (performance drag). You may want to create indexes for pulling data out of the database Squealer exports to. You should drop them again when you've done the pull.

The target row is inserted, or updated if present. We are using MySQL `INSERT ... UPDATE ON DUPLICATE KEY` extended syntax to achieve this for now. This allows an event-driven update of exported data as well as a bulk batch process.

