#!/bin/sh
# should not be called directly, source (.) it instead
: ${GERRIT_SITE:?'ERROR! GERRIT_SITE env var is not set'}

echo >&2 "Syncing repos"

gerritBasePath=$(git config --file ${GERRIT_SITE}/etc/gerrit.config gerrit.basePath)
fetchRepos=$(
find $gerritBasePath/ -type d -name *.git -exec test -f {}/config \; -print |
  while read repoPath; do
    git config --file ${repoPath}/config remote.origin.url > /dev/null || continue;
    git --git-dir ${repoPath} fetch origin
  done;
)
