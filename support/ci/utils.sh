#!/usr/bin/env bash

function section_start () {
  local section_title="${1}"
  local section_description="${2:-$section_title}"

  echo -e "section_start:$(date +%s):${section_title}[collapsed=true]\r\e[0K${section_description}"
}

function section_end () {
  local section_title="${1}"

  echo -e "section_end:$(date +%s):${section_title}\r\e[0K"
}

function display_debugging() {
  if [ "${KDK_DEBUG}" = "1" ] || [ "${KDK_DEBUG}" = "true" ]; then
    section_start "debugging-info" "Debugging info"

    debugging_commands

    section_end "debugging-info"
  fi

  true
}

function execute_command() {
  command="${*}"

  echo "${command}"
  echo "-------------------------------------------------------------------------------"
  eval "${command}"
  echo
}

function debugging_commands() {
  execute_command whoami
  execute_command ulimit -a
  execute_command /sbin/sysctl -a
  execute_command nproc
  execute_command df -h
  execute_command free -m
  execute_command 'env | grep -Ev "TOKEN|PASSWORD|LICENSE|KEY"'
  execute_command pwd
  execute_command ls -la
}

function run_timed_command() {
  local cmd="${1}"
  local metric_name="${2:-no}"
  local timed_metric_file
  local start
  start=$(date +%s)

  echosuccess "\$ ${cmd}"
  eval "${cmd}"

  local ret=$?
  local end
  end=$(date +%s)
  local runtime=$((end-start))

  if [[ $ret -eq 0 ]]; then
    echosuccess "==> '${cmd}' succeeded in ${runtime} seconds."

    if [[ "${metric_name}" != "no" ]]; then
      timed_metric_file=$(timed_metric_file "${metric_name}")
      echo "# TYPE ${metric_name} gauge" > "${timed_metric_file}"
      echo "# UNIT ${metric_name} seconds" >> "${timed_metric_file}"
      echo "${metric_name} ${runtime}" >> "${timed_metric_file}"
    fi

    return 0
  else
    echoerr "==> '${cmd}' failed (${ret}) in ${runtime} seconds."
    return $ret
  fi
}

function echoerr() {
  local header="${2:-no}"

  if [ "${header}" != "no" ]; then
    printf "\n\033[0;31m** %s **\n\033[0m" "${1}" >&2;
  else
    printf "\033[0;31m%s\n\033[0m" "${1}" >&2;
  fi
}

function echoinfo() {
  local header="${2:-no}"

  if [ "${header}" != "no" ]; then
    printf "\n\033[0;33m** %s **\n\033[0m" "${1}" >&2;
  else
    printf "\033[0;33m%s\n\033[0m" "${1}" >&2;
  fi
}

function echosuccess() {
  local header="${2:-no}"

  if [ "${header}" != "no" ]; then
    printf "\n\033[0;32m** %s **\n\033[0m" "${1}" >&2;
  else
    printf "\033[0;32m%s\n\033[0m" "${1}" >&2;
  fi
}
