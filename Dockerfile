ARG BASE_IMAGE=containers.intersystems.com/intersystems/iris-community:latest-em
FROM ${BASE_IMAGE} AS base

ARG IPM_INSTALLER=https://pm.community.intersystems.com/packages/zpm/latest/installer

COPY ./iris.script /tmp/iris.script

RUN \
  wget -q $IPM_INSTALLER -O /tmp/zpm.xml && \
  mkdir /usr/irissys/mgr/zpm && \
  iris start $ISC_PACKAGE_INSTANCENAME quietly && \
  iris session $ISC_PACKAGE_INSTANCENAME -U %SYS < /tmp/iris.script && \
  iris stop $ISC_PACKAGE_INSTANCENAME quietly

FROM ${BASE_IMAGE}

USER root

WORKDIR /opt/irisapp
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/irisapp && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get -y install git && \
  apt-get clean -y && rm -rf /var/lib/apt/lists/* && \
  mkdir /docker-entrypoint-initdb.d/

COPY docker-entrypoint.sh /

USER ${ISC_PACKAGE_MGRUSER}

COPY --from=0 --chown=${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /usr/irissys/iris.cpf /usr/irissys/iris.cpf
COPY --from=0 --chown=${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /usr/irissys/mgr/zpm /usr/irissys/mgr/zpm

ENV PATH="$PATH:/home/irisowner/.local/bin"

COPY --chown=${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} iris_ipm.py /usr/irissys/lib/python/

ENV PIP_BREAK_SYSTEM_PACKAGES=1

ARG ML=false

RUN pip install irissqlcli && \
    ([ "$ML" = "true" ] && python3 -m pip install --index-url https://registry.intersystems.com/pypi/simple --no-cache-dir --target /usr/irissys/mgr/python intersystems-iris-automl matplotlib || true) && \
    cat /usr/irissys/lib/python/iris_ipm.py >> /usr/irissys/lib/python/iris.py

COPY iriscli /home/irisowner/bin/

ENTRYPOINT [ "/tini", "--", "/docker-entrypoint.sh" ]

CMD [ "iris" ]
