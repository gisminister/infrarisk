/*
NOTE: Create a fresh database first and change the name in the first line of this script
To create the database, simply run the following command:
CREATE database cmrGeo2
GO
*/

USE cmrGeo2 --THIS DATABASE MUST EXIST, if not the script will be executed in the database you are currently sitting in...
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

print 'Dropping all tables prefixed with cmrT_, views prefixed with cmrV_ and SPs prefixed witn cmrSP_...'
GO
/********************************************************
--Drop all relevant database objects
*********************************************************/
declare @n char(1)
set @n = char(10)
declare @stmt nvarchar(max)

-- sps the are prefixed cmrSP_
select @stmt = isnull( @stmt + @n, '' ) +
    'drop procedure [' + schema_name(schema_id) + '].[' + name + ']'
from sys.procedures
where name LIKE 'cmrSP[_]%'

-- views the are prefixed cmrV_
select @stmt = isnull( @stmt + @n, '' ) +
    'drop view [' + schema_name(schema_id) + '].[' + name + ']'
from sys.views
where name LIKE 'cmrV[_]%'

-- foreign keys on tables that are prefixed cmrT_
select @stmt = isnull( @stmt + @n, '' ) +
    'alter table [' + schema_name(schema_id) + '].[' + object_name( parent_object_id ) + '] drop constraint [' + name + ']'
from sys.foreign_keys
where object_name( parent_object_id ) LIKE 'cmrT[_]%'

-- tables
select @stmt = isnull( @stmt + @n, '' ) +
    'drop table [' + schema_name(schema_id) + '].[' + name + ']'
from sys.tables
where name LIKE 'cmrT[_]%'

/*EXECUTE THE STATEMENT*/
exec sp_executesql @stmt

print 'Creating cmr tables'
GO
/********************************************************
--CREATE Level 0 objects
*********************************************************/
--Create and populate a Tally table with numbers 1 to 1000
SET NOCOUNT ON
SELECT TOP 1000 IDENTITY(INT,1,1) AS N
INTO dbo.cmrT_Tally
FROM Master.dbo.SysColumns sc1,
	Master.dbo.SysColumns sc2
--Add a Primary Key to maximize performance
ALTER TABLE dbo.cmrT_Tally
ADD CONSTRAINT PK_cmrT_Tally
PRIMARY KEY CLUSTERED (N) WITH FILLFACTOR = 100
GO
SET NOCOUNT OFF

