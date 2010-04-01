#!/usr/bin/env python
# Part of backup-tools
#
# Generates a report of the disk space usage on the root backups directory
#
# Sample output:
# ============
#
# Summary
#   * Projects: 7
#   * Disk space: 503 GB
#   * Free on the same partition: 30 GB
#   * Last day backup: 25 GB
#
# Per project
#   * hwforum
#     - Backups: 28
#     - Average: 12 GB
#     - Minimum: 11 GB
#     - Maximum: 13 GB
#     - Total: 300 GB
#
# Usage: ./diskspace-report.py /path/to/backup/root
#

import os, optparse, subprocess, re, time
from optparse import OptionParser
from string import Template

# See: http://wiki.python.org/moin/PythonDecoratorLibrary#Memoize
class memoized(object):
    """Decorator that caches a function's return value each time it is called.
    If called later with the same arguments, the cached value is returned, and
    not re-evaluated.
    """
    def __init__(self, func):
        self.func = func
        self.cache = {}
    def __call__(self, *args):
       try:
           return self.cache.setdefault(args,self.func(*args))
       except TypeError:
           # uncachable -- for instance, passing a list as an argument.
           # Better to not cache than to blow up entirely.
           return self.func(*args)
    def __repr__(self):
        """Return the function's docstring."""
        return self.func.__doc__

# See: http://docs.djangoproject.com/en/dev/ref/templates/builtins/#filesizeformat
def filesizeformat(bytes):
    """
    Formats the value like a 'human-readable' file size (i.e. 13 KB, 4.1 MB,
    102 bytes, etc).
    """
    try:
        bytes = float(bytes)
    except TypeError:
        return u"0 bytes"

    if bytes < 1024:
        return "%(size)d bytes" % {'size': bytes}
    if bytes < 1024 * 1024:
        return "%.1f KB" % (bytes / 1024)
    if bytes < 1024 * 1024 * 1024:
        return "%.1f MB" % (bytes / (1024 * 1024))
    return "%.1f GB" % (bytes / (1024 * 1024 * 1024))

# Helpers for sorting snapshots
def snapshot_size(snapshot):
    return snapshot.size
def snapshot_timestamp(snapshot):
    return snapshot.timestamp

class Snapshot(object):
    ID_REGEX = r"^(?P<project>\w+).(?P<year>\d{4})-(?P<month>\d{1,2})-(?P<day>\d{1,2}).(?P<timestamp>\d+)$"

    def __init__(self, path):
        self.path = path
        self.id = os.path.basename(path)

        m = re.compile(self.ID_REGEX).match(self.id)
        if m:
            # For the time being, we don't need anything except the timestamp
            self.timestamp = int(m.group('timestamp'))
        else:
            raise ValueError("Invalid snapshot ID (%s) for snapshot (%s)" % (self.id, self.path))

    @memoized
    def size(self):
        output = subprocess.Popen(['du', '-bs', self.path], stdout=subprocess.PIPE).communicate()[0]
        return int(re.findall(r'\w+', output)[0])
    size = property(size)


class Project(object):
    def __init__(self, path, name):
        self.path = path
        self.name = name

    @memoized
    def size(self):
        total = 0
        for snapshot in self.snapshots:
            total += snapshot.size
        return total
    size = property(size)

    @memoized
    def snapshots(self):
        snapshots = []
        for entry in os.listdir(self.path):
            entry_path = os.path.join(self.path, entry)

            # Skip files and hidden directories (like .ssh, etc)
            if not os.path.isdir(entry_path) or entry.startswith('.'):
                continue

            snapshots.append(Snapshot(entry_path))
        snapshots.sort(key=snapshot_timestamp)
        return snapshots
    snapshots = property(snapshots)

    @memoized
    def minimum(self):
        snapshots = self.snapshots
        snapshots.sort(key=snapshot_size)
        return snapshots[0]
    minimum = property(minimum)

    @memoized
    def maximum(self):
        snapshots = self.snapshots
        snapshots.sort(key=snapshot_size)
        return snapshots[-1]
    maximum = property(maximum)

    def average(self):
        return self.size / len(self.snapshots)
    average = property(average)

    def last(self):
        return self.snapshots[-1]
    last = property(last)


