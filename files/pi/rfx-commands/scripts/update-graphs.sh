#!/bin/bash

######################################################################
#
#	Catch signals...
#
######################################################################

trap 'rm -f "${tmpfile}" > /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15



######################################################################
#
#	Setup variables...
#
######################################################################

tmpfile="/tmp/`basename $0`-$$.tmp"
imageDir="/var/www/openhab"

donow=0
dodiff=0
do1w=0


while getopts "123" _opts
do
	case "${_opts}" in
	1) donow=1 ;;
	2) dodiff=1 ;;
	3) do1w=1 ;;
	?) echo "Unknown parameter '${_opts}'" ; return ;;
	esac
done

shift `expr $OPTIND - 1` ; OPTIND=1


if [ ${donow} -eq 1 ] ; then
	curl -s "http://localhost:8080/rrdchart.png?&items=T_NU_last,T_52_C700_last,T_50_0700_last,T_52_B700_last,T_50_3600_last,T_50_9300_last,T_52_A700_last&period=D&w=1024&h=442" > ${tmpfile}
	mv ${tmpfile} ${imageDir}/now.png
fi

if [ ${dodiff} -eq 1 ] ; then
	curl -s "http://localhost:8080/chart?items=OutMaxLast,OutAvgLast,OutMinLast,T_NU_last&period=3D&random=1&w=1024&h=460" > ${tmpfile}
	mv ${tmpfile} ${imageDir}/diff.png
fi

if [ ${do1w} -eq 1 ] ; then
	curl -s "http://localhost:8080/chart?items=OutAvgLast,T_NU_last&period=W&random=1&w=1024&h=460" > ${tmpfile}
	mv ${tmpfile} ${imageDir}/1w.png
fi


exit 0
