set feed on
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE using current logfile DISCONNECT PARALLEL 4;