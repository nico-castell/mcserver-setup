#!/bin/bash

# Create the file that will serve as input
INPUTFILE=/tmp/$$-mcserver-input
mkfifo -m 600 $INPUTFILE

# Load all files into cache
( find . -type f | xargs cat >/dev/null ) &

# Run the server
tail -f $INPUTFILE | java            \
	-Xmx1G -Xms1G -Xmn256M            \
	-XX:+UseG1GC                      \
	-XX:+UnlockExperimentalVMOptions  \
	-XX:G1HeapRegionSize=32M          \
	-XX:MaxGCPauseMillis=50           \
	-jar server.jar --nogui &

# Handle termination signal by properly stopping the server
trap "echo '/stop' >> $INPUTFILE; wait" 15

wait
rm $INPUTFILE
