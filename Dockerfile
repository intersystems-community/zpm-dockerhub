FROM --platform=$BUILDPLATFORM intersystems/iris-community-${BUILDARCH}:2024.1.0.238.0

RUN \
  wget -q https://pm.community.intersystems.com/packages/zpm/latest/installer -O /tmp/zpm.xml && \
  mkdir /usr/irissys/mgr/zpm && \
  iris start $ISC_PACKAGE_INSTANCENAME quietly && \
  /bin/echo -e \
    "set pNS(\"Globals\")=\"%DEFAULTDB\"\n" \
    "set sc=##class(Config.Namespaces).Create(\"%ALL\",.pNS)\n" \
    "if '\$Get(sc,1) do ##class(%SYSTEM.Process).Terminate(, 1)\n" \
    "set pDB(\"Directory\")=\"/usr/irissys/mgr/zpm/\"\n" \
    "set sc=##class(SYS.Database).CreateDatabase(pDB(\"Directory\"), 30)\n" \
    "do ##class(SYS.Database).MountDatabase(pDB(\"Directory\"))" \
    "if '\$Get(sc,1) do ##class(%SYSTEM.Process).Terminate(, 1)\n" \
    "set sc=##class(Config.Databases).Create(\"ZPM\",.pDB)\n" \
    "if '\$Get(sc,1) do ##class(%SYSTEM.Process).Terminate(, 1)\n" \
    "set pMap(\"Database\")=\"ZPM\"\n" \
    "set sc=##Class(Config.MapPackages).Create(\"%ALL\",\"%ZPM\",.pMap)\n" \
    "if '\$Get(sc,1) do ##class(%SYSTEM.Process).Terminate(, 1)\n" \
    "set sc=##Class(Config.MapGlobals).Create(\"%ALL\",\"%ZPM.*\",.pMap)\n" \
    "if '\$Get(sc,1) do ##class(%SYSTEM.Process).Terminate(, 1)\n" \
    "set sc=##Class(Config.MapGlobals).Create(\"%SYS\",\"ZPM.*\",.pMap)\n" \
    "if '\$Get(sc,1) do ##class(%SYSTEM.Process).Terminate(, 1)\n" \
    "set sc=##Class(Config.MapRoutines).Create(\"%ALL\",\"%ZPM.*\",.pMap)\n" \
    "if '\$Get(sc,1) do ##class(%SYSTEM.Process).Terminate(, 1)\n" \
    "set sc=##Class(Config.MapRoutines).Create(\"%ALL\",\"%ZLANGF00\",.pMap)\n" \
    "if '\$Get(sc,1) do ##class(%SYSTEM.Process).Terminate(, 1)\n" \
    "set sc=##Class(Config.MapRoutines).Create(\"%ALL\",\"%ZLANGC00\",.pMap)\n" \
    "if '\$Get(sc,1) do ##class(%SYSTEM.Process).Terminate(, 1)\n" \
    "set sc = ##class(%SYSTEM.OBJ).Load(\"/tmp/zpm.xml\", \"c\")\n" \
    "if '\$Get(sc,1) do ##class(%SYSTEM.Process).Terminate(, 1)\n" \
    "do ##class(SYS.Database).Defragment(pDB(\"Directory\"))" \
    "do ##class(SYS.Database).CompactDatabase(pDB(\"Directory\"),100)" \
    "do ##class(SYS.Database).ReturnUnusedSpace(pDB(\"Directory\"))" \
    "do ##class(SYS.Database).DismountDatabase(pDB(\"Directory\"))" \
    "halt" \
  | iris session $ISC_PACKAGE_INSTANCENAME -U %SYS && \
  iris stop $ISC_PACKAGE_INSTANCENAME quietly

FROM --platform=$TARGETPLATFORM intersystems/iris-community-${TARGETARCH}:2024.1.0.238.0

COPY iris.key /usr/irissys/mgr/iris.key

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

RUN pip install irissqlcli && \
    cat /usr/irissys/lib/python/iris_ipm.py >> /usr/irissys/lib/python/iris.py

COPY iriscli /home/irisowner/bin/

ENTRYPOINT [ "/tini", "--", "/docker-entrypoint.sh" ]

CMD [ "iris" ]
