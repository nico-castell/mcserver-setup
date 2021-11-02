#!/bin/bash

# Protect all files used by this process
umask 077

# Create the file that will serve as input
mkfifo /tmp/mcserver-input

# Run the server
tail -f /tmp/mcserver-input | java   \
	-Xmx5G -Xms5G -Xmn1G              \
	-XX:+UseG1GC                      \
	-XX:+UnlockExperimentalVMOptions  \
	-XX:G1HeapRegionSize=32M          \
	-XX:MaxGCPauseMillis=50           \
	-jar server*.jar --nogui & PID=$!

# Handle termination signal by properly stopping the server
trap "echo '/stop' >> /tmp/mcserver-input; wait" 15

wait
rm /tmp/mcserver-input
