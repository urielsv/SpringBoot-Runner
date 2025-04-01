#!/bin/bash
# lib/tomcat.sh - Tomcat server management functions
# author: urielsv <urielsosavazquez@gmail.com>
# Last updated 1/04/2025

is_tomcat_running() {
  if pgrep -f "catalina" > /dev/null; then
    return 0 # Running
  else
    return 1
  fi
}

start_tomcat() {
  echo -e "${BLUE}Starting Tomcat server...${NC}"
  export JAVA_HOME=$JAVA_HOME
  export CATALINA_OPTS="$CATALINA_OPTS -Dspring.profiles.active=$SPRING_PROFILES"
  $TOMCAT_HOME/bin/startup.sh
  
  # Wait for Tomcat to start
  local max_wait=30
  local counter=0
  echo -n "Starting Tomcat: "
  while ! curl -s http://localhost:$PORT > /dev/null && [ $counter -lt $max_wait ]; do
    echo -n "."
    sleep 1
    counter=$((counter+1))
  done
  echo ""
  
  if [ $counter -lt $max_wait ]; then
    echo -e "${GREEN}✓ Tomcat started successfully!${NC}"
  else
    echo -e "${RED}✗ Failed to start Tomcat within $max_wait seconds${NC}"
    exit 1
  fi
}

stop_tomcat() {
  echo -e "${BLUE}Stopping Tomcat server...${NC}"
  $TOMCAT_HOME/bin/shutdown.sh
  
  # Wait for Tomcat to stop
  local max_wait=15
  local counter=0
  echo -n "Stopping Tomcat: "
  while is_tomcat_running && [ $counter -lt $max_wait ]; do
    echo -n "."
    sleep 1
    counter=$((counter+1))
  done
  echo ""
  
  if is_tomcat_running; then
    echo -e "${YELLOW}! Tomcat didn't stop gracefully, force killing...${NC}"
    pkill -f "catalina"
    sleep 1
    if ! is_tomcat_running; then
      echo -e "${GREEN}✓ Tomcat stopped successfully!${NC}"
    else
      echo -e "${RED}✗ Failed to stop Tomcat!${NC}"
      exit 1
    fi
  else
    echo -e "${GREEN}✓ Tomcat stopped successfully!${NC}"
  fi
}

deploy_app() {
  echo -e "${BLUE}Deploying application to tomcat...${NC}"
  
  # Remove previous deployment if it exists
  if [ -d "$TOMCAT_HOME/webapps/$APP_NAME" ]; then
    echo -e "${YELLOW}Removing previous deployment...${NC}"
    rm -rf "$TOMCAT_HOME/webapps/$APP_NAME"
  fi
  
  if [ -f "$TOMCAT_HOME/webapps/$APP_NAME.war" ]; then
    echo -e "${YELLOW}Removing previous WAR file...${NC}"
    rm -f "$TOMCAT_HOME/webapps/$APP_NAME.war"
  fi
  
  # Make sure WAR file exists
  if [ ! -f "$APP_WAR_PATH" ]; then
    echo -e "${RED}WAR file not found at $APP_WAR_PATH${NC}"
    echo -e "${YELLOW}Run build first with '$0 build'${NC}"
    return 1
  fi
  
  # Copy the WAR file to the webapps directory
  echo -e "${BLUE}Copying WAR file to webapps directory...${NC}"
  cp "$APP_WAR_PATH" "$TOMCAT_HOME/webapps/$APP_NAME.war"
  
  echo -e "${GREEN}✓ Application deployed!${NC}"
  return 0
}

restart_server() {
  echo -e "${BLUE}Performing full restart...${NC}"
  stop_tomcat
  if deploy_app; then
    start_tomcat
    echo -e "${GREEN}✓ Restart completed!${NC}"
  else
    echo -e "${RED}✗ Failed to deploy application. Restart aborted.${NC}"
  fi
}

hot_reload() {
  echo -e "${BLUE}Attempting hot reload...${NC}"
  
  # For Spring Boot applications, try to trigger a reload
  # This requires Spring Boot Actuator with endpoints enabled
  if curl -s -X POST http://localhost:$PORT/$APP_NAME/actuator/restart > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Hot reload triggered successfully!${NC}"
    return 0
  elif curl -s -X POST http://localhost:$PORT/actuator/restart > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Hot reload triggered successfully!${NC}"
    return 0
  else
    echo -e "${YELLOW}! Hot reload not available, performing full restart...${NC}"
    restart_server
    return $?
  fi
}
