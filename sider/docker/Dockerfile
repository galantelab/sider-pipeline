FROM galantelab/sider:release-0.14.0

ARG FASTA_FILE
ARG GTF_FILE
ARG REF_PATH
ARG REF_CACHE
ARG ASSETS

ENV DEBIAN_FRONTEND=noninteractive \
    SAM_URL=https://github.com/samtools/samtools/releases/download/1.9/samtools-1.9.tar.bz2 \
    SAM_PATH=/samtools-1.9 \
    REFERENCE=${FASTA_FILE} \
    ANNOTATION=${GTF_FILE} \
    REF_PATH=${REF_PATH} \
    REF_CACHE=${REF_CACHE}

ENV PATH=${SAM_PATH}:${PATH}

RUN apt-get update \
  && apt-get install -y \
    awscli \
    bsdmainutils \
    bzip2 \
    gzip \
    libbz2-dev \
    libcurl4 \
    libcurl4-openssl-dev \
    liblzma-dev \
    libncurses5-dev \
    make \
    unzip \
    wget \
    zlib1g-dev \
  && ln -snf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime \
  && dpkg-reconfigure -f noninteractive tzdata \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN wget ${SAM_URL} \
  && tar xjf ${SAM_PATH}.tar.bz2 \
  && (cd ${SAM_PATH} && ./configure && make)

ADD ${ASSETS} /assets/

COPY fetch_and_run.sh /usr/bin/

ENTRYPOINT ["fetch_and_run.sh"]
