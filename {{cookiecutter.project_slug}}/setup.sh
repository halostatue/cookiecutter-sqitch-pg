#!/bin/bash

declare install_pgtap postgres_version platform sudo
declare -a cache_args

install_pgtap="${1:-package-install}"
postgres_version="9.6"
platform="$(uname | tr '[:upper:]' '[:lower:]')"
sudo=

prepare_ci()
{
  [ -z "${CI}" ] && return

  mkdir -p "${SEMAPHORE_CACHE_DIR}"/apt

  sudo=sudo
  cache_args=(-o "dir::cache::archives=${SEMAPHORE_CACHE_DIR}/apt")
}


linux_apt_get_update()
{
  "${sudo}" apt-get update -qq
}

linux_apt_get_install()
{
  # shellcheck disable=SC2068
  "${sudo}" apt-get ${cache_args[@]} install -yqq "${@}"
}

darwin_homebrew_cleanup()
{
  local -a brews
  brews=()
  for package in "${@}"; do
    brew list "${package}" > /dev/null 2>&1 && brews=(${brews[@]} ${package})
  done
  (( ${#brews[@]} )) && brew uninstall "${brews[@]}"
}

darwin_hombrew_install()
{
  local -a brews
  brews=()
  for package in "${@}"; do
    brew list "${package}" > /dev/null 2>&1 || brews=(${brews[@]} ${package})
  done
  (( ${#brews[@]} )) && brew install "${brews[@]}"
}

install_pgtap_build()
{
  local build_path
  build_path=$(mktemp -d)

  git clone https://github.com/theory/pgtap.git "${build_path}" &&
    pushd "${build_path}" &&
    make &&
    make install &&
    make installcheck &&
    popd
}

install_pgtap_darwin()
{
  darwin_hombrew_install homebrew/boneyard/pgtap
}

install_pgtap_linux()
{
  if [[ -z "${postgres_version}" ]]; then
    echo "No Postgres version specified; skipping..."
  else
    linux_apt_get_install "postgresql-9.6-pgtap"
  fi
}

install_pgtap()
{
  case "${install_pgtap}" in
    package-install)
      install_pgtap_"${platform}"
      ;;
    git-install)
      install_pgtap_build
      ;;
    *)
      echo "Skipping pgtap installation..."
      ;;
  esac
}

install_darwin()
{
  brew tap theory/sqitch
  darwin_homebrew_cleanup sqitch_pg
  darwin_hombrew_install sqitch cpanminus
  cpanm --quiet --notest -l "$(brew --prefix)" Template
}

install_linux()
{
  prepare_ci

  linux_apt_get_update

  # Only Debian/Ubuntu-style Linuxes for now.
  linux_apt_get_install libpq-dev libdbd-pg-perl postgresql-client cpanminus
  ${sudo} cpanm --quiet --notest App::Sqitch Template DBD::Pg
}

install_"${platform}"
install_pgtap
