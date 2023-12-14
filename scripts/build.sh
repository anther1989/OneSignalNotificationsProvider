#!/usr/bin/env bash

## Build the OneSignalNotificationsProvider-Package
## This script is used by the CI to build the package for all supported platforms and variants.
## It is also used by the developer to build the package locally.

# Constants
SCHEME_NAME="OneSignalNotificationsProvider-Package"
PLATFORMS=("iOS")
VARIANTS=("" " Simulator")

# Check if the terminal supports colors
if [ "$(tput colors 2>/dev/null)" -ge 8 ]; then
  GREEN="$(tput setaf 2)"
  BOLD="$(tput bold)"
  RESET="$(tput sgr0)"
else
  GREEN=""
  BOLD=""
  RESET=""
fi

for platform in "${PLATFORMS[@]}"
do
    for variant in "${VARIANTS[@]}"
    do
        echo "${BOLD}Building ${SCHEME_NAME} for ${platform}${variant}${RESET}"
        xcrun xcodebuild clean build -scheme "${SCHEME_NAME}" -destination "generic/platform=${platform}${variant}" -quiet
    done
done

echo "${BOLD}${GREEN}✅ BUILD SUCCEEDED${RESET}"
