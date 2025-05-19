#!/usr/bash

# -- echo helpers
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'        # no color

green() {
  declare arg1="$1"
  echo -e "${GREEN}$arg1${NC}"
}

red() {
  declare arg1="$1"
  echo -e "${RED}$arg1${NC}"
}

yellow() {
  declare arg1="$1"
  echo -e "${YELLOW}$arg1${NC}"
}
# /- echo helpers
