FROM ubuntu:18.04

ENV \
  SAMTOOLS_URL="https://github.com/samtools/samtools/releases/download/1.9/samtools-1.9.tar.bz2" \
  SAMTOOLS_PATH="/samtools-1.9" \
  PATH=${SAMTOOLS_PATH}:${PATH}

RUN apt-get update \
  && apt-get install -y \
    awscli \
    bzip2 \
    gcc \
    gzip \
    make \
    libbz2-dev \
    liblzma-dev \
    libncurses5-dev \
    wget \
    zlib1g-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN wget ${SAMTOOLS_URL} && tar xjf ${SAMTOOLS_PATH}.tar.bz2 && (cd ${SAMTOOLS_PATH} && make)

WORKDIR /

COPY worker.sh /

CMD ["./worker.sh"]
