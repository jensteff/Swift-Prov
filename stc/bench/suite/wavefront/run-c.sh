#!/usr/bin/env bash
set -e

if [[ ! $# -eq 2 ]]; then
  echo "usage $0 <n> <sleeptime>"
  exit 1
fi

N=$1
sleeptime=$2

prefix=wavefront._N_${N}__sleeptime_${sleeptime}.ADLB 
export ADLB_PRINT_TIME=1
export ADLB_PERF_COUNTERS=1 export
export ADLB_DEBUG=0
export TURBINE_DEBUG=0

mpiexec -n 8 ./wavefront ${N} ${sleeptime} &> $prefix.out

../scripts/opcounts.py $prefix.out | tee $prefix.counts
