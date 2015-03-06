select 
	"sql",
	"timestamp",
	FROM_UNIXTIME(max(unixtime))
from rfxcmd;
