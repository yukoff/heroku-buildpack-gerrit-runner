#!/bin/sh
# should not be called directly, source (.) it instead
: ${GERRIT_SITE:?'ERROR! GERRIT_SITE env var is not set'}
: ${GERRIT_WAR:?'ERROR! GERRIT_WAR env var is not set'}

echo "Reindexing..."
java -jar $GERRIT_WAR reindex -d $GERRIT_SITE --verbose
