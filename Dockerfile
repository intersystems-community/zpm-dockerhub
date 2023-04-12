# syntax = edrevo/dockerfile-plus

ARG IMAGE=containers.intersystems.com/intersystems/iris-community:2022.2.0.368.0
ARG IMAGEARM=containers.intersystems.com/intersystems/iris-community-arm64:2022.2.0.368.0
ARG DEV=0
FROM $IMAGE

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

FROM --platform=linux/amd64 $IMAGE as x86

INCLUDE+ Dockerfile.commun

FROM --platform=linux/arm64 $IMAGEARM as arm

INCLUDE+ Dockerfile.commun
