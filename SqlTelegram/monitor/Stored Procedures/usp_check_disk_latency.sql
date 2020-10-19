CREATE   PROCEDURE [monitor].[usp_check_disk_latency] 
AS
BEGIN
  SET NOCOUNT ON ;

  DECLARE 
    @message nvarchar(max)
    ,@threshold int
    ,@cpu_value int;

  SELECT @threshold = [t].[threshold]
  FROM [monitor].[threshold] [t]
  WHERE [t].[counter] = N'disk_latency';

  IF OBJECT_ID('tempdb..#t_disk_latency') IS NOT NULL
    DROP TABLE [#t_disk_latency];

  SELECT 
    [vfs].[database_id]
    ,[vfs].[file_id]
    ,[vfs].[sample_ms]
    ,[vfs].[num_of_reads]
    ,[vfs].[num_of_writes]
    ,[vfs].[io_stall_read_ms]
    ,[vfs].[io_stall_write_ms]
  INTO [#t_disk_latency]
  FROM sys.dm_io_virtual_file_stats (NULL, NULL) [vfs];

  ;WITH [file_usage_stats] AS 
  (
    SELECT 
      [db_name] = DB_NAME([cur].[database_id])
      ,[file_type] = [mf].[type_desc]
      ,[read_latency] = IIF(([cur].[num_of_reads] - [prev].[num_of_reads]) = 0
                            ,0 
                            ,(([cur].[io_stall_read_ms] - [prev].[io_stall_read_ms]) / ([cur].[num_of_reads] - [prev].[num_of_reads])) 
                            )
      ,[write_latency] = IIF(([cur].[num_of_writes] - [prev].[num_of_writes]) = 0 
                              ,0 
                              ,(([cur].[io_stall_write_ms] - [prev].[io_stall_write_ms]) / ([cur].[num_of_writes] - [prev].[num_of_writes])) 
                            )
    FROM [#t_disk_latency] [cur]
    INNER JOIN [monitor].[disk_latency] [prev] ON [prev].[database_id] = [cur].[database_id]
                                              AND [prev].[file_id] = [cur].[file_id]
    INNER JOIN sys.master_files [mf] ON [mf].[database_id] = [cur].[database_id]
                                    AND [mf].[file_id] = [cur].[file_id]
  )
  SELECT @message = STUFF
  ((
    SELECT CHAR(10)
      + N'Время выполнения операции ' + IIF([unpvt].[io_type] = N'read_latency', N'чтения: ', N'записи: ') + CAST([unpvt].[latency] AS nvarchar(max)) + N' мсек' + CHAR(10)
      + N'База данных: ' + [unpvt].[db_name] + CHAR(10) 
      + N'Тип файла: ' + [unpvt].[file_type] + CHAR(10)      
    FROM
    (
      SELECT 
        [db_name] = [fus].[db_name]
        ,[file_type] = [fus].[file_type]
        ,[read_latency] = [fus].[read_latency]
        ,[write_latency] = [fus].[write_latency]
      FROM [file_usage_stats] [fus]
    ) [p]
    UNPIVOT
    (
      [latency] FOR [io_type] IN ([read_latency], [write_latency])
    ) AS [unpvt]
    WHERE [unpvt].[latency] >= @threshold
    FOR XML PATH(N''))
    , 1, 1, N'' 
  );

  DELETE 
  FROM [monitor].[disk_latency];

  INSERT INTO [monitor].[disk_latency]
  (
    [database_id]
    ,[file_id]
    ,[sample_ms]
    ,[num_of_reads]
    ,[num_of_writes]
    ,[io_stall_read_ms]
    ,[io_stall_write_ms]
  )
  SELECT 
    [tdl].[database_id]
    ,[tdl].[file_id]
    ,[tdl].[sample_ms]
    ,[tdl].[num_of_reads]
    ,[tdl].[num_of_writes]
    ,[tdl].[io_stall_read_ms]
    ,[tdl].[io_stall_write_ms]
  FROM [#t_disk_latency] [tdl];

  IF @message IS NOT NULL
    EXEC [dbo].[usp_SendMessage]
      @message = @message;

END;