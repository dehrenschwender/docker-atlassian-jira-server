FROM ehrenschwender/ubuntu-server-jre:8
MAINTAINER Dirk Ehrenschwender <dirk.ehrenschwender@me.com>

# Setup useful environment variables
ENV JIRA_HOME     /var/atlassian/jira
ENV JIRA_INSTALL  /opt/atlassian/jira
ENV JIRA_VERSION  7.5.0

LABEL Description="This image is used to start Atlassian JIRA" Vendor="Atlassian" Version="${JIRA_VERSION}"

ENV JIRA_DOWNLOAD_URL https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-software-${JIRA_VERSION}.tar.gz

ENV MYSQL_VERSION 5.1.38
ENV MYSQL_DRIVER_DOWNLOAD_URL http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_VERSION}.tar.gz

ENV RUN_USER            daemon
ENV RUN_GROUP           psacln

# Install Atlassian JIRA and helper tools and setup initial home directory structure.
RUN set -x \
    && apt-get update \
    && apt-get install --yes apt-utils nano curl libtcnative-1 xmlstarlet \
    && apt-get clean \
    && mkdir -p                           "${JIRA_HOME}" \
    && mkdir -p                           "${JIRA_HOME}/caches/indexes" \
    && chmod -R 700                       "${JIRA_HOME}" \
    && chown -R ${RUN_USER}:${RUN_GROUP}  "${JIRA_HOME}" \
    && mkdir -p                           "${JIRA_INSTALL}/conf/Catalina" \
    && curl -Ls                           "${JIRA_DOWNLOAD_URL}" | tar -xz --directory "${JIRA_INSTALL}" --strip-components=1 --no-same-owner \
    && curl -Ls                           "${MYSQL_DRIVER_DOWNLOAD_URL}" | tar -xz --directory "${JIRA_INSTALL}/lib" --strip-components=1 --no-same-owner "mysql-connector-java-${MYSQL_VERSION}/mysql-connector-java-${MYSQL_VERSION}-bin.jar" \
    && chmod -R 700                       "${JIRA_INSTALL}/conf" \
    && chmod -R 700                       "${JIRA_INSTALL}/logs" \
    && chmod -R 700                       "${JIRA_INSTALL}/temp" \
    && chmod -R 700                       "${JIRA_INSTALL}/work" \
    && chown -R ${RUN_USER}:${RUN_GROUP}  "${JIRA_INSTALL}/conf" \
    && chown -R ${RUN_USER}:${RUN_GROUP}  "${JIRA_INSTALL}/logs" \
    && chown -R ${RUN_USER}:${RUN_GROUP}  "${JIRA_INSTALL}/temp" \
    && chown -R ${RUN_USER}:${RUN_GROUP}  "${JIRA_INSTALL}/work" \
    && echo -e                            "jira.home=${JIRA_HOME}" >> "${JIRA_INSTALL}/atlassian-jira/WEB-INF/classes/jira-application.properties" \
    && touch -d "@0"                      "${JIRA_INSTALL}/conf/server.xml"

USER ${RUN_USER}:${RUN_GROUP}

# Expose default HTTP connector port.
EXPOSE 8080

# Set volume mount points for installation and home directory. Changes to the
# home directory needs to be persisted as well as parts of the installation
# directory due to eg. logs.
VOLUME ["${JIRA_HOME}", "${JIRA_INSTALL}/logs"]

# Set the default working directory as the JIRA installation directory.
WORKDIR ${JIRA_INSTALL}

COPY "docker-entrypoint.sh" "/"
ENTRYPOINT ["/docker-entrypoint.sh"]

# Run Atlassian JIRA as a foreground process by default.
CMD ["./bin/start-jira.sh", "run"]
