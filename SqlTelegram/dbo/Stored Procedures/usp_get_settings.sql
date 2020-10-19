CREATE   PROCEDURE [dbo].[usp_get_settings]
(
  @url nvarchar(max) = NULL OUTPUT 
  ,@http_headers xml = NULL OUTPUT
  ,@chat_id bigint = NULL OUTPUT
  ,@last_update_id bigint = NULL OUTPUT
  ,@offset bigint = NULL OUTPUT
  ,@update_timeout bigint = NULL OUTPUT
  ,@limit bigint = NULL OUTPUT
  ,@num_rows bigint = NULL OUTPUT
  ,@num_cols bigint = NULL OUTPUT
  ,@col_width bigint = NULL OUTPUT
)
AS
BEGIN
  SET NOCOUNT ON;

  SELECT 
    @chat_id = [chat_id]
    ,@col_width = [col_width]
    ,@last_update_id = [last_update_id]
    ,@offset = [offset]
    ,@limit = [limit]
    ,@num_cols = [num_cols]
    ,@num_rows = [num_rows]
    ,@update_timeout = [update_timeout]
  FROM
  (
    SELECT 
      [name]
      ,[value]
    FROM [dbo].[settings] [s]
  ) [p]
  PIVOT
  (
    MAX([value])
    FOR [name] IN 
    (
      [chat_id]
      ,[col_width]
      ,[last_update_id]
      ,[limit]
      ,[num_cols]
      ,[num_rows]
      ,[offset]
      ,[update_timeout]
    )
  ) [pvt];

  SELECT 
    @url = [bot_token]
    ,@http_headers = [http_headers]
  FROM
  (
    SELECT 
      [name]
      ,[value_str]
    FROM [dbo].[settings] [s]
  ) [p]
  PIVOT
  (
    MAX([value_str])
    FOR [name] IN 
    (
      [bot_token]
      ,[http_headers]
    )
  ) [pvt];

END;