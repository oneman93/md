-- Find duplicate rows using ROW_NUMBER()
-- This query shows which rows are duplicates (ROW_NUM > 1)

SELECT 
    Student_ID,
    Course_Code,
    Term_Code,
    Enrolment_Name,
    ASP_ASP_Level_Group,
    DateCreated,
    Inactive,
    InactiveReason,
    ROW_NUMBER() OVER (
        PARTITION BY Student_ID, Course_Code, Term_Code, Enrolment_Name 
        ORDER BY DateCreated ASC  -- Keep the earliest record, remove later duplicates
    ) AS RowNum
FROM [QA].[ASP_data]
ORDER BY Student_ID, Course_Code, Term_Code, Enrolment_Name, DateCreated;

-- To see only the duplicates (rows that will be deleted):
SELECT *
FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY Student_ID, Course_Code, Term_Code, Enrolment_Name 
            ORDER BY DateCreated ASC
        ) AS RowNum
    FROM [QA].[ASP_data]
) AS Ranked
WHERE RowNum > 1;  -- These are the duplicate rows to delete

-- To delete duplicates (keeping the earliest record based on DateCreated):
DELETE FROM [QA].[ASP_data]
WHERE EXISTS (
    SELECT 1
    FROM (
        SELECT 
            Student_ID,
            Course_Code,
            Term_Code,
            Enrolment_Name,
            DateCreated,
            ROW_NUMBER() OVER (
                PARTITION BY Student_ID, Course_Code, Term_Code, Enrolment_Name 
                ORDER BY DateCreated ASC
            ) AS RowNum
        FROM [QA].[ASP_data]
    ) AS Ranked
    WHERE Ranked.RowNum > 1
    AND Ranked.Student_ID = [QA].[ASP_data].Student_ID
    AND Ranked.Course_Code = [QA].[ASP_data].Course_Code
    AND Ranked.Term_Code = [QA].[ASP_data].Term_Code
    AND Ranked.Enrolment_Name = [QA].[ASP_data].Enrolment_Name
    AND Ranked.DateCreated = [QA].[ASP_data].DateCreated
);

-- Alternative: Using CTE (Common Table Expression) - cleaner approach
WITH RankedData AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY Student_ID, Course_Code, Term_Code, Enrolment_Name 
            ORDER BY DateCreated ASC
        ) AS RowNum
    FROM [QA].[ASP_data]
)
DELETE FROM RankedData
WHERE RowNum > 1;

-- If you want to keep the LATEST record instead (remove older duplicates):
-- Change ORDER BY DateCreated ASC to ORDER BY DateCreated DESC in the ROW_NUMBER() function

