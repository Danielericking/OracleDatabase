col name for a40
col CUR_VAL for a50 word_wrapped
col UPDATE_COMMENT for a40 word_wrapped
col DESCRIPTION for a40 word_wrapped
select name , DISPLAY_VALUE cur_val, ISMODIFIED, DESCRIPTION , UPDATE_COMMENT
from V$parameter
where ISDEFAULT = 'FALSE'
order by name
/
