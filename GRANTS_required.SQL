accept User Prompt 'Enter user name : '
---required
GRANT SELECT ON sys.V_$logfile to &USER;
GRANT SELECT ON SYS.V_$LOG to &USER;
GRANT SELECT ON  SYS.V_$PARAMETER TO &USER;
GRANT SELECT ON SYS.V_$LIBRARYCACHE TO &USER;
GRANT SELECT ON SYS.V_$rowcache TO &USER;
GRANT SELECT ON  sys.v_$datafile TO &USER;
GRANT SELECT ON  sys.v_$filestat TO &USER;
GRANT SELECT ON  sys.ts$         TO &USER;
GRANT SELECT ON  sys.v_$dbfile   TO &USER;
GRANT SELECT ON  sys.file$  TO &USER;
GRANT SELECT ON  sys.v_$tempfile TO &USER;
GRANT SELECT ON  sys.v_$tempstat TO &USER;
