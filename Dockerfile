# escape=`

FROM --platform=windows/amd64 edgehog/git-adoptopenjdk8-jdk-hotspot:latest-windowsservercore-ltsc2016

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG VERSION=4.3
LABEL Description="This is a base image, which provides the Jenkins agent executable (agent.jar)" Version="${VERSION}"

ARG user=jenkins

ARG AGENT_FILENAME=agent.jar
ARG AGENT_HASH_FILENAME=$AGENT_FILENAME.sha1

RUN net user "$env:user" /add /expire:never /passwordreq:no ; `
    net localgroup Administrators /add $env:user ; `
    New-Item -ItemType Directory -Path C:/ProgramData/Jenkins | Out-Null

ARG AGENT_ROOT=C:/Users/$user
ARG AGENT_WORKDIR=${AGENT_ROOT}/Work

ENV AGENT_WORKDIR=${AGENT_WORKDIR}

# Get the Agent from the Jenkins Artifacts Repository
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; `
    Invoke-WebRequest $('https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/{0}/remoting-{0}.jar' -f $env:VERSION) -OutFile $(Join-Path C:/ProgramData/Jenkins $env:AGENT_FILENAME) -UseBasicParsing ; `
    Invoke-WebRequest $('https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/{0}/remoting-{0}.jar.sha1' -f $env:VERSION) -OutFile (Join-Path C:/ProgramData/Jenkins $env:AGENT_HASH_FILENAME) -UseBasicParsing ; `
    if ((Get-FileHash (Join-Path C:/ProgramData/Jenkins $env:AGENT_FILENAME) -Algorithm SHA1).Hash -ne (Get-Content (Join-Path C:/ProgramData/Jenkins $env:AGENT_HASH_FILENAME))) {exit 1} ; `
    Remove-Item -Force (Join-Path C:/ProgramData/Jenkins $env:AGENT_HASH_FILENAME)

USER $user

RUN New-Item -Type Directory $('{0}/.jenkins' -f $env:AGENT_ROOT) | Out-Null ; `
    New-Item -Type Directory $env:AGENT_WORKDIR | Out-Null

VOLUME ${AGENT_ROOT}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR ${AGENT_ROOT}
