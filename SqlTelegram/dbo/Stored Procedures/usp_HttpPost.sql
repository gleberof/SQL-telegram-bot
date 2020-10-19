CREATE PROCEDURE [dbo].[usp_HttpPost]
@url NVARCHAR (MAX) NULL, @headerXml XML NULL, @requestBody NVARCHAR (MAX) NULL, @success BIT NULL OUTPUT, @response NVARCHAR (MAX) NULL OUTPUT, @error NVARCHAR (MAX) NULL OUTPUT
AS EXTERNAL NAME [SqlTelegram].[SqlTelegram.ClrHttp].[HttpPost]



