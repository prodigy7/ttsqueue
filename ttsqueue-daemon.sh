#!/bin/bash

# Check -> needed packages installed?
which inotifywait >/dev/null 2>&1;
if [ "$?" -eq 1 ]; then
	echo -e ""
	echo -e "ERROR: Needed command inotifywait not found. Please install package inotify-tools."
	echo -e ""
	exit 1;
fi

which md5sum >/dev/null 2>&1;
if [ "$?" -eq 1 ]; then
	echo -e ""
	echo -e "ERROR: Needed command md5sum not found. Please install package coreutils."
	echo -e ""
	exit 4;
fi

which cvlc >/dev/null 2>&1;
if [ "$?" -eq 1 ]; then
	echo -e ""
	echo -e "ERROR: Needed command cvlc not found. Please install package vlx-nox."
	echo -e ""
	exit 4;
fi

# Define ttsqueue root
TTSROOT=$(dirname $0)

# Do some checks
if [ ! -f $TTSROOT/ttsqueue.conf ]; then
	echo -e ""
	echo -e "ERROR: Config file ttsqueue.conf in $TTSROOT not found"
	echo -e ""
	exit 10;
else

	# Load configuration
	source $TTSROOT/ttsqueue.conf

	# Check: Given user
	if [ "$TTSUSER" == "root" ]; then
		echo -e ""
		echo -e "ERROR: TTSUSER can not be root! Please choose another user and try it again"
		echo -e ""
		exit 11;
	else
		TTSUSERID=$(cat /etc/passwd | grep $TTSUSER | cut -d ":" -f4)
		if [ "$?" -ne 0 ] ; then
			echo -e ""
			echo -e "ERROR: TTSUSER $TTSUSER not found"
			echo -e ""
			exit 12;
		fi
	fi

	# Check: Variable defined
	if [ ! $TTSDELAY ]; then
		echo -e ""
		echo -e "ERROR: TTSDELAY not defined in ttsqueue.conf"
		echo -e ""
		exit 13;
	fi

	if [ ! $TTSQUEUE ]; then
		echo -e ""
		echo -e "ERROR: TTSQUEUE not defined in ttsqueue.conf"
		echo -e ""
		exit 14;
	fi

	# Check: FilePath exist
	if [ ! -f $TTSINTRO ]; then
		echo -e ""
		echo -e "ERROR: Intro file $TTSINTRO does not exist"
		echo -e ""
		exit 15;
	fi

	if [ ! -d $TTSQUEUE ]; then
		echo -e ""
		echo -e "ERROR: Queue path $TTSQUEUE does not exist"
		echo -e ""
		exit 16;
	fi

	# Check: User can write
	if [ ! -w $TTSQUEUE ]; then
		echo -e ""
		echo -e "ERROR: Queue path $TTSQUEUE is not writeable by user $TTSUSER"
		echo -e ""
		exit 17;
	fi

	if [ -f $TTSROOT/ttsqueue.log ]; then
		if [ ! -w $TTSROOT/ttsqueue.log ]; then
			echo -e ""
			echo -e "ERROR: Log file $TTSROOT/ttsqueue.log is not writeable by user $TTSUSER"
			echo -e ""
			exit 18;
		fi
	fi

	if [ -f $TTSROOT/ttsqueue.pid ]; then
		if [ ! -w $TTSROOT/ttsqueue.pid ]; then
			echo -e ""
			echo -e "ERROR: File $TTSROOT/ttsqueue.pid is not writeable by user $TTSUSER"
			echo -e ""
			exit 19;
		fi
	fi
fi


# Function for displaying help
function usage {
	echo -e ""
	echo -e "Usage:"
	echo -e " ttsqueue-daemon.sh [start|stop]"
	echo -e ""
	echo -e "Actions:"
	echo -e ""
	echo -e "  start\t\t\tStart ttsqueue daemon."
	echo -e "  stopt\t\t\tStop ttsqueue daemon."
	echo -e ""
}

