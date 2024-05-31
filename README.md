# find-all-sql
## An MS SQL code to search all tables for a value

When you are tasked to query a third party database that is poorly documented and does not have
foreign key references in place, it is difficult and very time consuming to reverse engineer the logical
connections between tables and columns. Frequently you resort to "poking" around hundreds of tables trying to
see if a value of a key exists. Right now I'm dealing with an EHR system that has thousands of 19487 MS SQL tables
with no foreign key references.

I have created a simple SQL script that allows me to go through all 19487 tables and see which tables have a value that I'm looking for.
Most of the columns that reference other tables end with "ID" - that allows to limit the number of queries to something reasonable.
If the number of tables is significantly lower, it is possible to search for all values of all columns.

Here is the script:

```SQL
DECLARE @SqlCodeCount AS NVARCHAR(1024);
DECLARE @SqlCodeFind AS NVARCHAR(1024);
DECLARE @CountOutValue AS INT;

DECLARE "Query" CURSOR FAST_FORWARD FOR
SELECT
	'SELECT @count_out = COUNT(*) FROM ' + TABLE_NAME + ' WHERE ' + COLUMN_NAME + ' = ''Value''',
	'SELECT * FROM ' + TABLE_NAME + ' WHERE ' + COLUMN_NAME + ' = ''Value'''
FROM
	INFORMATION_SCHEMA.COLUMNS
WHERE
	TABLE_NAME NOT LIKE 'Ignore%' AND
	COLUMN_NAME LIKE '%ID' AND
	DATA_TYPE LIKE '%char'
ORDER BY
	TABLE_NAME, COLUMN_NAME
;

OPEN "Query";
FETCH "Query" INTO @SqlCodeCount, @SqlCodeFind;

	WHILE @@FETCH_STATUS = 0
		BEGIN
			EXECUTE sp_executesql @SqlCodeCount, N'@count_out INT OUTPUT', @count_out = @CountOutValue OUTPUT;
			IF @CountOutValue > 0 BEGIN
				SELECT @SqlCodeFind;
				EXECUTE sp_executesql @SqlCodeFind;
			END;
			FETCH "Query" INTO @SqlCodeCount, @SqlCodeFind;
		END

CLOSE "Query";
DEALLOCATE "Query";
```

First, we create a query that finds all columns that end with "ID" in all tables that we do not wish to ignore (TABLE_NAME NOT LIKE).
The query uses simple string concatenation to dynamically create to queries - one to count all matching records in a table and the second
one to find the matching records. We use a cursor to go through the result of that query and for each row we execute the first dynamically created query
that counts matching records. If the result of the count is not zero, we execute the second query to find the matching records.

After running this script we end up with the list of only matching tables and records from the whole database.
