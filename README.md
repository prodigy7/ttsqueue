# TTSQueue
Simple script collection for playing tts queued under linux

## Installation
Extract files to a directory. Next rename ttsqueue.conf.dist to ttsqueue.conf and modify it for your requirements.

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
