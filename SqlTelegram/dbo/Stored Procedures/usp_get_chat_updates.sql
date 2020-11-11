CREATE   PROCEDURE [dbo].[usp_get_chat_updates]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE 
    @chat_id bigint
    ,@url nvarchar(max)  
    ,@http_headers xml   
    ,@offset bigint
    ,@update_timeout bigint
    ,@limit bigint
    ,@num_rows bigint
    ,@num_cols bigint
    ,@col_width bigint
    ,@success bit
    ,@response nvarchar(max)
    ,@error nvarchar(max)
    ,@query_url nvarchar(max)
    ,@json_update nvarchar(max) = '{}'
    ,@json_chat nvarchar(max) = N'{}'
    ,@command_response nvarchar(max)
    ,@text nvarchar(max)
    ,@message_url nvarchar(max)
    ,@message nvarchar(max)
    ,@query nvarchar(max)
    ,@update_id bigint
    ,@user_id bigint;	

  EXEC [dbo].[usp_get_settings]
    @url = @url OUTPUT 
    ,@http_headers = @http_headers OUTPUT
    ,@chat_id = @chat_id OUTPUT
    ,@last_update_id = @offset OUTPUT
    ,@update_timeout = @update_timeout OUTPUT
    ,@limit = @limit OUTPUT
    ,@num_rows = @num_rows OUTPUT
    ,@num_cols = @num_cols OUTPUT
    ,@col_width = @col_width OUTPUT;

  SET @offset = ISNULL(@offset + 1, 0);

  SET @query_url = CONCAT(@url, 'getUpdates');
  SET @json_update = JSON_MODIFY(@json_update,'$.timeout', @update_timeout);
  SET @json_update = JSON_MODIFY(@json_update,'$.offset', @offset);
  SET @json_update = JSON_MODIFY(@json_update,'$.limit', @limit);

  EXEC [dbo].[usp_HttpPost]
	  @url = @query_url,
	  @headerXml = @http_headers,
	  @requestBody = @json_update,
	  @success = @success OUTPUT,
	  @response = @response OUTPUT,
	  @error = @error OUTPUT;

  EXEC [dbo].[usp_Message2Command]
    @json = @response
    ,@bot_name = N'sql_tel_bot'
    ,@chat_id = @chat_id
    ,@response = @command_response OUTPUT;

  IF @command_response IS NOT NULL
  BEGIN
    SET @message_url = CONCAT(@url, N'sendMessage');
    SET @json_chat = N'{}';
    SET @json_chat = JSON_MODIFY(@json_chat, '$.text', @command_response);
    SET @json_chat = JSON_MODIFY(@json_chat, '$.chat_id', @chat_id); 
    SET @json_chat = JSON_MODIFY(@json_chat, '$.parse_mode', 'Markdown'); 

    EXEC [dbo].[usp_HttpPost]
      @url = @message_url,
      @headerXml = @http_headers,
      @requestBody = @json_chat,
      @success = @success OUTPUT,
      @response = @command_response OUTPUT,
      @error = @error OUTPUT;
  END;

  SELECT TOP (1) 
    @text = [text]
    ,@update_id = [update_id]
    ,@user_id = [user_id]
  FROM OPENJSON (@response, N'$.result')
  WITH 
  (
    [text] nvarchar(max) N'$.message.text'
    ,[chat_id] bigint N'$.message.chat.id'
    ,[update_id] bigint N'$.update_id' 
    ,[user_id] bigint N'$.message.from.id'
  )
  WHERE [chat_id] = @chat_id
  ORDER BY [update_id] DESC;

  IF LEFT(@text, 1) = N'*'
  AND EXISTS 
  (
    SELECT 1
    FROM [dbo].[users] [u]
    WHERE [u].[user_id] = @user_id
      AND [u].[authorized] = 1
  )
  BEGIN

    SET @query = RIGHT(@text, LEN(@text) - 1);

    EXEC [dbo].[usp_SQL2string]
	    @SqlString = @query,
	    @num_rows = @num_rows,
	    @num_cols = @num_cols,
      @col_width = @col_width,
      @list_width = N'',
      @response = @message OUTPUT

    SET @message_url = CONCAT(@url, N'sendMessage');
    SET @json_chat = N'{}';
    SET @json_chat = JSON_MODIFY(@json_chat, '$.text', @message);
    SET @json_chat = JSON_MODIFY(@json_chat, '$.chat_id', @chat_id); 
    SET @json_chat = JSON_MODIFY(@json_chat, '$.parse_mode', 'Markdown'); 

    EXEC [dbo].[usp_HttpPost]
      @url = @message_url,
      @headerXml = @http_headers,
      @requestBody = @json_chat,
      @success = @success OUTPUT,
      @response = @response OUTPUT,
      @error = @error OUTPUT;

  END;

  IF @update_id IS NOT NULL
    UPDATE [dbo].[settings]
    SET [value] = @update_id
    WHERE [name] = N'last_update_id';

END;