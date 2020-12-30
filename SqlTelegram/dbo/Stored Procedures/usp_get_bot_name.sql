CREATE   PROCEDURE [dbo].[usp_get_bot_name]
(
  @bot_name nvarchar(max) OUTPUT
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

  SET @message_url = CONCAT(@url, 'getMe');

  EXEC [dbo].[usp_HttpPost]
	  @url = @message_url,
	  @headerXml = @http_headers,
	  @requestBody = @json_chat,
	  @success = @success OUTPUT,
	  @response = @response OUTPUT,
	  @error = @error OUTPUT;

  SELECT TOP (1) @bot_name = [username]
  FROM OPENJSON (@response, N'$.result')
  WITH 
  (
    [username] nvarchar(max) N'$.username'
  );

END;