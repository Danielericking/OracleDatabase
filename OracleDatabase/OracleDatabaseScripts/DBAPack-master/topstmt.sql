DEFINE NTOPS=100
DEFINE MINEXECS = 1
DEFINE MINEXECSBYSEC=0.00027 REM 1 VEZ A CADA 60 MIN
DEFINE MINEXECSBYSEC=1       REM 1 VEZ A CADA 1  SEGUNDO
DEFINE MINEXECSBYSEC=0.1     REM 1 VEZ A CADA 10 SEGUNDOS
DEFINE MINEXECSBYSEC=0.01    REM 1 VEZ A CADA 100 SEGUNDOS
DEFINE MINEXECSBYSEC=0.00055 REM 1 VEZ A CADA 30 MIN
DEFINE SCHEMA='&1.'
DEFINE SORT="EXEC_BY_SECOND"
DEFINE SORT="CPU_TIME_BY_EXEC"
DEFINE SORT="LOGICAL_IO_BY_EXE"
DEFINE SORT="BUFFER_GETS"
DEFINE SORT="ELAPSED_TIME_BY_EXEC"


SET VERIFY OFF LINES 400 FEED OFF PAGES 1000
COL INST_iD NOPRINT
COL HASH_VALUE FORMAT 999999999999
COL EXECUTIONS FORMAT A12 HEAD 'Execucoes' JUST R
COL GETS_BY_EXEC FORMAT A12 HEAD 'Leit.Logicas|Por Execucao' JUST R
COL CPU_TIME_BY_EXEC FORMAT A14 HEAD 'CPU Time (ms)|Por execucao' JUST R
COL ELA_TIME_BY_EXEC FORMAT A17 HEAD 'Elapsed Time (ms)|Por execucao' JUST R
COL EXECS_BY_SEC FORMAT 9G990D99999 HEAD 'Execucoes|Por segundo' JUST R
COL CACHE_TIME FORMAT A12 HEAD 'Cache time' JUST R
COL LINHAS FORMAT A12 HEAD 'Linhas|Processadas' JUST R
COL BUFFER_GETS FORMAT A12 HEAD 'Leituras|Logicas' JUST R
COL CPU_TIME FORMAT A13 HEAD 'CPU Time (ms)|Total' JUST R
COL ELAPSED_TIME FORMAT A14 HEAD 'Elap Time (ms)|Total' JUST R
COL USER_NAME FORMAT A20 TRUNC
COL SQL_TEXT FORMAT A100 HEAD 'Inicio do Texto do SQL' TRUNC
col HH new_value HH
COL RANK FORMAT 9999

SET TERMOUT OFF

select
  'Hora Atual: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS' ) HH
from dual;

SET TERMOUT ON

