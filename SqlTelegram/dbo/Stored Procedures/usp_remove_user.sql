CREATE PROCEDURE [dbo].[usp_remove_user]
(
  @user_id bigint
)
AS
BEGIN
  SET NOCOUNT ON;

	DELETE [dbo].[users]
  WHERE [user_id] = @user_id;

END