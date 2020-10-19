CREATE TABLE [dbo].[commands] (
    [command]       NVARCHAR (50)  NOT NULL,
    [query]         NVARCHAR (MAX) NOT NULL,
    [description]   NVARCHAR (MAX) NULL,
    [columns_width] NVARCHAR (MAX) CONSTRAINT [df_columns_width] DEFAULT (N'') NOT NULL,
    CONSTRAINT [PK_commands] PRIMARY KEY CLUSTERED ([command] ASC)
);








GO
CREATE   TRIGGER [dbo].[tr_commands_change]
ON [dbo].[commands]
AFTER INSERT,DELETE,UPDATE
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
    ,@commands nvarchar(max);	  

  EXEC [dbo].[usp_get_settings]
    @url = @url OUTPUT 
    ,@http_headers = @http_headers OUTPUT
    ,@chat_id = @chat_id OUTPUT;

  SET @commands = 
  (
    SELECT 
      [command] = [c].[command]
      ,[description] = [c].[description]
    FROM [dbo].[commands] [c]
    FOR JSON AUTO
  );

  SET @message_url = CONCAT(@url, 'setMyCommands');
  SET @json_chat = JSON_MODIFY(@json_chat,'$.commands', @commands);

  EXEC [dbo].[usp_HttpPost]
	  @url = @message_url,
	  @headerXml = @http_headers,
	  @requestBody = @json_chat,
	  @success = @success OUTPUT,
	  @response = @response OUTPUT,
	  @error = @error OUTPUT;

END