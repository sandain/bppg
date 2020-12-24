# To install this Docker image (from folder containing the Dockerfile)
#    docker build -t bppg/genome-assembly:latest .

# To get a Bash shell:
#    docker run --entrypoint /bin/bash -v `pwd`:`pwd` -w `pwd` -it bppg/genome-assembly:latest

# To run the genome assembly:
#    docker run -v `pwd`:`pwd` -w `pwd` bppg/genome-assembly:latest <NAME> <R1> <R2>
#
#    <NAME> The name of the genome
#    <R1>, <R2> File names containing the short sequences to assemble.
#
#    R1 and R2 files must exist in the current working directory.
#    A valid rclone.conf file must also exist in the current working directory.

# This is the base image that we will work with.
FROM ubuntu:20.04

LABEL maintainer="jason.wood@jpl.nasa.gov"
LABEL description="Run a genome assembly pipeline utilizing Trim-Galore, SPAdes, and Quast"
LABEL version="1.0"

ARG QUAST_VER=5.1.0rc1
ARG RCLONE_CONF=rclone.conf

# Install prerequisites available from Ubuntu.
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y \
      spades trim-galore zlib1g-dev wget perl bioperl python-is-python3 python3 \
      python3-setuptools python3-matplotlib python3-simplejson python3-joblib \
      python3-pip pkg-config libfreetype6-dev libpng-dev g++ make locales && \
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

# Install rclone.
RUN wget https://downloads.rclone.org/rclone-current-linux-amd64.deb && \
    dpkg -i rclone-current-linux-amd64.deb && \
    rm rclone-current-linux-amd64.deb

# Create a folder for the script.
WORKDIR /app

