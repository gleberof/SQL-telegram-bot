CREATE   PROCEDURE [monitor].[usp_get_top_queries]
(
  @date_from datetime = NULL
  ,@db_name sysname = NULL
  ,@object_name sysname = NULL
)
AS
BEGIN

  SET NOCOUNT ON;

  SET @date_from = ISNULL(@date_from, DATEADD(minute, -30, GETDATE()));

  SELECT TOP (10) 
    --[query_hash] = [query_stats].[query_hash]
	  --,
    [db_name] = MIN([query_stats].[db_name])
    ,[object_name] = MIN([query_stats].[object_name])
    ,[execution_count] = SUM([query_stats].[execution_count])
    ,[min_elapsed_time] = MIN([query_stats].[min_elapsed_time])
    ,[avg_elapsed_time] = SUM([query_stats].[total_elapsed_time])/SUM([query_stats].[execution_count])
    ,[max_elapsed_time] = MAX([query_stats].[max_elapsed_time])
	  ,[statement] = MIN([query_stats].[statement_text])
  FROM (
	  SELECT 
      [qs].[query_hash]
      ,[qs].[execution_count]
      ,[qs].[min_elapsed_time]
      ,[qs].[total_elapsed_time]
      ,[qs].[max_elapsed_time]
		  ,[statement_text] = SUBSTRING([st].[text], ([qs].[statement_start_offset] / 2) + 1, (
				    (
					    CASE [statement_end_offset]
						    WHEN - 1
							    THEN DATALENGTH([st].[text])
						    ELSE [qs].[statement_end_offset]
					    END - [qs].[statement_start_offset]
				    ) / 2
				  ) + 1)
		  ,[db_name] = DB_NAME([st].[dbid])
		  ,[object_name] = OBJECT_NAME([st].[objectid], [st].[dbid])
	  FROM sys.dm_exec_query_stats [qs]
	  CROSS APPLY sys.dm_exec_sql_text([qs].[sql_handle]) [st]
    WHERE [qs].[last_execution_time] >= @date_from
      AND (DB_NAME([st].[dbid]) = @db_name OR @db_name IS NULL)
      AND (OBJECT_NAME([st].[objectid], [st].[dbid]) = @object_name OR @object_name IS NULL)
	  ) AS [query_stats]
  GROUP BY [query_stats].[query_hash]
  ORDER BY [max_elapsed_time] DESC;

END;