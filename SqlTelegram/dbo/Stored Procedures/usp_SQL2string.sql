CREATE PROCEDURE [dbo].[usp_SQL2string]
@SqlString NVARCHAR (MAX) NULL, @num_rows INT NULL, @num_cols INT NULL, @col_width INT NULL, @list_width NVARCHAR (MAX) NULL, @response NVARCHAR (MAX) NULL OUTPUT
AS EXTERNAL NAME [SqlTelegram].[SqlTelegram.ClrHttp].[SQL2string]







