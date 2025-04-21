#!/bin/bash

# Defaults
num_threads=1
counters=0

function usage
{
    echo "usage: intspeed.sh [-H | -h | --help] [--threads <int>] [--workload <int>]"
    echo "   threads: number of OpenMP threads to use. Default: ${num_threads}"
    echo "   workload: which workload number to run. Leaving this unset runs all."
    echo "   counters: if set, runs an hpm_counters instance on each hart"
}

if [ "$1" == "--help" -o "$1" == "-h" -o "$1" == "-H" ]; then
    usage
    exit 3
fi

while test $# -gt 0
do
   case "$1" in
        --workload)
            shift;
            workload_num=$1
            ;;
        --threads)
            shift;
            num_threads=$1
            ;;
        --counters)
            counters=1;
            ;;
        -h | -H | -help)
            usage
            exit
            ;;
        --*) echo "ERROR: bad option $1"
            usage
            exit 1
            ;;
        *) echo "ERROR: bad argument $1"
            usage
            exit 2
            ;;
    esac
    shift
done

work_dir=$PWD
export OMP_NUM_THREADS=$num_threads
mkdir -p ~/output

# Iterate through all subdirectories
# Array to store background PIDs
pids=()
max_parallel=8

for bmark_dir in */; do
    if [ -d "$bmark_dir" ]; then
        bmark_name=${bmark_dir%/}  # Remove trailing slash
        
        if [ -z "$workload_num" ]; then
            runscript="run.sh"
            echo "Starting speed $bmark_name run with $OMP_NUM_THREADS threads"
        else
            runscript="run_workload${workload_num}.sh"
            echo "Starting speed $bmark_name (workload ${workload_num}) run with $OMP_NUM_THREADS threads"
        fi

        # In some systems we might not support for our counter program; so optionally disable it 
        if [ -z "$DISABLE_COUNTERS" -a "$counters" -ne 0 ]; then
            start_counters
        fi

        # Actually start the workload
        cd $work_dir/${bmark_name}
        if [ -f "./${runscript}" ]; then
            # Run in background and store PID
            ./${runscript} > ~/output/${bmark_name}_${i}.out 2> ~/output/${bmark_name}_${i}.err &
            pids+=($!)
            
            # If we've reached max parallel jobs, wait for one to finish
            if [ ${#pids[@]} -eq $max_parallel ]; then
                wait -n  # Wait for any job to finish
                # Remove finished jobs from pids array
                pids=( $(jobs -p) )
            fi
        else
            echo "Warning: ${runscript} not found in ${bmark_name}"
        fi

        if [ -z "$DISABLE_COUNTERS" -a "$counters" -ne 0 ]; then
            stop_counters
        fi
        
        # Return to original directory for next iteration
        cd $work_dir
    fi
done

# Wait for remaining background jobs to finish
wait