class DiskSpaceReport(object):
    templates = {
        # Overall report template
        'report': """*Report generated at:* $time

Summary
=======
$summary

Per project
===========
$projects
""",

        # Summary template
        'summary': """
  * Projects: $count
  * Uses: $size
  * Free on the same partition: $free
  * Last day only: $last_day_size""",

        # Single project's template
        'project': """
  * ${name} ($percentage)
    - Backups: $count
    - Uses: $size
    - Average: $average
    - Minimum: $minimum ($minimum_date)
    - Maximum: $maximum ($maximum_date)
    - Last: $last ($last_date)"""
    }

    def __init__(self, path):
        self.path = path
        self._data = None

    def as_text(self):
        if not self.generated:
            self.generate()

        summary = Template(self.templates['summary']).substitute(**self._data['summary'])

        projects = ""
        for project in self._data['projects']:
            projects += Template(self.templates['project']).substitute(**project)

        return Template(self.templates['report']).substitute(summary=summary, projects=projects, time=self._data['time'])

    def as_html(self):
        # For the time being, we generate HTML from the text version which is
        # Markdown-compatible.
        # We fail gracefully if Markdown library isn't installed
        try:
            import markdown
        except ImportError:
            raise NotImplementedError("The HTML version of the report currently relies on Markdown library. You will need to install it first.")

        return """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <title>Disk space usage - %s</title>
  </head>
  <style type="text/css" media="screen">
    ul {
      margin: 5px;
    }
  </style>
<body>
%s
</body>
</html>
""" % (time.strftime('%Y-%m-%d'), markdown.markdown(self.as_text()))

    def generate(self):
        total_size = 0
        last_day_size = 0
        for p in self.projects:
            total_size += p.size
            last_day_size += p.snapshots[-1].size

        projects = []
        for p in self.projects:
            projects.append({
                'name': p.name,
                'count': len(p.snapshots),
            	'size': filesizeformat(p.size),
                'percentage': "%.1f%%" % ((1.0 * p.size / total_size) * 100),
            	'average': filesizeformat(p.average),
            	'minimum': filesizeformat(p.minimum.size),
                'minimum_date': time.strftime("%Y-%m-%d %H:%M", time.localtime(p.minimum.timestamp)),
            	'maximum': filesizeformat(p.maximum.size),
                'maximum_date': time.strftime("%Y-%m-%d %H:%M", time.localtime(p.maximum.timestamp)),
                'last': filesizeformat(p.last.size),
                'last_date': time.strftime("%Y-%m-%d %H:%M", time.localtime(p.last.timestamp))
            })

        partition_info = os.statvfs(self.path)
        free = filesizeformat(partition_info.f_bsize * partition_info.f_bavail)

        self._data = {
            'projects': projects,
            'summary': {
                'count': len(self.projects),
                'size': filesizeformat(total_size),
                'last_day_size': filesizeformat(last_day_size),
                'free': free
            },
            'time': time.strftime("%Y-%m-%d %H:%M:%S %Z"),
        }

    def generated(self):
        return self._data is not None
    generated = property(generated)

    @memoized
    def projects(self):
        projects = []
        for entry in os.listdir(self.path):
            entry_path = os.path.join(self.path, entry)

            # Skip files and hidden directories (like .ssh, etc)
            if not os.path.isdir(entry_path) or entry.startswith('.'):
                continue

            projects.append(Project(entry_path, entry))
        return projects
    projects = property(projects)


if __name__ == "__main__":
    cli = OptionParser(usage="%prog [options] <path-to-backup-root>",
                       description="Generates a report of the disk space usage on the root backups directory")
    cli.add_option('-f', '--format', dest='format', default='text',
                   help="Report format: html or text [default: %default]")
    cli.add_option('-a', '--archive', dest='archive', default=None, metavar="DIR",
                   help="Path to the directory where to store backups. If specified, the report will not be printed to STDOUT but will be stored in the directory under a well-organized structure")
    cli.add_option("-d", "--debug", dest="debug", action="store_true",
                   help="do not catch python exceptions, useful for debugging")

    (options, args) = cli.parse_args()

    if not len(args):
        cli.error("You must provide the path to the backups directory")

    try:
        # Require Python >= 2.4
        import sys
        if sys.version_info[0] < 2 or sys.version_info[1] < 4:
            cli.error("Python 2.4.0 or higher is required")

        report = DiskSpaceReport(args[0])
        if options.format not in ['text', 'html']:
            cli.error("Invalid format specified (%s)" % options.format)

        func = getattr(report, 'as_%s' % options.format)
        output = func()
        if not options.archive:
            print output
        else:
            if options.format == 'html':
                ext = 'html'
            else:
                ext = 'txt'
            t = time.localtime()
            d = os.path.join(os.path.expanduser(options.archive), time.strftime("%Y/%m", t))
            subprocess.call(['mkdir', '-p', d])
            f = open(os.path.join(d, time.strftime("report.%Y-%m-%d." + ext, t)), 'w')
            f.write(output)
            f.close()
    except Exception, e:
        if options.debug:
            raise
        else:
            cli.print_usage()
            cli.exit(2, "%s: %s\n" % (cli.get_prog_name(), e))
