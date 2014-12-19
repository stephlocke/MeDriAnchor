MeDriAnchor
===========

# MeDriAnchor
MeDriAnchor is the (Me)tadata (Dri)ven (Anchor) Model data warehouse system and 
is pronounced Me-Dry-Anchor. 

It extends the open source framework Anchor Model to allow the production of the
datawarehouse without using the GUI and also develops and executes the ETL needed
to load data from source systems into the Anchor modelled datawarehouse.

## How does it work?
* You have a control database, MeDriAnchor, which you insert metadata into. 
* Stored procedures convert the metadata into an XML Anchor schema
* The XML schema is sent to the Sisulator.js which returns a SQL representation
* The SQL schema is then deployed to the database
* Stored procedures produce the stored procedures for the ETL
* The ETL procedures are then executed

## What controls are there?
* Using the SQL ToDoc framework, shadow tables exist that contain all previous 
versions of records for full audit trail of metadata changes
* There is full logging of the process so that each statement that is executed is known
* By dint of the Anchor Model system, any loaded values can be date stamped
* Data quality is important, so tests can be applied to incoming data

## How does it perform?
* Anchor model datawarehouses are generally well performing on SQL Server due to
materialised joins
* There is some overhead when changes to the schema have to be made but the overall
impact is quite minimal unless you are making schema extensions every load
* The stored procs are all standardised and written with incremental load performance in mind
* The atomic nature of the model means that parallelisation is possible within types
