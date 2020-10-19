
CREATE FUNCTION [dbo].[ufn_get_num_rows]()
RETURNS bigint
AS
BEGIN
	RETURN (SELECT [value] FROM [dbo].[settings] WHERE [name] = N'num_rows');
END