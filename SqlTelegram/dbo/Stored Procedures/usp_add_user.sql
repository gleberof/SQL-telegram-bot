CREATE PROCEDURE [dbo].[usp_add_user]
(
  @user_id bigint
  ,@name nvarchar(50)
  ,@authorized bit
)
AS
BEGIN
  SET NOCOUNT ON;

	IF NOT EXISTS
  (
    SELECT 1
    FROM [dbo].[users]
    WHERE [user_id] = @user_id
  )
  INSERT INTO [dbo].[users]
  (
    [user_id]
    ,[name]
    ,[authorized]
  )
  VALUES
  (
    @user_id
    ,@name
    ,@authorized
  );

END