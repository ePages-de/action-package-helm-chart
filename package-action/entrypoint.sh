#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -x
unset HISTFILE # Disable generation of the .bash_history file

# Variables to be passed down from calling process:
# BUILD_TIMESTAMP -> in format yyyyMMddHHmmss
# PROJECT_CHART_NAME
# HELM_REPO_URL
# ARTIFACTORY_USERNAME
# ARTIFACTORY_PASSWORD

# The input parameters as upper case variables.
BUILD_TIMESTAMP="${1}"
PROJECT_CHART_NAME="${2}"
HELM_REPO_URL="${3}"
ARTIFACTORY_USERNAME="${4}"
ARTIFACTORY_PASSWORD="${5}"

if [[ -z "$BUILD_TIMESTAMP" ]]; then
  echo "Missing mandatory parameter: 'BUILD_TIMESTAMP'"
  exit 1
fi
if [[ -z "$PROJECT_CHART_NAME" ]]; then
  echo "Missing mandatory parameter: 'BUILD_TIMESTAMP'"
  exit 1
fi
if [[ -z "$HELM_REPO_URL" ]]; then
  echo "Missing mandatory parameter: 'HELM_REPO_URL'"
  exit 1
fi
if [[ -z "$ARTIFACTORY_USERNAME" ]]; then
  echo "Missing mandatory parameter: 'ARTIFACTORY_USERNAME'"
  exit 1
fi
if [[ -z "$ARTIFACTORY_PASSWORD" ]]; then
  echo "Missing mandatory parameter: 'ARTIFACTORY_PASSWORD'"
  exit 1
fi

# If there is no helm dir, exit
if [ ! -d src/deploy/helm ]; then
  exit 0
fi

# Determine chart version
chart_major_version=$(cat "src/deploy/helm/${PROJECT_CHART_NAME}/Chart.yaml" | grep '^version: ' | cut -d':' -f2 | xargs)
## From "20210910160410" to epoch "1631289850"
timestamp_epoch=$(date -d "${BUILD_TIMESTAMP:0:4}-${BUILD_TIMESTAMP:4:2}-${BUILD_TIMESTAMP:6:2} ${BUILD_TIMESTAMP:8:2}:${BUILD_TIMESTAMP:10:2}:${BUILD_TIMESTAMP:12:2}" '+%s')
new_chart_version="$chart_major_version.$timestamp_epoch"

# Save the version to a file for later use
echo "$new_chart_version" > helm-chart.version

helm repo add \
  --username ${ARTIFACTORY_USERNAME} \
  --password ${ARTIFACTORY_PASSWORD} \
  --pass-credentials \
  beyond-helm \
  "${HELM_REPO_URL}"

helm repo list # there should be something already here
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Check for messaging artifacts
output_message_values='build/message-artifacts-helm/message-artifact-values.yaml'
if [ -f "$output_message_values" ]; then
  MESSAGE_ARTIFACT_VALUES_FILE="${PWD}/${output_message_values}"
  RABBITMQ_ARTIFACTS_FILE=${PROJECT_CHART_NAME}/message-artifact-values.yaml
  VALUES_FILE=${PROJECT_CHART_NAME}/values.yaml

  cd src/deploy/helm

  cp "${MESSAGE_ARTIFACT_VALUES_FILE}" "${RABBITMQ_ARTIFACTS_FILE}"
  HEADER_LINE_NUMBER=$(grep -n '^springboot-master:' "${VALUES_FILE}" | cut -d':' -f1)
  TMP_FILE=${VALUES_FILE}.tmp
  head -n "${HEADER_LINE_NUMBER}" "${VALUES_FILE}" > "${TMP_FILE}"
  tail -n +2 "${RABBITMQ_ARTIFACTS_FILE}" | sed 's/^/  /' >> "${TMP_FILE}"
  tail -n "+$((HEADER_LINE_NUMBER + 1))" "${VALUES_FILE}" >> "${TMP_FILE}"
  mv "${TMP_FILE}" "${VALUES_FILE}"
else
  cd src/deploy/helm
fi

# Finally package it
helm package -u "${PROJECT_CHART_NAME}" --app-version "${BUILD_TIMESTAMP}" --version "${new_chart_version}"

helm_package_name="${PROJECT_CHART_NAME}-${new_chart_version}.tgz"

curl -sS --fail -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" \
  -X PUT "${HELM_REPO_URL}/${helm_package_name}" \
  -T "${helm_package_name}"

# Set the output parameters
echo '' # This needs to be in a new line to work
echo "chart-version=${new_chart_version}" >> $GITHUB_OUTPUT
