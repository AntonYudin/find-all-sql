
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

