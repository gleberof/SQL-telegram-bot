CREATE TABLE [monitor].[disk_latency] (
    [database_id]       SMALLINT NOT NULL,
    [file_id]           SMALLINT NOT NULL,
    [sample_ms]         BIGINT   NULL,
    [num_of_reads]      BIGINT   NULL,
    [num_of_writes]     BIGINT   NULL,
    [io_stall_read_ms]  BIGINT   NULL,
    [io_stall_write_ms] BIGINT   NULL,
    CONSTRAINT [PK_disk_latency] PRIMARY KEY CLUSTERED ([database_id] ASC, [file_id] ASC)
);

