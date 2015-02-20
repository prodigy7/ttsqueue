# TTSQueue
Simple set of bash scripts for queuing texts that should be spoken via Google TTS. Idea was to implement text-to-speech for a home automation system. 
To prevent multiple announcements at same the, this script implement a simple queue so announcements can be player ordered.

## Requirements
* inotify-tools Package
* bash
* A linux system

## Installation
Extract files to a directory. Next rename *ttsqueue.conf.dist* to *ttsqueue.conf* and modify it for your requirements.
Make sure that the user which is used for running the daemon has write permissions on the directory. You can do that for example with

     chown -R fhem /opt/fhem/plugins/ttsqueue/

fhem is the user set, /opt/fhem/plugins/ttsqueue/ the directory where you've stored the scripts.

## Usage
### Daemon

First you need to start the daemon. You can do that by calling

    ./ttsqueue-daemon.sh start

The script will start all needed stuff in the user context you've defined in ttsqueue.conf

### Client
If you want queue a new tts, do it simply by calling

    ./ttsqueue-cli.sh add "This is a text"

After calling the script will return a id. If you want remove quickly the tts again, you can do this by

    ./ttsqueue-cli.sh remove 1234

where 1234 is the id, returned by the add command. With the command

    ./ttsqueue-cli.sh check 1234

you can check your text is already spoken, or not.
