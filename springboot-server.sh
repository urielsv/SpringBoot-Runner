#!/bin/bash

# springboot-server.sh - Main script for SpringBoot Tomcat Development Server
# author: urielsv <urielsosavazquez@gmail.com>
# Last updated 31/03/2025

# Version info
VERSION="1.0.0"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Import modules
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/tomcat.sh"
source "$SCRIPT_DIR/lib/build.sh"
source "$SCRIPT_DIR/lib/interactive.sh"

# Main entry point
main() {
  # Process command
  case "$1" in
    start)
      load_config
      check_dependencies
      if ! is_tomcat_running; then
        start_tomcat
      else
        echo -e "${YELLOW}! Tomcat is already running!${NC}"
      fi
      ;;
    stop)
      load_config
      if is_tomcat_running; then
        stop_tomcat
      else
        echo -e "${YELLOW}! Tomcat is not running!${NC}"
      fi
      ;;
    restart)
      load_config
      check_dependencies
      restart_server
      ;;
    deploy)
      load_config
      check_dependencies
      deploy_app
      ;;
    hotreload)
      load_config
      check_dependencies
      hot_reload
      ;;
    build)
      load_config
      check_dependencies
      build_project
      ;;
    clean)
      load_config
      check_dependencies
      clean_project
      ;;
    debug)
      load_config
      check_dependencies
      build_debug
      ;;
    watch)
      load_config
      check_dependencies
      watch_for_changes
      ;;
    interactive)
      load_config
      check_dependencies
      run_interactive_mode
      ;;
    setup)
      setup_config
      ;;
    install)
      install_system
      ;;
    uninstall)
      uninstall_system
      ;;
    status)
      load_config
      show_server_status
      ;;
    version)
      show_version
      ;;
    help)
      show_usage
      ;;
    *)
      show_banner
      if [ -n "$1" ]; then
        echo -e "${RED}Unknown command: $1${NC}"
      fi
      show_usage
      exit 1
      ;;
  esac
}

# Run main with all arguments
main "$@"
