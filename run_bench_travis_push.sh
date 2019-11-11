#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_bench_travis_push.sh: Oracle benchmark - push results bach to GitHub.
#
# ------------------------------------------------------------------------------

setup_git() {
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
}

commit_result_files() {
  git diff --name-only HEAD~10 HEAD~5
  echo git diff --name-only HEAD~10 HEAD~5
  git checkout master
  echo git checkout master
  git pull
  echo git pull
  # Current month and year, e.g: Apr 2018
  dateAndMonth=`date "+%b %Y"`
  # Stage the modified files in dist/output
  git add -f priv/ora_bench_result.tsv
  echo git add -f priv/ora_bench_result.tsv
  git add -f priv/ora_bench_summary.tsv
  echo git add -f priv/ora_bench_summary.tsv
  # Create a new commit with a custom build message
  # with "[skip ci]" to avoid a build loop
  # and Travis build number for reference
  git commit -m "Travis update: $dateAndMonth (Build $TRAVIS_BUILD_NUMBER)" -m "[skip ci]"
  echo git commit -m "Travis update: $dateAndMonth (Build $TRAVIS_BUILD_NUMBER)" -m "[skip ci]"
}

upload_files() {
  # Remove existing "origin"
  git remote rm origin
  echo git remote rm origin
  # Add new "origin" with access token in the git URL for authentication
  git remote add origin https://KonnexionsGmbH:${ORA_BENCH_TOKEN}@github.com/KonnexionsGmbH/ora_bench.git > /dev/null 2>&1
  echo git remote add origin https://KonnexionsGmbH:${ORA_BENCH_TOKEN}@github.com/KonnexionsGmbH/ora_bench.git > /dev/null 2>&1
  git push origin master --quiet
  echo git push origin master --quiet
}

setup_git

commit_result_files

# Attempt to commit to git only if "git commit" succeeded
if [ $? -eq 0 ]; then
  echo "A new commit with changed result files exists. Uploading to GitHub"
  upload_files
else
  echo "No changes in result files. Nothing to do"
fi