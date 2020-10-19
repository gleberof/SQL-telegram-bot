CREATE PROCEDURE [dbo].[usp_Message2Command]
@json NVARCHAR (MAX) NULL, @bot_name NVARCHAR (MAX) NULL, @chat_id NVARCHAR (MAX) NULL, @response NVARCHAR (MAX) NULL OUTPUT
AS EXTERNAL NAME [SqlTelegram].[SqlTelegram.ClrHttp].[Message2Command]



