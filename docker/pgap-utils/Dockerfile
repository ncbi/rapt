#FROM ncbi/pgap-base:latest
FROM centos:7

ARG version
ARG bindir
ARG libdir
ARG trnascan_version
ARG ncbi_crisper_version


USER root
WORKDIR /root
COPY --chown=root:root etc /etc

RUN echo "ip_resolve=4" >> /etc/yum.conf
RUN yum -y update && yum -y install yum-utils && yum -y groupinstall development
RUN yum -y install https://centos7.iuscommunity.org/ius-release.rpm
#RUN yum -y install http://dl.iuscommunity.org/pub/ius/stable/CentOS/7/x86_64/ius-release-1.0-13.ius.centos7.noarch.rpm
RUN yum -y install python36u python36u-pip python36u-devel nodejs

RUN yum -y install binutils perl sqlite ncbi-crispr${ncbi_crisper_version} nodejs ncbi-gcc730-opt-libs  ncbi-gcc493-opt-libs PyYAML
RUN ln -s /usr/bin/perl /usr/bin/perl5.16 \
    && ln -s /usr/bin/perl /opt/perl/5.16.3/bin/perl \
    && ln -s /usr/bin/node /usr/bin/nodejs \
    && rm /etc/yum.repos.d/ncbi.repo \
    && echo -e "* soft nofile 8192\n* hard nofile 8192\n" >> /etc/security/limits.conf
ENV PGAP_VERSION=${version}
ENV GP_HOME=/panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/bacterial_pipeline/system

RUN mkdir -p ${GP_HOME} && ln -s /panfs/pan1.be-md.ncbi.nlm.nih.gov /panfs/pan1

COPY infernal.tgz /root
WORKDIR /root
COPY binaries /root/binaries
RUN tar xvPf infernal.tgz -C /
WORKDIR /root/binaries
#RUN tar --exclude='*/etc' --exclude='*/setup' -xvf install.prod.tar.gz -C /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/bacterial_pipeline/system
RUN tar --exclude='*/etc' --exclude='*/setup' --exclude='*/src.tar.gz' -xvf install.tar.gz -C /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/bacterial_pipeline/system \
    && tar xvPf linked_exe.tar -C / \
    && tar xvPf libraries.tar -C / --skip-old-files \
    && tar xvPf trnascan.tgz -C /
RUN cd /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/ThirdParty/tRNAscan-SE/ \
    && rm -rf production \
    && ln -s ${trnascan_version} production

RUN mv ${GP_HOME}/next ${GP_HOME}/current && ln -s ${GP_HOME}/current/arch/x86_64/bin ${GP_HOME}/bin

# Strip down to the bare essentials
WORKDIR ${bindir}
RUN find . -maxdepth 1 -type f -not -name "*.p*" -not -name "*.txt" -not -name "*.ini" -not -name "cluster_blastp_wnode" -print0 | xargs -0 -i strip {}
#WORKDIR ${libdir}
#RUN strip *

WORKDIR /root

RUN useradd -ms /bin/bash gpipe
ENV NCBI=/netopt/ncbi_tools64
ENV GP_HOME=/panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/bacterial_pipeline/system
ENV PATH=${bindir}:${GP_HOME}/third-party/bin:${PATH}
ENV NI_SERVICE_NAME_TAXONOMY="some bogus value"
ENV NI_SERVICE_NAME_TAXONOMY3="some bogus value"

COPY binaries/bin ${GP_HOME}/third-party/bin
COPY package.versions ${GP_HOME}/third-party/
COPY binaries/bin/* ${GP_HOME}/bin/
COPY scripts/* ${bindir}/
COPY skesa ${GP_HOME}/third-party/bin
RUN chmod +x ${GP_HOME}/third-party/bin/skesa
#COPY binaries/tRNAscan-SE /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/ThirdParty/tRNAscan-SE

COPY ncbirc /netopt/ncbi_tools64/.ncbirc

RUN rm -rf binaries


WORKDIR /home/gpipe

CMD ["/usr/bin/bash"]

