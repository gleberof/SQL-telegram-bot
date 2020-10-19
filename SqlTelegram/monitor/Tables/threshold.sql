CREATE TABLE [monitor].[threshold] (
    [counter]   NVARCHAR (255)  NOT NULL,
    [threshold] DECIMAL (18, 2) NOT NULL,
    [type]      NVARCHAR (10)   NOT NULL,
    CONSTRAINT [PK_threshold] PRIMARY KEY CLUSTERED ([counter] ASC)
);



