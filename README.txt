1. INTRODUCTION
===============

  backup-tools is an organized set of tools developed here in EDC for being used
  by projects for backing up their data to a remote server.


2. A WORD ON THE FEATURE-SET
============================

  backup-tools is not intended to be a one-size-fits-all solution, but rather,
  implements the common needs of projects. Should a project need more features
  or customization, they should create their own branch of backup-tools and add
  any extra functionality they require. Ideally, all branches should later be
  merged to the base backup-tools.


3. THEORY OF OPERATION
======================

  Backup-tools will be installed on the real live production servers. A config
  file will be created for each project, telling backup-tools about the project
  directories and databases that will need to be backed up. When the appropriate
  backup-tools script (called run-all.sh) is invoked, it will create a backup
  for each of the configured projects and then send this backup to a remote
  server where the backups will be archived and rotated. An e-mail is sent to
  project owners informing them of the success or failure of the backup process.


4. INSTALLATION
===============

  Installation should be performed by, or coordinateed with, the administrator
  of the remote backup server.

  1. Copy the backup-tools package somewhere in the system. e.g. To get it
     directly from git into /usr/local/backup-tools:

       $: git clone gitosis@git.edc:backup-tools.git /usr/local/backup-tools

  2. Make sure the following files under backup-tools are executable:

     run-all.sh
     make-project-backup.sh
     toolbox/*.sh

  3. Open backup-tools/projects-conf/default and provide ALL parameters. They
     are all documented inline.

  4. Configure a passwordless SSH key for the user which backup-tools cron job
     will run under. This key must be authorized on the remote backup server.

     You must also approve the remote backup server SSH Fingerprint. You can do
     this by manually SSH-ing to the remote server at least once from the user
     account under which backup-tools will run in future. If that account is
     root, then as root, you will need to SSH like this:

       $: ssh <remote-backup-user>@<remote-backup-host>

     SSH will prompt your to verify and accept the fingerprint. Answer Yes.

  5. Setup rotation of local backup entries. There will be local backup entries
     of your project(s), you can safely remove them as they have been synced to
     the remote backup server or you may wish to keep them for added safety.

     For this step, you just need to take a decision. The next step will address
     how to accomplish the rotation or automatic cleanup of synchronized backup
     entries.

  6. Add a cronjob to run backup-tools/run-all.sh as frequent as you require and
     perform cleanup or rotation after it has synchronized the newly created
     backups.

     (a) If you decided to cleanup all backups (i.e. not keep any backups
         locally), then your cron command should look like:

           backup-tools/run-all.sh && rm -rf /path/to/backup/*

     (b) If you decided to keep and rotate all backups, then your cron command
         should look like:

           backup-tools/run-all.sh && backup-tools/utilities/rotate.sh <local-backup-dir> <days-to-keep>

         Consult appendix 1 below for how to use rotate.sh utility which comes
         with backup-tools.

     By default, run-all.sh will execute projects sequentially. If you wish to
     pause for a given number of seconds between each project, you can do that
     by passing the number of seconds to run-all.sh. In the following example,
     backup-tools will sleep for 15 minutes between each project:

       $: backup-tools/run-all.sh 900

  7. Optional: For added security, you should secure the projects-conf/defaults
     file by making it readable by the owner only:

       $: chmod 600 backup-tools/projects-conf/defaults

  Now backup-tools has been installed and is ready to be used. The section "ADD
  A PROJECT" below describes how to configure it to backup a given project.


5. ADD A PROJECT
================

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


6. CONFIGURING THE REMOTE BACKUP SERVER
=======================================

  backup-tools contains a utility for rotating backups, which can be used on the
  local and/or remote backup server.

  The following are instructions for using it:

  1. Open utilities/rotate.sh and configure the KEEP parameter to the number
     of days you wish to keep.

  2. Add a cron job to run `utilities/rotate.sh <backup-dir>` every day.

  You are done!

  3. Optional: For better security, you may add the following restrictions to
     the authorized SSH keys in authorized_keys(8) file:

       command="backup-tools/utilities/rsync-only.py",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty

     Then make sure that `backup-tools/utilities/rsync-only.py` is executable:

       $: chmod +x backup-tools/utilities/rsync-only.py

     This will restrict the commands this key can use to rsync only. For more
     information, check authorized_keys(8) manpage.


APPENDIX 1: ROTATING FILES USING ROTATE.SH
==========================================

  backup-tools/utilities/rotate.sh is a utility for rotating backup files. It
  assumes a certain directory schema which is the same that backup-tools
  generates so they are both compatible.

  rotate.sh expects 2 parameters:

    1. Path to the backup directory: The same as LOCAL_BACKUP_DIRECTORY in your
       backup-tools/projects-conf/defaults file

    2. Number of days to keep: The number of days to keep backups for. Note that
       if there are multiple backups per day they will be all treated as one day

  To use it, you simply need to add a cron job to run every day:

    $: backup-tools/utilities/rotate.sh <local-backup-dir> <days-to-keep>

  On the project server, you just need to execute the above after the backup
  have been sent to the remote server. Check section 4.6.b for more details.

  On the remote server, you should execute it daily using a separate cron job.


Enjoy!
