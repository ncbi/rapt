ARG BASE
ARG PGAP_VERSION
FROM ncbi/${BASE}:${PGAP_VERSION}

USER root

COPY pgap /pgap

WORKDIR /pgap

RUN echo "ip_resolve=4" >> /etc/yum.conf
RUN yum -y update && yum -y install yum-utils && yum -y groupinstall development
RUN yum -y install https://centos7.iuscommunity.org/ius-release.rpm
#RUN yum -y install http://dl.iuscommunity.org/pub/ius/stable/CentOS/7/x86_64/ius-release-1.0-13.ius.centos7.noarch.rpm
RUN yum -y install python36u python36u-pip python36u-devel nodejs
RUN pip3.6 install -U cwltool[deps] PyYAML cwlref-runner

RUN cat input.yaml MG37/input.yaml > mg37_input.yaml
RUN mkdir /pgap/input

CMD ["/bin/sh"]
