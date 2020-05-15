FROM python:3.8-slim-buster

ENV VIRTUAL_ENV -p python3.8 /env
ENV PATH /env/bin:$PATH

COPY app/requirements.txt /app/
RUN pip install --no-cache-dir -r /app/requirements.txt

ENV PYTHONPATH /app
ENV PYTHONUNBUFFERED 1

ENV NCBI=/netopt/ncbi_tools64
ENV PATH=${PATH}:/usr/bin/skesa:/usr/bin/vdb
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/lib/ngs:/usr/lib/vdb

COPY . /

ENTRYPOINT []

CMD ["python", "/app/execute.py"]

