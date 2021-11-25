#!/bin/bash

set -x

cat /app/templates/hive-site.xml.tmpl | envsubst > ${HIVE_CONF}/hive-site.xml
cat /app/templates/core-site.xml.tmpl | envsubst > ${HADOOP_CONF}/core-site.xml

if [ "$INSTALL_MODE" == "true" ]; then
    exec "${HIVE_HOME}/bin/schematool" -dbType mysql -initSchema
else
    exec "${HIVE_HOME}/bin/hive" --service metastore
fi
