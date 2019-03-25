
-- ash-events.sql
-- get ash events for a sql_id within a time range
-- sql_id and range currently hardcoded
--
-- Jared Still 2017-11-08  still@pythian.com jkstill@gmail.com

var v_sql_id varchar2(13)

define v_sql_id = '59842mh2aqkwq'

exec :v_sql_id := '&v_sql_id'

col sample_time format a26
col inst_id format 999999
col session_id format 999999
col session_serial# format 999999
col event format a60
col event_count format 99,999,990

select sample_time, inst_id, session_id, session_serial#, event, count(*) event_count
from gv$active_session_history h
where h.sql_id = :v_sql_id
and h.sample_time > sysdate - (2/24)
and h.event is not null
group by sample_time, inst_id, session_id, session_serial#, event
order by sample_time, inst_id, session_id, session_serial#, event
/


