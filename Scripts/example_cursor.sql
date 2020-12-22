USE AdventureWorks2017
GO
-- a cursor let us make a loop into data result of a select
DECLARE Employee_cursor CURSOR FOR
  SELECT BusinessEntityID,JobTitle
  FROM AdventureWorks2017.HumanResources.Employee;
OPEN Employee_cursor; -- like an index but in memory
FETCH NEXT FROM Employee_cursor;
WHILE @@FETCH_STATUS = 0
	BEGIN
		FETCH NEXT FROM Employee_cursor;
	END
CLOSE Employee_cursor;
DEALLOCATE Employee_cursor;
GO

-- Each loop
--BusinessEntityID	JobTitle
--1					Chief Executive Officer

--BusinessEntityID	JobTitle
--2					Vice President of Engineering
