# Use a Java 8 base image
FROM eclipse-temurin:8-focal

# Set working directory
WORKDIR /app

# Add a service user with a rather large uid to avoid confusion with host user
RUN groupadd -g 10000 hive && \
    useradd -u 10000 -g 10000 -r -s /sbin/nologin -c "Hive Service User" hive

# Install some dependencies
RUN apt-get update && \
    apt-get install -y gettext-base && \
    apt-get clean && \
    apt-get autoremove

# Entrypoint
ENTRYPOINT ["/app/tini", "--"]
CMD ["/app/docker-entrypoint.sh"]

# Download Hadoop
ARG HADOOP_VERSION=3.2.2
ENV HADOOP_VERSION=${HADOOP_VERSION}
ENV HADOOP_HOME=/app/hadoop-${HADOOP_VERSION}
ENV HADOOP_CONF=${HADOOP_HOME}/etc/hadoop
RUN curl https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    | tar -xzC /app

# Download Hive
ARG HIVE_VERSION=3.1.2
ENV HIVE_VERSION=${HIVE_VERSION}
ENV HIVE_HOME=/app/apache-hive-${HIVE_VERSION}-bin
ENV HIVE_CONF=${HIVE_HOME}/conf
RUN curl https://dlcdn.apache.org/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz \
    | tar -xzC /app

# Fix guava compatibility issue with old Hive version
RUN rm -rf ${HIVE_HOME}/lib/guava-19.0.jar && \
    cp ${HADOOP_HOME}/share/hadoop/common/lib/guava-27.0-jre.jar ${HIVE_HOME}/lib/

# Download GCS Connector to enable access to google cloud storage
RUN cd ${HADOOP_HOME}/share/hadoop/common/lib && \
    curl -O -L https://repo1.maven.org/maven2/com/google/cloud/bigdataoss/gcs-connector/hadoop3-2.2.4/gcs-connector-hadoop3-2.2.4-shaded.jar

# Download MySQL JDBC library for metastore connection
RUN cd ${HIVE_HOME}/lib && \
    curl -O https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.27/mysql-connector-java-8.0.27.jar

# Download Tini for PID 1
ARG TINI_VERSION=v0.19.0
RUN cd /app/ && \
    curl -O -L https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini && \
    chmod +x /app/tini

COPY files/hive-log4j2.properties ${HIVE_CONF}/

COPY templates /app/templates

COPY files/docker-entrypoint.sh /app/

# Fixup file permission
RUN chown hive ${HIVE_CONF} ${HADOOP_CONF}/core-site.xml && \
    chmod +x /app/docker-entrypoint.sh

# Set default user to run
USER hive
