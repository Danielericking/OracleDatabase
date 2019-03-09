col sample_time for a25
col sess for a10
select *
from (
	select  to_char(min(ash.sample_time),'YYYY-MON-DD HH24:MI') start_time, to_char(max(ash.sample_time),'YYYY-MON-DD HH24:MI') end_time
		--, ash.session_id||','||ash.session_serial# sess
		, ash.user_id, u.username
		--, ash.sql_id ,ash.sql_plan_hash_value
		, round(max(pga_allocated)/1024/1024,2) pga_mb, round(max(temp_space_allocated)/1024/1024,2) temp_mb
		, sum(TM_DELTA_CPU_TIME) cpu_time, sum(TM_DELTA_DB_TIME) db_time
	from v$active_session_history ash, dba_users u
	where  ash.user_id=u.user_id
		and sample_time > trunc(sysdate-7)
		and SESSION_STATE = 'ON CPU'
	--group by session_id, session_serial#,ash.user_id,u.username, ash.sql_id, ash.sql_plan_hash_value
	group by ash.user_id,u.username
	--having max(ash.temp_space_allocated/1024/1024) > 100
	order by cpu_time, db_time
)
where rownum < 25
/
