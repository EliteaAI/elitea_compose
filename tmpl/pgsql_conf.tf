resource "local_file" "pgsql_postgresql_conf" {
  count = (!var.EXTERNAL_PGSQL_SVC_ENABLED && var.PG_CUSTOM_CONFIG_ENABLED) ? 1 : 0
  content = templatefile(
    "${path.module}/tftemplates/pgsql_conf/postgresql.conf.tpl",
    {
      PGSQL_PORT                          = var.PGSQL_PORT
      PG_MAX_CONNECTIONS                  = var.PG_MAX_CONNECTIONS
      PG_SHARED_BUFFERS                   = var.PG_SHARED_BUFFERS
      PG_EFFECTIVE_CACHE_SIZE             = var.PG_EFFECTIVE_CACHE_SIZE
      PG_MAINTENANCE_WORK_MEM             = var.PG_MAINTENANCE_WORK_MEM
      PG_CHECKPOINT_COMPLETION_TARGET     = var.PG_CHECKPOINT_COMPLETION_TARGET
      PG_WAL_BUFFERS                      = var.PG_WAL_BUFFERS
      PG_DEFAULT_STATISTICS_TARGET        = var.PG_DEFAULT_STATISTICS_TARGET
      PG_RANDOM_PAGE_COST                 = var.PG_RANDOM_PAGE_COST
      PG_EFFECTIVE_IO_CONCURRENCY         = var.PG_EFFECTIVE_IO_CONCURRENCY
      PG_WORK_MEM                         = var.PG_WORK_MEM
      PG_HUGE_PAGES                       = var.PG_HUGE_PAGES
      PG_JIT                              = var.PG_JIT
      PG_WAL_COMPRESSION                  = var.PG_WAL_COMPRESSION
      PG_IO_METHOD                        = var.PG_IO_METHOD
      PG_MIN_WAL_SIZE                     = var.PG_MIN_WAL_SIZE
      PG_MAX_WAL_SIZE                     = var.PG_MAX_WAL_SIZE
      PG_MAX_WORKER_PROCESSES             = var.PG_MAX_WORKER_PROCESSES
      PG_MAX_PARALLEL_WORKERS_PER_GATHER  = var.PG_MAX_PARALLEL_WORKERS_PER_GATHER
      PG_MAX_PARALLEL_WORKERS             = var.PG_MAX_PARALLEL_WORKERS
      PG_MAX_PARALLEL_MAINTENANCE_WORKERS = var.PG_MAX_PARALLEL_MAINTENANCE_WORKERS
      PG_WAL_LEVEL                        = var.PG_WAL_LEVEL
      PG_SYNCHRONOUS_COMMIT               = var.PG_SYNCHRONOUS_COMMIT
      PG_LOG_MIN_DURATION_STATEMENT       = var.PG_LOG_MIN_DURATION_STATEMENT
      PG_LOG_CONNECTIONS                  = var.PG_LOG_CONNECTIONS
      PG_LOG_DISCONNECTIONS               = var.PG_LOG_DISCONNECTIONS
      PG_LOG_LINE_PREFIX                  = var.PG_LOG_LINE_PREFIX
    }
  )
  filename = "../pgsql_conf/postgresql.conf"
}

resource "local_file" "pgsql_pg_hba_conf" {
  count    = (!var.EXTERNAL_PGSQL_SVC_ENABLED) ? 1 : 0
  content  = file("${path.module}/tftemplates/pgsql_conf/pg_hba.conf.tpl")
  filename = "../pgsql_conf/pg_hba.conf"
}
