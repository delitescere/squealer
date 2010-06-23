# Squealer

## Usage
See lib/example_squeal.rb for the example squeal.

To run standalone, simply make your data squeal thusly:

`ruby example_squeal.rb`

where the squeal script includes a `require 'squealer'`.

## Rationale
* For some reason cranky old data guys think there exists no other than the relational theory for modelling data
* Josh Graham is crankier and in many cases older (although much better looking) than your cranky old DBA, so he remembers when RDBMS were not prolific, and one had to construct queries that explicitly traversed the network or hierarchical databases of the time (or even the indexed file systems). CODASYL, can you spell it?
* Although many business problems are best expressed in terms of a spreadsheet (a tuple space), and despite the somewhat disturbing fact that the majority of the world's critical commercial systems hinge on Excel spreadsheets, not every problem is best modelled this way
* MongoDB (along with a growing number of other noSQL == "not only SQL" databases) provides an alternate mechanism to store data in a way that naturally reflects the real-world problem. Simpler application code, higher performance and straight-forward scalabiltity are natural benefits of modelling in a way that most closely reflects reality
* At the inaugural QCon San Francisco in a discussion with Martin Fowler and Ola Bini, Josh postulated that ORMs had it the wrong way around: that the application should be persisting its data in a manner natural to it, and that external systems (like reporting and decision support systems - or even numbskull integration at the persistence layer) should bear the cost of mapping. With the huge efforts put into noSQL engines like MongoDB, neo4j, Redis, Hadoop, CouchDB, Memcached, et cetera, has come a rise in popularity. With this increased and broader usage comes people who are looking for tools to make these data stores more accessible. The application is no longer bearing the cost of mapping - it's now time for the ancillary and external systems to pick up the bill!
* squealer provides a simple, declarative language for mapping values from trees into relations. It is inherently flexibile by being an internal Ruby DSL, so any imperative traversal or mapping logic can be expressed
* It can be used both in bulk operations on many documents (e.g. a periodic batch job) or executed for one document asynchronously as part of an after_save method (e.g. via a Resque job). It is possible that more work may done on this event-driven approach, perhaps in the form of a squealerd, to reduce latency.

## Release Notes
### v2.2
* Adds support for PostgreSQL database as an export target
* Uses EXPORT_DBMS environment variable to specify database adapter
 * EXPORT_DMBS=mysql
 * EXPORT_DBMS=postgres
 * MySQL is default if not specified
* Switched to using DataMapper's DataObjects SQL wrapper
* Removed the need for some typecasting and export schema restrictions (e.g. true/false maps to whatever is idiomatic for the specified DBMS)
* NB: The pg gem for PostgreSQL segfaults on Ruby 1.8.7-p249 so we've reverted to supporting up to 1.8.7-p174

### v2.1
* Ruby 1.8.6 back-compatibility added. Using `eval "", binding, __FILE__, __LINE__` instead of `binding.eval`
* Target SQL script using backtick-quoted (MySQL) identifiers to avoid column-name / keyword conflict
* Automatically typecast Ruby `Boolean` (to integer), `Symbol` (to string), `Array` (to comma-seperated string)
* Improved handling and reporting of Target SQL errors
* Schaefer's Special "skewer" Script to reflect on Mongoid models and generate an initial squeal script and SQL schema DDL script. This tool is intended to build the _initial_ scripts only. It is extremely useful to get you going, but do think about the needs of the consumer of the export database, and adjust the scripts to suit. [How do you make something squeal? You skewer it!]

### v2.0
* `Object#import` now wraps a MongoDB cursor to provide counters and timings. Only `each` is supported for now, however `source` takes optional conditions.
* Progress bar and summary.

### v1.2.1
* `Object#import` syntax has changed. Now `import.source(collection).each` rather than `import.collection(collection).find({}).each`. `source` returns a MongoDB cursor like `find` does. See lib/example_squeal.rb for options.

### v1.2
* `Object#target` verifies there is a variable in scope with the same name as the `table_name` being targetted, it must be a `Hash` and must have an `_id` key
* Block to `Object#assign` not required, infers value from source scope
* A block returning `nil` now uses `nil` as the value to `Object#assign`, rather than inferring value from source scope

## Warning
Squealer is for _standalone_ operation. DO NOT use it directly from within your Ruby application. To make the DSL easy to use, we alter some core types:

* `Hash#method_missing` - You prefer dot notation. JSON uses dot notation. You are importing from a data store which represents collections as arrays of hashmaps. Dot notation for navigating those collections is convenient. If you use a field name that happens to be a method on Hash you will have to use index notation. (e.g. `kitten.toys` is good, however `kitten.freeze` is not good. Use `kitten['freeze']` instead.)
* `NilClass#each` - As you are importing from schemaless repositories and you may be trying to iterate on fields that contain embedded collections, if a specific parent does not contain one of those child collections, the driver will be returning `nil` as the value for that field. Having `NilClass#each` return a `[]` for a nil is convenient, semantically correct in this context, and removes the need for many `nil` checks in the block you provide to `Object#assign`
* `Object` - `#import`, `#export`, `#target`, and `#assign` "keywords" are provided for convenience
* You need to remember that all temporal data (date, time, datetime, timestamp, whatever) are all converted to a full UTC date and time. This means that if you want to use the simple assign expression (with no block), the target column must be defined as a SQL type that can automatically accept a full date and time. If you just want to store the date or time portion, or do any other manipulation, you must use a block to convert the source value. 

## It is a data mapper, it doesn't use one.
Squealer doesn't use your application classes. It doesn't use your ActiveRecord models. It doesn't use mongoid (as awesome as that is), mongodoc, or mongomapper. It's an ETL tool. It could even be called a HRM (Hashmap-Relational-Mapper), but only in hushed tones in the corner boothes of dark pubs. It directly uses the Ruby driver for MongoDB and the Ruby driver for MySQL.

## Databases supported
For now, this is specifically for importing _MongoDB_ documents and exporting to either _MySQL_ or _PostgreSQL_.

## Notes
Tested on Ruby 1.8.7(-p174) and Ruby 1.9.1(-p378)

The target SQL database _must_ have no foreign keys (because it can't rely on the primary key values and referential integrity is the responsibility of the source data store or the application that uses it).

The target SQL database must use a primary key of `CHAR(24)`. For now, we've assumed that column name is `id`. Each record's `id` value will get the source document `_id` value. There are some plans to make this more flexible. If you are actively requiring this, let Josh know.

It is assumed the target data will be quite denormalized - particularly that the hierarchy keys for embedded documents are flattened. This means that a document from `office.room.box` will be exported to a record containing the `id` for `office`, the `id` for `room` and the `id` for `box`.

It is assumed no indexes are present in the target database table (performance drag). You may want to create indexes for pulling data out of the database Squealer exports to. Run a SQL DDL script on your MySQL database after squealing to add the indexes. You should drop the indexes before squealing again.

The target row is inserted, or updated if present. When MySQL is the export DBMS, we are using it's non-standard `INSERT ... UPDATE ON DUPLICATE KEY` extended syntax to achieve this. For PostgreSQL, we use an UPDATE followed by an INSERT. Doing update-or-insert allows an idempotent event-driven update of exported data (e.g. through redis queues) as well as a bulk batch process.

## Copyright

Copyright © 2010 Joshua A Graham and authors.

## License

See [LICENSE](blob/master/LICENSE "License").

