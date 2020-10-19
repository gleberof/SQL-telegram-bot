CREATE PROCEDURE [monitor].[usp_check_lock_wait] 
AS
BEGIN
  SET NOCOUNT ON ;

  DECLARE 
    @message nvarchar(max)
    ,@threshold bigint;

  SELECT @threshold = [t].[threshold]
  FROM [monitor].[threshold] [t]
  WHERE [t].[counter] = N'lock_wait'

  SELECT @message = STUFF
  ((
    SELECT CHAR(10)
      + N'Сессия ' + CAST([p].[spid] as nvarchar(max)) + N' заблокирована сессией ' + CAST([p].[blocked] as nvarchar(max)) + N' дольше ' + CAST([p].[waittime]/1000 as nvarchar(max)) + N' секунд' + CHAR(10)
      + N'Тип ожидания: ' + [p].[lastwaittype] + CHAR(10) 
      + N'База данных: ' + DB_NAME([p].[dbid]) + CHAR(10) 
      + N'Объект ожидания: ' + [p].[waitresource] + CHAR(10)
    FROM sys.sysprocesses [p]
    WHERE [p].[blocked] > 0 
      AND [p].[blocked] <> [p].[spid]
      AND [p].[waittime] >= @threshold * 1000
    FOR XML PATH(N''))
    , 1, 1, N''
  );

  IF @message IS NOT NULL
    EXEC [dbo].[usp_SendMessage]
      @message = @message;

END;