CREATE   PROCEDURE [monitor].[usp_get_progress]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE 
    @chat_id bigint
    ,@url nvarchar(max)
    ,@http_headers xml
    ,@json_chat nvarchar(max) = N'{}'
    ,@message_url nvarchar(max)
    ,@success bit
    ,@response nvarchar(max)
    ,@error nvarchar(max)
    ,@message nvarchar(max)
    ,@message_id bigint
    ,@session_id bigint
    ,@command nvarchar(50)
    ,@database sysname
    ,@start_time datetime
    ,@estimated_completion_time datetime
    ,@percent_complete numeric(5,2);

  EXEC [dbo].[usp_get_settings]
    @url = @url OUTPUT 
    ,@http_headers = @http_headers OUTPUT
    ,@chat_id = @chat_id OUTPUT;
   
  IF OBJECT_ID('tempdb..#t_progress') IS NOT NULL
    DROP TABLE [#t_progress];
  
  SELECT 
    [session_id] = [r].[session_id]
    ,[command] = [r].[command]
    ,[database] = DB_NAME([r].[database_id])
    ,[start_time] = [r].[start_time]
    ,[estimated_completion_time] = DATEADD(second, [r].[estimated_completion_time]/1000, GETDATE())
    ,[percent_complete] = [r].[percent_complete]
  INTO [#t_progress]
  FROM sys.dm_exec_requests [r] 
  WHERE [r].[command] IN ('BACKUP DATABASE','RESTORE DATABASE')
  
  DECLARE [cur_progress] CURSOR LOCAL FAST_FORWARD FOR
  SELECT 
    [session_id] = [t].[session_id]
    ,[command] = [t].[command]
    ,[database] = [t].[database]
    ,[start_time] = [t].[start_time]
    ,[estimated_completion_time] = [t].[estimated_completion_time]
    ,[percent_complete] = [t].[percent_complete]
    ,[message_id] = [p].[message_id]
  FROM [#t_progress] [t] 
  LEFT JOIN [monitor].[progress] [p] ON [p].[session_id] = [t].[session_id]

  OPEN [cur_progress];

  WHILE 1 = 1
  BEGIN
    FETCH NEXT FROM [cur_progress] INTO @session_id, @command, @database, @start_time, @estimated_completion_time, @percent_complete, @message_id
    IF @@FETCH_STATUS <> 0 BREAK;

    SET @message = CONCAT(
                          N'Сессия: ' + CONVERT(nvarchar(20), @session_id) + CHAR(10)
                          ,N'База: ' + @database + CHAR(10)
                          ,N'Команда: ' + @command + CHAR(10)
                          ,N'Время начала: ' + CONVERT(nvarchar(50), @start_time, 120) + CHAR(10)
                          ,N'Прогнозируемое время завершения: ' + CONVERT(nvarchar(50), @estimated_completion_time, 120) + CHAR(10)
                          ,REPLICATE(N'▓', FLOOR(@percent_complete/10)) + REPLICATE(N'░', 10 - FLOOR(@percent_complete/10)), CONVERT(nvarchar(6), @percent_complete) + N'%' + CHAR(10)
                         );
    SET @json_chat = N'{}';
    SET @json_chat = JSON_MODIFY(@json_chat, '$.text', @message);
    SET @json_chat = JSON_MODIFY(@json_chat, '$.chat_id', @chat_id);
    
    IF @message_id IS NOT NULL
    BEGIN
            
      SET @message_url = CONCAT(@url, N'editMessageText');
      SET @json_chat = JSON_MODIFY(@json_chat, '$.message_id', @message_id);

      EXEC [dbo].[usp_HttpPost]
        @url = @message_url,
        @headerXml = @http_headers,
        @requestBody = @json_chat,
        @success = @success OUTPUT,
        @response = @response OUTPUT,
        @error = @error OUTPUT;

    END
    ELSE
    BEGIN
            
      SET @message_url = CONCAT(@url, N'sendMessage');  

      EXEC [dbo].[usp_HttpPost]
        @url = @message_url,
        @headerXml = @http_headers,
        @requestBody = @json_chat,
        @success = @success OUTPUT,
        @response = @response OUTPUT,
        @error = @error OUTPUT;

      SELECT TOP (1) @message_id = [message_id]
      FROM OPENJSON (@response, N'$.result')
      WITH 
      (
        [message_id] nvarchar(max) N'$.message_id'
      );

      INSERT INTO [monitor].[progress]
      (
        [session_id]
        ,[message_id]
        ,[command]
        ,[database]
        ,[start_time]
        ,[estimated_completion_time]
      )
      VALUES
      (
        @session_id
        ,@message_id
        ,@command
        ,@database
        ,@start_time
        ,@estimated_completion_time
      );

    END;

  END;

  CLOSE [cur_progress];
  DEALLOCATE [cur_progress];
  
  DECLARE [cur_complete] CURSOR LOCAL FAST_FORWARD FOR
  SELECT 
    [p].[session_id]
    ,[p].[message_id]
    ,[p].[command]
    ,[p].[database]
    ,[p].[start_time]
    ,[p].[estimated_completion_time]
  FROM [monitor].[progress] [p] 
  LEFT JOIN [#t_progress] [t] ON [t].[session_id] = [p].[session_id]
  WHERE [t].[session_id] IS NULL
  
  OPEN [cur_complete];

  WHILE 1 = 1
  BEGIN
    FETCH NEXT FROM [cur_complete] INTO @session_id, @message_id, @command, @database, @start_time, @estimated_completion_time
    IF @@FETCH_STATUS <> 0 BREAK;

    SET @message_url = CONCAT(@url, N'editMessageText');
    SET @message = CONCAT(
                          N'Сессия: ' + CONVERT(nvarchar(20), @session_id) + CHAR(10)
                          ,N'База: ' + @database + CHAR(10)
                          ,N'Команда: ' + @command + CHAR(10)
                          ,N'Время начала: ' + CONVERT(nvarchar(50), @start_time, 120) + CHAR(10)
                          ,N'Прогнозируемое время завершения: ' + CONVERT(nvarchar(50), @estimated_completion_time, 120) + CHAR(10)
                          ,REPLICATE(N'▓', 10), N'100%' + CHAR(10)
                          );
    SET @json_chat = N'{}';
    SET @json_chat = JSON_MODIFY(@json_chat, '$.text', @message);
    SET @json_chat = JSON_MODIFY(@json_chat, '$.chat_id', @chat_id);
    SET @json_chat = JSON_MODIFY(@json_chat, '$.message_id', @message_id);

    EXEC [dbo].[usp_HttpPost]
      @url = @message_url,
      @headerXml = @http_headers,
      @requestBody = @json_chat,
      @success = @success OUTPUT,
      @response = @response OUTPUT,
      @error = @error OUTPUT;

    DELETE
    FROM [monitor].[progress]
    WHERE [session_id] = @session_id;

  END; 
  
  CLOSE [cur_complete];
  DEALLOCATE [cur_complete];

END;