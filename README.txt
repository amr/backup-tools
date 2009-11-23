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


THEORY OF OPERATION
===================

  Backup-tools will be installed on the real live production servers. A config
  file will be created for each project, telling backup-tools about the project
  directories and databases that will need to be backed up. When the appropriate
  backup-tools script (called run-all.sh) is invoked, it will create a backup
  for each of the configured projects and then send this backup to a remote
  server where the backups will be archived and rotated. An e-mail is sent to
  project owners informing them of the success or failure of the backup process.


INSTALLATION
============

  Installation should be performed by, or coordinateed with, the administrator
  of the remote backup server.

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

  Any project owner can add a project under backup-tools to be backed up on the
  remote server. No action from the remote backup administrator is required.

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
