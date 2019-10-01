USE [DBA]
GO

ALTER PROCEDURE [dbo].[usp_DBARestoreBkup]
	-- Add the parameters for the stored procedure here
	@sourceDbname varchar(50),							-- Database name on the publisher
	@destDbname varchar(50),							-- Database name on the subscriber
	@SourceLocation varchar(100),						-- Location of the log files on the publisher
	@LocalLocation varchar(100) = 'f:\dump\',			-- Location of the standby file on the subscriber
	@DataFilesDirectory varchar(255) = NULL,		-- Location where data files have to be moved
	@LogFilesDirectory varchar(255) = NULL,		-- Location where log files have to be moved
	@StandBy bit = 1						-- Set the database to StandBy mode, otherwise make it READWRITE mode
AS
BEGIN
/*
	Author:		<Authors - Shrikant Kumar and Clint Herring>
	Description:	<Description -	This proc automates restoring once per day read-only dbs.  
				It gets the latest from the publisher and restores that to subscribers.  The parameters tell it all the information it needs.  
				There is only one related table - DBALastFilesApplied that this proc uses to keep track of the last restored database.  
				This table does not need to be set up.  The proc creates and populates the table if it does not exist.

				This proc will try to restore a database from a bkup located in the @SourceLocation location. 

		Example: Exec usp_DBARestoreBkup 'AMG_Extra','AMG_Extra', '\\tul1cipcnpdb1\f$\dump\archive\', 'f:\dump\' 

	Modifications:	July 09, 2019 - Ajay Dwivedi
					Add parameters to accept data/log files location, and take existing files in consideration
*/

	SET NOCOUNT ON
	declare @LastFileApplied varchar(100)
	declare @execstr varchar(1000)
	declare @file TABLE (filename varchar(500))
	declare @msgstr varchar(1024);

	-- fetch existing files locations
	if OBJECT_ID('tempdb..#DbFiles_Existing') is not null
		drop table #DbFiles_Existing
	create table #DbFiles_Existing 
	(	id int identity(1,1),
		dbName varchar(125), 
		fileType varchar(10), 
		logicalName varchar(125), 
		physicalName varchar(255)
		,fileDirectory as (REPLACE(physicalName,RIGHT(physicalName,CHARINDEX('\',REVERSE(physicalName))-1),''))
		,fileBaseName as (RIGHT(physicalName,CHARINDEX('\',REVERSE(physicalName))-1)) 
	);

	-- read backup file metadata
	DECLARE @Backup_File_Details table
	(
		LogicalName          nvarchar(128),
		PhysicalName         nvarchar(260),
		[Type]               char(1),
		FileGroupName        nvarchar(128),
		Size                 numeric(20,0),
		MaxSize              numeric(20,0),
		FileID               bigint,
		CreateLSN            numeric(25,0),
		DropLSN              numeric(25,0),
		UniqueID             uniqueidentifier,
		ReadOnlyLSN          numeric(25,0),
		ReadWriteLSN         numeric(25,0),
		BackupSizeInBytes    bigint,
		SourceBlockSize      int,
		FileGroupID          int,
		LogGroupGUID         uniqueidentifier,
		DifferentialBaseLSN  numeric(25,0),
		DifferentialBaseGUID uniqueidentifier,
		IsReadOnl            bit,
		IsPresent            bit,
		TDEThumbprint        varbinary(32) -- remove this column if using SQL 2005
	)

	declare @dbFileCounts int = 0;
	declare @dbFileCounter int = 0;
	declare @_logicalName varchar(125);
	declare @_physicalName varchar(225);


	if OBJECT_ID('DBALastFileApplied') is null	--Create table if it does not exist
		begin
			CREATE TABLE DBALastFileApplied
			(
				dbname varchar(50),
				LastFileApplied varchar(100),
				lastUpdateDate datetime default CURRENT_TIMESTAMP
			)
		end

	-- AMG_avg_data.bak
	set @execstr = 'exec xp_cmdshell ''dir ' + @SourceLocation + '*' + @sourceDbname + '_FULL* /od /b '''
	insert @file exec (@execstr)
	set @execstr = 'exec xp_cmdshell ''dir ' + @SourceLocation + '*' + @sourceDbname + '_data* /od /b '''
	insert @file exec (@execstr)

	delete from @file where filename is null				-- Delete the extra NULL record created by the dir command
	delete from @file where filename = 'File not found'	
	
	if not exists (Select * from @file)
		begin
			print 'No files to process'
			return
		end
	--If (select COUNT(*) from @file) > 1
	--	begin
	--	   set @msgstr = 'There is more than one db bkup file for ' + @sourceDbname + ' in the source location ' + @sourceLocation + '.'
	--		print @msgstr
	--		Raiserror(@msgstr, 11, 1)
	--		return
	--	end
	select @LastFileApplied =  MAX(filename) from @file;

	-- fetch existing files locations
	insert #DbFiles_Existing (dbName, fileType, logicalName, physicalName)
	select db_name(mf.database_id) as dbName, type_desc as fileType, name as logicalName, physical_name as physicalName
			--,REPLACE(physical_name,RIGHT(physical_name,CHARINDEX('\',REVERSE(physical_name))-1),'')
			--,RIGHT(physical_name,CHARINDEX('\',REVERSE(physical_name))-1)
	from sys.master_files mf where mf.database_id = DB_ID(@destDbname);

	-- read backup file metadata
	SET @execstr = 'restore filelistonly from disk = '''+ @sourceLocation + @LastFileApplied + '''';
	--print @execstr;
	INSERT INTO @Backup_File_Details
	EXEC (@execstr);

	-- case 01:- when destination is existing, but logical file names does not match
	if exists(select * from #DbFiles_Existing)
	begin
		--select * from #DbFiles_Existing;
		--select * from @Backup_File_Details;

		if exists( select e.*, b.* from #DbFiles_Existing as e full outer join @Backup_File_Details as b on b.LogicalName = e.logicalName where e.logicalName is null or b.LogicalName is null)
		begin
			RAISERROR ('LogicalName of inside backup file not same as existing LogicalName of database files', 17, 1);  
			return;
		end
	end
	-- case 02:- when destination is not existing, and data/log file path is not specified
	if not exists(select * from #DbFiles_Existing) and ( @DataFilesDirectory is null or @LogFilesDirectory is null)
	begin
		RAISERROR ('Database does not pre-exists. So kindly provide Data/Log files path to be MOVED to.', 17, 1);  
		return;
	end
	
	begin
		if exists(select * from #DbFiles_Existing)
		begin
			if @StandBy = 1
				set @execstr = 'restore database [' + @destdbname + '] from disk = ''' + @sourceLocation + @LastFileApplied + ''' with stats, replace, standby = ''f:\dump\' + @sourceDbname + '_undo.dat''';
			else 
				set @execstr = 'restore database [' + @destdbname + '] from disk = ''' + @sourceLocation + @LastFileApplied + ''' with stats, replace';

			set @dbFileCounts = (select count(*) from #DbFiles_Existing);
			set @dbFileCounter = 1;
			while (@dbFileCounter <= @dbFileCounts)
			begin
				select @_logicalName = logicalName, @_physicalName = physicalName from #DbFiles_Existing where id = @dbFileCounter;
				set @execstr += ' 
		,move '''+ @_logicalName +''' to ''' + @_physicalName +'''';

				set @dbFileCounter = @dbFileCounter + 1;
			end		
			
			--print @execstr
		end

		exec(@execstr)
		
		if not exists(Select * from DBALastFileApplied where dbname = @destDbname)		-- If record does not exist
			insert into DBALastFileApplied (dbname, LastFileApplied) values(@destDbname, @LastFileApplied)	-- create it
		else
			update DBALastFileApplied SET LastFileApplied = @LastFileApplied, lastUpdateDate = CURRENT_TIMESTAMP where dbname = @destDbname -- update it
		select @LastFileApplied =  min(filename) from @file where filename > @LastFileApplied	-- Move to the next file to apply
		
	end
	
	if OBJECT_ID('tempdb..#DbFiles_Existing') is not null
		drop table #DbFiles_Existing
END
GO


