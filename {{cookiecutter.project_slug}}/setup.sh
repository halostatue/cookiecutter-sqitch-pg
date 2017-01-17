#!/bin/bash

cleanup_brew()
{
  local -a brews
  brews=()
  for package in "${@}"; do
    brew list "${package}" > /dev/null 2>&1 && brews=(${brews[@]} ${package})
  done
  (( ${#brews[@]} )) && brew uninstall "${brews[@]}"
}

install_brew()
{
  local -a brews
  brews=()
  for package in "${@}"; do
    brew list "${package}" > /dev/null 2>&1 || brews=(${brews[@]} ${package})
  done
  (( ${#brews[@]} )) && brew install "${brews[@]}"
}

install_darwin()
{
  brew tap theory/sqitch
  cleanup_brew sqitch_pg
  install_brew sqitch cpanminus pgtap
  cpanm --quiet --notest -l "$(brew --prefix)" Template
}

install_linux()
{
  # OK, this is only Debian/Ubuntu-style Linuxes, but I don't use anything else.
  apt-get install -yq libdbd-pg-perl postgresql-client cpanminus postgresql-tap
  cpanm --quiet --notest App::Sqitch Template DBD::Pg
}

install_"$(uname | tr 'A-Z' 'a-z')"
