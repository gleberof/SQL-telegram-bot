CREATE PROCEDURE [monitor].[usp_check_cpu_usage] 
AS
BEGIN
  SET NOCOUNT ON ;

  DECLARE 
    @message nvarchar(max)
    ,@threshold int
    ,@cpu_value int;

  SELECT @threshold = [t].[threshold]
  FROM [monitor].[threshold] [t]
  WHERE [t].[counter] = N'cpu_usage';

  SELECT 
    @cpu_value = [record].value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int')
  FROM 
  (
    SELECT TOP (1) CONVERT(XML, [record]) AS [record]
    FROM sys.dm_os_ring_buffers [rb]
    WHERE [ring_buffer_type] = N'RING_BUFFER_SCHEDULER_MONITOR'
      AND [record] LIKE '% %'
    ORDER BY [timestamp] DESC
  ) AS [cpu_usage];

  IF @cpu_value >= @threshold
  BEGIN
    SET @message = N'Загрузка CPU: ' + CAST(@cpu_value AS nvarchar(3)) + '%';

    EXEC [dbo].[usp_SendMessage]
      @message = @message;
  END;

END;