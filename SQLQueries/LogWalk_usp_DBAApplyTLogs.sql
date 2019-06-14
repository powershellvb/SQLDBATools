USE [DBA]
GO

IF OBJECT_ID('dbo.usp_DBAApplyTLogs') IS NULL
	EXEC ('CREATE PROCEDURE dbo.usp_DBAApplyTLogs AS SELECT 1 AS DummyToBeReplace;');
GO

ALTER PROCEDURE [dbo].[usp_DBAApplyTLogs]
	-- Add the parameters for the stored procedure here
	@sourceDbname varchar(50),							-- Database name on the publisher
	@destDbname varchar(50),							-- Database name on the subscriber
	@SourceLocation varchar(100) = '\\tul1cipcnpdb1\f$\dump\',	-- Location of the log files on the publisher; default Prod
	@LocalLocation varchar(100) = 'f:\LogWalk_TUF_Files\'					-- Location of the standby file on the subscriber
AS
BEGIN
	-- =============================================
	-- Author:		<Authors - Shrikant Kumar and Clint Herring>
	-- Create date: <Create Date - 6/13/2014>
	-- Description:	<Description -	This proc automates applying logs for log shipping.  It reads the log files generated
	-- on the publisher and applies them to the subscriber.  The parameters tell it all the information it needs.  There 
	-- is only one related table - DBALastFileApplied (located in the master database) that this proc uses to keep track of 
	-- which log was applied last on the database.  This table does not need to be set up.  The proc creates and populates
	-- the table if it does not exist.
	--
	-- This proc will try to apply logs located in the @SourceLocation location.  If it is not the right file, it will
	-- move on to the next file and try to apply it, till it finds the right file.  If it is not able to find the right 
	-- file to apply it will quit with an error message - 'Restore failed due to missing file.'  To rectify the issue, the 
	-- user will have to point the @SourceLocation to location where the correct file exists and delete the DBALastFileApplied
	-- table in the Master database of the subscriber.
	-- 2015/05/29 WCH Added a new column PointerResetFile in case the job is ever manually stopped this will be the start file value.
	-- =============================================

	SET NOCOUNT ON
	declare @LastFileApplied varchar(100)
	declare @execstr varchar(1000)
	declare @Failed int
	Declare @file TABLE (filename varchar(500));
	DECLARE @SuccessfullApply varchar(100);

	set @Failed = 0;							-- Flag to check if the last apply was successful or not
	if OBJECT_ID('DBALastFileApplied') is null	--Create table if it does not exist
		begin
			CREATE TABLE DBALastFileApplied
			(
				dbname varchar(50),
				LastFileApplied varchar(100),
				lastUpdateDate datetime default CURRENT_TIMESTAMP
			)
		end

	Select @LastFileApplied = Isnull(PointerResetFile,LastFileApplied) from DBALastFileApplied where dbname = @destDbname	-- Get the last log file applied
   Set @SuccessfullApply = @LastFileApplied

	--set @execstr = 'exec xp_cmdshell ''dir ' + @SourceLocation + '*' + @sourceDbname + '_* /od /b '''
	set @execstr = 'exec xp_cmdshell ''dir ' + @SourceLocation + '*' + @sourceDbname + '_LOG_* /od /b ''';

	insert @file exec (@execstr)
	delete from @file where filename is null				-- Delete the extra NULL record created by the dir command
	delete from @file where filename = 'File not found'		
	if not exists (Select * from @file)
	begin
		print 'No files to process'
		return
	end

	exec xp_create_subdir @LocalLocation;
	
	if(@LastFileApplied is not null)							-- Skip files that have already been applied
		delete from @file where filename <= @LastFileApplied
		
	select @LastFileApplied =  min(filename) from @file
	while @LastFileApplied is not null
	begin
		set @execstr = 'restore log [' + @destdbname + '] from disk = ''' + @sourceLocation + @LastFileApplied + ''' with stats, replace, norecovery'
		print @execstr
		begin try							-- Apply Transaction logs
			exec(@execstr)
			set @Failed = 0;
			SET @SuccessfullApply = @LastFileApplied
		end try
		begin catch
			select ERROR_MESSAGE();
			print 'Failed on restoring ' + @LastFileApplied
			set @Failed = 1;
		end catch
		if not exists(Select * from DBALastFileApplied where dbname = @destDbname)		-- If record does not exist
			insert into DBALastFileApplied (dbname, LastFileApplied) values(@destDbname, @LastFileApplied)	-- create it
		else
			update DBALastFileApplied SET LastFileApplied = @LastFileApplied, lastUpdateDate = CURRENT_TIMESTAMP where dbname = @destDbname -- update it
		select @LastFileApplied =  min(filename) from @file where filename > @LastFileApplied	-- Move to the next file to apply
	end
	
	UPDATE DBALastFileApplied set LastFileApplied = @SuccessfullApply, lastUpdateDate = CURRENT_TIMESTAMP WHERE dbname = @destDbname;		-- This update will reset the LastFileApplied to the last good restore point.
	if(@Failed = 1)
	begin
		if(@SuccessfullApply is null)
			set @execstr = 'No log file was applied due to missing file'
		else
			set @execstr = 'Restore failed due to missing file.  Last successful log file applied was ' + @SuccessfullApply
		Raiserror(@execstr, 11, 1)
	end
	IF (SELECT Is_In_Standby FROM sys.databases WHERE Name = @destDbname AND [State] = 1) = 0
	BEGIN							-- Set database in usable (Read only) mode
		set @execstr = 'restore database [' + @destdbname + '] with standby=''' + @LocalLocation + @destDbname + '_undo.dat'''
		print @execstr
		exec(@execstr)
	END
END


GO


