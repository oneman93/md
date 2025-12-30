-- SQL Server function to extract DIPTT20 code from string format: "Name-Number-Code-Number"
-- Example: "Alarna Currey-256070-DIPTT20-O1" returns "DIPTT20"

-- Option 1: Using STRING_SPLIT with ordinal (SQL Server 2022+)
-- This is the most reliable method if you're on SQL Server 2022 or later
CREATE OR ALTER FUNCTION dbo.fnGetDIPTT20(@inputString NVARCHAR(MAX))
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @result NVARCHAR(100) = NULL;
    
    IF @inputString IS NOT NULL AND LEN(@inputString) > 0
    BEGIN
        -- Use STRING_SPLIT with ordinal enabled (SQL Server 2022+)
        SELECT @result = value
        FROM STRING_SPLIT(@inputString, '-', 1)  -- Third parameter enables ordinal
        WHERE ordinal = 3;  -- Get 3rd segment (1-indexed)
    END
    
    RETURN @result;
END;
GO

-- Option 1b: Using STRING_SPLIT without ordinal (SQL Server 2016-2019)
-- WARNING: STRING_SPLIT doesn't guarantee order in SQL Server 2016-2019
-- This version removes TOP and uses only OFFSET/FETCH, but order is not guaranteed
CREATE OR ALTER FUNCTION dbo.fnGetDIPTT20_StringSplit(@inputString NVARCHAR(MAX))
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @result NVARCHAR(100) = NULL;
    
    IF @inputString IS NOT NULL AND LEN(@inputString) > 0
    BEGIN
        -- Removed TOP 1 - can't use TOP with OFFSET
        SELECT @result = value
        FROM STRING_SPLIT(@inputString, '-')
        ORDER BY (SELECT NULL)  -- Note: Doesn't guarantee order in SQL Server 2016-2019
        OFFSET 2 ROWS FETCH NEXT 1 ROW ONLY;  -- Get 3rd segment (0-indexed: 2)
    END
    
    RETURN @result;
END;
GO

-- Option 2: Using traditional string parsing (works on older SQL Server versions)
CREATE OR ALTER FUNCTION dbo.fnGetDIPTT20_Compat(@inputString NVARCHAR(MAX))
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @result NVARCHAR(100) = NULL;
    DECLARE @firstDash INT;
    DECLARE @secondDash INT;
    DECLARE @thirdDash INT;
    
    IF @inputString IS NOT NULL AND LEN(@inputString) > 0
    BEGIN
        -- Find positions of dashes
        SET @firstDash = CHARINDEX('-', @inputString);
        SET @secondDash = CHARINDEX('-', @inputString, @firstDash + 1);
        SET @thirdDash = CHARINDEX('-', @inputString, @secondDash + 1);
        
        -- Extract the third segment (between 2nd and 3rd dash)
        IF @secondDash > 0 AND @thirdDash > 0
        BEGIN
            SET @result = SUBSTRING(@inputString, @secondDash + 1, @thirdDash - @secondDash - 1);
        END
        ELSE IF @secondDash > 0
        BEGIN
            -- If there's no third dash, get from 2nd dash to end
            SET @result = SUBSTRING(@inputString, @secondDash + 1, LEN(@inputString) - @secondDash);
        END
    END
    
    RETURN @result;
END;
GO

-- Usage examples:
-- SELECT dbo.fnGetDIPTT20('Alarna Currey-256070-DIPTT20-O1');  -- Returns: DIPTT20
-- SELECT dbo.fnGetDIPTT20_Compat('Alarna Currey-256070-DIPTT20-O1');  -- Returns: DIPTT20

-- Test cases:
/*
SELECT 
    dbo.fnGetDIPTT20('Alarna Currey-256070-DIPTT20-O1') AS Result1,
    dbo.fnGetDIPTT20('John Doe-123456-ABCDEF-X2') AS Result2,
    dbo.fnGetDIPTT20('Test-111-CODE-999') AS Result3;
*/

