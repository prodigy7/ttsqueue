#!/bin/bash

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
	TTSUSERID=$(cat /etc/passwd | grep $TTSUSER | cut -d ":" -f4)
	if [ "$?" -ne 0 -o "$UID" -ne 0 ] ; then
		echo -e ""
		echo -e "ERROR: Please run this script only with user root or $TTSUSER"
		echo -e ""
		exit 12;
	fi

	# Check: Variable defined
	if [ ! $TTSQUEUE ]; then
		echo -e ""
		echo -e "ERROR: TTSQUEUE not defined in ttsqueue.conf"
		echo -e ""
		exit 11;
	fi

	# Check: Path exist
	if [ ! -d $TTSQUEUE ]; then
		echo -e ""
		echo -e "ERROR: Queue path $TTSQUEUE does not exist"
		echo -e ""
		exit 12;
	fi

	# Check: User can write
	if [ ! -w $TTSQUEUE ]; then
		echo -e ""
		echo -e "ERROR: Queue path $TTSQUEUE is not writeable by user $TTSUSER"
		echo -e ""
		exit 13;
	fi
fi

# Some default defintions
TTS=""

# Function for displaying help
function usage {
	echo -e ""
	echo -e "Usage:"
	echo -e " ttsqueue-cli.sh action parameter"
	echo -e ""
	echo -e "Actions:"
	echo -e ""
	echo -e "  add\t\t\tAdd text to text-to-speach queue."
	echo -e "\t\t\tParameter is the text to be spoken. Script returns the id of the queued text."
	echo -e ""
	echo -e "\t\t\tExample:"
	echo -e "\t\t\t\tuser@pc:/home/user>ttsqueue-cli.sh add \"This is a test\""
	echo -e "\t\t\t\t7263"
	echo -e "\t\t\t\tuser@pc:/home/user>"
	echo -e ""
	echo -e "  check\t\t\tCheck text is already spoken."
	echo -e "\t\t\tScript returns exit codes: 0 = not spoken, 1 = spoken/removed."
	echo -e ""
	echo -e "\t\t\tExample:"
	echo -e "\t\t\t\tuser@pc:/home/user>ttsqueue-cli.sh check 7263"
	echo -e "\t\t\t\tuser@pc:/home/user>echo \$?"
	echo -e "\t\t\t\t0"
	echo -e "\t\t\t\tuser@pc:/home/user>"
	echo -e ""
	echo -e "  remove\t\tRemove text from text-to-speach queue."
	echo -e "\t\t\tParameter is the id which was returned during action add. Script returns exit codes: 0 = success, 1 = failed (text maybe already spoken)."
	echo -e ""
	echo -e "\t\t\tExample:"
	echo -e "\t\t\t\tuser@pc:/home/user>ttsqueue-cli.sh remove 7263"
	echo -e "\t\t\t\tuser@pc:/home/user>echo \$?"
	echo -e "\t\t\t\t1"
	echo -e "\t\t\t\tuser@pc:/home/user>"
	echo -e ""
}

# Handling with parameters
case $1 in

	# Handle parameter add
	add)

		# If no text given, return error
		if [ "$2" == "" ] ; then
			echo -e ""
			echo -e "ERROR: No text for speach given"
			echo -e ""
			exit 14;

		# If text given, queue
		else
			TTS="$2"
			echo "$TTS" > $TTSQUEUE/$$
			chown $TTSUSER $TTSQUEUE/$$
			echo $$
			exit 0;
		fi
	;;

	# Handle parameter remove
	remove)

		# If no id given, return error
		if [ "$2" == "" ] ; then
			echo -e ""
			echo -e "ERROR: No text id given"
			echo -e ""
			exit 15

		# Handle remove of text
		else

			# If text exists/is removable, do it
			if [ -w $TTSQUEUE/$2 ] ; then
				rm $TTSQUEUE/$2 >/dev/null 2>&1
				exit 0;

			# If text already spoken/not removeable, return error code
			else
				exit 1;
			fi
		fi
	;;

	# Handle parameter remove
	check)

		# If no id given, return error
		if [ "$2" == "" ] ; then
			echo -e ""
			echo -e "ERROR: No text id given"
			echo -e ""
			exit 15

		# Handle remove of text
		else

			# If text exists, report it
			if [ -f $TTSQUEUE/$2 ] ; then
				exit 0;

			# If text already spoken, report it
			else
				exit 1;
			fi
		fi
	;;

	*)
		usage;
		exit 20;
	;;
esac

exit 0
