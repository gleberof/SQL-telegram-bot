CREATE PROCEDURE [dbo].[usp_request_access]
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
    ,@user_id bigint
    ,@name nvarchar(50);	  

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

  SELECT TOP (1) 
    @user_id = [user_id]
    ,@name = [name]
  FROM OPENJSON (@response, N'$.result')
  WITH 
  (
    [text] nvarchar(max) N'$.message.text'
    ,[chat_id] bigint N'$.message.chat.id'
    ,[update_id] bigint N'$.update_id'
    ,[user_id] bigint N'$.message.from.id'
    ,[name] nvarchar(50) N'$.message.from.username'
  )
  WHERE [chat_id] = @chat_id
    AND [text] LIKE '/request_access%'
  ORDER BY [update_id] DESC;

  EXEC [dbo].[usp_add_user]
    @user_id = @user_id
    ,@name = @name
    ,@authorized = 0;

  SELECT [response] = 'User created'

END