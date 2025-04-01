#!/bin/bash

# lib/utils.sh - Common utility functions
# author: urielsv <urielsosavazquez@gmail.com>
# Last updated 31/03/2025

# Colors for console output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

check_dependencies() {
  local missing_deps=false
  
  # Check for Java
  if ! command -v java &> /dev/null; then
    echo -e "${RED}✗ Java not found${NC}"
    missing_deps=true
  else
    local java_version=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
    echo -e "${GREEN}✓ Java found: $java_version${NC}"
  fi
  
  # Check for curl
  if ! command -v curl &> /dev/null; then
    echo -e "${RED}✗ curl not found${NC}"
    missing_deps=true
  else
    echo -e "${GREEN}✓ curl found$(curl --version | head -n 1 | cut -d' ' -f1-2)${NC}"
  fi
  
  # Check for inotify-tools if on Linux
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if ! command -v inotifywait &> /dev/null; then
      echo -e "${YELLOW}! inotifywait not found - file watching will be disabled${NC}"
    else
      echo -e "${GREEN}✓ inotifywait found${NC}"
    fi
  fi
  
  # Check build tool (mvn)
  if [ "$BUILD_TYPE" = "maven" ]; then
    if ! command -v mvn &> /dev/null; then
      echo -e "${RED}✗ Maven not found${NC}"
      missing_deps=true
    else
      local mvn_version=$(mvn --version | head -n 1)
      echo -e "${GREEN}✓ Maven found: $mvn_version${NC}"
    fi
  fi
  
  if $missing_deps; then
    echo -e "${RED}Please install missing dependencies${NC}"
    return 1
  fi
  
  return 0
}

show_usage() {
  echo -e "${BOLD}${CYAN}SpringBoot Tomcat Development Server${NC}"
  echo -e "${CYAN}Usage: $0 [command]${NC}"
  echo ""
  echo -e "${BOLD}Commands:${NC}"
  echo "  start         Start the Tomcat server"
  echo "  stop          Stop the Tomcat server"
  echo "  restart       Restart the Tomcat server"
  echo "  deploy        Deploy the application"
  echo "  build         Build the application"
  echo "  clean         Clean the build artifacts"
  echo "  debug         Build with debug output"
  echo "  hotreload     Perform a hot reload"
  echo "  watch         Watch for file changes and reload automatically"
  echo "  interactive   Start in interactive mode (with key commands)"
  echo "  setup         Create/update configuration"
  echo "  install       Install this script system-wide"
  echo "  uninstall     Uninstall this script from system"
  echo "  status        Show server status"
  echo "  help          Show this help message"
  echo ""
  echo -e "${BOLD}Interactive Mode Commands:${NC}"
  echo "  r - Reload (full restart)"
  echo "  h - Hot reload"
  echo "  b - Build only"
  echo "  d - Deploy only"
  echo "  c - Clear screen"
  echo "  l - View logs"
  echo "  s - Server status"
  echo "  q - Quit"
}

show_version() {
  echo -e "${BOLD}${CYAN}SpringBoot Tomcat Development Server${NC}"
  echo -e "Version: $VERSION"
  echo -e "Author: Uriel Sosa Vazquez <urielsosavazquez@gmail.com>"
  echo -e "License: MIT"
}

show_banner() {
  echo -e "${BOLD}${CYAN}==================================${NC}"
  echo -e "${BOLD}${CYAN}SpringBoot Tomcat Development Server${NC}"
  echo -e "${BOLD}${CYAN}==================================${NC}"
  echo -e "${CYAN}Version: $VERSION${NC}"
}

ensure_directories() {
  if [ ! -d "$TOMCAT_HOME" ]; then
    echo -e "${RED}✗ Tomcat home directory not found: $TOMCAT_HOME${NC}"
    return 1
  fi
  
  if [ ! -d "$TOMCAT_HOME/webapps" ]; then
    echo -e "${RED}✗ Tomcat webapps directory not found: $TOMCAT_HOME/webapps${NC}"
    return 1
  fi
  
  if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}✗ Source directory not found: $SOURCE_DIR${NC}"
    return 1
  fi
  
  return 0
}

log_message() {
  local level=$1
  local message=$2
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  # Log to console with color
  case $level in
    INFO)
      echo -e "${BLUE}[INFO] $message${NC}"
      ;;
    SUCCESS)
      echo -e "${GREEN}[SUCCESS] $message${NC}"
      ;;
    WARN)
      echo -e "${YELLOW}[WARN] $message${NC}"
      ;;
    ERROR)
      echo -e "${RED}[ERROR] $message${NC}"
      ;;
    *)
      echo -e "$message"
      ;;
  esac
  
  # Also log to file if LOG_FILE is defined
  if [ -n "$LOG_FILE" ]; then
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
  fi
}

detect_os() {
  case "$OSTYPE" in
    linux*)
      OS_TYPE="Linux"
      ;;
    darwin*)
      OS_TYPE="MacOS"
      ;;
    msys*|cygwin*)
      OS_TYPE="Windows"
      ;;
    *)
      OS_TYPE="Unknown"
      ;;
  esac
  
  echo -e "${BLUE}Detected OS: $OS_TYPE${NC}"
}
