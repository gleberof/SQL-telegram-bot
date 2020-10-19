
CREATE FUNCTION [dbo].[ufn_get_col_width]()
RETURNS bigint
AS
BEGIN
	RETURN (SELECT [value] FROM [dbo].[settings] WHERE [name] = N'col_width');
END