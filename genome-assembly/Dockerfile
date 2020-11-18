# To install this Docker image (from folder containing the Dockerfile)
#    docker build -t bppg/genome-assembly:latest .

# To get a Bash shell:
#    docker run --entrypoint /bin/bash -v `pwd`:`pwd` -w `pwd` -it bppg/genome-assembly:latest

# To run the app:
#    docker run -v `pwd`:`pwd` -w `pwd` bppg/genome-assembly:latest <NAME> <R1> <R2> <EMAIL>

# This is the base image that we will work with.
FROM ubuntu:20.04

LABEL maintainer="jason.wood@jpl.nasa.gov"
LABEL description="Run a genome assembly pipeline utilizing Trim-Galore, Spades, and Quast"
LABEL version="1.0"

ARG QUAST_VER=5.1.0rc1

# Install prerequisites available from Ubuntu.
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y \
      spades trim-galore zlib1g-dev wget perl python-is-python3 python3 \
      python3-setuptools python3-matplotlib python3-simplejson python3-joblib \
      python3-pip pkg-config libfreetype6-dev libpng-dev g++ make locales \
      sendmail && \
    locale-gen en_US.UTF-8 && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/*

# Install Quast.
RUN wget https://github.com/ablab/quast/releases/download/quast_${QUAST_VER}/quast-${QUAST_VER}.tar.gz && \
    tar -xzf quast-${QUAST_VER}.tar.gz && \
    rm quast-${QUAST_VER}.tar.gz && \
    cd quast-${QUAST_VER} && \
    ./setup.py install

# Create a folder for the script.
WORKDIR /app

# Create the script.
RUN printf '#!/bin/sh\n' > /app/run.sh && \
    printf 'NAME=$1\n' >> /app/run.sh && \
    printf 'R1=$2\n' >> /app/run.sh && \
    printf 'R2=$3\n' >> /app/run.sh && \
    printf 'EMAIL=$4\n' >> /app/run.sh && \
    printf 'if [ -z "$R1" ] || [ ! -s "$R1" ]; then\n' >> /app/run.sh && \
    printf '  echo "Error: R1 file $R1 not found!" >&2\n' >> /app/run.sh && \
    printf '  exit 1\n' >> /app/run.sh && \
    printf 'fi\n' >> /app/run.sh && \
    printf 'if [ -z "$R2" ] || [ ! -s "$R2" ]; then\n' >> /app/run.sh && \
    printf '  echo "Error: R2 file $R2 not found!" >&2\n' >> /app/run.sh && \
    printf '  exit 1\n' >> /app/run.sh && \
    printf 'fi\n' >> /app/run.sh && \
    printf 'mkdir -p output\n' >> /app/run.sh && \
    printf 'trim_galore -o output --paired $R1 $R2\n' >> /app/run.sh && \
    printf 'R1_TRIMMED=output/$(basename $R1 .fastq.gz)_val_1.fq.gz\n' >> /app/run.sh && \
    printf 'R2_TRIMMED=output/$(basename $R2 .fastq.gz)_val_2.fq.gz\n' >> /app/run.sh && \
    printf 'if [ -z "$R1_TRIMMED" ] || [ -z "$R2_TRIMMED" ] || [ ! -s $R1_TRIMMED ] || [ ! -s $R2_TRIMMED ]; then\n' >> /app/run.sh && \
    printf '  echo "Error: Trimmed R1 or R2 file not found!" >&2\n' >> /app/run.sh && \
    printf '  exit 1\n' >> /app/run.sh && \
    printf 'fi\n' >> /app/run.sh && \
    printf 'spades.py -1 $R1_TRIMMED -2 $R2_TRIMMED -o output\n' >> /app/run.sh && \
    printf 'if [ -z output/scaffolds.fasta ] || [ ! -s output/scaffolds.fasta ]; then\n' >> /app/run.sh && \
    printf '  echo "Error: Scaffolds not found!" >&2\n' >> /app/run.sh && \
    printf '  exit 1\n' >> /app/run.sh && \
    printf 'fi\n' >> /app/run.sh && \
    printf 'quast.py --glimmer -o output output/scaffolds.fasta\n' >> /app/run.sh && \
    printf 'tar -zcvf $NAME.tar.gz -C output .\n' >> /app/run.sh && \
    printf 'printf "To: $EMAIL\\nSubject: JPL AWS Job complete\\n\\n%s\\n" $NAME | sendmail -t $EMAIL\n' >> /app/run.sh && \
    chmod 755 /app/run.sh

# Run the script on entry.
ENTRYPOINT ["/app/run.sh"]
