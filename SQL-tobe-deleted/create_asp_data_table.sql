-- Drop table if exists and create ASP_data table
IF OBJECT_ID('QA.ASP_data', 'U') IS NOT NULL
    DROP TABLE [QA].[ASP_data];
GO

CREATE TABLE [QA].[ASP_data](
	[Student_ID] [varchar](50) NULL,
	[Course_Code] [varchar](200) NULL,
	[Term_Code] [varchar](50) NULL,
	[Enrolment_Name] [varchar](500) NULL,
	[ASP_ASP_Level_Group] [varchar](50) NULL,
	[DateCreated] [datetime] NULL,
	[Inactive] [bit] NULL,
	[InactiveReason] [varchar](200) NULL
) ON [PRIMARY];
GO

