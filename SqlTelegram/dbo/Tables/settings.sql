CREATE TABLE [dbo].[settings] (
    [name]      NVARCHAR (50)  NOT NULL,
    [value]     BIGINT         NULL,
    [value_str] NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_settings] PRIMARY KEY CLUSTERED ([name] ASC)
);



