#!/bin/sh

PROG=$0

INSTANCES_CONF=instances.conf
JOBS_CONF=jobs.conf

JPL_PEM=~/.ssh/jpl.pem
RCLONE_CONF=~/.config/rclone/rclone.conf

# ---------------------------------------------------------------------------
# Script Usage
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF

Usage: $PROG <command> <command options>

Commands:

  enqueue <Type> <Name> <Files>   Add a job to the queue.
  instance <IP Address/Domain>    Add an AWS instance to run jobs.
  start                           Start the job queue.
  status                          Print current status of jobs and queues.
  
Requirements:
  ~/.ssh/jpl.pem                  RSA private key used to connect to AWS.
  ~/.config/rclone/rclone.conf    Rclone configuration for the job.

EOF
}

# ---------------------------------------------------------------------------
# Run the bppg/genome-assembly pipeline.
#
# @param 1 The AWS instance.
# @param 2 The name of the genome assembly job.
# @param 3 The R1 file.
# @param 4 The R2 file. 
# ---------------------------------------------------------------------------
genome_assembly() {
  local INSTANCE NAME R1 R2 R1_BASENAME R2_BASENAME
  INSTANCE=$1
  NAME=$2
  R1=$3
  R2=$4
  R1_BASENAME=$(basename $R1)
  R2_BASENAME=$(basename $R2)
  # Upload the files to the instance.
  upload_files $INSTANCE $R1 $R2 $RCLONE_CONF
  # Run the bppg/genome-assembly pipeline.
  ssh -T -i $JPL_PEM ubuntu@$INSTANCE "cd /data && docker run -d -v \`pwd\`:\`pwd\` -w \`pwd\` bppg/genome-assembly:latest $NAME $R1_BASENAME $R2_BASENAME"
}

# ---------------------------------------------------------------------------
# Report the status of a job.
#
# @param 1 The job to query.
# ---------------------------------------------------------------------------
job_status() {
  local JOB TYPE STATUS
  JOB=$1
  TYPE=$(grep $JOB $JOBS_CONF | cut -f1)
  # Get the status of the job.
  STATUS=$(rclone --config=$RCLONE_CONF cat $TYPE:$JOB.status 2>/dev/null)
  echo $STATUS
}

# ---------------------------------------------------------------------------
# Upload files to an AWS instance.
#
# @param 1 The AWS instance.
# @param 2..N The list of files being uploaded.
# ---------------------------------------------------------------------------
upload_files() {
  local INSTANCE  FTP_SCRIPT
  INSTANCE=$1
  shift
  FILES="$@"
  # Create an FTP script containing the sequence of commands to submit.
  FTP_SCRIPT="cd /data"
  # Next, upload each file to the instance.
  for FILE in $FILES; do
    FTP_SCRIPT=$(printf "$FTP_SCRIPT\nput $FILE")
  done
  # End the FTP session.
  FTP_SCRIPT=$(printf "$FTP_SCRIPT\nexit\n")
  # Run the FTP script.
  printf "$FTP_SCRIPT" | sftp -i $JPL_PEM ubuntu@$INSTANCE
}

# ---------------------------------------------------------------------------
# Watch for finished jobs.
# ---------------------------------------------------------------------------
watch_jobs() {
  local RUNNING INSTANCE JOB TYPE STATUS
  RUNNING="true"
  while [ "$RUNNING" = "true" ]; do
    grep -v "^\s*#" $INSTANCES_CONF | grep -v -e "^$" | grep -v available | while read -r INSTANCE; do
      JOB=$(printf "$INSTANCE" | cut -f2 | cut -d: -f2)
      TYPE=$(grep $JOB $JOBS_CONF | cut -f1)
      # Get the status of the job.
      STATUS=$(job_status $JOB)
      if [ "$STATUS" = "Done" ]; then
        # Remove the job from the queue.
        perl -i -ne "print unless (/$JOB/);" $JOBS_CONF
        # Mark the instance as available.
        perl -i -pe "s/job:$JOB/available/" $INSTANCES_CONF
        # Remove the job status from Google Drive.
        rclone --config=$RCLONE_CONF delete $TYPE:$JOB.status
      fi
    done
    sleep 30
    # Shutdown instances and end the watch_jobs process if there are no more jobs.
    if [ $(grep -v "^\s*#" $JOBS_CONF | grep -v -e "^$" | wc -l) -eq 0 ]; then
      for INSTANCE in $(grep -v "^\s*#" $INSTANCES_CONF | cut -f1); do
        ssh -T -i $JPL_PEM ubuntu@$INSTANCE "sudo shutdown now"
        perl -i -ne "print unless (/$INSTANCE/);" $INSTANCES_CONF
      done
      RUNNING="false"
    fi
  done
}

