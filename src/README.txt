INTRODUCTION
============

  backup-tools is an organized set of tools developed here in EDC for being used
  by projects for backing up their data to a remote server.


A WORD ON THE FEATURE-SET
=========================

  backup-tools is not intended to be a one-size-fits-all solution, but rather,
  implements the common needs of projects. Should a project need more features
  or customization, they should create their own branch of backup-tools and add
  any extra functionality they require. Ideally, all branches should later be
  merged to the base backup-tools.


INSTALLATION
============

  1. Copy the backup-tools package somewhere in the system.

  2. Open backup-tools/projects-conf/default and provide ALL parameters. They
     are all documented inline.

  3. Configure a passwordless SSH key for the user which backup-tools cron job
     will run under. This key must be authorized on the remote backup server.

  4. Add a cronjob to run backup-tools/run-all.sh as frequent as you require.

  Now backup-tools has been installed and is ready to be used. The section "ADD
  A PROJECT" below describes how to add configure it to backup a given project.


ADD A PROJECT
=============

  1. Create a configuration file under backup-tools/projects-conf. You should
     do so by copying the existing project_template file. Example:

     $: cp projects-conf/project_template projects-conf/<your-project-name>

  2. Open the file and adjust ALL parameters.

  3. Make the file executable. Example:

     $: chmod +x projects-conf/<your-project-name>

  4. Verify that it works as intended by executing:

     $: ./make-project-backup.sh projects-conf/<your-project-name>

  You are done!


CONFIGURING THE REMOTE BACKUP SERVER
====================================

  backup-tools contains a utility for rotating backups, which can be used on the
  local and/or remote backup server.

  The following are instructions for using it:

  1. Open remote-utils/rotate.sh and configure the KEEP parameter to the number
     of days you wish to keep.

  2. Add a cron job to run remote-utils/rotate.sh every day.

  You are done!


Enjoy!
