ARG IMAGE=store/intersystems/iris-community:2020.1.0.199.0
ARG IMAGE=store/intersystems/iris-community:2019.4.0.383.0
ARG DEV=0
FROM $IMAGE

USER root

WORKDIR /opt/irisapp
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/irisapp

USER irisowner

RUN \
  wget -q https://pm.community.intersystems.com/packages/zpm/latest/installer -O /tmp/zpm.xml && \
  iris start $ISC_PACKAGE_INSTANCENAME quietly && \
  /bin/echo -e \
    "Do ##class(%SYSTEM.OBJ).Load(\"/tmp/zpm.xml\", \"ck\")\n" \
    "if '\$Get(sc,1) do ##class(%SYSTEM.Process).Terminate(, 1)\n" \
    "do ##class(SYS.Container).QuiesceForBundling()\n" \
    "halt" \
  | iris session $ISC_PACKAGE_INSTANCENAME -U %SYS && \
  iris stop $ISC_PACKAGE_INSTANCENAME quietly && \
  rm -rf /usr/irissys/mgr/IRIS.WIJ; \
  rm -rf /usr/irissys/mgr/journal/*; \
  rm -rf /usr/irissys/mgr/stream/*; \
  rm -rf /usr/irissys/mgr/iristemp/*; \
  rm /tmp/zpm.xml
