
CREATE PROCEDURE [dbo].[usp_SendSticker]
(
	@sticker nvarchar(max)
)
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
    ,@error nvarchar(max);

  EXEC [dbo].[usp_get_settings]
    @url = @url OUTPUT 
    ,@http_headers = @http_headers OUTPUT
    ,@chat_id = @chat_id OUTPUT;

  SET @message_url = CONCAT(@url, N'sendSticker');
  SET @json_chat = JSON_MODIFY(@json_chat, '$.sticker', @sticker);
  SET @json_chat = JSON_MODIFY(@json_chat, '$.chat_id', @chat_id);

  EXEC dbo.usp_HttpPost
    @url = @message_url,
    @headerXml = @http_headers,
    @requestBody = @json_chat,
    @success = @success OUTPUT,
    @response = @response OUTPUT,
    @error = @error OUTPUT;
END