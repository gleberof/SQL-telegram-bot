CREATE PROCEDURE [dbo].[usp_HttpGet]
@url NVARCHAR (MAX) NULL, @headerXml XML NULL, @success BIT NULL OUTPUT, @response NVARCHAR (MAX) NULL OUTPUT, @error NVARCHAR (MAX) NULL OUTPUT
AS EXTERNAL NAME [SqlTelegram].[SqlTelegram.ClrHttp].[HttpGet]



