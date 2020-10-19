CREATE TABLE [monitor].[progress] (
    [session_id]                BIGINT        NOT NULL,
    [message_id]                BIGINT        NOT NULL,
    [command]                   NVARCHAR (50) NOT NULL,
    [database]                  [sysname]     NULL,
    [start_time]                DATETIME      NULL,
    [estimated_completion_time] DATETIME      NULL,
    PRIMARY KEY CLUSTERED ([session_id] ASC)
);

