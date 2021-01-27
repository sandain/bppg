# To install this Docker image (from folder containing the Dockerfile)
#    docker build -t bppg/funannotate:latest .

# To get a Bash shell:
#    docker run --volume $(pwd):$(pwd) --workdir $(pwd) --entrypoint /bin/bash -it bppg/funannotate:latest

# To run the genome assembly:
#    docker run --rm --user "$(id -u $(logname)):$(id -g $(logname))" --volume $(pwd):$(pwd) --workdir $(pwd) bppg/funannotate:latest funannotate

# NOTE: GeneMark files must be in the current working directory. Download them
#       from http://topaz.gatech.edu/GeneMark/license_download.cgi
#       SignalP 4.1 file must also be in the current working directory.
#       Download it from http://www.cbs.dtu.dk/services/SignalP-4.1/

FROM nextgenusfs/funannotate

# Install prerequisites.
RUN apt-get update && \
    apt-get install -y \
      gcc g++ make binutils wget python3-h5py python-numpy python-qt4 \
      python-lxml python-six libcairo2-dev libpango1.0-dev libidn11 \
      libpangocairo-1.0-0 && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/*

# Install prerequisites for GeneMark.
RUN echo yes | cpan MCE::Mutex && \
    echo yes | cpan Math::Utils

# Install GeneMark.
COPY gmes_linux_64.tar.gz /venv
COPY gm_key_64 /.gm_key
RUN cd /venv && \
    tar -xvzf gmes_linux_64.tar.gz && \
    rm gmes_linux_64.tar.gz && \
    cd /venv/gmes_linux_64 && \
    perl change_path_in_perl_scripts.pl "/usr/bin/env perl"
ENV PATH="/venv/gmes_linux_64/:/$PATH"
ENV GENEMARK_PATH=/venv/gmes_linux_64

# Install SignalP.
COPY signalp-4.1g.Linux.tar.gz /venv
RUN cd /venv && \
    tar -xvzf signalp-4.1g.Linux.tar.gz && \
    rm signalp-4.1g.Linux.tar.gz && \
    cd signalp-4.1 && \
    perl -i -pe "s/\$ENV{SIGNALP} = \'\/usr\/opt\/www\/pub\/CBS\/services\/SignalP-4\.1\/signalp-4\.1\'/\$ENV{SIGNALP} = \'\/venv\/signalp-4\.1\'/" signalp && \
    perl -i -pe 's/my \$outputDir = "\/var\/tmp";/my \$outputDir = "\.";/' signalp
ENV PATH="/venv/signalp-4.1/:$PATH"

# Install Tandem Repeats Finder.
RUN cd /venv/bin && \
    wget http://tandem.bu.edu/cgi-bin/trf/trf.download.pl?fileselect=30 -O trf && \
    chmod +x trf

# Install RepeatMasker.
ENV PYTHONPATH="/usr/lib/python3/dist-packages/:/venv/lib/python3.7/site-packages/"
RUN cd /venv && \
    wget http://www.repeatmasker.org/RepeatMasker/RepeatMasker-4.1.1.tar.gz && \
    tar -xvzf RepeatMasker-4.1.1.tar.gz && \
    rm RepeatMasker-4.1.1.tar.gz && \
    cd RepeatMasker && \
    /usr/bin/env perl configure \
      -trf_prgm=/venv/bin/trf \
      -hmmer_dir=/venv/bin
ENV PATH="/venv/RepeatMasker/:$PATH"

# Install RECON.
RUN cd /venv && \
    wget http://www.repeatmasker.org/RepeatModeler/RECON-1.08.tar.gz && \
    tar -xvzf RECON-1.08.tar.gz && \
    rm RECON-1.08.tar.gz && \
    cd RECON-1.08/src && \
    make && make install

# Install RepeatScout.
RUN cd /venv && \
    wget http://www.repeatmasker.org/RepeatScout-1.0.6.tar.gz && \
    tar -xvzf RepeatScout-1.0.6.tar.gz && \
    rm RepeatScout-1.0.6.tar.gz && \
    cd RepeatScout-1.0.6 && \
    make

# Install RMBlast.
RUN cd /venv && \
    wget http://www.repeatmasker.org/rmblast-2.10.0+-x64-linux.tar.gz && \
    tar -xvzf rmblast-2.10.0+-x64-linux.tar.gz && \
    rm rmblast-2.10.0+-x64-linux.tar.gz

# Install GenomeTools.
RUN cd /venv && \
    wget http://genometools.org/pub/genometools-1.6.1.tar.gz && \
    tar -xvzf genometools-1.6.1.tar.gz && \
    rm genometools-1.6.1.tar.gz && \
    cd genometools-1.6.1 && \
    make threads=yes && make install

# Install CD-Hit.
RUN cd /venv && \
    wget https://github.com/weizhongli/cdhit/archive/V4.8.1.tar.gz && \
    tar -xvzf V4.8.1.tar.gz && \
    rm V4.8.1.tar.gz && \
    cd cdhit-4.8.1 && \
    make

# Install LTR retriever.
RUN cd /venv && \
    wget https://github.com/oushujun/LTR_retriever/archive/v2.6.tar.gz && \
    tar -xvzf v2.6.tar.gz && \
    rm v2.6.tar.gz && \
    cd LTR_retriever-2.6 && \
    printf "BLAST+=\nRepeatMasker=/venv/RepeatMasker\nHMMER=\nCDHIT=/venv/cdhit-4.8.1\nBLAST=\n" > paths

# Install Ninja.
RUN cd /venv && \
    wget https://github.com/TravisWheelerLab/NINJA/archive/0.95-cluster_only.tar.gz && \
    tar -xvzf 0.95-cluster_only.tar.gz && \
    rm 0.95-cluster_only.tar.gz

# Install RepeatModeler.
RUN cd /venv && \
    wget http://www.repeatmasker.org/RepeatModeler/RepeatModeler-2.0.1.tar.gz && \
    tar -xvzf RepeatModeler-2.0.1.tar.gz && \
    rm RepeatModeler-2.0.1.tar.gz && \
    cd RepeatModeler-2.0.1 && \
    printf "\n\n\n\n\n" | /usr/bin/env perl configure \
      -trf_prgm=/venv/bin/trf \
      -repeatmasker_dir=/venv/RepeatMasker \
      -recon_dir=/venv/RECON-1.08/bin \
      -rscout_dir=/venv/RepeatScout-1.0.6 \
      -rmblast_dir=/venv/rmblast-2.10.0/bin \
      -genometools_dir=/venv/genometools-1.6.1 \
      -cdhit_dir=/venv/cdhit-4.8.1 \
      -ltr_retriever_dir=/venv/LTR_retriever-2.6 \
      -ninja_dir=/venv/NINJA-0.95-cluster_only/NINJA
ENV PATH="/venv/RepeatModeler-2.0.1/:$PATH"

# Install Eggnog Mapper.
RUN cd /venv && \
    wget https://github.com/eggnogdb/eggnog-mapper/archive/2.0.4-rf1.tar.gz && \
    tar -xvzf 2.0.4-rf1.tar.gz && \
    rm 2.0.4-rf1.tar.gz && \
    cd eggnog-mapper-2.0.4-rf1 && \
    ./download_eggnog_data.py -y --data_dir /venv/eggnog-mapper-2.0.4-rf1/data/
ENV PATH="/venv/eggnog-mapper-2.0.4-rf1/:$PATH"

# Install a recent copy of NCBI tbl2asn.
RUN cd /venv && \
    wget https://ftp.ncbi.nih.gov/toolbox/ncbi_tools/converters/by_program/tbl2asn/linux64.tbl2asn.gz && \
    gunzip linux64.tbl2asn.gz && \
    chmod +x linux64.tbl2asn && \
    mv linux64.tbl2asn /venv/bin/tbl2asn 

# Install Funannotate databases.
RUN /venv/bin/funannotate setup --install all

# Install the Augustus configuration files.
COPY augustus.3.3.config.tar.gz /venv
RUN cd /venv && \
    tar -xvzf augustus.3.3.config.tar.gz && \
    rm augustus.3.3.config.tar.gz
ENV AUGUSTUS_CONFIG_PATH=/venv/augustus/3.3/config

# Create a run script for funannotate
RUN printf '#!/bin/sh\n' > /venv/bin/funannotate.sh && \
    printf 'parse_args() {\n' >> /venv/bin/funannotate.sh && \
    printf '  first=""\n' >> /venv/bin/funannotate.sh && \
    printf '  for ARG in "$@"; do\n' >> /venv/bin/funannotate.sh && \
    printf '    if [ "$first" = "" ] && [ "$ARG" = "funannotate" ]; then\n' >> /venv/bin/funannotate.sh && \
    printf '      first=$ARG\n' >> /venv/bin/funannotate.sh && \
    printf '      continue\n' >> /venv/bin/funannotate.sh && \
    printf '    fi\n' >> /venv/bin/funannotate.sh && \
    printf '    SPACES=$(echo "$ARG" | egrep "[[:space:]]")\n' >> /venv/bin/funannotate.sh && \
    printf '    [ "$SPACES" ] && [ "$ARGS" ] && ARGS="$ARGS \\"$ARG\\""\n' >> /venv/bin/funannotate.sh && \
    printf '    [ "$SPACES" ] && [ ! "$ARGS" ] && ARGS="\\"$ARG\\""\n' >> /venv/bin/funannotate.sh && \
    printf '    [ ! "$SPACES" ] && [ "$ARGS" ] && ARGS="$ARGS $ARG"\n' >> /venv/bin/funannotate.sh && \
    printf '    [ ! "$SPACES" ] && [ ! "$ARGS" ] && ARGS="$ARG"\n' >> /venv/bin/funannotate.sh && \
    printf '  done\n' >> /venv/bin/funannotate.sh && \
    printf '  echo "$ARGS"\n' >> /venv/bin/funannotate.sh && \
    printf '}\n' >> /venv/bin/funannotate.sh && \
    printf 'parsed=$(parse_args "$@")\n' >> /venv/bin/funannotate.sh && \
    printf 'printf "Running funannotate with arguments: %%s\\n" "$parsed"\n' >> /venv/bin/funannotate.sh && \
    printf '/venv/bin/funannotate $parsed\n' >> /venv/bin/funannotate.sh && \
    chmod 755 /venv/bin/funannotate.sh

# Define the entry to run Funannotate.
ENTRYPOINT ["/venv/bin/funannotate.sh"]
