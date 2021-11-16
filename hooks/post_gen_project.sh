#!/bin/bash

pgtap="{{ cookiecutter.pgtap }}"
[[ ${pgtap} == 'no' ]] && rm -rf test

git init
git add .
git commit -m "Cookiecutter generated initial Sqitch project: {{ cookiecutter.project_slug }}"
