CREATE   PROCEDURE [monitor].[usp_check_job_failed] 
AS
BEGIN
  SET NOCOUNT ON ;

  DECLARE 
    @message nvarchar(max)
    ,@threshold bigint;

  SELECT @threshold = [t].[threshold]
  FROM [monitor].[threshold] [t]
  WHERE [t].[counter] = N'lock'

  SELECT @message = STUFF
  ((
    SELECT CHAR(10)
      + N'Задание [' + [j].[name] + N'] завершилось с ошибкой ' + CHAR(10)
      + N'Шаг: ' + [s].[step_name] + CHAR(10) 
      + N'Время запуска: ' + CONVERT(nvarchar(30), [msdb].[dbo].[agent_datetime]([h].[run_date], [h].[run_time]), 120) + CHAR(10) 
      + N'Длительность выполнения: ' + CAST((([h].[run_duration]/10000*3600 + ([h].[run_duration]/100)%100*60 + [h].[run_duration]%100 + 31 ) / 60) AS nvarchar(max)) + N' мин' + CHAR(10)
    FROM [msdb].[dbo].[sysjobhistory] [h]
    INNER JOIN [msdb].[dbo].[sysjobs] [j] ON [j].[job_id] = [h].[job_id]
    INNER JOIN [msdb].[dbo].[sysjobsteps] [s] ON [s].[job_id] = [j].[job_id]
    WHERE [h].[step_id] <> 0
      AND [msdb].[dbo].[agent_datetime]([h].[run_date], [h].[run_time]) >= DATEADD(minute, -15, GETDATE())
      AND [h].[run_status] = 0 -- Failure
    FOR XML PATH(N''))
    , 1, 1, N''
  );

  IF @message IS NOT NULL
    EXEC [dbo].[usp_SendMessage]
      @message = @message;

END;