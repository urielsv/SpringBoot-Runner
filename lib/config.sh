#!/bin/bash

# lib/config.sh - Configuration management functions
# author: urielsv <urielsosavazquez@gmail.com>
# Last updated 31/03/2025

# Configuration file paths
CONFIG_FILE="$HOME/.springboot-server-config.sh"

# Default configuration values
TOMCAT_HOME=""
APP_NAME="webapp"
APP_WAR_PATH=""
SOURCE_DIR=""
JAVA_HOME=""
SPRING_PROFILES="dev"
PORT=8080
CATALINA_OPTS="-Xms512m -Xmx1024m"
BUILD_COMMAND=""
BUILD_TYPE="maven"

load_config() {
  local config_to_use=""
  
  # Check for user config first
  if [ -f "$CONFIG_FILE" ]; then
    config_to_use="$CONFIG_FILE"
  fi
  
  # Load config if found
  if [ -n "$config_to_use" ]; then
    echo -e "${BLUE}Loading configuration from $config_to_use${NC}"
    source "$config_to_use"
    validate_config
  else
    echo -e "${YELLOW}Configuration setup is needed to use this script. Please run '$0 setup' to create a configuration.${NC}"
  fi
  
}

validate_config() {
  local missing_config=false
  
  if [ -z "$TOMCAT_HOME" ]; then
    echo -e "${RED}TOMCAT_HOME is not set${NC}"
    missing_config=true
  fi
  
  if [ -z "$APP_WAR_PATH" ]; then
    echo -e "${RED}APP_WAR_PATH is not set${NC}"
    missing_config=true
  fi
  
  if [ -z "$SOURCE_DIR" ]; then
    echo -e "${RED}SOURCE_DIR is not set${NC}"
    missing_config=true
  fi
  
  if [ -z "$JAVA_HOME" ]; then
    echo -e "${RED}JAVA_HOME is not set${NC}"
    missing_config=true
  fi
  
  if [ -z "$BUILD_COMMAND" ]; then
    if [ "$BUILD_TYPE" = "maven" ]; then
      BUILD_COMMAND="cd $SOURCE_DIR && mvn clean package -DskipTests"
    else
      echo -e "${RED}Unknown BUILD_TYPE: $BUILD_TYPE${NC}"
      missing_config=true
    fi
  fi
  
  if $missing_config; then
    echo -e "${RED}Some essential configuration is missing.${NC}"
    echo -e "${YELLOW}Run '$0 setup' to create a configuration.${NC}"
    if [ "$1" != "check_only" ]; then
      exit 1
    fi
  fi
}

setup_config() {
  echo -e "${BLUE}Setting up SpringBoot Server configuration...${NC}"
  echo -e "${YELLOW}Press Enter to accept the default value (shown in brackets)${NC}"
  
  # Detect Java
  local detected_java=""
  if command -v java &> /dev/null; then
    detected_java=$(java -XshowSettings:properties -version 2>&1 | grep 'java.home' | awk '{print $3}')
    echo -e "${GREEN}Detected Java: $detected_java${NC}"
  fi
  
  # Detect Tomcat
  local detected_tomcat=""
  if [ -d "/opt/tomcat" ]; then
    detected_tomcat="/opt/tomcat"
    echo -e "${GREEN}Detected Tomcat: $detected_tomcat${NC}"
  elif [ -d "/usr/share/tomcat9" ]; then
    detected_tomcat="/usr/share/tomcat9"
    echo -e "${GREEN}Detected Tomcat: $detected_tomcat${NC}"
  fi
  
  # Ask for configuration values
  read -p "Tomcat home directory [$detected_tomcat]: " input_tomcat
  TOMCAT_HOME=${input_tomcat:-$detected_tomcat}
  
  read -p "Java home directory [$detected_java]: " input_java
  JAVA_HOME=${input_java:-$detected_java}
  
  read -p "Application name [springapp]: " input_app_name
  APP_NAME=${input_app_name:-springapp}
  
  read -p "Source directory: " SOURCE_DIR
  
  # Detect build system
  local detected_build="maven"
  if [ -f "$SOURCE_DIR/pom.xml" ]; then
    detected_build="maven"
    echo -e "${GREEN}Detected Maven build system${NC}"
  fi
  
  read -p "Build system (maven) [$detected_build]: " input_build
  BUILD_TYPE=${input_build:-$detected_build}
  
  local default_build_cmd="cd $SOURCE_DIR && mvn clean package -DskipTests"
  
  read -p "Build command [$default_build_cmd]: " input_build_cmd
  BUILD_COMMAND=${input_build_cmd:-$default_build_cmd}
  
  # Determine WAR path based on build system
  local default_war_path=""
  if [ "$BUILD_TYPE" = "maven" ]; then
    default_war_path="$SOURCE_DIR/target/$APP_NAME.war"
  fi
  
  read -p "WAR file path [$default_war_path]: " input_war_path
  APP_WAR_PATH=${input_war_path:-$default_war_path}
  
  read -p "Spring profile [dev]: " input_profile
  SPRING_PROFILES=${input_profile:-dev}
  
  read -p "Server port [8080]: " input_port
  PORT=${input_port:-8080}
  
  read -p "JVM options [-Xms512m -Xmx1024m]: " input_opts
  CATALINA_OPTS=${input_opts:-"-Xms512m -Xmx1024m"}
  
  # Create configuration file
  cat > "$CONFIG_FILE" << EOF
# SpringBoot Server Configuration
TOMCAT_HOME="$TOMCAT_HOME"
APP_NAME="$APP_NAME"
APP_WAR_PATH="$APP_WAR_PATH"
SOURCE_DIR="$SOURCE_DIR"
JAVA_HOME="$JAVA_HOME"
SPRING_PROFILES="$SPRING_PROFILES"
PORT=$PORT
CATALINA_OPTS="$CATALINA_OPTS"
BUILD_TYPE="$BUILD_TYPE"
BUILD_COMMAND="$BUILD_COMMAND"
EOF
  
  echo -e "${GREEN}Configuration saved to $CONFIG_FILE${NC}"
  echo -e "${BLUE}You can edit this file directly to change configuration${NC}"
}

