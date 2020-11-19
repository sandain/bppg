# To install this Docker image (from folder containing the Dockerfile)
#    docker build -t bppg/hello-world:latest .

# To get a Bash shell:
#    docker run --entrypoint /bin/bash -it bppg/hello-world:latest

# To run the app:
#    docker run bppg/hello-world:latest

# To run the app with a command line argument:
#    docker run bppg/hello-world:latest Jason

# This is the base image that we will work with.
FROM ubuntu:20.04

LABEL maintainer="jason.wood@jpl.nasa.gov"
LABEL description="This is a simple example Dockerfile"
LABEL version="1.0"

# Install prerequisites.
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y perl && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/*

# Create a folder for the script.
WORKDIR /app

# Create the script.
RUN printf '#!/usr/bin/env perl\n' > /app/hello-world && \
    printf 'printf "Hello %%s!\\n", $ARGV[0] if (@ARGV > 0);\n' >> /app/hello-world && \
    printf 'printf "Hello World!\\n" if (@ARGV == 0);\n' >> /app/hello-world && \
    chmod 755 /app/hello-world
    
# Run the script on entry.
ENTRYPOINT ["/app/hello-world"]
