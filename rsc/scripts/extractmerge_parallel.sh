#!/bin/bash

set -e

trap 'echo "$0 : An ERROR has occured."' ERR

wdir=`pwd`/.extmerge$$
mkdir -p $wdir
trap "echo -e \"\ncleanup: erasing '$wdir'\" ; rm -f $wdir/* ; rmdir $wdir ; exit" EXIT
 
function isStillRunning() 
{ 
  if [ "x$SGE_ROOT" = "x" ] ; then echo "0"; return; fi # is cluster environment present ?
  
  # does qstat work ?
  qstat &>/dev/null
  if [ $? != 0 ] ; then 
    echo "ERROR : qstat failed. Is Network available ?" >&2
    echo "1"
    return
  fi
  
  local ID=$1
  local user=`whoami | cut -c 1-10`
  local stillrunnning=`qstat | grep $user | awk '{print $1}' | grep $ID | wc -l`
  echo $stillrunnning
}

function waitIfBusyId() 
{
  local ID=$1
  if [ `isStillRunning $ID` -gt 0 ] ; then
    echo -n "waiting..."
    while [ `isStillRunning $ID` -gt 0 ] ; do echo -n '.' ; sleep 5 ; done
    echo "done."
  fi
}

    
Usage() {
    echo ""
    echo "Usage: `basename $0` <out4D> <idx> <\"input files\"> <qsub logdir>"
    echo ""
    exit 1
}

[ "$4" = "" ] && Usage    
  
out="$1"
idx="$2"
inputs="$3"
logdir="$4"

n=0
for input in $inputs ; do
  echo "`basename $0`: extracting volume at pos. $idx from '$input'..."
  jid=`fsl_sub -l $logdir fslroi $input $wdir/_tmp_$(zeropad $n 4) $idx 1`
  n=$(echo "$n + 1" | bc)
done

waitIfBusyId $jid

echo "`basename $0`: merging..."

jid=`fsl_sub -j $jid -l $logdir fslmerge -t ${out} $(imglob $wdir/_tmp_????)`

waitIfBusyId $jid

echo "`basename $0`: done."