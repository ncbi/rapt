FROM debian:buster-slim

ENV NCBI=/netopt/ncbi_tools64
ENV PATH=${PATH}:/usr/bin/skesa:/usr/bin/vdb
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/lib/ngs:/usr/lib/vdb

RUN apt-get update && apt-get install -y libxml2

COPY netopt /netopt/
COPY usr /usr/

CMD ["/usr/bin/bash"]