# Respond to the command line arguments.
# ---------------------------------------------------------------------------
COMMAND=$1

case "$COMMAND" in
  enqueue)
    # Verify command line arguments.

  ;;
  instance)
    # Verify command line arguments.
    if [ "$2" = "" ]; then
      printf "Error: IP address of instance not provided.\n"
      usage
      exit 1
    fi
    # Mark the instance as available.
    printf "%s\tavailable\n" $2 >> $INSTANCES_CONF
  ;;
  start)
    # Insure required configuration files exist.
    if [ ! -s $JPL_PEM ] || [ ! -r $JPL_PEM ]; then
      printf "Error: Unable to find a valid RSA private key to connect to AWS.\n"
      printf "This file should be saved to $JPL_PEM, see the README.md for more information\n"
      usage
      exit 1
    fi
    if [ ! -s $RCLONE_CONF ] || [ ! -r $RCLONE_CONF ]; then
      printf "Error: Unable to find a valid Rclone configuration to connect to Google Drive.\n"
      printf "This file should be saved to $RCLONE_CONF, see the README.md for more information\n"
      usage
      exit 1
    fi
    # Start a process to watch for finished jobs.
    watch_jobs &
    # Read in the jobs.conf file, ignoring comments.
    JOBS=$(grep -v "^\s*#" $JOBS_CONF | grep -v -e "^$" | cut -f2)
    for JOB in $JOBS; do
      # Look for the type of job and the arguments for that job.
      TYPE=$(grep "$JOB" $JOBS_CONF | cut -f1)
      ARGS=$(grep "$JOB" $JOBS_CONF | cut -f1 --complement)
      # Make sure this job is not already running.
      JOB_RUNNING=$(grep $JOB $INSTANCES_CONF)
      if [ -n "$JOB_RUNNING" ]; then
        continue
      fi
      # Find an instance accepting jobs, or wait for one to become available.
      INSTANCE=""
      while [ "$INSTANCE" = "" ]; do
        INSTANCE=$(grep -v "^\s*#" $INSTANCES_CONF | grep -m1 available | cut -f1)
        if [ "$INSTANCE" = "" ]; then
          sleep 10
        fi
      done
      # Start the job.
      if [ "$TYPE" = "genome-assembly" ]; then
        printf "Starting genome assembly $JOB on instance $INSTANCE.\n"
        genome_assembly $INSTANCE $ARGS
      fi
      # Mark the instance as busy with a job.
      perl -i -pe "s/$INSTANCE\tavailable/$INSTANCE\tjob:$JOB/" $INSTANCES_CONF
    done
  ;;
  status)
    INSTANCES=$(grep -v "^\s*#" $INSTANCES_CONF | grep -v -e "^$" | cut -f1)
    JOBS=$(grep -v "^\s*#" $JOBS_CONF | grep -v -e "^$" | cut -f2)
    printf "Instance Status:\n"
    for INSTANCE in $INSTANCES; do
      STATUS=$(grep $INSTANCE $INSTANCES_CONF | cut -f2)
      printf "  $INSTANCE\t$STATUS\n"
    done
    printf "\nJob Status:\n"
    for JOB in $JOBS; do
      TYPE=$(grep $JOB $JOBS_CONF | cut -f1)
      # Get the status of the job.
      STATUS=$(job_status $JOB)
      if [ "$STATUS" = "" ]; then
        STATUS="Not Started"
      fi
      printf "  $JOB\t$STATUS\n"
    done
  ;;
  *)
    printf "Error in command line usage.\n"
    usage
    exit 1
  ;;
esac
exit 0