function monitoringQueue {

	# Start watching
	inotifywait -q -m -e close_write "$TTSQUEUE" | while read DIRECTORY EVENTLIST EVENTFILE; do

		# Build full qualified path
		FILEPATH="$DIRECTORY/$EVENTFILE"

		# Special: If file "stop" is created, stop daemon
		if [ "$EVENTFILE" == "stop" ] ; then
			echo -e "Daemon stopped"

			# Remove stop file
			rm $FILEPATH >/dev/null 2>&1

			# Remove pid
			rm $TTSROOT/ttsqueue.pid >/dev/null 2>&1

			# Kill this and all child processes
			kill -- $(ps -o pgid=$$ | grep -o '[0-9]*') >/dev/null 2>&1
			killall inotifywait >/dev/null 2>&1

			exit 0
		else
			# Some output for log file
			date
			cat $DIRECTORY/$EVENTFILE;

			# Generate MD5 Checksum
			MD5SUM=$(md5sum $DIRECTORY/$EVENTFILE | cut -d " " -f1);

			# If cache file does not exist, create
			if [ ! -f $TTSROOT/cache/$MD5SUM.mp3 ]; then

				# Encode text string
				SPEAKTEXT=$(cat $DIRECTORY/$EVENTFILE | od -An -tx1 | tr ' ' % | xargs printf "%s")

				# Build TTS Request
				TTSREQUEST=$(echo $TTSURL | sed "s/%SPEAKTEXT%/$SPEAKTEXT/g")

				# Fetch file and store in cache
				wget -q -U Mozilla "$TTSREQUEST" -O $TTSROOT/cache/$MD5SUM.mp3
			fi

			# Play
			if [ -z "$TTSINTRO" ]; then
				cvlc $TTSPLAYPARAM "$TTSROOT/cache/$MD5SUM.mp3"
			else
				cvlc $TTSPLAYPARAM "$TTSINTRO" "$TTSROOT/cache/$MD5SUM.mp3"
			fi

			echo -e ""

			# Now remove file
			if [ -w $DIRECTORY/$EVENTFILE ] ; then
				rm $FILEPATH >/dev/null 2>&1

				# Wait before next can be played
				sleep $TTSDELAY
			fi
		fi
	done > $TTSROOT/ttsqueue.log 2>&1 &

	# Write pid to file
	echo $! > $TTSROOT/ttsqueue.pid
}

# Handling with parameters
case $1 in

	# Start daemon
	start)

		# Check is already running
		if [ -f $TTSROOT/ttsqueue.pid ] ; then
			PID=$(cat $TTSROOT/ttsqueue.pid | sed "s/\n//g")
			ps -ef | grep $PID | grep -v grep >/dev/null
			if [ "$?" -eq 0 ] ; then
				echo "Daemon is already running"
				exit 2;
			else
				rm $TTSROOT/ttsqueue.pid >/dev/null 2>&1
			fi
		fi

		# Cleanup queue
		rm $TTSQUEUE/* >/dev/null 2>&1

		nohup sudo -u $TTSUSER $0 daemon >/dev/null 2>&1 &
		if [ "$?" -eq 0 ] ; then

			# Print status
			echo -e "Daemon started"
		fi
	;;

	# Get status
	status)

		# Check is already running
		if [ -f $TTSROOT/ttsqueue.pid ] ; then
			PID=$(cat $TTSROOT/ttsqueue.pid | sed "s/\n//g")
			ps -ef | grep -v "grep" | grep $PID  >/dev/null
			if [ "$?" == "0" ] ; then
				echo -e "Daemon running"
				exit 0
			else
				echo "Daemon is not running"
				exit 2;
			fi
		else
			echo -e "Daemon is not running"
			exit 3;
		fi

	;;

	# Stop daemon
	stop)

		# Check is already running
		if [ -f $TTSROOT/ttsqueue.pid ] ; then
			PID=$(cat $TTSROOT/ttsqueue.pid | sed "s/\n//g")
			ps -ef | grep -v "grep" | grep $PID >/dev/null
			if [ "$?" == "0" ] ; then
				echo -e "Daemon stopped"
				echo "$TTS" > $TTSQUEUE/stop

				exit 0
			else
				echo "Daemon is not running"
				rm $TTSROOT/ttsqueue.pid >/dev/null 2>&1
				exit 2;
			fi
		else
			echo -e "Daemon is not running"
			exit 3;
		fi

	;;

	daemon)
		monitoringQueue;
		exit 0;
	;;

	*)
		usage;
		exit 20;
	;;
esac

exit 0
