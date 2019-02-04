#!/bin/bash

# $1 = Satellite
# $2 = Orbit number
# $3 = yyyymmdd
# $4 = hhmm
# $5 = lvl1_dir

#. /local_disk/opt/acpg/cfg/.profile_pps
#. /software/polsatproc/pps-v2014/run-acpg/cfg/.profile_pps
#source /vol/software/polsatproc/pps-v2014/source_me_MET-20141015
#source /home/ubuntu/pytroll/etc/source_me_MET-pps-v2014-xenial

echo $1
echo $2
echo $3
echo $4
echo $5

if [ "$5" == "L-BAND" ]; then
    source_file=/software/pytroll/etc/source_me_MET-pps-v2014-xenial-l
elif [ "$5" == "XL-BAND" ]; then
    source_file=/software/pytroll/etc/source_me_MET-pps-v2014-xenial-xl
elif [ "$5" == "global-segments" ]; then
    source_file=/software/pytroll/etc/source_me_MET-pps-v2014-xenial-global
else
    source_file=/software/pytroll/etc/source_me_MET-pps-v2014-xenial-$5
    source_dir=/data/nwcsaf/pps-v2014-ears/import/PPS_data/source/
fi

source $source_file

env

#if [ "x$3" == "x0" ] && [ "x$4" == "x0" ]; then
#    PPS_OPTIONS="-p $1 $2"
#else
#    PPS_OPTIONS="-p $1 $2 --satday $3 --sathour $4"
#fi

#python /software/polsatproc/pps-v2014/run-acpg/scr/ppsMakeAvhrr.py $PPS_OPTIONS
#python /software/polsatproc/pps-v2014/run-acpg/scr/ppsMakePhysiography.py $PPS_OPTIONS
#python /software/polsatproc/pps-v2014/run-acpg/scr/ppsMakeNwp.py $PPS_OPTIONS
#python /software/polsatproc/pps-v2014/run-acpg/scr/ppsCmaskPrepare.py $PPS_OPTIONS
#python /software/polsatproc/pps-v2014/run-acpg/scr/ppsCmask.py $PPS_OPTIONS
#python /software/polsatproc/pps-v2014/run-acpg/scr/ppsCtype.py $PPS_OPTIONS

#python /software/polsatproc/pps-v2014/run-acpg/scr/ppsPrecipPrepare.py $PPS_OPTIONS

if [ "x$6" != "x" ]; then
    SM_AAPP_DATA_DIR=$6
    export SM_AAPP_DATA_DIR
    echo "Level 1 dir = $SM_AAPP_DATA_DIR"
fi

start_date=$3
start_time=$4
start="${start_date}_$start_time"
if [[ $start =~ (.*([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2}).*) ]]
then
    epoch_datetime=$(date -d "${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]}T${BASH_REMATCH[5]}:${BASH_REMATCH[6]}:00" +%s)
    echo $epoch_datetime
fi

satellite=$1

if [ "$satellite" ==  "noaa20" ]
then
    satellite_dir="j01"
else
    satellite_dir=$satellite
fi

search_dir=$(printf "%3s_%s_%05d" $satellite_dir $start $2)
search_dir="$source_dir/$search_dir"

if [ -e $search_dir ]
then
    echo "Directory does exists: $search_dir"
else
    echo "Directory does NOT exists: $search_dir"
    log_msg="Directory does NOT exists: $search_dir"
    range=600
    start_epoch_datetime=$(($epoch_datetime-$range))
    max_range=$(($epoch_datetime+$range))
    for(( check_epoch=$start_epoch_datetime; check_epoch<$max_range; ))
       {
	   echo $check_epoch
	   check_dir_name=$(date -d@$check_epoch +%Y%m%d_%H%M)
	   search_dir=$(printf "%s/%3s_%s_%05d" $source_dir $satellite_dir $check_dir_name $2)
	   echo "Search dir: $search_dir"
	   if [ -e $search_dir ]
	   then
	       start_date=$(date -d@$check_epoch +%Y%m%d)
	       start_time=$(date -d@$check_epoch +%H%M)
	       echo "Dir $search_dir exist. Use this: start date: $start_date, start time: $start_time"
	       log_msg="$log_msg\nDir $search_dir exist. Use this: start date: $start_date, start time: $start_time"
	       echo -e $log_msg | mail -s "EUM EARS VIIRS start time on directory deviation" trygveas@met.no
	       break
	   fi
	   check_epoch=$(($check_epoch+60))
       }
fi


if [ "x$3" == "x0" ] && [ "x$4" == "x0" ]; then
    echo "USING: python /opt/acpg/scr/ppsRunAllParallel.py -p $1 $2 --cpp 0 --precip 0 --ctth 0"
    python /opt/acpg/scr/ppsRunAllParallel.py -p $1 $2 --cpp 0 --precip 0 --ctth 0
else
    echo "USING: python /opt/acpg/scr/ppsRunAllParallel.py -p $1 $2 --satday $start_date --sathour $start_time --cpp 0 --precip 0 --ctth 0"
    python /opt/acpg/scr/ppsRunAllParallel.py -p $1 $2 --satday $start_date --sathour $start_time --cpp 0 --precip 0 --ctth 0
fi
