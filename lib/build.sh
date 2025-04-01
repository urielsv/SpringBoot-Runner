#!/bin/bash

# lib/build.sh - Build system functions
# author: urielsv <urielsosavazquez@gmail.com>
# Last updated 31/03/2025

build_project() {
  echo -e "${BLUE}Building project...${NC}"
  
  # Make sure the source directory exists
  if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Source directory not found: $SOURCE_DIR${NC}"
    return 1
  fi
  
  # Execute the build command
  echo -e "${BLUE}Executing: $BUILD_COMMAND${NC}"
  eval $BUILD_COMMAND
  
  local build_status=$?
  if [ $build_status -eq 0 ]; then
    echo -e "${GREEN}✓ Build successful!${NC}"
    
    # Verify that WAR file was created
    if [ ! -f "$APP_WAR_PATH" ]; then
      echo -e "${YELLOW}! WAR file not found at: $APP_WAR_PATH${NC}"
      echo -e "${YELLOW}! Check your build configuration${NC}"
      return 1
    fi
    
    echo -e "${GREEN}✓ WAR file created at: $APP_WAR_PATH${NC}"
    return 0
  else
    echo -e "${RED}✗ Build failed with status $build_status${NC}"
    return 1
  fi
}

watch_for_changes() {
  echo -e "${BLUE}Watching for file changes in $SOURCE_DIR...${NC}"
  echo -e "${BLUE}Press Ctrl+C to stop watching${NC}"
  
  # Check if inotifywait is installed
  if ! command -v inotifywait &> /dev/null; then
    echo -e "${RED}Error: inotifywait is not installed.${NC}"
    exit 1
  fi
  
  # Set up patterns to exclude to reduce false triggers
  local exclude_pattern="\.git|\.idea|\.svn|target\/|build\/|\.vscode\/|\.class$|~$|\.swp$"
  
  echo -e "${GREEN}✓ Watching for changes. Press Ctrl+C to stop.${NC}"
  
  while true; do
    echo -e "${BLUE}Waiting for file changes...${NC}"
    
    # Watch for changes with inotifywait
    inotifywait -r -e modify,create,delete,move --exclude "$exclude_pattern" "$SOURCE_DIR"
    
    echo -e "${YELLOW}! Changes detected! Rebuilding...${NC}"
    
    # Give a small delay to allow multiple save events to settle
    sleep 1
    
    if build_project; then
      echo -e "${BLUE}Reloading application...${NC}"
      hot_reload
    else
      echo -e "${RED}✗ Skipping reload due to build failure${NC}"
    fi
  done
}

clean_project() {
  echo -e "${BLUE}Cleaning project...${NC}"
  
  local clean_command=""
  if [ "$BUILD_TYPE" = "maven" ]; then
    clean_command="cd $SOURCE_DIR && mvn clean"
  else
    echo -e "${RED}Unknown build type: $BUILD_TYPE${NC}"
    return 1
  fi
  
  echo -e "${BLUE}Executing: $clean_command${NC}"
  eval $clean_command
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Project cleaned successfully!${NC}"
    return 0
  else
    echo -e "${RED}✗ Failed to clean project${NC}"
    return 1
  fi
}

build_debug() {
  echo -e "${BLUE}Building project in debug mode...${NC}"
  
  local debug_build_command=""
  if [ "$BUILD_TYPE" = "maven" ]; then
    debug_build_command="cd $SOURCE_DIR && mvn clean package -DskipTests -X"
  else
    echo -e "${RED}Unknown build type: $BUILD_TYPE${NC}"
    return 1
  fi
  
  echo -e "${BLUE}Executing: $debug_build_command${NC}"
  eval $debug_build_command
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Debug build successful!${NC}"
    return 0
  else
    echo -e "${RED}✗ Debug build failed${NC}"
    return 1
  fi
}
