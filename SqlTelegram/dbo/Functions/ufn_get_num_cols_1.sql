
CREATE FUNCTION [dbo].[ufn_get_num_cols]()
RETURNS bigint
AS
BEGIN
	RETURN (SELECT [value] FROM [dbo].[settings] WHERE [name] = N'num_cols');
END