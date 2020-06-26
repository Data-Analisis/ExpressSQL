/************************************
Begin sp_helpme tests
*************************************/

--Clean Class
EXEC tSQLt.DropClass 'testsphelpme';
GO

EXEC tSQLT.NewTestClass 'testsphelpme';
GO

/*
test that sp_sizeoptimiser exists
*/
CREATE PROCEDURE testsphelpme.[test sp_helpme exists]
AS
BEGIN

--Assert
EXEC tSQLt.AssertObjectExists @objectName = 'dbo.sp_helpme', @message = 'Stored procedure sp_helpme does not exist.';

END;
GO

/*
test that sp_helpme errors on non-existant object
*/
CREATE PROCEDURE testsphelpme.[test sp_helpme errors for missing object]
AS
BEGIN

--Build
DECLARE @Table SYSNAME = 'dbo.IDontExist';

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = N'The object ''dbo.IDontExist'' does not exist in database ''tSQLt'' or is invalid for this operation.', @ExpectedSeverity = 16, @ExpectedState = 1, @ExpectedErrorNumber = 15009
EXEC [sp_helpme] @Table;

END;
GO

/*
test that sp_helpme does not fail for object that exists
*/
CREATE PROCEDURE testsphelpme.[test sp_helpme does not error for object that exists]
AS
BEGIN

--Build
--Assume tSQLt's table tSQLt.CaptureOutputLog always exists
DECLARE @Table SYSNAME = 'tSQLt.CaptureOutputLog';
DECLARE @cmd NVARCHAR(MAX) = N'EXEC [sp_helpme] ''' + @Table + ''';';

--Assert
EXEC tSQLt.ExpectNoException;
EXEC tSQLt.ResultSetFilter 0, @cmd; --Still runs but suppresses undesired output

END;
GO

/*
test first result set of sp_helpme for a table
*/
CREATE PROCEDURE testsphelpme.[test sp_helpme first result for table]
AS
BEGIN

--Build
--Assume tSQLt's table tSQLt.CaptureOutputLog always exists
DECLARE @Table SYSNAME = 'tSQLt.CaptureOutputLog';
DECLARE @epname SYSNAME = 'Description';
DECLARE @cmd NVARCHAR(MAX) = N'EXEC [sp_helpme] ''' + @Table + ''', ''' + @epname + ''';';

CREATE TABLE #Expected  (
	[name] SYSNAME NOT NULL
	,[owner] NVARCHAR(20) NOT NULL
	,[object_type] NVARCHAR(100) NOT NULL
	,[create_datetime] DATETIME NOT NULL
	,[modify_datetime] DATETIME NOT NULL
	,[ExtendedProperty] SQL_VARIANT NULL
)

INSERT INTO #Expected
SELECT
	[Name]					= o.name,
	[Owner]					= user_name(ObjectProperty(object_id, 'ownerid')),
	[Type]					= substring(v.name,5,31),
	[Created_datetime]		= o.create_date,
	[Modify_datetime]		= o.modify_date,
	[ExtendedProperty]		= ep.[value]
FROM sys.all_objects o
	INNER JOIN master.dbo.spt_values v ON o.type = substring(v.name,1,2) collate DATABASE_DEFAULT
	LEFT JOIN sys.extended_properties ep ON ep.major_id = o.[object_id]
		AND ep.[name] = @epname
		AND ep.minor_id = 0
		AND ep.class = 1 
WHERE v.type = 'O9T'
	AND o.name = 'CaptureOutputLog';

CREATE TABLE #Actual  (
	[name] SYSNAME NOT NULL
	,[owner] NVARCHAR(20) NOT NULL
	,[object_type] NVARCHAR(100) NOT NULL
	,[create_datetime] DATETIME NOT NULL
	,[modify_datetime] DATETIME NOT NULL
	,[ExtendedProperty] SQL_VARIANT NULL
)
INSERT INTO #Actual
EXEC tSQLt.ResultSetFilter 1, @cmd;

--Assert
EXEC tSQLt.AssertEqualsTable #Expected, #Actual;

END;
GO

/************************************
End sp_helpme tests
*************************************/