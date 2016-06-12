#!/bin/bash

# Check the OS
platform=$(uname)
if [[ "$platform" != "Linux" ]]; then
  echo "This script does not work on $platform";
  exit 1;
fi

# Check for Chef DK
has_berks=$(which berks 2> /dev/null)
if [[ "$?" == "1" ]]; then
  echo "The chef development kit must be installed, and berks must be located in your PATH";
  exit 1;
fi

clean () {
  echo -e "\nCleaning..."

  # Delete links
  find . -maxdepth 1 -mindepth 1 -type l -exec echo Unlinking {} \; -exec rm {} \;
}

build() {
  echo -e "\nBuilding..."

  # Update vendor files
  berks vendor

  # Remove extra copies of local cookbooks
  for cookbook in $(find . -maxdepth 1 -mindepth 1 -type d -not -name berks-cookbooks -not -path '*/\.*' | sed 's/^\.\///'); do
    if [ -d "berks-cookbooks/$cookbook" ]; then
      echo "Removing berks-cookbooks/$cookbook"
      rm -rf "berks-cookbooks/$cookbook"
    fi
  done
}

install() {
  echo -e "\nInstalling..."

  # Link vendored cookbooks in root
  find berks-cookbooks -maxdepth 1 -mindepth 1 -type d -exec echo Linking {} \; -exec ln -sf {} \;
}

clean
build
install
