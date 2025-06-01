#!/bin/ash
# Software: PaperMC
# Variables: MINECRAFT_VERSION?, BUILD_NUMBER?, SERVER_BINARY

PROJECT_DATA=$(curl -fsS https://api.papermc.io/v2/projects/paper)
if [ -z "$PROJECT_DATA" ]; then
  echo "Error: Failed to fetch data from PaperMC API." >&2
  exit 1
fi

_DESIRED_MINECRAFT_VERSION="${MINECRAFT_VERSION}"
if [ -n "${_DESIRED_MINECRAFT_VERSION}" ] && \
   echo "$PROJECT_DATA" | jq -e --arg VERSION "$_DESIRED_MINECRAFT_VERSION" '.versions | any(. == $VERSION)' > /dev/null 2>&1; then
  echo "Using Minecraft version: ${_DESIRED_MINECRAFT_VERSION}."
else
  _LATEST_VERSION=$(echo "$PROJECT_DATA" | jq -r '.versions[-1]')
  if [ -n "${_DESIRED_MINECRAFT_VERSION}" ]; then
    echo "Minecraft version '${_DESIRED_MINECRAFT_VERSION}' not found or invalid. Using latest: ${_LATEST_VERSION}."
  else
    echo "Minecraft version not specified. Using latest: ${_LATEST_VERSION}."
  fi
  MINECRAFT_VERSION="${_LATEST_VERSION}"
fi

VERSION_BUILD_DATA=$(curl -fsS "https://api.papermc.io/v2/projects/paper/versions/${MINECRAFT_VERSION}")
if [ -z "$VERSION_BUILD_DATA" ]; then
  echo "Error: Failed to fetch build data for Minecraft version ${MINECRAFT_VERSION}." >&2
  exit 1
fi

_LATEST_BUILD=$(echo "$VERSION_BUILD_DATA" | jq -r '.builds[-1]')
_DESIRED_BUILD_NUMBER="${BUILD_NUMBER}"

if [ -n "$_DESIRED_BUILD_NUMBER" ] && \
   echo "$VERSION_BUILD_DATA" | jq -e --argjson BN "$_DESIRED_BUILD_NUMBER" '.builds | any(. == $BN)' > /dev/null 2>&1; then
  echo "Using build number: ${_DESIRED_BUILD_NUMBER} for Minecraft ${MINECRAFT_VERSION}."
  BUILD_NUMBER="${_DESIRED_BUILD_NUMBER}"
else
  if [ -n "$_DESIRED_BUILD_NUMBER" ]; then
    echo "Build '${_DESIRED_BUILD_NUMBER}' not found or invalid for Minecraft ${MINECRAFT_VERSION}. Using latest build: ${_LATEST_BUILD}."
  else
    echo "Build number not specified for Minecraft ${MINECRAFT_VERSION}. Using latest build: ${_LATEST_BUILD}."
  fi
  BUILD_NUMBER="${_LATEST_BUILD}"
fi

JAR_NAME="paper-${MINECRAFT_VERSION}-${BUILD_NUMBER}.jar"
DOWNLOAD_URL="https://api.papermc.io/v2/projects/paper/versions/${MINECRAFT_VERSION}/builds/${BUILD_NUMBER}/downloads/${JAR_NAME}"

cd /mnt/server || echo "Error: Failed to change directory to /mnt/server" >&2 && exit 1

echo "Downloading ${JAR_NAME} from ${DOWNLOAD_URL} to ${SERVER_BINARY}..."
rm -f "${SERVER_BINARY}"
if curl -fsSL -o "${SERVER_BINARY}" "${DOWNLOAD_URL}"; then
  echo "Download complete: ${SERVER_BINARY}"
else
  echo "Error: Download failed for ${JAR_NAME} from ${DOWNLOAD_URL}" >&2
  rm -f "${SERVER_BINARY}"
  exit 1
fi