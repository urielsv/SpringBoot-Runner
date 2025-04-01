# SpringBoot-Runner
A command-line tool for running, reloading, hot-reloading, building and deploying Java SpringBoot applications with Tomcat 9.

# Features
- Start, stop, and restart Tomcat server
- Deploy SpringBoot WAR applications to Tomcat
- hot reload capability (requires inotifywait)
- Automatic file watching and reloading on changes
- Interactive mode with keyboard shortcuts
- Support for maven build systems

# Prerequisites
Before using this tool please ensure you have installed:
- Java JDK 11 or higher
- Apache Tomcat 9
- Maven
- Bash shell
- inotify-tools (optional, for file watching on Linux)

# Installation
1. Clone the repository
   ```
   bashgit clone https://github.com/urielsv/SpringBoot-Runner.git
   cd SpringBoot-Runner
   ```
2. Make the script executable:
   ```
   chmod +x springboot-server.sh
   chmod +x lib/*.sh
   ```
3. Run the setup script
      ```
   ./springboot-server.sh setup
   ```
   And follow the steps to complete the installation process.
4. (Optional) Make the script system-wide
   ```
   sudo ./springboot-server.sh install
   ```
   This will make `springboot-server` command available everywhere on your system.

# Usage
```
# Start the Tomcat server
./springboot-server.sh start

# Stop the Tomcat server
./springboot-server.sh stop

# Restart the Tomcat server
./springboot-server.sh restart

# Build your SpringBoot application
./springboot-server.sh build

# Deploy your application to Tomcat
./springboot-server.sh deploy

# Perform a hot reload
./springboot-server.sh hotreload

# Watch for changes and automatically reload
./springboot-server.sh watch

# Show server status
./springboot-server.sh status
```
 If you are encountering errors please check the "Permissions" section

# Interactive Mode
Interactive mode provides keyboard shortcuts for common operations:
```
./springboot-server.sh interactive
```

In this mode, you can use the following keys:

- r - Reload (full restart)
- h - Hot reload
- b - Build only
- d - Deploy only
- c - Clear screen
- l - View logs
- s - Show server status
- q - Quit

# Configuration
The tool uses configuration files in the following locations:
- User specific: ~/.springboot-server-config.sh
- System-wide: /etc/springboot-server/config.sh

# Permissions
If you encounter permission issues when trying to start Tomcat, you may need to run the tool with sudo:
```
sudo ./springboot-server.sh start
```
or, you can set the proper permissions on your Tomcat installation:
```
# Make Tomcat scripts executable
sudo chmod +x /path/to/tomcat/bin/*.sh

# Make key directories writable
sudo chmod -R 755 /path/to/tomcat/logs
sudo chmod -R 755 /path/to/tomcat/webapps
sudo chmod -R 755 /path/to/tomcat/work
sudo chmod -R 755 /path/to/tomcat/temp

# Change ownership (replace 'yourusername' with your actual username)
sudo chown -R yourusername:yourusername /path/to/tomcat/logs
sudo chown -R yourusername:yourusername /path/to/tomcat/webapps
sudo chown -R yourusername:yourusername /path/to/tomcat/work
```
After setting these permissions, you should be able to run the tool without sudo.

# Contribution Guidelines
Contributions are welcome! Please feel free to submit a Pull Request.

# License
This project is licensed under the MIT License - see the LICENSE file for details.
      