# Create the script.
RUN printf '#!/bin/sh\n' > /app/run.sh && \
    printf 'NAME=$1\n' >> /app/run.sh && \
    printf 'R1=$2\n' >> /app/run.sh && \
    printf 'R2=$3\n' >> /app/run.sh && \
    printf 'TEST_RCLONE=$(rclone --config=%s config show genome-assembly 2>/dev/null | grep "type = drive")\n' ${RCLONE_CONF} >> /app/run.sh && \
    printf 'if [ -z "$TEST_RCLONE" ]; then\n' >> /app/run.sh && \
    printf '  echo "Error: rclone config for genome-assembly not found!" >&2\n' >> /app/run.sh && \
    printf '  rm -Rf output $NAME.tar.gz $R1 $R2 rclone.conf\n' >> /app/run.sh && \
    printf '  exit 1\n' >> /app/run.sh && \
    printf 'fi\n' >> /app/run.sh && \
    printf 'if [ -z "$NAME" ]; then\n' >> /app/run.sh && \
    printf '  echo "Error: name not provided!" >&2\n' >> /app/run.sh && \
    printf '  echo "Done" | rclone --config=%s rcat genome-assembly:$NAME.status\n' ${RCLONE_CONF} >> /app/run.sh && \
    printf '  rm -Rf output $NAME.tar.gz $R1 $R2 rclone.conf\n' >> /app/run.sh && \
    printf '  exit 1\n' >> /app/run.sh && \
    printf 'fi\n' >> /app/run.sh && \
    printf 'if [ -z "$R1" ] || [ ! -s "$R1" ]; then\n' >> /app/run.sh && \
    printf '  echo "Error: R1 file $R1 not found!" >&2\n' >> /app/run.sh && \
    printf '  echo "Done" | rclone --config=%s rcat genome-assembly:$NAME.status\n' ${RCLONE_CONF} >> /app/run.sh && \
    printf '  rm -Rf output $NAME.tar.gz $R1 $R2 rclone.conf\n' >> /app/run.sh && \
    printf '  exit 1\n' >> /app/run.sh && \
    printf 'fi\n' >> /app/run.sh && \
    printf 'if [ -z "$R2" ] || [ ! -s "$R2" ]; then\n' >> /app/run.sh && \
    printf '  echo "Error: R2 file $R2 not found!" >&2\n' >> /app/run.sh && \
    printf '  echo "Done" | rclone --config=%s rcat genome-assembly:$NAME.status\n' ${RCLONE_CONF} >> /app/run.sh && \
    printf '  rm -Rf output $NAME.tar.gz $R1 $R2 rclone.conf\n' >> /app/run.sh && \
    printf '  exit 1\n' >> /app/run.sh && \
    printf 'fi\n' >> /app/run.sh && \
    printf 'mkdir -p output\n' >> /app/run.sh && \
    printf 'echo "Running Trim-Galore" | rclone --config=%s rcat genome-assembly:$NAME.status\n' ${RCLONE_CONF} >> /app/run.sh && \
    printf 'trim_galore -o output --paired $R1 $R2\n' >> /app/run.sh && \
    printf 'R1_TRIMMED=output/$(basename $R1 .fastq.gz)_val_1.fq.gz\n' >> /app/run.sh && \
    printf 'R2_TRIMMED=output/$(basename $R2 .fastq.gz)_val_2.fq.gz\n' >> /app/run.sh && \
    printf 'if [ -z "$R1_TRIMMED" ] || [ -z "$R2_TRIMMED" ] || [ ! -s $R1_TRIMMED ] || [ ! -s $R2_TRIMMED ]; then\n' >> /app/run.sh && \
    printf '  echo "Error: Trimmed R1 or R2 file not found!" >&2\n' >> /app/run.sh && \
    printf '  echo "Done" | rclone --config=%s rcat genome-assembly:$NAME.status\n' ${RCLONE_CONF} >> /app/run.sh && \
    printf '  rm -Rf output $NAME.tar.gz $R1 $R2 rclone.conf\n' >> /app/run.sh && \
    printf '  exit 1\n' >> /app/run.sh && \
    printf 'fi\n' >> /app/run.sh && \
    printf 'echo "Running SPAdes" | rclone --config=%s rcat genome-assembly:$NAME.status\n' ${RCLONE_CONF} >> /app/run.sh && \
    printf 'spades.py -1 $R1_TRIMMED -2 $R2_TRIMMED -o output\n' >> /app/run.sh && \
    printf 'if [ -z output/scaffolds.fasta ] || [ ! -s output/scaffolds.fasta ]; then\n' >> /app/run.sh && \
    printf '  echo "Error: Scaffolds not found!" >&2\n' >> /app/run.sh && \
    printf '  echo "Done" | rclone --config=%s rcat genome-assembly:$NAME.status\n' ${RCLONE_CONF} >> /app/run.sh && \
    printf '  rm -Rf output $NAME.tar.gz $R1 $R2 rclone.conf\n' >> /app/run.sh && \
    printf '  exit 1\n' >> /app/run.sh && \
    printf 'fi\n' >> /app/run.sh && \
    printf 'echo "Running Quast" | rclone --config=%s rcat genome-assembly:$NAME.status\n' ${RCLONE_CONF} >> /app/run.sh && \
    printf 'quast.py --glimmer -o output output/scaffolds.fasta\n' >> /app/run.sh && \
    printf 'echo "Creating archive" | rclone --config=%s rcat genome-assembly:$NAME.status\n' ${RCLONE_CONF} >> /app/run.sh && \
    printf 'tar -zcvf $NAME.tar.gz -C output .\n' >> /app/run.sh && \
    printf 'echo "Transfering results to GDrive" | rclone --config=%s rcat genome-assembly:$NAME.status\n' ${RCLONE_CONF} >> /app/run.sh && \
    printf 'rclone --config=%s copy $NAME.tar.gz genome-assembly:\n' ${RCLONE_CONF} >> /app/run.sh && \
    printf 'perl -MBio::SeqIO -e '"'"'$in=Bio::SeqIO->new(-file=>"<output/scaffolds.fasta",-format=>"fasta");$out=Bio::SeqIO->new(-file=>">$NAME.filtered.fasta",-format=>"fasta");while($seq=$in->next_seq){$out->write_seq($seq)if(length $seq->seq>=500);}$in->close;$out->close;'"'"'\n' >> /app/run.sh && \
    printf 'rclone --config=%s copy $NAME.filtered.fasta genome-assembly:\n' >> /app/run.sh && \
    printf 'echo "Done" | rclone --config=%s rcat genome-assembly:$NAME.status\n' ${RCLONE_CONF} >> /app/run.sh && \
    printf 'rm -Rf output $NAME.tar.gz $R1 $R2 rclone.conf\n' >> /app/run.sh && \
    chmod 755 /app/run.sh

# Run the script on entry.
ENTRYPOINT ["/app/run.sh"]
