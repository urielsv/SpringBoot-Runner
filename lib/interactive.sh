#!/bin/bash

# lib/interactive.sh - Interactive mode functions
# author: urielsv <urielsosavazquez@gmail.com>
# Last updated 31/03/2025

run_interactive_mode() {
  WATCH_ENABLED=true
  WATCHER_PID=""
  
  handle_file_changes() {
    if [ "$WATCH_ENABLED" = true ]; then
      echo -e "${YELLOW}! Changes detected in source directory!${NC}"
      echo -e "${BLUE}Building project...${NC}"
      if build_project; then
        echo -e "${BLUE}Hot reloading...${NC}"
        hot_reload
      else
        echo -e "${RED}✗ Skipping reload due to build failure${NC}"
      fi
      # Clear any buffered input
      while read -t 0.1 -n 1; do : ; done
    fi
  }
  
  cleanup_interactive() {
    echo -e "\n${BLUE}Exiting interactive mode...${NC}"
    if [ ! -z "$WATCHER_PID" ]; then
      kill $WATCHER_PID >/dev/null 2>&1
    fi
    exit 0
  }
  
  # Set up trap to handle ctrl-c
  trap cleanup_interactive SIGINT SIGTERM
  
  clear
  
  if ! is_tomcat_running; then
    start_tomcat
    deploy_app
  fi
  
  show_interactive_header
  
  if command -v inotifywait &> /dev/null; then
    (
      while true; do
        # Exclude patterns to reduce false triggers
        local exclude_pattern="\.git|\.idea|\.svn|target\/|build\/|\.vscode\/|\.class$|~$|\.swp$"
        inotifywait -r -e modify,create,delete,move --exclude "$exclude_pattern" "$SOURCE_DIR" >/dev/null 2>&1
        # Signal to the main script that a change was detected
        kill -USR1 $$
      done
    ) &
    WATCHER_PID=$!
    
    # Set up trap to handle file change signals
    trap handle_file_changes USR1
    
    echo -e "${GREEN}✓ File watching enabled${NC}"
  else
    echo -e "${YELLOW}! inotifywait not found. File watching disabled.${NC}"
    echo -e "${YELLOW}  Install with: sudo apt-get install inotify-tools${NC}"
  fi
  
  while true; do
    # Read a single character without requiring Enter
    read -rsn1 key
    
    case "$key" in
      r)
        echo -e "${BLUE}Reloading server...${NC}"
        WATCH_ENABLED=false
        build_project && restart_server
        WATCH_ENABLED=true
        ;;
      h)
        echo -e "${BLUE}Hot reloading...${NC}"
        WATCH_ENABLED=false
        build_project && hot_reload
        WATCH_ENABLED=true
        ;;
      b)
        echo -e "${BLUE}Building only...${NC}"
        WATCH_ENABLED=false
        build_project
        WATCH_ENABLED=true
        ;;
      d)
        echo -e "${BLUE}Deploying only...${NC}"
        WATCH_ENABLED=false
        deploy_app
        WATCH_ENABLED=true
        ;;
      c)
        clear
        show_interactive_header
        ;;
      l)
        less +F "$TOMCAT_HOME/logs/catalina.out"
        clear
        show_interactive_header
        ;;
      s)
        show_server_status
        ;;
      q)
        echo -e "${BLUE}Exiting...${NC}"
        if [ ! -z "$WATCHER_PID" ]; then
          kill $WATCHER_PID >/dev/null 2>&1
        fi
        echo -e "${BLUE}Do you want to stop the Tomcat server? (y/n)${NC}"
        read -rsn1 stop_server
        if [ "$stop_server" = "y" ]; then
          stop_tomcat
        else
          echo -e "${GREEN}Leaving server running.${NC}"
        fi
        exit 0
        ;;
    esac
  done
}

show_interactive_header() {
  echo -e "${BOLD}${CYAN}==== SpringBoot Development Server ====${NC}"
  echo -e "${BOLD}${CYAN}App: ${NC}${APP_NAME} ${BOLD}${CYAN}Profile: ${NC}${SPRING_PROFILES} ${BOLD}${CYAN}Port: ${NC}${PORT}"
  echo -e "${CYAN}----------------------------------------${NC}"
  echo -e "${BOLD}Commands:${NC}"
  echo -e "  ${BOLD}r${NC} - Reload (full restart)"
  echo -e "  ${BOLD}h${NC} - Hot reload (when supported)"
  echo -e "  ${BOLD}b${NC} - Build only"
  echo -e "  ${BOLD}d${NC} - Deploy only"
  echo -e "  ${BOLD}c${NC} - Clear screen"
  echo -e "  ${BOLD}l${NC} - View logs"
  echo -e "  ${BOLD}s${NC} - Server status"
  echo -e "  ${BOLD}q${NC} - Quit"
  echo -e "${CYAN}----------------------------------------${NC}"
  echo -e "Server is running at ${BOLD}http://localhost:${PORT}/${APP_NAME}${NC}"
}

show_server_status() {
  echo -e "${BLUE}Server Status:${NC}"
  
  if is_tomcat_running; then
    echo -e "  Tomcat: ${GREEN}Running${NC}"
    
    local tomcat_pid=$(pgrep -f "catalina")
    echo -e "  PID: ${tomcat_pid}"
    
    if [ -d "$TOMCAT_HOME/webapps/$APP_NAME" ]; then
      echo -e "  Application: ${GREEN}Deployed${NC}"
    else
      echo -e "  Application: ${YELLOW}Not deployed${NC}"
    fi
    
    if command -v ps &> /dev/null; then
      local memory=$(ps -o rss= -p "$tomcat_pid" | awk '{print $1/1024 " MB"}')
      echo -e "  Memory Usage: ${memory}"
    fi
    
    if command -v ps &> /dev/null; then
      local uptime=$(ps -o etime= -p "$tomcat_pid")
      echo -e "  Uptime: ${uptime}"
    fi
    
    if curl -s http://localhost:$PORT/$APP_NAME > /dev/null 2>&1; then
      echo -e "  HTTP Status: ${GREEN}Accessible${NC}"
    else
      echo -e "  HTTP Status: ${RED}Not accessible${NC}"
    fi
  else
    echo -e "  Tomcat: ${RED}Not running${NC}"
  fi
  
  if [ -f "$APP_WAR_PATH" ]; then
    echo -e "  WAR File: ${GREEN}Exists${NC} ($(du -h "$APP_WAR_PATH" | cut -f1))"
    local war_modified=$(stat -c "%y" "$APP_WAR_PATH" 2>/dev/null || stat -f "%Sm" "$APP_WAR_PATH" 2>/dev/null)
    echo -e "  Last built: $war_modified"
  else
    echo -e "  WAR File: ${RED}Not found${NC}"
  fi
  
  echo ""
}
