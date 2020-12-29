USE [telegram];
GO

-- Put bot token here
DECLARE @bot_token nvarchar(max) = N'';

SET @bot_token = @bot_token + N'/'

INSERT [dbo].[settings] ([name], [value], [value_str], [value_date]) VALUES (N'bot_token', NULL, @bot_token, NULL)
GO


-- Send message in chat
DECLARE @chat_id bigint;

EXEC [dbo].[usp_GetChatId]
  @chat_id = @chat_id OUTPUT;

INSERT [dbo].[settings] ([name], [value], [value_str], [value_date]) VALUES (N'chat_id', @chat_id, NULL, NULL)
GO


INSERT [dbo].[settings] ([name], [value], [value_str], [value_date]) VALUES (N'col_width', 10, NULL, NULL)
GO
INSERT [dbo].[settings] ([name], [value], [value_str], [value_date]) VALUES (N'http_headers', NULL, N'<Header Name="Content-Type" Value="application/json" />', NULL)
GO
INSERT [dbo].[settings] ([name], [value], [value_str], [value_date]) VALUES (N'last_check_date', NULL, NULL, NULL)
GO
INSERT [dbo].[settings] ([name], [value], [value_str], [value_date]) VALUES (N'last_update_id', 100885916, NULL, NULL)
GO
INSERT [dbo].[settings] ([name], [value], [value_str], [value_date]) VALUES (N'limit', 10, NULL, NULL)
GO
INSERT [dbo].[settings] ([name], [value], [value_str], [value_date]) VALUES (N'num_cols', 8, NULL, NULL)
GO
INSERT [dbo].[settings] ([name], [value], [value_str], [value_date]) VALUES (N'num_rows', 8, NULL, NULL)
GO
INSERT [dbo].[settings] ([name], [value], [value_str], [value_date]) VALUES (N'offset', 0, NULL, NULL)
GO
INSERT [dbo].[settings] ([name], [value], [value_str], [value_date]) VALUES (N'update_timeout', 2, NULL, NULL)
GO



INSERT [dbo].[commands] ([command], [query], [description], [columns_width]) VALUES (N'job_execution_stats', N'EXEC [monitor].[usp_get_job_execution_stats]', N'Get last job execution stats', N'10,16,16,3,9')
GO
INSERT [dbo].[commands] ([command], [query], [description], [columns_width]) VALUES (N'jobs', N'SELECT 
  [j].[name]
  ,[ja].[session_id]
  ,[start_date] = CONVERT(nvarchar(8), [ja].[start_execution_date], 114)
  ,[step_id] = ISNULL([ja].[last_executed_step_id], 0) + 1
  ,[js].[step_name]
FROM [msdb].[dbo].[sysjobactivity] [ja]
INNER JOIN [msdb].[dbo].[sysjobs] [j] ON [j].[job_id] = [ja].[job_id]
LEFT JOIN [msdb].[dbo].[sysjobsteps] [js] ON [js].[job_id] = [j].[job_id]
                                         AND ISNULL([ja].[last_executed_step_id], 0) + 1 = [js].[step_id]
WHERE [ja].[session_id] = (SELECT TOP 1 [session_id] FROM [msdb].[dbo].[syssessions] ORDER BY [agent_start_date] DESC)
  AND [ja].[start_execution_date] IS NOT NULL
  AND [ja].[stop_execution_date] IS NULL', N'Get current jobs', N'10,4,10,2,10')
GO
INSERT [dbo].[commands] ([command], [query], [description], [columns_width]) VALUES (N'sessions', N'select  session_id, status, blocking_session_id, wait_type,wait_time, wait_resource
from sys.dm_exec_requests a
where status <> ''background''
  and session_id > 40
order by wait_time desc', N'Get current sessions', N'3,3,3,10,10,10')
GO
INSERT [dbo].[commands] ([command], [query], [description], [columns_width]) VALUES (N'top_queries', N'EXEC [monitor].[usp_get_top_queries]', N'Get top 10 queries in the last 30 minutes', N'6,12,4,4,4,4,30')
GO
INSERT [dbo].[commands] ([command], [query], [description], [columns_width]) VALUES (N'version', N'SELECT @@VERSION', N'Get SQL Server version', N'600')
GO
INSERT [dbo].[commands] ([command], [query], [description], [columns_width]) VALUES (N'request_access', N'EXEC [dbo].[usp_request_access]', N'Request access to use commands', N'12')
GO


INSERT [monitor].[threshold] ([counter], [threshold], [type]) VALUES (N'cpu_usage', CAST(80.00 AS Decimal(18, 2)), N'percent')
GO
INSERT [monitor].[threshold] ([counter], [threshold], [type]) VALUES (N'disk_free_space_pct', CAST(10.00 AS Decimal(18, 2)), N'percent')
GO
INSERT [monitor].[threshold] ([counter], [threshold], [type]) VALUES (N'disk_latency', CAST(25.00 AS Decimal(18, 2)), N'msec')
GO
INSERT [monitor].[threshold] ([counter], [threshold], [type]) VALUES (N'lock_wait', CAST(60.00 AS Decimal(18, 2)), N'sec')
GO
