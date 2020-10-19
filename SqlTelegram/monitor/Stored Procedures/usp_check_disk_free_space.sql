CREATE   PROCEDURE [monitor].[usp_check_disk_free_space] 
AS
BEGIN
  SET NOCOUNT ON ;

  DECLARE 
    @message nvarchar(max)
    ,@threshold int
    ,@cpu_value int;

  SELECT @threshold = [t].[threshold]
  FROM [monitor].[threshold] [t]
  WHERE [t].[counter] = N'disk_free_space_pct';

  ;WITH [disk_free_space] AS
  (
    SELECT DISTINCT 
      [disk_name] = LEFT([dovs].[volume_mount_point], 1)
      ,[free_space_prc] = CONVERT(decimal(5,2), CONVERT(decimal(18,2), [dovs].[available_bytes]/1048576.0)/CONVERT(decimal(18,2), [dovs].[total_bytes]/1048576.0) * 100)
    FROM sys.master_files [mf]
    CROSS APPLY sys.dm_os_volume_stats([mf].[database_id], [mf].[FILE_ID]) [dovs]
  )
  SELECT @message = STUFF
  ((
    SELECT CHAR(10)
      + N'Свободное место на диске ' + [disk_name] + N': ' + CAST([dfs].[free_space_prc] AS nvarchar(6)) + N'%' + CHAR(10)      
    FROM [disk_free_space] [dfs]
    WHERE [dfs].[free_space_prc] <= @threshold
    FOR XML PATH(N''))
    , 1, 1, N'' 
  );

  IF @message IS NOT NULL
    EXEC [dbo].[usp_SendMessage]
      @message = @message;

END;