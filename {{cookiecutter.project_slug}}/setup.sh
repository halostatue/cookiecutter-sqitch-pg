#!/bin/bash

declare install_pgtap postgres_version platform
install_pgtap="{{ cookiecutter.pgtap }}"
postgres_version="{{ cookiecutter.postgres_version }}"
platform="$(uname | tr 'A-Z' 'a-z')"

cleanup_brew()
{
  local -a brews
  brews=()
  for package in "${@}"; do
    brew list "${package}" > /dev/null 2>&1 && brews=(${brews[@]} ${package})
  done
  (( {{ "${#brews[@]}" }} )) && brew uninstall "${brews[@]}"
}

install_brew()
{
  local -a brews
  brews=()
  for package in "${@}"; do
    brew list "${package}" > /dev/null 2>&1 || brews=(${brews[@]} ${package})
  done
  (( {{ "${#brews[@]}" }} )) && brew install "${brews[@]}"
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
  install_brew homebrew/boneyard/pgtap
}

install_pgtap_linux()
{
  local package
  if [[ -z "${postgres_version}" ]]; then
    echo "No Postgres version specified; skipping..."
  else
    package="postgresql-{{ cookiecutter.postgres_version }}-pgtap"
    apt-get install -yq "${package}"
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
  cleanup_brew sqitch_pg
  install_brew sqitch cpanminus
  cpanm --quiet --notest -l "$(brew --prefix)" Template
}

install_linux()
{
  # Only Debian/Ubuntu-style Linuxes for now.
  apt-get install -yq  \
    libpq-dev \
    libdbd-pg-perl \
    postgresql-client \
    cpanminus
  cpanm --quiet --notest App::Sqitch Template DBD::Pg
}

install_"${platform}"
install_pgtap
