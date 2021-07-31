#!/bin/bash

export PATH=$PATH:/openils/bin

# this waits for ejabberd to be running on private.ejabberd and public.ejabberd
wait_ejabberd(){
	# Wait for ejabberd
	echo "[opensrf-docker] Waiting for ejabberd private network..."
	while ! nc -z private.ejabberd 5222; do
		sleep 1
	done
	echo "[opensrf-docker] private.ejabberd found"

	echo "[opensrf-docker] Waiting for ejabberd public network..."
	while ! nc -z public.ejabberd 5222; do
		sleep 1
	done
	echo "[opensrf-docker] public.ejabberd found"

	echo "[opensrf-docker] giving ejabberd users 25s to get registered"
	sleep 25
	# Start the first process
	echo "[opensrf-docker] starting OpenSRF services"
}

# this is the main loop, runs and makes sure the pids in the pidfiles are running
scanpids(){
	# loop and watch pidfiles for missing processes
	PIDFILES="$(find /openils/var/run -type f -name '*.pid')"

	echo "[opensrf-docker] looping, waiting for PIDs to fail"
	while true
	do
		for PIDFILE in $PIDFILES
		do
			PIDS="$(cat $PIDFILE)"
			for PID in $PIDS
			do
				STATUS=$(ps $PID)
				if [ "$?" -ne 0 ]
				then
					echo "[opensrf-docker] ERROR: Process failed: $(basename $PIDFILE .pid)"
					exit 1
				fi
			done
		done
	done 
}

ARGS="$@"
if [ $# -eq 0 ]; then
    ARGS="--start-all"
fi

wait_ejabberd

osrf_control $ARGS

scanpids &
wait $!
echo "[opensrf-docker] Tailing log file..."
tail -f /openils/var/log/osrfsys.log