PROMPT
PROMPT Top &NTOPS. Statements
PROMPT Execucoes (minimo): &MINEXECS. === Execucoes/Segundo (minimo): &MINEXECSBYSEC.
PROMPT Schema: &SCHEMA. === ORDER BY: &SORT.
PROMPT &HH.
WITH /* Top Statements */ CURSORES AS
(
  SELECT /*+ ALL_ROWS */ 
     S.INST_ID
    ,S.SQL_ID
    ,S.PARSING_SCHEMA_NAME USER_NAME
    ,S.ROWS_PROCESSED LINHAS, S.EXECUTIONS, S.BUFFER_GETS
    ,((SYSDATE -TO_DATE( S.FIRST_LOAD_TIME, 'YYYY-MM-DD/HH24:MI:SS' )) DAY(2) TO SECOND(0)) CACHE_TIME
    ,TRUNC(DECODE(SYSDATE-TO_DATE( S.FIRST_LOAD_TIME, 'YYYY-MM-DD/HH24:MI:SS' ), NULL, 0, 0, 0, 
                        S.EXECUTIONS/((SYSDATE-TO_DATE( S.FIRST_LOAD_TIME, 'YYYY-MM-DD/HH24:MI:SS' ))*24*60*60)),5) EXECS_BY_SEC
    ,TRUNC(S.CPU_TIME/1000) CPU_TIME
    ,TRUNC(S.ELAPSED_TIME/1000) ELAPSED_TIME
    ,TRUNC(DECODE(S.EXECUTIONS,NULL,0,0,0,S.BUFFER_GETS/S.EXECUTIONS)) GETS_BY_EXEC
    ,TRUNC(DECODE(S.EXECUTIONS,NULL,0,0,0,S.CPU_TIME/1000/S.EXECUTIONS)) CPU_TIME_BY_EXEC
    ,TRUNC(DECODE(S.EXECUTIONS,NULL,0,0,0,S.ELAPSED_TIME/1000/S.EXECUTIONS)) ELA_TIME_BY_EXEC
    ,REPLACE( REPLACE( S.SQL_TEXT, chr(10), ' ' ), chr(13), '' ) SQL_TEXT 
    --,S.SQL_FULLTEXT
  FROM GV$SQLAREA S 
  WHERE DECODE(SYSDATE-TO_DATE( S.FIRST_LOAD_TIME, 'YYYY-MM-DD/HH24:MI:SS' ), NULL, 0, 0, 0, 
                      S.EXECUTIONS/((SYSDATE-TO_DATE( S.FIRST_LOAD_TIME, 'YYYY-MM-DD/HH24:MI:SS' ))*24*60*60)) >= &MINEXECSBYSEC.
  AND   S.EXECUTIONS >= &MINEXECS.
  AND   S.PARSING_SCHEMA_NAME LIKE UPPER(NVL('&SCHEMA.', '%'))
  AND   S.SQL_TEXT NOT LIKE 'SELECT /* DS_SVC */%'
  AND   S.SQL_TEXT NOT LIKE 'WITH /* Top Statements */ CURSORES AS%'
  and   rownum <= &NTOPS. 
  ORDER BY 
	CASE '&SORT.'
		WHEN 'CPU_TIME_BY_EXEC' THEN DECODE(S.EXECUTIONS,NULL,0,0,0,S.CPU_TIME/1000/S.EXECUTIONS)
		WHEN 'ELAPSED_TIME_BY_EXEC' THEN DECODE(S.EXECUTIONS,NULL,0,0,0,S.ELAPSED_TIME/1000/S.EXECUTIONS)
		WHEN 'BUFFER_GETS' THEN S.BUFFER_GETS
		WHEN 'EXECS_BY_SECOND' THEN DECODE(SYSDATE-TO_DATE( S.FIRST_LOAD_TIME, 'YYYY-MM-DD/HH24:MI:SS' ), NULL, 0, 0, 0, 
											S.EXECUTIONS/((SYSDATE-TO_DATE( S.FIRST_LOAD_TIME, 'YYYY-MM-DD/HH24:MI:SS' ))*24*60*60))
		ELSE DECODE(S.EXECUTIONS,NULL,0,0,0,S.BUFFER_GETS/S.EXECUTIONS) 
	END
  DESC 
  --FETCH FIRST &NTOPS. ROWS ONLY
)
SELECT 
   C.inst_id
  ,ROWNUM RANK
  ,C.SQL_ID
  ,C.user_name
  ,LPAD(
   decode(sign(1e+12-C.GETS_BY_EXEC), -1, to_char(C.GETS_BY_EXEC/1e+09, 'fm999g999g999' ) || 'G',
   decode(sign(1e+09-C.GETS_BY_EXEC), -1, to_char(C.GETS_BY_EXEC/1e+06, 'fm999g999g999' ) || 'M',
   decode(sign(1e+06-C.GETS_BY_EXEC), -1, to_char(C.GETS_BY_EXEC/1e+03, 'fm999g999g999' ) || 'K',
   to_char(C.GETS_BY_EXEC, 'fm999g999g999' )  ) ) ), 12, ' ' ) GETS_BY_EXEC
  ,LPAD(
     decode(sign(1e+12-C.CPU_TIME_BY_EXEC), -1, to_char(C.CPU_TIME_BY_EXEC/1e+09, 'fm999g999g999' ) || 'G',
     decode(sign(1e+09-C.CPU_TIME_BY_EXEC), -1, to_char(C.CPU_TIME_BY_EXEC/1e+06, 'fm999g999g999' ) || 'M',
     decode(sign(1e+06-C.CPU_TIME_BY_EXEC), -1, to_char(C.CPU_TIME_BY_EXEC/1e+03, 'fm999g999g999' ) || 'K',
     to_char(C.CPU_TIME_BY_EXEC, 'fm999g999g999g999' )  ) ) ), 14, ' ' ) CPU_TIME_BY_EXEC
  ,LPAD(
     decode(sign(1e+12-C.ELA_TIME_BY_EXEC), -1, to_char(C.ELA_TIME_BY_EXEC/1e+09, 'fm999g999g999' ) || 'G',
     decode(sign(1e+09-C.ELA_TIME_BY_EXEC), -1, to_char(C.ELA_TIME_BY_EXEC/1e+06, 'fm999g999g999' ) || 'M',
     decode(sign(1e+06-C.ELA_TIME_BY_EXEC), -1, to_char(C.ELA_TIME_BY_EXEC/1e+03, 'fm999g999g999' ) || 'K',
     to_char(C.ELA_TIME_BY_EXEC, 'fm999g999g999' )  ) ) ), 17, ' ' ) ELA_TIME_BY_EXEC
  ,C.EXECS_BY_SEC
  ,LPAD(
   decode(sign(1e+12-C.EXECUTIONS), -1, to_char(C.EXECUTIONS/1e+09, 'fm999g999g999' ) || 'G',
   decode(sign(1e+09-C.EXECUTIONS), -1, to_char(C.EXECUTIONS/1e+06, 'fm999g999g999' ) || 'M',
   decode(sign(1e+06-C.EXECUTIONS), -1, to_char(C.EXECUTIONS/1e+03, 'fm999g999g999' ) || 'K',
   to_char(C.EXECUTIONS, 'fm999g999g999' )  ) ) ), 12, ' ' ) EXECUTIONS
  ,C.CACHE_TIME
  ,LPAD(
   decode(sign(1e+12-C.BUFFER_GETS), -1, to_char(C.BUFFER_GETS/1e+09, 'fm999g999g999' ) || 'G',
   decode(sign(1e+09-C.BUFFER_GETS), -1, to_char(C.BUFFER_GETS/1e+06, 'fm999g999g999' ) || 'M',
   decode(sign(1e+06-C.BUFFER_GETS), -1, to_char(C.BUFFER_GETS/1e+03, 'fm999g999g999' ) || 'K',
   to_char(C.BUFFER_GETS, 'fm999g999g999' )  ) ) ), 12, ' ' ) BUFFER_GETS
  ,LPAD(
   decode(sign(1e+12-C.LINHAS), -1, to_char(C.LINHAS/1e+09, 'fm999g999g999' ) || 'G',
   decode(sign(1e+09-C.LINHAS), -1, to_char(C.LINHAS/1e+06, 'fm999g999g999' ) || 'M',
   decode(sign(1e+06-C.LINHAS), -1, to_char(C.LINHAS/1e+03, 'fm999g999g999' ) || 'K',
   to_char(C.LINHAS, 'fm999g999g999' )  ) ) ), 12, ' ' ) LINHAS
  ,LPAD(
   decode(sign(1e+12-C.CPU_TIME), -1, to_char(C.CPU_TIME/1e+09, 'fm999g999g999' ) || 'G',
   decode(sign(1e+09-C.CPU_TIME), -1, to_char(C.CPU_TIME/1e+06, 'fm999g999g999' ) || 'M',
   decode(sign(1e+06-C.CPU_TIME), -1, to_char(C.CPU_TIME/1e+03, 'fm999g999g999' ) || 'K',
   to_char(C.CPU_TIME, 'fm999g999g999' )  ) ) ), 12, ' ' ) CPU_TIME
  ,LPAD(
   decode(sign(1e+12-C.ELAPSED_TIME), -1, to_char(C.ELAPSED_TIME/1e+09, 'fm999g999g999' ) || 'G',
   decode(sign(1e+09-C.ELAPSED_TIME), -1, to_char(C.ELAPSED_TIME/1e+06, 'fm999g999g999' ) || 'M',
   decode(sign(1e+06-C.ELAPSED_TIME), -1, to_char(C.ELAPSED_TIME/1e+03, 'fm999g999g999' ) || 'K',
   to_char(C.ELAPSED_TIME, 'fm999g999g999' )  ) ) ), 12, ' ' ) ELAPSED_TIME
  ,C.SQL_TEXT 
FROM CURSORES C
ORDER BY 
	CASE '&SORT.'
		WHEN 'CPU_TIME_BY_EXEC' THEN C.CPU_TIME_BY_EXEC
		WHEN 'ELAPSED_TIME_BY_EXEC' THEN C.ELA_TIME_BY_EXEC
		WHEN 'EXECS_BY_SECOND' THEN C.EXECS_BY_SEC
		WHEN 'BUFFER_GETS' THEN C.BUFFER_GETS
		ELSE C.GETS_BY_EXEC
	END
DESC
/

PROMPT

COL HASH_VALUE CLEAR
COL GETS_BY_EXEC CLEAR
COL LINHAS CLEAR
COL SQL_TEXT CLEAR
COL BUFFER_GETS CLEAR
COL EXECUTIONS CLEAR
COL CPU_TIME CLEAR
COL CPU_TIME_BY_EXEC CLEAR
COL ELAPSED_TIME CLEAR
COL USER_NAME CLEAR

SET VERIFY ON FEED 6 LINES 200 PAGES 100
col HH CLEAR 
col RANK CLEAR 
UNDEFINE 1 SCHEMA