install_system() {
  echo -e "${BLUE}Installing SpringBoot Server system-wide...${NC}"
  
  # Get the script's path
  SCRIPT_PATH=$(readlink -f "$0")
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  SCRIPT_DIR=$(dirname "$SCRIPT_DIR")
  
  # Create installation directory
  sudo mkdir -p /usr/local/bin
  sudo mkdir -p /usr/local/lib/springboot-server
  sudo mkdir -p /etc/springboot-server
  
  # Copy the main script
  sudo cp "$SCRIPT_PATH" /usr/local/bin/springboot-server
  sudo chmod +x /usr/local/bin/springboot-server
  
  # Copy the library files
  sudo cp -r "$SCRIPT_DIR/lib" /usr/local/lib/springboot-server/
  
  # Create default config file if it doesn't exist
  if [ ! -f "$DEFAULT_CONFIG_FILE" ]; then
    sudo mkdir -p $(dirname "$DEFAULT_CONFIG_FILE")
    sudo bash -c "cat > $DEFAULT_CONFIG_FILE << EOF
# SpringBoot Server Default Configuration
# This is the system-wide configuration
# Users can override by creating $HOME/.springboot-server-config.sh
TOMCAT_HOME=\"\"
APP_NAME=\"springapp\"
APP_WAR_PATH=\"\"
SOURCE_DIR=\"\"
JAVA_HOME=\"\"
SPRING_PROFILES=\"dev\"
PORT=8080
CATALINA_OPTS=\"-Xms512m -Xmx1024m\"
BUILD_TYPE=\"maven\"
BUILD_COMMAND=\"\"
EOF"
  fi
  
  echo -e "${GREEN}✓ Installation complete!${NC}"
  echo -e "${BLUE}You can now run 'springboot-server' from anywhere.${NC}"
  echo -e "${BLUE}Make sure to update the script to load libraries from the new location.${NC}"
}

uninstall_system() {
  echo -e "${BLUE}Uninstalling SpringBoot Server...${NC}"
  
  # Remove the script and libraries
  sudo rm -f /usr/local/bin/springboot-server
  sudo rm -rf /usr/local/lib/springboot-server
  
  # Ask about removing config
  echo -e "${BLUE}Do you want to remove configuration files as well? (y/n)${NC}"
  read -rsn1 remove_config
  if [ "$remove_config" = "y" ]; then
    sudo rm -rf /etc/springboot-server
    rm -f "$HOME/.springboot-server-config.sh"
    echo -e "${GREEN}✓ Configuration files removed.${NC}"
  fi
  
  echo -e "${GREEN}✓ Uninstallation complete!${NC}"
}
