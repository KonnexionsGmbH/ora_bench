#!/bin/bash

# ------------------------------------------------------------------------------
#
# run_travis_push_to_github.sh: Oracle benchmark - push results back to GitHub.
#
# ------------------------------------------------------------------------------

if [ "${ORA_BENCH_CHOICE_DRIVER}" = "complete" ]; then
  setup_git() {
    git config --global user.email "travis@travis-ci.org"
    git config --global user.name "Travis CI"
  }
  
  commit_result_files() {
    cp priv/ora_bench_result.tsv /tmp
    cd /tmp || exit 255
    git clone --branch=gh-pages https://github.com/KonnexionsGmbH/ora_bench.git
    mv /tmp/ora_bench_result.tsv ora_bench/results/
    cd ora_bench || exit 255
    # Current month and year, e.g: Apr 2018
    dateAndMonth=$(date "+%b %Y")
    # Stage the modified files in dist/output
    git add -f results/ora_bench_result.tsv
    # Create a new commit with a custom build message
    # with "[skip ci]" to avoid a build loop
    # and Travis build number for reference
    git commit -m "Travis update: $dateAndMonth (Build $TRAVIS_BUILD_NUMBER)" -m "[skip ci]"
  }
  
  upload_files() {
    # Remove existing "origin"
    git remote rm origin
    # Add new "origin" with access token in the git URL for authentication
    git remote add origin https://KonnexionsGmbH:"${ORA_BENCH_TOKEN}"@github.com/KonnexionsGmbH/ora_bench.git > /dev/null 2>&1
    git push origin gh-pages
  }
  
  setup_git
  
  # Attempt to commit to git only if "git commit" succeeded
  if commit_result_files; then
    echo "A new commit with changed result files exists. Uploading to GitHub"
    upload_files
  else
    echo "No changes in result files. Nothing to do"
  fi
else    
  echo "Not a complete run. Nothing to do"
fi
