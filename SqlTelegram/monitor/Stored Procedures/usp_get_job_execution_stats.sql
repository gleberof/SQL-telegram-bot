
CREATE   PROCEDURE [monitor].[usp_get_job_execution_stats]
(
  @date_from datetime = NULL
  ,@job_name sysname = NULL
)
AS
BEGIN

  SET NOCOUNT ON;

  ;WITH [cte_last_job_run] AS
  (
    SELECT 
      [jh].[job_id]
      ,[jh].[run_status]
      ,[jh].[run_date]
      ,[jh].[run_time]
      ,[jh].[run_duration]
      ,[rn] = RANK() OVER (PARTITION BY [job_id] ORDER BY [run_date] DESC, [run_time] DESC)
    FROM [msdb].[dbo].[sysjobhistory] [jh]
    WHERE [step_id] = 0
  )
  SELECT 
    [job_name] = [j].[name]
    ,[last_run_date] = CONVERT(nvarchar(16), [msdb].[dbo].[agent_datetime]([jh].[run_date], [jh].[run_time]), 120)
    ,[nex_run_date] = CONVERT(nvarchar(16), [msdb].[dbo].[agent_datetime]([js].[next_run_date], [js].[next_run_time]), 120)
    ,[run_status] = CASE [jh].[run_status]
		                  WHEN 0 THEN 'Failed'
		                  WHEN 1 THEN 'Success'
		                  WHEN 2 THEN 'Retry'
		                  WHEN 3 THEN 'Canceled'
		                  WHEN 4 THEN 'In progress'
		                END 
    ,[run_duration] = STUFF(STUFF(STUFF(RIGHT(REPLICATE('0', 8) + CAST([jh].[run_duration] as varchar(8)), 8), 3, 0, ':'), 6, 0, ':'), 9, 0, ':')
  FROM [msdb].[dbo].[sysjobs] [j] 
  INNER JOIN [cte_last_job_run] [jh] ON [j].[job_id] = [jh].[job_id]
  INNER JOIN [msdb].[dbo].[sysjobschedules] [js] ON [js].[job_id] = [j].[job_id]
  WHERE [jh].[rn] = 1
    AND ([msdb].[dbo].[agent_datetime]([jh].[run_date], [jh].[run_time]) >= @date_from OR @date_from IS NULL)
    AND ([j].[name] = @job_name OR @job_name IS NULL);

END;