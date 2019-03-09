-- Copyright 2018 Tanel Poder. All rights reserved. More info at http://tanelpoder.com
-- Licensed under the Apache License, Version 2.0. See LICENSE.txt for terms & conditions.

-- old - unfinished

--------------------------------------------------------------------------------
--
-- File name:   sw.sql
-- Purpose:     Display current Session Wait info
--
-- Author:      Tanel Poder
-- Copyright:   (c) http://www.tanelpoder.com
--
-- Usage:       @sw <sid>
--              @sw 52,110,225
-- 	        	@sw "select sid from v$session where username = 'XYZ'"
--              @sw &mysid
--
--------------------------------------------------------------------------------

--col sw_event 	head EVENT for a40 truncate
--col sw_p1transl head P1TRANSL for a42
--col sw_sid		head SID for 999999
--
--select /*+ ORDERED USE_NL(sw.gv$session_wait.s) */
--	sw.sid sw_sid,
--	CASE WHEN sw.state = 'WAITING' THEN 'WAITING' ELSE 'WORKING' END AS state,
--	CASE WHEN sw.state = 'WAITING' THEN event ELSE 'On CPU / runqueue' END AS sw_event,
--	CASE WHEN sw.state = 'WAITING' THEN sw.p1 ELSE NULL END p1,
--	CASE WHEN sw.state = 'WAITING' THEN sw.p2 ELSE NULL END p2,
--	CASE WHEN sw.state = 'WAITING' THEN sw.p3 ELSE NULL END p3,
----	CASE
----		WHEN event like 'enq%' AND state = 'WAITING' THEN
----			'0x'||trim(to_char(CASE WHEN state = 'WAITING' THEN sw.p1 ELSE NULL END, 'XXXXXXXXXXXXXXXX'))||': '||
----			chr(bitand(CASE WHEN state = 'WAITING' THEN sw.p1 ELSE NULL END, -16777216)/16777215)||
----			chr(bitand(CASE WHEN state = 'WAITING' THEN sw.p1 ELSE NULL END,16711680)/65535)||
----			' mode '||bitand(CASE WHEN state = 'WAITING' THEN sw.p1 ELSE NULL END, power(2,14)-1)
----		WHEN event like 'latch%' AND state = 'WAITING' THEN
----			  '0x'||trim(to_char(CASE WHEN state = 'WAITING' THEN sw.p1 ELSE NULL END, 'XXXXXXXXXXXXXXXX'))
---- temp
----		WHEN event like 'latch%' AND state = 'WAITING' THEN
----			  '0x'||trim(to_char(CASE WHEN state = 'WAITING' THEN sw.p1 ELSE NULL END, 'XXXXXXXXXXXXXXXX'))||': '||(
----			  		select MAX(name)||'[par'
----			  			from v$latch_parent
----			  			where addr = hextoraw(trim(to_char(CASE WHEN state = 'WAITING' THEN sw.p1 ELSE NULL END,rpad('0',length(rawtohex(addr)),'X'))))
----			   		union all
----			   		select MAX(name)||'[c'||MAX(child#)||']'
----				   		from v$latch_children
----			  			where addr = hextoraw(trim(to_char(CASE WHEN state = 'WAITING' THEN sw.p1 ELSE NULL END,rpad('0',length(rawtohex(addr)),'X'))))
----			  )
----	ELSE NULL END AS sw_p1transl,
--	count(*) "COUNT"
--FROM
--	(select /*+ NO_MERGE */ &1 sid from dual connect by level <= 100000) s,
--	v$session_wait sw
--WHERE
--	sw.sid IN (&1)
--AND s.sid = sw.sid
--	GROUP BY
--		sw.sid,
--		CASE WHEN sw.state = 'WAITING' THEN 'WAITING' ELSE 'WORKING' END,
--		CASE WHEN sw.state = 'WAITING' THEN event ELSE 'On CPU / runqueue' END,
--		CASE WHEN sw.state = 'WAITING' THEN sw.p1 ELSE NULL END,
--		CASE WHEN sw.state = 'WAITING' THEN sw.p2 ELSE NULL END,
--		CASE WHEN sw.state = 'WAITING' THEN sw.p3 ELSE NULL END
--ORDER BY
--	"COUNT" DESC
--/
