#!/usr/bin/env python
#
# rsync-only - A wrapper around rsync for use with the SSH "command" restriction
#
# It's to be used with the SSH authorized_keys(8) "command" restriction. It
# allows you to restrict given user commands to rsync and its (configurable)
# safe options only.
#
# @TODO: Add support for allowing certain subset of rsync options only, most
#        notably: --delete and --server. A generic configurable solution would
#        be even nicer.
#

import os
import sys
import subprocess
from optparse import OptionParser

class RsyncWrapper:
    # Original rsync command given
    command = None

    # Location of the rsync binary
    rsync_bin = None

    def __init__(self, command, rsync_bin=["rsync", "/usr/bin/rsync"]):
        self.rsync_bin = rsync_bin

        if not self.is_rsync(command):
            raise StandardError("Invalid rsync command given: %s" % command)
        else:
            self.command = command

    def is_rsync(self, command):
        """Checks whether given command is indeed rsync"""
        for bin in self.rsync_bin:
            if command.startswith(bin):
                return True
        return False

    def execute(self):
        """Executes the rsync command and returns its return value"""
        return subprocess.call(self.command.split(' '))


def main():
    cli = OptionParser(usage='%prog [options]',
                       description='Limits execution of SSH commands to rsync only')
    cli.add_option('-g', '--debug', dest='debug', action='store_true',
                   help='Turn on debugging mode')

    (options, args) = cli.parse_args()

    try:
        # Require Python >= 2.4
        if sys.version_info[0] < 2 or sys.version_info[1] < 4:
            raise StandardError("Python 2.4.0 or higher is required")

        # If SSH_ORIGINAL_COMMAND is not specified, then the user is assuming
        # this is a normal login shell.
        if not os.environ.has_key('SSH_ORIGINAL_COMMAND'):
            raise StandardError("This is not a login shell. You can only use rsync.")

        rsync = RsyncWrapper(os.environ['SSH_ORIGINAL_COMMAND'])
        retval = rsync.execute()
        cli.exit(retval)

    except StandardError, e:
        if options.debug:
            raise
        else:
            cli.exit(1, "%s\n" % e)

if __name__ == "__main__":
    main()