/****** Object:  Table [dbo].[cmrT_ImportIntersectionTable] ******/
CREATE TABLE [dbo].[cmrT_ImportIntersectionTable](
	[OBJECTID] [int] NOT NULL,
	[study_id] [int] NOT NULL,
	[element_feature_id] [int] NOT NULL,
	[elementtype_code] [char](10) NOT NULL,
	[route_code] [char](10) NULL,
	[aadt_passenger] [int] NULL,
	[aadt_goods] [int] NULL,
	[diversion_time] [numeric](38, 8) NULL,
	[hazardzone_feature_id] [int] NOT NULL,
	[processtype_id] [int] NULL,
	[event_frequency] [int] NULL,
	[freq_interval_plus] [int] NULL,
	[freq_interval_minus] [int] NULL,
	[element_size] [numeric](38, 8) NOT NULL
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[cmrT_ProcessType] ******/
CREATE TABLE [dbo].[cmrT_ProcessType](
	[processtype_id] [int] NOT NULL,
	[processtype_name] [varchar](64) NOT NULL,
	[magnitude_unit] [varchar](24) NULL,
	[event_width] [decimal](38,8) NULL,
	[frequency_size_factor] [decimal](38,8) NULL,
	[event_cooccurrence_factor] [decimal](38,8) NULL,
 CONSTRAINT [PK_cmrT_ProcessType] PRIMARY KEY CLUSTERED 
(
	[processtype_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level2type=N'COLUMN'
	, @level1name=N'cmrT_ProcessType'
	, @level2name=N'event_width'
	, @value=N'If not NULL then this field defines a fixed width for events of the given processtype'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level2type=N'COLUMN'
	, @level1name=N'cmrT_ProcessType'
	, @level2name=N'frequency_size_factor'
	, @value=N'If not NULL then event frequency is multiplied by (element size * factor)'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level2type=N'COLUMN'
	, @level1name=N'cmrT_ProcessType'
	, @level2name=N'event_cooccurrence_factor'
	, @value=N'A value that describes probability of event coocccurrence within hazard zone'
GO

/****** Object:  Table [dbo].[cmrT_StudyArea] ******/
CREATE TABLE [dbo].[cmrT_StudyArea](
	[study_id] [int] IDENTITY(100,1) NOT NULL,
	[study_name] [varchar](50) NOT NULL,
	[study_description] [varchar](512) NULL,
	[hazardzone_dataset_filepath] [nvarchar](4000) NULL,
	[element_dataset_filepath] [nvarchar](4000) NULL,
 CONSTRAINT [PK_cmrT_StudyArea] PRIMARY KEY CLUSTERED 
(
	[study_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[cmrT_ElementCategory] ******/
CREATE TABLE [dbo].[cmrT_ElementCategory](
	[elementcategory_id] [int] NOT NULL,
	[elementcategory_name] [varchar](50) NOT NULL,
CONSTRAINT [PK_cmrT_ElementCategory] PRIMARY KEY CLUSTERED 
(
	[elementcategory_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[cmrT_ValueTypeCalculation] ******/
CREATE TABLE [dbo].[cmrT_ValueTypeCalculation](
	[valuetype_calculation_id] [int] NOT NULL,
	[valuetype_calculation_name] [varchar](50) NOT NULL,
	[use_element_event_frequency] [bit] NULL,
	[use_route_event_frequency] [bit] NULL,
	[use_element_impact_size] [bit] NULL,
	[use_aadt_passenger] [bit] NULL,
	[use_aadt_goods] [bit] NULL,
	[use_diversion_time] [bit] NULL,
 CONSTRAINT [PK_cmrT_ValueTypeCalculation] PRIMARY KEY CLUSTERED 
(
	[valuetype_calculation_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[cmrT_ValueTypeCategory] ******/
CREATE TABLE [dbo].[cmrT_ValueTypeCategory](
	[valuetype_category_id] [int] NOT NULL,
	[valuetype_category_name] [varchar](24) NOT NULL,
	[valuetype_category_unit] [varchar](16) NOT NULL,
 CONSTRAINT [PK_cmrT_ValueTypeCategory] PRIMARY KEY CLUSTERED 
(
	[valuetype_category_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/********************************************************
--CREATE Level 1 objects
*********************************************************/
/****** Object:  Table [dbo].[cmrT_ElementType] ******/
CREATE TABLE [dbo].[cmrT_ElementType](
	[elementtype_id] [int] NOT NULL,
	[elementtype_code] [char](10) NOT NULL,
	[elementtype_name] [varchar](64) NOT NULL,
	[elementcategory_id] [int] NOT NULL,
CONSTRAINT [PK_cmrT_ElementType] PRIMARY KEY CLUSTERED 
(
	[elementtype_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[cmrT_ValueType] *****/
CREATE TABLE [dbo].[cmrT_ValueType](
	[valuetype_id] [int] IDENTITY(1,1) NOT NULL,
	[valuetype_name] [varchar](50) NOT NULL,
	[valuetype_calculation_id] int NOT NULL,
	[valuetype_category_id] int NOT NULL,
	[valuetype_description] [varchar](512) NOT NULL,
CONSTRAINT [PK_cmrT_ValueType] PRIMARY KEY CLUSTERED 
(
	[valuetype_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/********************************************************
--CREATE Level 2 objects
*********************************************************/
/****** Object:  Table [dbo].[cmrT_Element] ******/
CREATE TABLE [dbo].[cmrT_Element](
	[element_id] [int] IDENTITY(1,1) NOT NULL,
	[study_id] [int] NOT NULL,
	[element_feature_id] [int] NOT NULL,
	[element_size] [decimal](38,8) NOT NULL,
	[elementtype_code] [char](10) NOT NULL,
	[route_code] [char](10) NULL,
	[aadt_passenger] [int] NOT NULL,
	[aadt_goods] [int] NOT NULL,
	[diversion_time] [decimal](38,8) NOT NULL,
 CONSTRAINT [PK_cmrT_Element] PRIMARY KEY CLUSTERED 
	(
		[element_id] ASC
	),
 CONSTRAINT [UC_cmrT_Element_StudyIdFeatureId] UNIQUE 
	(
		[study_id] ASC,
		[element_feature_id] ASC
	)
) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level2type=N'COLUMN'
	, @level1name=N'cmrT_Element'
	, @level2name=N'route_code'
	, @value=N'A route identifyer for calculation of closure costs'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level2type=N'COLUMN'
	, @level1name=N'cmrT_Element'
	, @level2name=N'aadt_passenger'
	, @value=N'Annual average daily passenger traffic (number of vehicles)'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level2type=N'COLUMN'
	, @level1name=N'cmrT_Element'
	, @level2name=N'aadt_goods'
	, @value=N'Annual average daily goods traffic (number of vehicles)'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level2type=N'COLUMN'
	, @level1name=N'cmrT_Element'
	, @level2name=N'diversion_time'
	, @value=N'Expected diversion time due to closure'
GO

/****** Object:  Table [dbo].[cmrT_HazardZone] ******/
CREATE TABLE [dbo].[cmrT_HazardZone](
	[hazardzone_id] [int] IDENTITY(1,1) NOT NULL,
	[study_id] [int] NOT NULL,
	[hazardzone_feature_id] [int] NOT NULL,
	[processtype_id] [int] NOT NULL,
	[event_frequency] [int] NOT NULL,
	[freq_error_interval_plus] [int] NOT NULL,
	[freq_error_interval_minus] [int] NOT NULL,
 CONSTRAINT [PK_cmrT_HazardZone] PRIMARY KEY CLUSTERED 
	(
		[hazardzone_id] ASC
	),
 CONSTRAINT [UC_cmrT_HazardZone_StudyIdFeatureId] UNIQUE 
	(
		[study_id] ASC,
		[hazardzone_feature_id] ASC
	)
) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level2type=N'COLUMN'
	, @level1name=N'cmrT_HazardZone'
	, @level2name=N'event_frequency'
	, @value=N'Frequency given as return period (100 for one event per 100 years)'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level2type=N'COLUMN'
	, @level1name=N'cmrT_HazardZone'
	, @level2name=N'freq_error_interval_plus'
	, @value=N'The positive uncertainty interval, e.g. 10 if frequency is 100 and uncertainty range is 80-110'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level2type=N'COLUMN'
	, @level1name=N'cmrT_HazardZone'
	, @level2name=N'freq_error_interval_minus'
	, @value=N'The negative uncertainty interval, e.g. 20 if frequency is 100 and uncertainty range is 80-110'
GO

/****** Object:  Table [dbo].[cmrT_ElementValue]    Script Date: 12/20/2012 13:07:55 ******/
CREATE TABLE [dbo].[cmrT_ElementValue](
	[elementtype_id] [int] NOT NULL,
	[valuetype_id] [int] NOT NULL,
	[value_mean] [decimal](38,8) NOT NULL,
	[value_PosErr] [decimal](38,8) NOT NULL,
	[value_NegErr] [decimal](38,8) NOT NULL,
	[note_field] [varchar](512) NULL,
 CONSTRAINT [PK_cmrT_ElementValue] PRIMARY KEY CLUSTERED 
(
	[elementtype_id] ASC,
	[valuetype_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[cmrT_DamageFunction] ******/
CREATE TABLE [dbo].[cmrT_DamageFunction](
	[processtype_id] [int] NOT NULL,
	[valuetype_id] [int] NOT NULL,
	[damage_prob] [decimal](38,8) DEFAULT 0 NOT NULL,
	[damage_max] [decimal](38,8) DEFAULT 0 NOT NULL,
	[damage_exponent] [decimal](38,8) DEFAULT 0 NOT NULL,
	[note_field] [varchar](512) NULL,
	[damage_avg]  AS (([damage_prob]*[damage_max])/([damage_exponent]+1.0)) PERSISTED,
 CONSTRAINT [PK_cmrT_DamageFunction] PRIMARY KEY CLUSTERED 
(
	[processtype_id] ASC,
	[valuetype_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level2type=N'COLUMN'
	, @level1name=N'cmrT_DamageFunction'
	, @level2name=N'damage_prob'
	, @value=N'The probability that an event of the given process type causes damage to the given value type (0-1)'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level2type=N'COLUMN'
	, @level1name=N'cmrT_DamageFunction'
	, @level2name=N'damage_max'
	, @value=N'The maximum damage an event of the given process type may cause to the given value type'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level2type=N'COLUMN'
	, @level1name=N'cmrT_DamageFunction'
	, @level2name=N'damage_exponent'
	, @value=N'The exponent (c) in a function with shape f(x) = ax^c where 0<=x<=1'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level2type=N'COLUMN'
	, @level1name=N'cmrT_DamageFunction'
	, @level2name=N'damage_avg'
	, @value=N'Calculated column with the average value of the damage function within the interval [damage_prob, 1]'
GO

/********************************************************
--CREATE Level 3 objects
*********************************************************/
/****** Object:  Table [dbo].[cmrT_ElementHazardZone]    Script Date: 12/20/2012 18:01:26 ******/
CREATE TABLE [dbo].[cmrT_ElementHazardZone](
	[element_id] [int] NOT NULL,
	[hazardzone_id] [int] NOT NULL,
 CONSTRAINT [PK_cmrT_ElementHazardZone] PRIMARY KEY CLUSTERED 
(
	[element_id] ASC,
	[hazardzone_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


/********************************************************
--CREATE Indices
*********************************************************/
print 'Creating table indices'
GO
CREATE NONCLUSTERED INDEX [IX_cmrT_Element_elementtype_code] ON [dbo].[cmrT_Element] 
	(
		[elementtype_code] ASC
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_cmrT_ElementType_elementtype_code ON [dbo].[cmrT_ElementType]
	(
		[elementtype_code] ASC
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_cmrT_Element_route_code ON [dbo].[cmrT_Element]
	(
		[route_code] ASC
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


/********************************************************
--CREATE Foreign keys
*********************************************************/
print 'Creating relationships (foreign keys)'
GO

ALTER TABLE [dbo].[cmrT_DamageFunction]  WITH CHECK ADD  CONSTRAINT [FK_cmrT_DamageFunction_cmrT_ProcessType] FOREIGN KEY([processtype_id])
REFERENCES [dbo].[cmrT_ProcessType] ([processtype_id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[cmrT_DamageFunction] CHECK CONSTRAINT [FK_cmrT_DamageFunction_cmrT_ProcessType]
GO

ALTER TABLE [dbo].[cmrT_DamageFunction]  WITH CHECK ADD  CONSTRAINT [FK_cmrT_DamageFunction_cmrT_ValueType] FOREIGN KEY([valuetype_id])
REFERENCES [dbo].[cmrT_ValueType] ([valuetype_id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[cmrT_DamageFunction] CHECK CONSTRAINT [FK_cmrT_DamageFunction_cmrT_ValueType]
GO

ALTER TABLE [dbo].[cmrT_Element]  WITH CHECK ADD  CONSTRAINT [FK_cmrT_Element_cmrT_StudyArea] FOREIGN KEY([study_id])
REFERENCES [dbo].[cmrT_StudyArea] ([study_id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[cmrT_Element] CHECK CONSTRAINT [FK_cmrT_Element_cmrT_StudyArea]
GO

ALTER TABLE [dbo].[cmrT_ElementHazardZone]  WITH CHECK ADD  CONSTRAINT [FK_cmrT_ElementHazardZone_cmrT_Element] FOREIGN KEY([element_id])
REFERENCES [dbo].[cmrT_Element] ([element_id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[cmrT_ElementHazardZone] CHECK CONSTRAINT [FK_cmrT_ElementHazardZone_cmrT_Element]
GO


ALTER TABLE [dbo].[cmrT_ElementHazardZone]  WITH CHECK ADD  CONSTRAINT [FK_cmrT_ElementHazardZone_cmrT_HazardZone] FOREIGN KEY([hazardzone_id])
REFERENCES [dbo].[cmrT_HazardZone] ([hazardzone_id])
GO
ALTER TABLE [dbo].[cmrT_ElementHazardZone] CHECK CONSTRAINT [FK_cmrT_ElementHazardZone_cmrT_HazardZone]
GO

ALTER TABLE [dbo].[cmrT_ElementType]  WITH CHECK ADD  CONSTRAINT [FK_cmrT_ElementType_cmrT_ElementCategory] FOREIGN KEY([elementcategory_id])
REFERENCES [dbo].[cmrT_ElementCategory] ([elementcategory_id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[cmrT_ElementType] CHECK CONSTRAINT [FK_cmrT_ElementType_cmrT_ElementCategory]
GO

ALTER TABLE [dbo].[cmrT_ElementValue]  WITH CHECK ADD  CONSTRAINT [FK_cmrT_ElementValue_cmrT_ElementType] FOREIGN KEY([elementtype_id])
REFERENCES [dbo].[cmrT_ElementType] ([elementtype_id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[cmrT_ElementValue] CHECK CONSTRAINT [FK_cmrT_ElementValue_cmrT_ElementType]
GO

ALTER TABLE [dbo].[cmrT_ElementValue]  WITH CHECK ADD  CONSTRAINT [FK_cmrT_ElementValue_cmrT_ValueType] FOREIGN KEY([valuetype_id])
REFERENCES [dbo].[cmrT_ValueType] ([valuetype_id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[cmrT_ElementValue] CHECK CONSTRAINT [FK_cmrT_ElementValue_cmrT_ValueType]
GO

ALTER TABLE [dbo].[cmrT_HazardZone]  WITH CHECK ADD  CONSTRAINT [FK_cmrT_HazardZone_cmrT_StudyArea] FOREIGN KEY([study_id])
REFERENCES [dbo].[cmrT_StudyArea] ([study_id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[cmrT_HazardZone] CHECK CONSTRAINT [FK_cmrT_HazardZone_cmrT_StudyArea]
GO

ALTER TABLE [dbo].[cmrT_ValueType]  WITH CHECK ADD  CONSTRAINT [FK_cmrT_ValueType_cmrT_ValueTypeCategory] FOREIGN KEY([valuetype_category_id])
REFERENCES [dbo].[cmrT_ValueTypeCategory] ([valuetype_category_id])
GO
ALTER TABLE [dbo].[cmrT_ValueType] CHECK CONSTRAINT [FK_cmrT_ValueType_cmrT_ValueTypeCategory]
GO

ALTER TABLE [dbo].[cmrT_ValueType]  WITH CHECK ADD  CONSTRAINT [FK_cmrT_ValueType_cmrT_ValueTypeCalculation] FOREIGN KEY([valuetype_calculation_id])
REFERENCES [dbo].[cmrT_ValueTypeCalculation] ([valuetype_calculation_id])
GO
ALTER TABLE [dbo].[cmrT_ValueType] CHECK CONSTRAINT [FK_cmrT_ValueType_cmrT_ValueTypeCalculation]
GO

/********************************************************
--CREATE Stored procedures
*********************************************************/
print 'Creating stored procedures'
GO
/****** Object:  StoredProcedure [dbo].[cmrSP_importResults]  ******/
CREATE PROCEDURE [dbo].[cmrSP_importResults]
	@study_id int
AS
	SET NOCOUNT ON

	DECLARE @retcode INT
	DECLARE @nrecords INT
	DECLARE @msg VARCHAR(255)
	
	DECLARE @results TABLE(retcode INT, [message] varchar(255))

	--Make sure the study id exists
	IF NOT EXISTS (SELECT * FROM cmrT_StudyArea WHERE study_id=@study_id)
		INSERT @results VALUES(1, 'No study area exist with id '+CAST(@study_id AS varchar(10)))
	IF NOT EXISTS (SELECT * FROM @results WHERE retcode > 0) --No errors
	BEGIN
		--Now we try to import data from the intersection table
		BEGIN TRANSACTION
		BEGIN TRY
			--Make sure the cmrT_ImportIntersectionTable does not contain intersections with zero event_frequency or zero element_size
			DELETE FROM cmrT_ImportIntersectionTable WHERE event_frequency <= 0 OR event_frequency IS NULL
			SELECT @nrecords = @@ROWCOUNT
			IF @nrecords>0
				INSERT @results
					SELECT 0, 'Deleted '+CAST(@nrecords AS varchar(10))+' rows with zero or undefined event_frequency'
			DELETE FROM cmrT_ImportIntersectionTable WHERE element_size <= 0 OR element_size IS NULL
			SELECT @nrecords = @@ROWCOUNT
			IF @nrecords>0
				INSERT @results
					SELECT 0, 'Deleted '+CAST(@nrecords AS varchar(10))+' rows with zero or undefined element_size'
		
			--Insert hazard zones
			INSERT INTO [cmrT_HazardZone]
					   ([study_id]
					   ,[hazardzone_feature_id]
					   ,[processtype_id]
					   ,[event_frequency]
					   ,[freq_error_interval_plus]
					   ,[freq_error_interval_minus])
			SELECT DISTINCT [study_id]
				  ,[hazardzone_feature_id]
				  ,ISNULL([processtype_id],0)
				  ,ISNULL([event_frequency],0)
				  ,ISNULL([freq_interval_plus],0)
				  ,ISNULL([freq_interval_minus],0)
			FROM cmrT_ImportIntersectionTable t
			WHERE t.[study_id]=@study_id

			INSERT @results
				SELECT 0, 'Inserted '+CAST(@@ROWCOUNT AS varchar(10))+' rows into hazardzone table'
				
			--Insert elements
			INSERT INTO [cmrT_Element]
					   ([study_id]
					   ,[element_feature_id]
					   ,[element_size]
					   ,[elementtype_code]
					   ,[route_code]
					   ,[aadt_passenger]
					   ,[aadt_goods]
					   ,[diversion_time])
			SELECT DISTINCT
				[study_id]
				, [element_feature_id]
				, [element_size]
				, [elementtype_code]
				, [route_code]
				, ISNULL([aadt_passenger],0)
				, ISNULL([aadt_goods],0)
				, ISNULL([diversion_time],0)
			FROM cmrT_ImportIntersectionTable t
			WHERE t.[study_id]=@study_id
				
			INSERT @results
				SELECT 0, 'Inserted '+CAST(@@ROWCOUNT AS varchar(10))+' rows into element table'


			--Insert intersections
			INSERT INTO [cmrT_ElementHazardZone]
					   ([element_id]
					   ,[hazardzone_id])
			SELECT e.[element_id]
				  ,hz.[hazardzone_id]
			FROM cmrT_ImportIntersectionTable t
				INNER JOIN [cmrT_Element] e ON t.[study_id]=e.[study_id] AND t.[element_feature_id]=e.[element_feature_id]
				INNER JOIN [cmrT_HazardZone] hz ON t.[study_id]=hz.[study_id] AND t.[hazardzone_feature_id]=hz.[hazardzone_feature_id]
			WHERE t.[study_id]=@study_id

			INSERT @results
				SELECT 0, 'Inserted '+CAST(@@ROWCOUNT AS varchar(10))+' element hazardzone intersections into ElementHazardZone table'
				
			--Delete all records from import table
			TRUNCATE TABLE cmrT_ImportIntersectionTable
			--Commit
			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			SELECT @msg = ERROR_MESSAGE()
			INSERT @results
				SELECT 1, @msg
			ROLLBACK TRANSACTION
			INSERT @results
				SELECT 1, @msg
		END CATCH
	END
	SELECT * FROM @results
	SELECT @retcode = MAX(retcode) FROM @results
RETURN @retcode
GO

/****** Object:  StoredProcedure [dbo].[cmrSP_setStudyArea]  ******/
CREATE PROCEDURE [dbo].[cmrSP_setStudyArea]
	@study_id int = NULL OUTPUT
	, @study_name VARCHAR(50)
	, @hazardzone_dataset_filepath NVARCHAR(4000)
	, @element_dataset_filepath NVARCHAR(4000)
	, @study_description VARCHAR(MAX) = NULL
AS
	SET NOCOUNT ON
	DECLARE @retcode INT
	
	DECLARE @results TABLE(study_id INT, [message] varchar(255))

	IF NOT EXISTS (SELECT * FROM cmrT_StudyArea WHERE study_id=@study_id)
	BEGIN
		INSERT cmrT_StudyArea (study_name, study_description, hazardzone_dataset_filepath, element_dataset_filepath) VALUES (@study_name, @study_description, @hazardzone_dataset_filepath, @element_dataset_filepath)
		SELECT @study_id=@@IDENTITY
		INSERT @results VALUES(@study_id, 'Success!')
		SELECT @retcode = 0
	END
	ELSE
	BEGIN
		UPDATE cmrT_StudyArea SET study_name = @study_name
			, study_description = @study_description
			, hazardzone_dataset_filepath = @hazardzone_dataset_filepath
			, element_dataset_filepath = @element_dataset_filepath
		WHERE study_id=@study_id
		INSERT @results VALUES(@study_id, 'Success!')
		SELECT @retcode = 0
	END
	--Make sure cmr is ready to recieve data
	--Delete all records from import table (if any)
	TRUNCATE TABLE cmrT_ImportIntersectionTable
	--Make sure any related data are deleted
	DELETE FROM cmrT_ElementHazardZone WHERE EXISTS (SELECT * FROM cmrT_Element e WHERE cmrT_ElementHazardZone.element_id=e.element_id AND e.study_id=@study_id)
	DELETE FROM cmrT_Element WHERE study_id=@study_id
	DELETE FROM cmrT_HazardZone WHERE study_id=@study_id
	
	SELECT * FROM @results
RETURN @retcode
GO

/****** Object:  StoredProcedure [dbo].[cmrSP_resultSummary] ******/
CREATE PROCEDURE [dbo].[cmrSP_resultSummary]
	@study_id INT
	, @timeframe INT = 1
	, @route BIT = 0
	, @elementtype BIT = 0
	, @valuetype BIT = 0
	, @hazardzone BIT = 0
	, @processtype BIT = 0
AS
	;WITH errorCTE AS (
		SELECT study_id
				, valuetype_category_id
				, valuetype_category_name
				, @timeframe AS timeframe --Timeframe for evaluating uncertainty of damage function (V errors)
				, hazardzone_feature_id = CASE @hazardzone WHEN 1 THEN hazardzone_feature_id ELSE NULL END
				, elementtype_code = CASE @elementtype WHEN 1 THEN elementtype_code ELSE NULL END
				, route_code = CASE @route WHEN 1 THEN route_code ELSE NULL END
				, processtype_name
				, valuetype_id
				, valuetype_name
				, COUNT(study_id) AS n --Number elements at risk
				, SUM(H) AS annual_frequency --Annual frequency
				, SUM(H)*@timeframe AS timeframe_frequency --Timeframe frequency
				, SUM(H*E*V) AS risk --Risk
				, E_PosErr = CASE SUM(H*E*V)
					WHEN 0 THEN 0
					ELSE
						SQRT(SUM(POWER(H*E_PosErr*V,2)))
					END
				, E_NegErr = CASE SUM(H*E*V)
					WHEN 0 THEN 0
					ELSE
						SQRT(SUM(POWER(H*E_NegErr*V,2)))
					END
				, V_PosErr = CASE SUM(H*E*V)
					WHEN 0 THEN 0
					ELSE
						SQRT(SUM(H)*@timeframe*POWER(SUM(H*E*V_PosErr),2))/(100*SUM(H))
					END
				, V_NegErr = CASE SUM(H*E*V)
					WHEN 0 THEN 0
					ELSE
						SQRT(SUM(H)*@timeframe*POWER(SUM(H*E*V_NegErr),2))/(100*SUM(H))
					END
		FROM dbo.cmrV_ElementValueDamages
		WHERE study_id=@study_id
		GROUP BY study_id
			, valuetype_category_id
			, valuetype_category_name
			, CASE @hazardzone WHEN 1 THEN hazardzone_feature_id ELSE NULL END
			, CASE @elementtype WHEN 1 THEN elementtype_code ELSE NULL END
			, CASE @route WHEN 1 THEN route_code ELSE NULL END
			, processtype_name
			, valuetype_id
			, valuetype_name
	)
	SELECT study_id
			, timeframe
			, hazardzone_feature_id
			, valuetype_category_id
			, valuetype_category_name
			, elementtype_code
			, route_code
			, processtype_name = CASE @processtype WHEN 1 THEN processtype_name ELSE NULL END
			, valuetype_name = CASE @valuetype WHEN 1 THEN valuetype_name ELSE NULL END
			, SUM(n) AS n
			, SUM(annual_frequency) AS annual_frequency
			, SUM(timeframe_frequency) AS timeframe_frequency
			, SUM(risk) AS risk
			, SQRT(SUM(POWER(E_PosErr,2))) AS E_PosErr
			, SQRT(SUM(POWER(E_NegErr,2))) AS E_NegErr
			, SQRT(SUM(POWER(V_PosErr,2))) AS V_PosErr
			, SQRT(SUM(POWER(V_NegErr,2))) AS V_NegErr
		FROM errorCTE
		GROUP BY study_id
			, timeframe
			, hazardzone_feature_id
			, valuetype_category_id
			, valuetype_category_name
			, elementtype_code
			, route_code
			, CASE @processtype WHEN 1 THEN processtype_name ELSE NULL END
			, CASE @valuetype WHEN 1 THEN valuetype_name ELSE NULL END
		ORDER BY study_id
			, timeframe
			, hazardzone_feature_id
			, valuetype_category_id
			, elementtype_code
			, route_code
			, processtype_name
RETURN 0
GO



print 'Creating views'
GO
/********************************************************
--Create Level 0 views
*********************************************************/
CREATE VIEW dbo.[cmrV_plotDamageFunction]
/*
View for generating plots of the damage functions
Returns expected damage, y, ad f(x)=[damage_max]*(([x]+[damage_prob]-1)/[damage_prob])^[damage_exponent]
*/
AS
WITH tally AS (
	SELECT (N-1)/100.0 AS x
	FROM cmrT_Tally
	WHERE N<=101
)
SELECT processtype_id
	, valuetype_id
	, [x]
	, [y] = CASE 
		WHEN [x]<1-[damage_prob] THEN 0
		ELSE [damage_max]*POWER(([x]+[damage_prob]-1)/[damage_prob],[damage_exponent])
	END
FROM dbo.cmrT_DamageFunction
	, tally
GO

CREATE VIEW [dbo].[cmrV_HazardZone]
AS
/*
Convenient view of hazard zones with related attributes
*/
SELECT h.hazardzone_id
      ,h.study_id
      ,h.hazardzone_feature_id
      ,h.processtype_id
      ,event_frequency = CAST(h.event_frequency AS FLOAT)
      ,pt.processtype_name
      ,pt.magnitude_unit
      ,event_width = ISNULL(pt.event_width,1.0/frequency_size_factor) --If both width and frequency_size_factor is NULL this will still be NULL, this is correct
      ,pt.frequency_size_factor
      ,pt.event_cooccurrence_factor
  FROM dbo.cmrT_HazardZone h
  INNER JOIN dbo.cmrT_ProcessType pt ON h.processtype_id=pt.processtype_id
  WHERE pt.processtype_id<>100
GO


CREATE VIEW [dbo].[cmrV_Element]
AS
/*
Convenient view of elements with attached properties
*/
SELECT e.element_id
	, e.study_id
	, e.element_feature_id
	, element_size = CAST(e.element_size AS FLOAT)
	, e.elementtype_code
	, et.elementtype_id
	, et.elementtype_name
	, ec.elementcategory_id
	, ec.elementcategory_name
	, RTRIM(e.route_code) AS route_code
	, e.aadt_passenger
	, e.aadt_goods
	, e.diversion_time
  FROM dbo.cmrT_Element e
  INNER JOIN dbo.cmrT_ElementType et ON e.elementtype_code=et.elementtype_code
  INNER JOIN dbo.cmrT_ElementCategory ec ON et.elementcategory_id=ec.elementcategory_id
GO

CREATE VIEW [dbo].[cmrV_ElementValue]
AS
/*
Convenient view of element values with attached properties
*/
SELECT ec.elementcategory_id
	, ec.elementcategory_name
	, et.elementtype_id
	, et.elementtype_code
	, et.elementtype_name
	, vt.valuetype_id
	, vt.valuetype_name
	, vt.valuetype_calculation_id
	, vtu.valuetype_calculation_name
	, vt.valuetype_category_id
	, vta.valuetype_category_name
	, ev.value_mean
	, ev.value_PosErr
	, ev.value_NegErr
	, vtu.use_element_event_frequency
	, vtu.use_route_event_frequency
	, vtu.use_element_impact_size
	, vtu.use_aadt_passenger
	, vtu.use_aadt_goods
	, vtu.use_diversion_time
	, ev.note_field
FROM dbo.cmrT_ElementType et
INNER JOIN dbo.cmrT_ElementValue ev ON et.elementtype_id = ev.elementtype_id
INNER JOIN dbo.cmrT_ElementCategory ec ON et.elementcategory_id=ec.elementcategory_id
INNER JOIN dbo.cmrT_ValueType vt ON ev.valuetype_id=vt.valuetype_id
INNER JOIN dbo.cmrT_ValueTypeCalculation vtu ON vt.valuetype_calculation_id=vtu.valuetype_calculation_id
INNER JOIN dbo.cmrT_ValueTypeCategory vta ON vt.valuetype_category_id=vta.valuetype_category_id
UNION
SELECT ec.elementcategory_id
	, ec.elementcategory_name
	, et.elementtype_id
	, et.elementtype_code
	, et.elementtype_name
	, -1 --valuetype_id
	, 'Event frequency' --valuetype_name
	, 0 --valuetype_calculation_id
	, 'event' --valuetype_calculation_name
	, -1 --valuetype_category_id
	, 'Event frequency' --valuetype_category_name
	, 1 --value_mean 
	, 0 -- value_PosErr
	, 0 --value_NegErr
	, 1 --use_element_event_frequency
	, NULL --use_route_event_frequency
	, NULL --use_element_impact_size
	, NULL --use_aadt_passenger
	, NULL --use_aadt_goods
	, NULL --use_diversion_time
	, 'Hard coded element value that simply indicates frequency of element events'
FROM dbo.cmrT_ElementType et
INNER JOIN dbo.cmrT_ElementCategory ec ON et.elementcategory_id=ec.elementcategory_id
UNION
SELECT ec.elementcategory_id
	, ec.elementcategory_name
	, et.elementtype_id
	, et.elementtype_code
	, et.elementtype_name
	, 0 --valuetype_id
	, 'Route event frequency' --valuetype_name
	, 0 --valuetype_calculation_id
	, 'route_event' --valuetype_calculation_name
	, 0 --valuetype_category_id
	, 'Route event frequency' --valuetype_category_name
	, 1 --value_mean 
	, 0 -- value_PosErr
	, 0 --value_NegErr
	, NULL --use_element_event_frequency
	, 1 --use_route_event_frequency
	, NULL --use_element_impact_size
	, NULL --use_aadt_passenger
	, NULL --use_aadt_goods
	, NULL --use_diversion_time
	, 'Hard coded element value that simply indicates frequency of route events'
FROM dbo.cmrT_ElementType et
INNER JOIN dbo.cmrT_ElementCategory ec ON et.elementcategory_id=ec.elementcategory_id
GO


CREATE VIEW [dbo].[cmrV_DamageFunction]
AS
/*
List of all damage functions with all relevant attributes
*/
SELECT d.processtype_id
	, pt.processtype_name
	, d.valuetype_id
	, vt.valuetype_name
	, vt.valuetype_calculation_id
	, vtu.valuetype_calculation_name
	, vt.valuetype_category_id
	, vta.valuetype_category_name
	, d.damage_prob
	, d.damage_max
	, d.damage_exponent
	, d.damage_avg
	, damage_PosErr = CASE
		WHEN d.damage_prob<=0.16 THEN 0 --If damage_prob is less than lower confidence limit then posErr is zero
		WHEN [damage_max]*POWER(([damage_prob]-0.16)/[damage_prob],[damage_exponent]) < d.damage_avg THEN 0 --If average is above the confidence interval then posErr is also zero
		ELSE [damage_max]*POWER(([damage_prob]-0.16)/[damage_prob],[damage_exponent])-d.damage_avg --Else posErr is difference between upper limit and average
		END
	, damage_NegErr = CASE
		WHEN d.damage_prob<=0.84 THEN d.damage_avg --If damage_prob is less than upper confidence limit then negErr is same as average
		WHEN [damage_max]*POWER(([damage_prob]-0.84)/[damage_prob],[damage_exponent]) > d.damage_avg THEN 0 --If average is below confidence interval then negErr is zero
		ELSE d.damage_avg-[damage_max]*POWER(([damage_prob]-0.84)/[damage_prob],[damage_exponent]) --Else negErr is difference between limit and average
		END
	, d.note_field
FROM dbo.cmrT_DamageFunction d
INNER JOIN dbo.cmrT_ProcessType pt ON d.processtype_id=pt.processtype_id
INNER JOIN dbo.cmrT_ValueType vt ON d.valuetype_id=vt.valuetype_id
INNER JOIN dbo.cmrT_ValueTypeCalculation vtu ON vt.valuetype_calculation_id=vtu.valuetype_calculation_id
INNER JOIN dbo.cmrT_ValueTypeCategory vta ON vt.valuetype_category_id=vta.valuetype_category_id
UNION
SELECT processtype_id
	, processtype_name
	, -1 --valuetype_id
	, 'Event frequency' --valuetype_name
	, 0 --valuetype_calculation_id
	, 'Frequency' --valuetype_calculation_name
	, -1 --valuetype_category_id
	, 'Event frequency' --valuetype_category_name
	, 1 --damage_prob
	, 1 --damage_max
	, 0.000001 --damage_exponent
	, 1 --damage_avg
	, 0 --damage_posErr
	, 0 --damage_negErr
	, 'Hard coded damage function that simply indicates frequency of route events'
FROM dbo.cmrT_ProcessType
UNION
SELECT processtype_id
	, processtype_name
	, 0 --valuetype_id
	, 'Route event frequency' --valuetype_name
	, 0 --valuetype_calculation_id
	, 'Frequency' --valuetype_calculation_name
	, 0 --valuetype_category_id
	, 'Route event frequency' --valuetype_category_name
	, 1 --damage_prob
	, 1 --damage_max
	, 0.000001 --damage_exponent
	, 1 --damage_avg
	, 0 --damage_posErr
	, 0 --damage_negErr
	, 'Hard coded damage function that simply indicates frequency of route events'
FROM dbo.cmrT_ProcessType
GO

/********************************************************
--Create Level 1 views
*********************************************************/
CREATE VIEW [dbo].[cmrV_ElementHazardZone]
AS
/*
Convenient view of element hazardzone intersections with attached properties
*/
WITH elementData AS ( --First select all relevant attributes per element
	SELECT e.study_id
		, e.element_id
		, e.element_feature_id
		, e.elementtype_code
		, e.elementtype_id
		, e.elementcategory_id
		, e.elementcategory_name
		, e.route_code
		, e.element_size
		, impact_size = ISNULL(hz.event_width,e.element_size) --For some process types the impact size is fixed
		, hz.hazardzone_id
		, hz.hazardzone_feature_id
		, hz.processtype_id
		, hz.processtype_name
		, hz.event_cooccurrence_factor
		, hazardzone_event_frequency = 1.0 / hz.event_frequency
		, event_frequency = ISNULL(e.element_size*hz.frequency_size_factor,1.0)/hz.event_frequency
		, e.aadt_passenger
		, e.aadt_goods
		, e.diversion_time
	FROM dbo.cmrT_ElementHazardZone ehz
	INNER JOIN dbo.cmrV_Element e ON ehz.element_id=e.element_id
	INNER JOIN dbo.cmrV_HazardZone hz ON ehz.hazardzone_id=hz.hazardzone_id
), routeData AS ( --Then summarize frequencies over hazardzone and route (needed for calculation of route frequencies when we have concurrent events)
	SELECT hazardzone_id
		, route_code
			--The frequency sum
		, SUM(event_frequency) AS event_frequency_sum
			--An adjusted frequency that is somewhere between maximum frequency (when cooccurence factor = 1) and the sum of the frequencies (when cooccurence factor = 0)
		, MAX(event_frequency)+(1-MAX(event_cooccurrence_factor))*(SUM(event_frequency)-MAX(event_frequency)) AS event_frequency_adj --Adjusted for concurrent events
  FROM elementData
  WHERE route_code IS NOT NULL
  GROUP BY hazardzone_id, route_code
) --Now we are ready to output the attributes
SELECT e.study_id
	, e.element_id
	, e.element_feature_id
	, e.elementtype_code
	, e.elementtype_id
	, e.elementcategory_id
	, e.elementcategory_name
	, e.route_code
	, e.element_size
	, e.impact_size
	, e.hazardzone_id
	, e.hazardzone_feature_id
	, e.processtype_id
	, e.processtype_name
	, e.event_cooccurrence_factor
	, e.hazardzone_event_frequency --The original frequency of hazard zone
	, e.event_frequency --The event frequency calculated for this object
	, route_event_frequency = ISNULL(rd.event_frequency_adj*e.event_frequency/rd.event_frequency_sum,0) --The contribution to the total route event frequency from this object
	, e.aadt_passenger
	, e.aadt_goods
	, e.diversion_time
FROM elementData e
LEFT JOIN routeData rd ON e.route_code=rd.route_code AND e.hazardzone_id=rd.hazardzone_id
GO


/********************************************************
--Create Level 2 views
*********************************************************/
CREATE VIEW dbo.cmrV_ElementValueDamages
AS
WITH cte AS (
	SELECT ehz.study_id
		, ehz.element_id
		, ehz.element_feature_id
		, ehz.hazardzone_id
		, ehz.hazardzone_feature_id
		, ehz.elementtype_code
		, ehz.elementcategory_name
		, ehz.route_code
		, ehz.processtype_id
		, hz.processtype_name
		, ehz.element_size
		, ehz.impact_size
		, ev.valuetype_category_id
		, ev.valuetype_category_name
		, ev.valuetype_id
		, ev.valuetype_name
		, ev.value_mean
		, ev.value_posErr
		, ev.value_negErr
		, ev.valuetype_calculation_name
		--Hazard: This is either route event frequency or event frequency
		, H = ISNULL(ev.use_route_event_frequency*ehz.route_event_frequency
				, ev.use_element_event_frequency*ehz.event_frequency)
		--We calculate the scaling of the element value at risk here in the cte and then the E itself in the actual query
		, E_scaling = COALESCE(--Scale with impact size or traffic in following order:
					ev.use_element_impact_size*ehz.impact_size --Scale with 1)impact size or...
					, ev.use_aadt_passenger*ehz.aadt_passenger/24.0 --2)passenger traffic or...
					, ev.use_aadt_goods*ehz.aadt_goods/24.0 --3)goods traffic
					, 1) --or simply 1 if none is specified (for low level risk metrics such as closure frequency)
				*ISNULL(ev.use_diversion_time*ehz.diversion_time,1) --Scale with diversion time if specified
		--Vulnerability with errors
		, V = d.damage_avg
		, V_PosErr = d.damage_PosErr
		, V_NegErr = d.damage_NegErr
	FROM dbo.cmrV_ElementHazardZone ehz
	INNER JOIN dbo.cmrV_HazardZone hz ON ehz.hazardzone_id=hz.hazardzone_id
	INNER JOIN dbo.cmrV_ElementValue ev ON ehz.elementtype_id=ev.elementtype_id
	INNER JOIN dbo.cmrV_DamageFunction d ON ehz.processtype_id=d.processtype_id AND ev.valuetype_id=d.valuetype_id
)
SELECT cte.study_id
	, cte.element_id
	, cte.element_feature_id
	, cte.hazardzone_id
	, cte.hazardzone_feature_id
	, cte.elementtype_code
	, cte.elementcategory_name
	, cte.route_code
	, cte.processtype_id
	, cte.processtype_name
	, cte.element_size
	, cte.impact_size
	, cte.valuetype_category_id
	, cte.valuetype_category_name
	, cte.valuetype_id
	, cte.valuetype_name
	, cte.value_mean
	, cte.value_posErr
	, cte.value_negErr
	, cte.valuetype_calculation_name
	--Hazard
	, cte.H
	--Multiply the E_scaling from the cte to calculate the actual value with associated errors
	, E = cte.value_mean*cte.E_scaling
	, E_PosErr = cte.value_PosErr*cte.E_scaling
	, E_NegErr = cte.value_NegErr*cte.E_scaling
	--Vulnerability with errors
	, cte.V
	, cte.V_PosErr
	, cte.V_NegErr
FROM cte
GO



CREATE VIEW dbo.cmrV_ElementValueDamagesPivot
/*
A view that pivots the element value damages over valuetype categories to make sure we dont mix apples and pears when they are aggregated
*/
AS
SELECT study_id
	, element_id
	, element_feature_id
	, hazardzone_id
	, hazardzone_feature_id
	, elementtype_code
	, elementcategory_name
	, route_code
	, processtype_id
	, processtype_name
	, element_size
	, valuetype_name
	, CAST(ISNULL([-1],0) AS DECIMAL(10,4)) AS [EventFrequency]
	, CAST(ISNULL([0],0) AS DECIMAL(10,4)) AS [RouteEventFrequency]
	, CAST(ISNULL([1],0) AS DECIMAL(10,4)) AS [ClosureFrequency]
	, CAST(ISNULL([2],0) AS DECIMAL(10,4)) AS [ClosureDuration]
	, CAST(ISNULL([3],0) AS MONEY) AS [RepairCosts]
	, CAST(ISNULL([4],0) AS MONEY) AS [ReopeningCosts]
	, CAST(ISNULL([5],0) AS MONEY) AS [ClosureCosts]
FROM (SELECT study_id
		, element_id
		, element_feature_id
		, hazardzone_id
		, hazardzone_feature_id
		, elementtype_code
		, elementcategory_name
		, route_code
		, processtype_id
		, processtype_name
		, element_size
		, valuetype_name
		, valuetype_category_id
		, H*E*V AS risk
	FROM dbo.cmrV_ElementValueDamages
) AS src
	PIVOT (SUM(risk) FOR valuetype_category_id IN ([0],[-1],[1],[2],[3],[4],[5])) AS pvt
GO


CREATE VIEW dbo.cmrV_ElementSummary
AS
SELECT study_id
	, element_id
	, element_feature_id
	, SUM([EventFrequency]) AS [EventFrequency]
	, SUM([RouteEventFrequency]) AS [RouteEventFrequency]
	, SUM([ClosureFrequency]) AS [ClosureFrequency]
	, SUM([ClosureDuration]) AS [ClosureDuration]
	, SUM([RepairCosts]) AS [RepairCosts]
	, SUM([ReopeningCosts]) AS [ReopeningCosts]
	, SUM([ClosureCosts]) AS [ClosureCosts]
FROM dbo.cmrV_ElementValueDamagesPivot
GROUP BY study_id, element_id, element_feature_id
GO

CREATE VIEW dbo.cmrV_RouteSummary
AS
SELECT study_id
	, route_code
	, SUM([EventFrequency]) AS [EventFrequency]
	, SUM([RouteEventFrequency]) AS [RouteEventFrequency]
	, SUM([ClosureFrequency]) AS [ClosureFrequency]
	, SUM([ClosureDuration]) AS [ClosureDuration]
	, SUM([RepairCosts]) AS [RepairCosts]
	, SUM([ReopeningCosts]) AS [ReopeningCosts]
	, SUM([ClosureCosts]) AS [ClosureCosts]
FROM dbo.cmrV_ElementValueDamagesPivot
GROUP BY study_id, route_code
GO

CREATE VIEW dbo.cmrV_ProcesstypeSummary
AS
SELECT study_id
	, processtype_name
	, SUM([EventFrequency]) AS [EventFrequency]
	, SUM([RouteEventFrequency]) AS [RouteEventFrequency]
	, SUM([ClosureFrequency]) AS [ClosureFrequency]
	, SUM([ClosureDuration]) AS [ClosureDuration]
	, SUM([RepairCosts]) AS [RepairCosts]
	, SUM([ReopeningCosts]) AS [ReopeningCosts]
	, SUM([ClosureCosts]) AS [ClosureCosts]
FROM dbo.cmrV_ElementValueDamagesPivot
GROUP BY study_id, processtype_name
GO

CREATE VIEW dbo.cmrV_HazardZoneSummary
AS
SELECT study_id
	, hazardzone_id
	, hazardzone_feature_id
	, SUM([EventFrequency]) AS [EventFrequency]
	, SUM([RouteEventFrequency]) AS [RouteEventFrequency]
	, SUM([ClosureFrequency]) AS [ClosureFrequency]
	, SUM([ClosureDuration]) AS [ClosureDuration]
	, SUM([RepairCosts]) AS [RepairCosts]
	, SUM([ReopeningCosts]) AS [ReopeningCosts]
	, SUM([ClosureCosts]) AS [ClosureCosts]
FROM dbo.cmrV_ElementValueDamagesPivot
GROUP BY study_id, hazardzone_id, hazardzone_feature_id
GO


CREATE VIEW dbo.cmrV_StudySummary
AS
SELECT study_id
	, SUM([EventFrequency]) AS [EventFrequency]
	, SUM([RouteEventFrequency]) AS [RouteEventFrequency]
	, SUM([ClosureFrequency]) AS [ClosureFrequency]
	, SUM([ClosureDuration]) AS [ClosureDuration]
	, SUM([RepairCosts]) AS [RepairCosts]
	, SUM([ReopeningCosts]) AS [ReopeningCosts]
	, SUM([ClosureCosts]) AS [ClosureCosts]
FROM dbo.cmrV_ElementValueDamagesPivot
GROUP BY study_id
GO


CREATE VIEW dbo.cmrV_ErrorEstimateE
AS
/* Returns E error estimate (fraction of value) for each value type within each study area */
WITH cte1 AS (
	SELECT e.study_id
		, ev.elementtype_id
		, e.elementtype_code
		, ev.valuetype_id
		, ev.valuetype_name
		, ev.value_mean
		, ev.value_PosErr
		, ev.value_NegErr
		, E_scaling = COALESCE(--Scale with impact size or traffic in following order:
				ev.use_element_impact_size*e.element_size --Scale with 1)impact size or...
				, ev.use_aadt_passenger*e.aadt_passenger --2)passenger traffic or...
				, ev.use_aadt_goods*e.aadt_goods --3)goods traffic
				, 1) --or simply 1 if none is specified (for low level risk metrics such as closure frequency)
	FROM [cmrV_Element] e
	INNER JOIN [cmrV_ElementValue] ev ON e.elementtype_code=ev.elementtype_code
	WHERE ev.value_mean>0
		AND valuetype_id>0
)
SELECT study_id
	, valuetype_id
	, valuetype_name
	, E_posErr = SQRT(SUM(POWER(value_PosErr*E_scaling,2)))/SUM(value_mean*E_scaling)
	, E_negErr = SQRT(SUM(POWER(value_NegErr*E_scaling,2)))/SUM(value_mean*E_scaling) 
FROM cte1
GROUP BY study_id
	, valuetype_id
	, valuetype_name
GO

CREATE VIEW dbo.cmrV_ErrorEstimateV
AS
/*
Esimtates the positive and negative error of the V value within each study area
The estimates are given for each damage function (combination of process and valuetype)
*/
WITH cte1 AS (
	SELECT study_id
		, processtype_id
		, processtype_name
		, valuetype_id
		, valuetype_name
		, valuetype_category_id
		, valuetype_category_name
		, cnt = COUNT(ALL study_id) --Number of impacted elements in group
		, R = SUM(H*E*V)
		, H = SUM(H) --Total frequency of events in group
		, V = MAX(V) --Average damage /vulnerability for group (same for all rows)
		, V_PosErr = MAX(V_PosErr) --Single event positive error of V (68% confidence)
		, V_NegErr = MAX(V_NegErr) --Single event negative error of V (68% confidence)
		, timespan = 50
	FROM cmrV_ElementValueDamages
--	WHERE valuetype_id>0
	GROUP BY study_id
		, processtype_id
		, processtype_name
		, valuetype_id
		, valuetype_name
		, valuetype_category_id
		, valuetype_category_name
)
SELECT c.study_id
		, c.processtype_id
		, c.processtype_name
		, c.valuetype_id
		, c.valuetype_name
		, valuetype_category_id
		, valuetype_category_name
		, c.cnt
		, c.timespan
		, R
		, c.H
		, c.V
		, V_PosErrPct = CASE
			WHEN V = 0 THEN 0 --If vulnerability is zero then error is also zero
			WHEN H*timespan<1 THEN V_PosErr/V --If less than one event is expected within timespan, use single event error
			ELSE (1/V)*SQRT((H*timespan)*POWER(V_PosErr,2))/(H*timespan) --If multiple events is expected within timespan, adjust error
			END
		, V_NegErrPct = CASE
			WHEN V = 0 THEN 0 --If vulnerability is zero then error is also zero
			WHEN H*timespan<1 THEN V_NegErr/V --If less than one event is expected within timespan, use single event error
			ELSE (1/V)*SQRT((H*timespan)*POWER(V_NegErr,2))/(H*timespan) --If multiple events is expected within timespan, adjust error
			END
FROM cte1 c
GO

/********************************************************
--POPULATE BASE TABLES
*********************************************************/
print 'Populating base tables with default parameter values'
GO

SET NOCOUNT ON
--[cmrT_ProcessType]
INSERT INTO [dbo].[cmrT_ProcessType]
(processtype_id,processtype_name,magnitude_unit,event_width,frequency_size_factor,event_cooccurrence_factor)
VALUES(3, 'Rock fall', 'm3', 5, 0.033333, 0.2),
	(10, 'Shallow landslide', 'm3', NULL, NULL, 1),
	(13, 'Debris flow', 'm3', 30, 0.033333, 1),
	(20, 'Avalanche', 'm3', 30, 0.033333, 0.2),
	(100, 'Flood', 'm', NULL, NULL, 1)


--[cmrT_ElementCategory]
INSERT INTO [dbo].[cmrT_ElementCategory] (elementcategory_id, elementcategory_name)
VALUES(1, 'Building'),
	(2, 'Road'),
	(3, 'Railroad')

--[cmrT_ValueTypeCalculation]
INSERT INTO [dbo].[cmrT_ValueTypeCalculation]
(valuetype_calculation_id,valuetype_calculation_name,use_element_event_frequency,use_route_event_frequency,use_element_impact_size,use_aadt_passenger,use_aadt_goods,use_diversion_time)
VALUES(1, 'event*impact_size', 1, NULL, 1, NULL, NULL, NULL)
,(2, 'event', 1, NULL, NULL, NULL, NULL, NULL)
,(3, 'route_event*AADTp*diversion_time', NULL, 1, NULL, 1, NULL, 1)
,(4, 'route_event*AADTg*diversion_time', NULL, 1, NULL, NULL, 1, 1)
,(5, 'route_event', NULL, 1, NULL, NULL, NULL, NULL)

--[cmrT_ValueTypeCategory]
INSERT INTO [dbo].[cmrT_ValueTypeCategory]
(valuetype_category_id,valuetype_category_name,valuetype_category_unit)
VALUES(1, 'Closure frequency', 'events')
, (2, 'Closure duration', 'hours')
, (3, 'Repair costs', 'NOK')
, (4, 'Reopening costs', 'NOK')
, (5, 'Closure costs', 'NOK')

--[cmrT_ElementType]
INSERT INTO [dbo].[cmrT_ElementType]
(elementtype_id,elementtype_code,elementtype_name,elementcategory_id)
VALUES(210, 'BANE ', 'Railway',3)
, (110, 'EV ', 'Classified road',2)
, (130, 'FV ', 'County road',2)
, (140, 'KV ', 'Municipal road',2)
, (150, 'PV ', 'Private road',2)
, (120, 'RV ', 'Classified road',2)
, (160, 'SV ', 'Other road',2)

--[cmrT_ValueType]
SET IDENTITY_INSERT [dbo].[cmrT_ValueType] ON
INSERT INTO [dbo].[cmrT_ValueType]
(valuetype_id,valuetype_name,valuetype_calculation_id,valuetype_category_id,valuetype_description)
VALUES(1, 'Road surface', 1, 3, 'Cost of repairing damaged road surface (per meter)')
, (2, 'Road foundation', 1, 3, 'Cost of repairing the road foundation (per meter)')
, (3, 'Road railing', 1, 3, 'Cost of replacing damaged road railing (per meter)')
, (4, 'Road clearing', 2, 4, 'Cost of road clearing work (per event)')
, (5, 'Road people delay', 3, 5, 'Cost of road person delays (per car per hour)')
, (6, 'Road goods delay', 4, 5, 'Cost of road goods transport delays (per heavy car per hour)')
, (7, 'Road closure frequency', 5, 1, 'Frequency of road closures (no scaling)')
, (8, 'Road closure duration', 5, 2, 'Duration of road closures (no scaling)')
, (11, 'Railway tracks', 1, 3, 'Cost of repairing damaged railway tracks (per meter)')
, (12, 'Railway foundation', 1, 3, 'Cost of repairing damaged railway foundation (per meter)')
, (13, 'Railway cables', 1, 3, 'Cost of replacing damaged railway cables (per meter)')
, (14, 'Railway clearing', 2, 4, 'Cost of railway clearing work (per event)')
, (15, 'Railway passenger delay', 3, 5, 'Cost of railway passenger delays (per person per hour)')
, (16, 'Railway goods delay', 4, 5, 'Cost of railway goods transport delays (per tonne per hour)')
, (17, 'Railway closure frequency', 5, 1, 'Frequency of railway closures (no scaling)')
, (18, 'Railway closure duration', 5, 2, 'Duration of railway closures (no scaling)')
SET IDENTITY_INSERT [dbo].[cmrT_ValueType] OFF

--[dbo].[cmrT_ElementValue]
INSERT INTO [dbo].[cmrT_ElementValue]
(elementtype_id,valuetype_id,value_mean,value_PosErr,value_NegErr,note_field)
VALUES(110, 1, 12000, 3000, 3000, 'Expert judgement')
, (110, 2, 18000, 4500, 4500, 'Expert judgement')
, (110, 3, 660, 165, 165, 'Expert judgement')
, (110, 4, 20000, 5000, 5000, 'Expert judgement (2 man days + 1 heavy equipment)')
, (110, 5, 135, 35, 35, 'The weighted average from figure 5.13 in "Håndbok 140, Konsekvensanalyser" (SVV, 2006). Errors are estimated to +/-25%.')
, (110, 6, 791, 197, 197, 'Values from figure 5.14 in "Håndbok 140, Konsekvensanalyser" (SVV, 2006), but subtracted 135 NOK since goods traffic is included in AADT. Errors are estimated as +/-25%.')
, (110, 7, 1, 0, 0, 'The value here is the frequency itself, thus we simply use 1')
, (110, 8, 1, 0, 0, 'The value here comes directly from the damage function, thus we simply use 1')
, (120, 1, 12000, 3000, 3000, 'Expert judgement')
, (120, 2, 18000, 4500, 4500, 'Expert judgement')
, (120, 3, 660, 165, 165, 'Expert judgement')
, (120, 4, 20000, 5000, 5000, 'Expert judgement (2 man days + 1 heavy equipment)')
, (120, 5, 135, 35, 35, 'The weighted average from figure 5.13 in "Håndbok 140, Konsekvensanalyser" (SVV, 2006). Errors are estimated to +/-25%.')
, (120, 6, 791, 197, 197, 'Values from figure 5.14 in "Håndbok 140, Konsekvensanalyser" (SVV, 2006), but subtracted 135 NOK since goods traffic is included in AADT. Errors are estimated as +/-25%.')
, (120, 7, 1, 0, 0, 'The value here is the frequency itself, thus we simply use 1')
, (120, 8, 1, 0, 0, 'The value here comes directly from the damage function, thus we simply use 1')
, (130, 1, 8000, 2000, 2000, 'Expert judgement')
, (130, 2, 12000, 3000, 3000, 'Expert judgement')
, (130, 3, 660, 165, 165, 'Expert judgement')
, (130, 4, 20000, 5000, 5000, 'Expert judgement (2 man days + 1 heavy equipment)')
, (130, 5, 135, 35, 35, 'The weighted average from figure 5.13 in "Håndbok 140, Konsekvensanalyser" (SVV, 2006). Errors are estimated to +/-25%.')
, (130, 6, 791, 197, 197, 'Values from figure 5.14 in "Håndbok 140, Konsekvensanalyser" (SVV, 2006), but subtracted 135 NOK since goods traffic is included in AADT. Errors are estimated as +/-25%.')
, (130, 7, 1, 0, 0, 'The value here is the frequency itself, thus we simply use 1')
, (130, 8, 1, 0, 0, 'The value here comes directly from the damage function, thus we simply use 1')
, (140, 1, 6000, 1500, 1500, 'Expert judgement')
, (140, 2, 9000, 2250, 2250, 'Expert judgement')
, (140, 3, 330, 82.5, 82.5, 'Expert judgement')
, (140, 4, 20000, 5000, 5000, 'Expert judgement (2 man days + 1 heavy equipment)')
, (140, 7, 1, 0, 0, 'The value here is the frequency itself, thus we simply use 1')
, (140, 8, 1, 0, 0, 'The value here comes directly from the damage function, thus we simply use 1')
, (150, 1, 5000, 1250, 1250, 'Expert judgement')
, (150, 2, 7000, 1750, 1750, 'Expert judgement')
, (150, 4, 20000, 5000, 5000, 'Expert judgement (2 man days + 1 heavy equipment)')
, (150, 7, 1, 0, 0, 'The value here is the frequency itself, thus we simply use 1')
, (150, 8, 1, 0, 0, 'The value here comes directly from the damage function, thus we simply use 1')
, (160, 1, 1000, 250, 250, 'Expert judgement')
, (160, 2, 4000, 1000, 1000, 'Expert judgement')
, (160, 7, 1, 0, 0, 'The value here is the frequency itself, thus we simply use 1')
, (160, 8, 1, 0, 0, 'The value here comes directly from the damage function, thus we simply use 1')
, (210, 11, 12000, 3000, 3000, 'Same value as used for roads.')
, (210, 12, 18000, 4500, 4500, 'Same value as used for roads.')
, (210, 13, 2000, 0, 0, 'Wild guess')
, (210, 14, 20000, 5000, 5000, 'Same value as used for roads.')
, (210, 15, 90, 22, 22, 'The weighted average from figure 5.9 in "Håndbok 140, Konsekvensanalyser" (SVV, 2006). Errors are estimated to +/-25%.')
, (210, 16, 72, 18, 18, 'Value taken from TØI report 1189/2012')
, (210, 17, 1, 0, 0, 'The value here comes directly from the damage function, thus we simply use 1')
, (210, 18, 1, 0, 0, 'The value here comes directly from the damage function, thus we simply use 1')

--[dbo].[cmrT_DamageFunction]
INSERT INTO [dbo].[cmrT_DamageFunction]
(processtype_id,valuetype_id,damage_prob,damage_max,damage_exponent,note_field)
VALUES(3, 1, 0.12, 1, 0.1, '12% of registered events are reported to cause damage (to paving and/or foundation). We assume that most of these events leads to total damage of paving.')
, (3, 2, 0.12, 1, 3, '12% of registered events are reported to cause damage (to surface and/or foundation). We assume that damages to foundation are usually small.')
, (3, 3, 0.1, 1, 0.01, '8.5% of registered events are reported to cause damage (rounded up to 10). We assume that most of these events leads to total damage.')
, (3, 4, 1, 3, 4, 'All events are assumed to generate a need for clearing For most events the clearing costs are very small, but for large events the costs may considerable (3 units).')
, (3, 5, 0.1, 48, 3.5, '10% of registered events are reported to cause full closure (partial closures are not included). Above this the damage function is fitted to the cumulative frequency distribution of closures.')
, (3, 6, 0.1, 48, 3.5, '10% of registered events are reported to cause full closure (partial closures are not included). Above this the damage function is fitted to the cumulative frequency distribution of closures.')
, (3, 7, 0.1, 1, 0.01, '10% of registered events are reported to cause full closure (partial closures are not included).')
, (3, 8, 0.1, 48, 3.5, '10% of registered events are reported to cause full closure (partial closures are not included). Above this the damage function is fitted to the cumulative frequency distribution of closures.')
, (3, 11, 0.42, 1, 0.5, '42% of registered events are reported to cause damage. We assume that most of these events leads to large damages.')
, (3, 12, 0.12, 1, 1, '12% of registered events are reported to cause damage. We assume equal distribution between small and large damages.')
, (3, 13, 0.11, 1, 0.5, '11% of registered events are reported to cause damage. We assume that most of these events leads to large damages.')
, (3, 14, 1, 3, 4, 'All events are assumed to generate a need for clearing For most events the clearing costs are very small, but for large events the costs may considerable (3 units).')
, (3, 15, 0.15, 48, 2, '15% of registered events are reported to cause closure. We assume that most closures are much shorter than the maximum.')
, (3, 16, 0.15, 48, 2, '15% of registered events are reported to cause closure. We assume that most closures are much shorter than the maximum.')
, (3, 17, 0.15, 1, 0.01, '15% of registered events are reported to cause closure.')
, (3, 18, 0.15, 48, 2, '15% of registered events are reported to cause closure. We assume that most closures are much shorter than the maximum.')
, (10, 1, 0.17, 1, 0.1, '17% of registered events are reported to cause damage (to paving and/or foundation). We assume that most of these events leads to total damage of paving.')
, (10, 2, 0.17, 1, 10, '17% of registered events are reported to cause damage (to surface and/or foundation). We assume that damages to foundation are usually small.')
, (10, 3, 0.12, 1, 0.01, '11.5% of registered events are reported to cause damage. We assume that most of these events leads to total damage.')
, (10, 4, 1, 2, 2, 'All events are assumed to generate a need for clearing. For most events the clearing costs are small, but for large events the costs may considerable (2 units).')
, (10, 5, 0.29, 48, 3.2, '29% of registered events are reported to cause full closure (partial closures are not included). Above this the damage function is fitted to the cumulative frequency distribution of closures.')
, (10, 6, 0.29, 48, 3.2, '29% of registered events are reported to cause full closure (partial closures are not included). Above this the damage function is fitted to the cumulative frequency distribution of closures.')
, (10, 7, 0.29, 1, 0.01, '29% of registered events are reported to cause full closure (partial closures are not included).')
, (10, 8, 0.29, 48, 3.2, '29% of registered events are reported to cause full closure (partial closures are not included). Above this the damage function is fitted to the cumulative frequency distribution of closures.')
, (10, 11, 0.76, 1, 0.5, '76% of registered events are reported to cause damage. We assume that most of these events leads to large damages.')
, (10, 12, 0.67, 1, 0.5, '67% of registered events are reported to cause damage. We assume that most of these events leads to large damages.')
, (10, 13, 0.03, 1, 0.5, '3% of registered events are reported to cause damage. We assume that most of these events leads to large damages.')
, (10, 14, 1, 2, 2, 'All events are assumed to generate a need for clearing. For most events the clearing costs are small, but for large events the costs may considerable (2 units).')
, (10, 15, 0.26, 48, 1, '26% of registered events are reported to cause closure (this seems low considering that 76% of the same events are reported to damage tracks or foundation). We assume an equal distribution between long and short closures.')
, (10, 16, 0.26, 48, 1, '26% of registered events are reported to cause closure (this seems low considering that 76% of the same events are reported to damage tracks or foundation). We assume an equal distribution between long and short closures.')
, (10, 17, 0.26, 1, 0.01, '26% of registered events are reported to cause closure (this seems low considering that 76% of the same events are reported to damage tracks or foundation).')
, (10, 18, 0.26, 48, 1, '26% of registered events are reported to cause closure (this seems low considering that 76% of the same events are reported to damage tracks or foundation). We assume an equal distribution between long and short closures.')
, (13, 1, 0.25, 1, 0.1, '25% of registered events are reported to cause damage (to paving and/or foundation). We assume that most of these events leads to total damage of paving.')
, (13, 2, 0.2, 1, 4, '25% of registered events are reported to cause damage (to surface and/or foundation). We assume that damages to foundation are usually small.')
, (13, 3, 0.2, 1, 0.01, '18% of registered events are reported to cause damage. We assume that most of these events leads to total damage.')
, (13, 4, 1, 2, 2, 'All events are assumed to generate a need for clearing. For most events the clearing costs are small, but for large events the costs may considerable (2 units).')
, (13, 5, 0.46, 48, 3.5, '46% of registered events are reported to cause full closure (partial closures are not included). Above this the damage function is fitted to the cumulative frequency distribution of closures.')
, (13, 6, 0.46, 48, 3.5, '46% of registered events are reported to cause full closure (partial closures are not included). Above this the damage function is fitted to the cumulative frequency distribution of closures.')
, (13, 7, 0.46, 1, 0.01, '46% of registered events are reported to cause full closure (partial closures are not included).')
, (13, 8, 0.46, 48, 3.5, '46% of registered events are reported to cause full closure (partial closures are not included). Above this the damage function is fitted to the cumulative frequency distribution of closures.')
, (13, 11, 0.79, 1, 0.5, '79% of registered events are reported to cause damage. We assume that most of these events leads to large damages.')
, (13, 12, 0.75, 1, 0.5, '75% of registered events are reported to cause damage. We assume that most of these events leads to large damages.')
, (13, 13, 0.06, 1, 0.5, '6% of registered events are reported to cause damage. We assume that most of these events leads to large damages.')
, (13, 14, 1, 2, 2, 'All events are assumed to generate a need for clearing. For most events the clearing costs are small, but for large events the costs may considerable (2 units).')
, (13, 15, 0.46, 48, 2, '46% of registered events are reported to cause closure (this seems low considering that 79% of the same events are reported to damage tracks or foundation). We assume that most closures are much shorter than the maximum.')
, (13, 16, 0.46, 48, 2, '46% of registered events are reported to cause closure (this seems low considering that 79% of the same events are reported to damage tracks or foundation). We assume that most closures are much shorter than the maximum.')
, (13, 17, 0.46, 1, 0.01, '46% of registered events are reported to cause closure (this seems low considering that 79% of the same events are reported to damage tracks or foundation).')
, (13, 18, 0.46, 48, 2, '46% of registered events are reported to cause closure (this seems low considering that 79% of the same events are reported to damage tracks or foundation). We assume that most closures are much shorter than the maximum.')
, (20, 1, 0.005, 0.5, 2, '0.5% of registered events are reported to cause damage (to paving and/or foundation). We assume that damages to paving are usually small.')
, (20, 2, 0, 0, 0, '0.5% of registered events are reported to cause damage to surface or foundation, but we do not assume any damage to the latter.')
, (20, 3, 0.055, 1, 0.01, '5.5% of registered events are reported to cause damage. We assume that most of these events leads to total damage.')
, (20, 4, 1, 1, 0.1, 'All events are assumed to generate a need for clearing. For most events the clearing costs are large (near 1 unit).')
, (20, 5, 0.72, 48, 2, '72% of registered events are reported to cause full closure (partial closures are not included). Above this the damage function is fitted to the cumulative frequency distribution of closures.')
, (20, 6, 0.72, 48, 2, '72% of registered events are reported to cause full closure (partial closures are not included). Above this the damage function is fitted to the cumulative frequency distribution of closures.')
, (20, 7, 0.72, 1, 0.01, '72% of registered events are reported to cause full closure (partial closures are not included).')
, (20, 8, 0.72, 48, 2, '72% of registered events are reported to cause full closure (partial closures are not included). Above this the damage function is fitted to the cumulative frequency distribution of closures.')
, (20, 11, 0.12, 1, 0.5, '12% of registered events are reported to cause damage. We assume that most of these events leads to large damages.')
, (20, 12, 0.09, 1, 2, '9% of registered events are reported to cause damage. We assume that most of these events leads to small damages.')
, (20, 13, 0.28, 1, 0.5, '28% of registered events are reported to cause damage. We assume that most of these events leads to large damages.')
, (20, 14, 1, 1, 2, 'All events are assumed to generate a need for clearing.  For most events the clearing costs are small.')
, (20, 15, 0.26, 48, 3, '25% of registered events are reported to cause closure. We assume that most closures are much, much shorter than the maximum.')
, (20, 16, 0.26, 48, 3, '25% of registered events are reported to cause closure. We assume that most closures are much, much shorter than the maximum.')
, (20, 17, 0.26, 1, 0.01, '25% of registered events are reported to cause closure.')
, (20, 18, 0.26, 48, 3, '25% of registered events are reported to cause closure. We assume that most closures are much, much shorter than the maximum.')
, (100, 1, 0, 0, 0, NULL)
, (100, 2, 0, 0, 0, NULL)
, (100, 3, 0, 0, 0, NULL)
, (100, 4, 0, 0, 0, NULL)
, (100, 5, 1, 48, 1, 'No data on events available, but we assume that nearly all flooding event result in closure and that maximum damage is 48 hours.')
, (100, 6, 1, 48, 1, 'No data on events available, but we assume that nearly all flooding event result in closure and that maximum damage is 48 hours.')
, (100, 7, 1, 1, 0.1, 'No data on events available, but we assume that nearly all flooding events result in closure.')
, (100, 8, 1, 48, 1, 'No data on events available, but we assume that nearly all flooding event result in closure and that maximum damage is 48 hours.')
, (100, 11, 0, 0, 0, NULL)
, (100, 12, 0, 0, 0, NULL)
, (100, 13, 0, 0, 0, NULL)
, (100, 14, 0, 0, 0, NULL)
, (100, 15, 1, 1, 0.1, 'No data on events available, but we assume that nearly all flooding event result in closure and thus the average damage should be close to 1')
, (100, 16, 1, 1, 0.1, 'No data on events available, but we assume that nearly all flooding event result in closure and thus the average damage should be close to 1')
, (100, 17, 1, 1, 0.1, 'No data on events available, but we assume that nearly all flooding event result in closure and thus the average damage should be close to 1')
, (100, 18, 0, 0, 0, NULL)


/********************************************************
--INSERT TEST DATA
*********************************************************/
/*
print 'Inserting test data for study_id = 100'
SET NOCOUNT ON
SET IDENTITY_INSERT [dbo].[cmrT_StudyArea] ON
INSERT [dbo].[cmrT_StudyArea] ([study_id], [study_name], [study_description], [hazardzone_dataset_filepath], [element_dataset_filepath]) VALUES (100, N'Testdata', N'Just for testing', N'None', N'None')
SET IDENTITY_INSERT [dbo].[cmrT_StudyArea] OFF

SET IDENTITY_INSERT [dbo].[cmrT_HazardZone] ON
INSERT [dbo].[cmrT_HazardZone] ([hazardzone_id], [study_id], [hazardzone_feature_id], [processtype_id], [event_frequency], [freq_error_interval_plus], [freq_error_interval_minus]) VALUES (1, 100, 1, 3, 100, 0, 5)
INSERT [dbo].[cmrT_HazardZone] ([hazardzone_id], [study_id], [hazardzone_feature_id], [processtype_id], [event_frequency], [freq_error_interval_plus], [freq_error_interval_minus]) VALUES (2, 100, 2, 10, 100, 0, 5)
INSERT [dbo].[cmrT_HazardZone] ([hazardzone_id], [study_id], [hazardzone_feature_id], [processtype_id], [event_frequency], [freq_error_interval_plus], [freq_error_interval_minus]) VALUES (3, 100, 3, 13, 100, 0, 5)
INSERT [dbo].[cmrT_HazardZone] ([hazardzone_id], [study_id], [hazardzone_feature_id], [processtype_id], [event_frequency], [freq_error_interval_plus], [freq_error_interval_minus]) VALUES (4, 100, 4, 20, 100, 0, 5)
SET IDENTITY_INSERT [dbo].[cmrT_HazardZone] OFF

SET IDENTITY_INSERT [dbo].[cmrT_Element] ON
INSERT [dbo].[cmrT_Element] ([element_id], [study_id], [element_feature_id], [element_size], [elementtype_code], [route_code], [aadt_passenger], [aadt_goods], [diversion_time]) VALUES (1, 100, 1, 100, N'EV', N'E6', 5570, 1058, 2)
INSERT [dbo].[cmrT_Element] ([element_id], [study_id], [element_feature_id], [element_size], [elementtype_code], [route_code], [aadt_passenger], [aadt_goods], [diversion_time]) VALUES (2, 100, 2, 100, N'EV', N'E6', 5570, 1058, 2)
INSERT [dbo].[cmrT_Element] ([element_id], [study_id], [element_feature_id], [element_size], [elementtype_code], [route_code], [aadt_passenger], [aadt_goods], [diversion_time]) VALUES (3, 100, 3, 100, N'EV', N'E6', 5570, 1058, 2)
INSERT [dbo].[cmrT_Element] ([element_id], [study_id], [element_feature_id], [element_size], [elementtype_code], [route_code], [aadt_passenger], [aadt_goods], [diversion_time]) VALUES (4, 100, 4, 100, N'EV', N'E6', 5570, 1058, 2)
SET IDENTITY_INSERT [dbo].[cmrT_Element] OFF

INSERT cmrT_ElementHazardZone (element_id, hazardzone_id) VALUES(1,1)
INSERT cmrT_ElementHazardZone (element_id, hazardzone_id) VALUES(2,2)
INSERT cmrT_ElementHazardZone (element_id, hazardzone_id) VALUES(3,3)
INSERT cmrT_ElementHazardZone (element_id, hazardzone_id) VALUES(4,4)
INSERT cmrT_ElementHazardZone (element_id, hazardzone_id) VALUES(1,4)
SET NOCOUNT OFF
GO
*/
print 'If the script completed witn no errors you should be all set to go...'