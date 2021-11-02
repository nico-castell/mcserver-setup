# A Minecraft Server
In this guide, we are going to set up a Minecraft Server that runs on a linux server as a *service*.

<!-- Author: Nicolás Castellán (cnicolas.developer@gmail.com) -->
<!-- Creative Commons Attribution 4.0 International License   -->
<!-- SPDX License Identifier: CC-BY-4.0                       -->

What does it mean to run as a *service*? It means 3 things:
1. The minecraft server will run in the background (That doesn't mean slow, just not visible when
	you're not looking).
2. It will start when the computer boots.
3. It will stop properly when you power off the computer.

This guide provides the needed files to accomplish this, so you don't need to be worrying about
every detail of the system configuration.

Additionally, for security reasons, the server will be run as a dedicated user with few permissions,
the user will be called **mcserver**.

## Installation
1. Install Java, use the appropiate Java version for the Minecraft version:
	| Minecraft version | Java version |
	| ----------------- | ------------ |
	| 1.0-1.16          | 1.8.0        |
	| 1.17+             | 16+          |

	For Fedora Server, use:
	```bash
	dnf install java-latest-openjdk-headless # Java 16+
	dnf install java-1.8.0-openjdk-headless  # Java 1.8.0
	```
	
	For Ubuntu Server, use:
	```bash
	apt install openjdk-16-jre-headless # Java 16+
	apt install default-jre-headless    # Java 1.8.0
	```

2. Create the user with reduced permissions (they cannot use sudo or even log in):
	```bash
	useradd -M -s /bin/false mcserver
	```

3. Create the minecraft server directory:
	```bash
	mkdir /var/mcserver
	cd /var/mcserver
	```
	
4. Get the *server.jar* file from [Minecraft.net](https://www.minecraft.net/en-us/download/server),
	you can find older versions of the game from [MCVersions.net](https://mcversions.net/).

	You'll need to copy the exact download link and use the wget command to download:
	```bash
	wget https://launcher.mojang.com/v1/objects/a16d67e5807f57fc4e550299cf20226194497dc2/server.jar
	```
	That's the official link for version *1.17.1* at the time of writing this guide.

5. Run the server for the first time to create the needed files, such as *server.properties* and
	*eula.txt*.
	```bash
	java -jar server*.jar --nogui --initSettings
	```

	After this, you must set eula to true in the file *eula.txt*. Also, now would be the time to
	configure the *server.properties* file and get a server icon (*server-icon.png*, 64x64
	resolution).

6. You still have some files to copy, those are:
	| File in this folder | Destination                             |
	| ------------------- | --------------------------------------- |
	| *mcserver-run.sh*   | */usr/local/bin/mcserver-run*           |
	| *mcserverd.service* | */etc/systemd/system/mcserverd.service* |

	Make sure you're using the ammount of RAM you want to use by editing the file you copied
	*/usr/local/bin/mcserver-run*.

	Once you've done that, you need to make sure the file */usr/local/bin/mcserver-run* can be
	executed by running **chmod 755 /usr/local/bin/mcserver-run**, and reload systemd unit files by
	running **systemctl daemon-reload**.

	You can do all of that with the commands:
	```bash
	cd /path/to/this-folder
	cp mcserver-run.sh /usr/local/bin/mcserver-run
	cp mcserverd.service /etc/systemd/system/mcserverd.service
	chmod 755 /usr/local/bin/mcserver-run
	systemctl daemon-reload
	```

7. Awesome, now we only need to configure the firewall. Assuming you're using the default port for
	the minecraft server (25565), you need to do the following:

	- If you're on Fedora Serverc, copy the file *mcserver.xml* to */etc/firewalld/services*, you
		should edit the ports in the file if you're not using the default port, then run the following
		commands:
		```bash
		firewall-cmd --add-service=mcserver --permanent
		firewall-cmd --reload
		```

	- If you're on Ubuntu Server, use the **ufw** command. If you're not using the default port, just
		allow a different port.
		```bash
		ufw allow 25565 comment mcserver
		```

8. Now, you can finally enable and start the server with systemctl:
	```bash
	systemctl enable --now mcserverd.service
	```

9. (Optional) Install [No-Ip's Dynamic Update Client](https://www.noip.com/), this program ensures
	you have a DNS pointing to your non-static public IP address.

	You'll need to build from source, so you need build dependencies installed (you can remove them
	after building). Run one of the following commands:
	```bash
	dnf install @c-development  # For Fedora Server
	apt install build-essential # For Ubuntu Server
	```

	Now, you need to download, build and configure the client:
	```bash
	cd /usr/local/src
	wget http://www.noip.com/client/linux/noip-duc-linux.tar.gz
	tar xz noip-duc-linux.tar.gz
	cd noip*/
	make install
	```

	Once you're done with that, copy the *duc-noip-local.\** files from this folder to
	*/etc/systemd/system*, and run the command **systemctl daemon-reload** so systemd finds the
	services. After that, just enable the timer (**systemctl enable --now duc-noip-local.timer**).

## Backing up the server
This guide also comes with a backup script called *compress.sh*, which (you guessed it) creates a
compressed backup of the server files.

The script uses the **pxz** and **pigz** commands, make sure you have them installed.

Usage:
1. To run the program, you must first stop the server using systemctl:
	```bash
	systemctl stop mcserverd.service
	```

2. Once the server has stopped running, you can run the script:
	```bash
	cd /path/to/this-folder
	./compress.sh -gz
	```

	The script can use one of 3 compression algorithms:
	| Algorithm | Compatibility                 | Compression & speed            | Flag   |
	| --------- | ----------------------------- | ------------------------------ | ------ |
	| **zip**   | Compatible with all OSs       | Bad compression, fast          | `-zip` |
	| **gz**    | Compatible with UNIX-Like OSs | Good compression, fast         | `-gz`  |
	| **xz**    | Compatible with UNIX-Like OSs | Better compression, super slow | `-xz`  |

3. (Only) After the script is done, you can restart the server using systemctl:
	```bash
	systemctl sart mcserverd.service
	```

4. NOTE: The *compress.sh* script can execute steps 1 to 3 if you use the `-f` flag, but it is
	important that you understand that the server cannot be compressed while it's running because it
	**will** lead to errors in the compression, and possible loss of data.
