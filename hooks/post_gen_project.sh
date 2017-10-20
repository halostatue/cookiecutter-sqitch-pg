#!/bin/bash

pgtap="{{ cookiecutter.pgtap }}"
[[ ${pgtap} == 'no' ]] && rm -rf test

if ! type -aP sqitch > /dev/null; then
  printf "Sqitch is not installed.\n"
  # shellcheck disable=SC2019,SC2018
  if [[ $(uname | tr 'A-Z' 'a-z') == "darwin" ]]; then
    printf "Installing sqitch...\n"
    ./setup.sh
  else
    printf "Installing sqitch... (uses sudo to install the appropriate packages)\n"
    sudo ./setup.sh
  fi
fi

service="{{ cookiecutter.project_service }}"
username="{{ cookiecutter.username }}"
slug="{{ cookiecutter.project_slug }}"

sqitch init "${slug}" \
  --uri "https://${service}/${username}/${slug}" \
  --engine pg \
  --target "db:pg:{{ cookiecutter.development_database }}"

sqitch target add development "db:pg:{{ cookiecutter.development_database }}"
sqitch engine alter pg --target development
sqitch config --add deploy.verify true
sqitch config --add rebase.verify true
sqitch config --add add.template_directory templates

git init
git add .
git commit -m "Cookiecutter generated initial Sqitch project: {{ cookiecutter.project_slug }}"
