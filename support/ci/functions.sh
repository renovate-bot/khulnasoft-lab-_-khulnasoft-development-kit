# shellcheck shell=bash

KDK_CHECKOUT_PATH="${HOME}/kdk"

if [[ ${KDK_DEBUG} == "1" ]]; then
  export GIT_CURL_VERBOSE=1
fi

cd_into_checkout_path() {
  cd "${KDK_CHECKOUT_PATH}/${1}" || exit
}

init() {
  sudo /sbin/sysctl fs.inotify.max_user_watches=1048576

  install_kdk_clt
}

install_kdk_clt() {
  if [[ "$("${KDK_CHECKOUT_PATH}/bin/kdk" config get kdk.use_bash_shim)" == "true" ]]; then
    echo "INFO: Installing kdk shim.."
    install_shim
  else
    echo "INFO: Installing khulnasoft-development-kit Ruby gem.."
    install_gem
  fi
}

install_shim() {
  cp -f "${KDK_CHECKOUT_PATH}/bin/kdk" /usr/local/bin
}

install_gem() {
  cd_into_checkout_path "gem"

  gem build khulnasoft-development-kit.gemspec
  gem install khulnasoft-development-kit-*.gem
}

checkout() {
  cd_into_checkout_path

  # $CI_MERGE_REQUEST_SOURCE_PROJECT_URL only exists in pipelines generated in merge requests.
  if [ -n "${CI_MERGE_REQUEST_SOURCE_PROJECT_URL}" ]; then
    git remote set-url origin "${CI_MERGE_REQUEST_SOURCE_PROJECT_URL}.git"
  fi

  git fetch
  git checkout "${1}"
}

set_khulnasoft_upstream() {
  cd_into_checkout_path "gitlab"

  local remote_name
  local default_branch

  remote_name="upstream"
  default_branch="master"

  if git remote | grep -Eq "^${remote_name}$"; then
    echo "Remote ${remote_name} already exists in $(pwd)."
    return
  fi

  git remote add "${remote_name}" "https://github.com/khulnasoft-lab/khulnasoft.git"

  git remote set-url --push "${remote_name}" none # make 'upstream' fetch-only
  echo "Fetching ${default_branch} from ${remote_name}..."

  git fetch "${remote_name}" ${default_branch}

  # check if the default branch already exists
  if git show-ref --verify --quiet refs/heads/${default_branch}; then
    git branch --set-upstream-to="${remote_name}/${default_branch}" ${default_branch}
  else
    git branch ${default_branch} "${remote_name}/${default_branch}"
  fi
}

install() {
  cd_into_checkout_path

  echo "> Installing KDK.."
  kdk install
  set_khulnasoft_upstream
}

update() {
  cd_into_checkout_path

  echo "> Updating KDK.."
  # we use `make update` instead of `kdk update` to ensure the working directory
  # is not reset to the default branch.
  make update
  set_khulnasoft_upstream
  restart
}

reconfigure() {
  cd_into_checkout_path

  echo "> Running kdk reconfigure.."
  kdk reconfigure
}

reset_data() {
  cd_into_checkout_path

  echo "> Running kdk reset-data.."
  kdk reset-data
}

pristine() {
  cd_into_checkout_path

  echo "> Running kdk pristine.."
  kdk pristine
}

start() {
  cd_into_checkout_path

  echo "> Starting up KDK.."
  kdk start
}

stop() {
  cd_into_checkout_path

  echo "> Stopping KDK.."

  # shellcheck disable=SC2009
  ps -ef | grep "[r]unsv" || true

  KDK_KILL_CONFIRM=true kdk kill || true

  # shellcheck disable=SC2009
  ps -ef | grep "[r]unsv" || true
}

restart() {
  cd_into_checkout_path

  echo "> Restarting KDK.."

  stop_start

  echo "> Upgrading PostgreSQL data directory if necessary.."
  support/upgrade-postgresql

  stop_start
}

stop_start() {
  cd_into_checkout_path

  stop
  status
  start
}

status() {
  cd_into_checkout_path

  echo "> Running kdk status.."
  kdk status || true
}

doctor() {
  cd_into_checkout_path

  echo "> Running kdk doctor.."
  set +e
  kdk doctor
  code=$?
  set -e
  # code 2 is for Ruby errors, so we wanna fail the job
  if [ $code -eq 2 ]; then
    return 1
  fi
}

test_url() {
  cd_into_checkout_path

  sleep 60

  status

  support/ci/test_url
}

setup_geo() {
  sudo /sbin/sysctl fs.inotify.max_user_watches=524288

  if [ -n "${CI_MERGE_REQUEST_SOURCE_BRANCH_SHA}" ]; then
    sha="${CI_MERGE_REQUEST_SOURCE_BRANCH_SHA}"
  else
    sha="${CI_COMMIT_SHA}"
  fi

  cd ..
  KHULNASOFT_LICENSE_MODE=test CUSTOMER_PORTAL_URL="https://customers.staging.gitlab.com" kdk/support/geo-install kdk kdk2 "${sha}"
  output=$(cd kdk2/gitlab && bin/rake gitlab:geo:check)

  matchers=(
    "KhulnaSoft Geo is enabled ... yes"
    "This machine's Geo node name matches a database record ... yes, found a secondary node named \"kdk2\""
    "KhulnaSoft Geo tracking database is correctly configured ... yes"
    "Database replication enabled? ... yes"
    "Database replication working? ... yes"
  )

  for matcher in "${matchers[@]}"; do
    if [[ $output != *${matcher}* ]]; then
      echo "Geo install failed. The string is not found: ${matcher}"
      exit 1
    fi
  done
}
