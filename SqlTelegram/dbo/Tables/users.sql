CREATE TABLE [dbo].[users] (
    [user_id]    BIGINT     NOT NULL,
    [name]       NCHAR (50) NOT NULL,
    [authorized] BIT        NOT NULL,
    CONSTRAINT [PK_users] PRIMARY KEY CLUSTERED ([user_id] ASC)
);

