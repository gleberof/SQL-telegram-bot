
CREATE PROCEDURE [dbo].[usp_GetChatId]
(
  @chat_id bigint OUTPUT
)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE 
    @url nvarchar(max)
    ,@http_headers xml
    ,@json_chat nvarchar(max) = '{}'
    ,@message_url nvarchar(max)
    ,@success bit
    ,@response nvarchar(max)
    ,@error nvarchar(max);	  

  EXEC [dbo].[usp_get_settings]
    @url = @url OUTPUT 
    ,@http_headers = @http_headers OUTPUT;

  SET @message_url = CONCAT(@url, 'getUpdates');

  EXEC [dbo].[usp_HttpPost]
	  @url = @message_url,
	  @headerXml = @http_headers,
	  @requestBody = @json_chat,
	  @success = @success OUTPUT,
	  @response = @response OUTPUT,
	  @error = @error OUTPUT;

  SELECT TOP (1) @chat_id = [chat_id]
  FROM OPENJSON (@response, N'$.result')
  WITH 
  (
    [chat_id] nvarchar(max) N'$.message.chat.id'
    ,[update_id] bigint N'$.update_id'
  )
  ORDER BY [update_id] DESC;

END;