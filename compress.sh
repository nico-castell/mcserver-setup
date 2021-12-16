#!/bin/bash

FILE_NAME="server_$(date +"%Y-%m-%d")" # The name of the archive file
LOCATION="/var/mcserver-backups"       # The location to store the file
MCFOLDER="/var/mcserver"               # The location of the server folder
force=no

while [ -n "$1" ]; do
case "$1" in
	-xz) METHOD=xz   ;;
	-gz) METHOD=gz   ;;
	-zst) METHOD=zst ;;
	-zip) METHOD=zip ;;
	-f) force=yes    ;;
	*)
		printf "\e[31mERROR: Option \e[01m%s\e[22m not recognized\e[00m\n" "$1" >&2
		printf "\e[33mUsage:\e[00m ./%s (-xz | -gz | -zip)\n" `basename "$0"` >&2
		exit 1
	;;
esac; shift; done

if [ $(systemctl is-active mcserverd.service) = "active" -a "$force" = "no" ]; then
	printf "\e[31mERROR: You can't back up the server while it's running\e[00m\n" >&2
	printf "Use \e[01m-f\e[22m to stop mcserverd and back it up.\n" >&2
	exit 2
fi

if [ -z "$METHOD" ]; then
	printf "\e[31mERROR: You must specify a method\e[00m\n" >&2
	printf "\e[33mUsage:\e[00m ./%s (-xz | -gz | -zst | -zip) (-f)\n" `basename "$0"` >&2
	exit 1
fi

cd "${MCFOLDER%/*}"

# Stop the server while it's being backed up
[ "$force" = "yes" ] && systemctl stop mcserverd.service

# Declare variables used for progress
let TOTAL_FILES=$(find mcserver -depth | wc -l)
let COUNT=0

# Display progress as the compression is running
while read -r i; do
	let COUNT++
	printf "Compressing server: %s\r" $(echo "scale=2; ($COUNT/$TOTAL_FILES)*100" | bc | sed -e 's/\.[0-9]\{,2\}//g' -e 's/^[0-9]\{,3\}/&%/g')
done< <(
case "$METHOD" in
	xz)  tar -I 'xz -T0 -9' -cvf $LOCATION/$FILE_NAME.tar.xz $(basename $MCFOLDER)     ;;
	gz)  tar -I pigz -cvf $LOCATION/$FILE_NAME.tar.gz $(basename $MCFOLDER)            ;;
	zst) tar -I 'zstd -T0 -19' -cvf $LOCATION/$FILE_NAME.tar.zst $(basename $MCFOLDER) ;;
	zip) zip -r $LOCATION/$FILE_NAME.zip $(basename $MCFOLDER)                         ;;
esac
)
echo

chown mcserver:mcserver $LOCATION/$FILE_NAME*
chmod 666 $LOCATION/$FILE_NAME*
unset COUNT TOTAL_FILES

# Restart the server after it's done backing up.
[ "$force" = "yes" ] && systemctl start mcserverd.service

if [[ $2 == "-p" ]]; then
	read -sp "Press ENTER to exit..."
	echo
fi

exit 0
