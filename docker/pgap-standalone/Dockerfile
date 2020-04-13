ARG BASE
ARG PGAP_VERSION
FROM ncbi/${BASE}:${PGAP_VERSION}

USER root

COPY pgap /pgap/pgap

WORKDIR /pgap

RUN pip3.6 install -U cwltool[deps] PyYAML cwlref-runner

RUN mkdir /pgap/input

CMD ["/bin/sh"]
