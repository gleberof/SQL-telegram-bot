
CREATE FUNCTION [dbo].[ufn_get_last_update_id]()
RETURNS bigint
AS
BEGIN
	RETURN (SELECT [value] FROM [dbo].[settings] WHERE [name] = N'last_update_id');
END