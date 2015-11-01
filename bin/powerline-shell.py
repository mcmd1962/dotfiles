#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import argparse
import sys
import cPickle

import os
import datetime
import re
import signal
import socket
import subprocess
import time

def warn(msg):
    print '[powerline-bash] ', msg

class Powerline:
    symbols = {
        'compatible': {
            'lock': 'RO',
            'separator': u'\u25B6',
            'separator_thin': u'\u276F'
        },
        'patched': {
            'lock': u'\uE0A2',
            'separator': u'\uE0B0',
            'separator_thin': u'\uE0B1'
        },
        'flat': {
            'lock': 'RO',
            'separator': '',
            'separator_thin': ''
        },
    }

    color_templates = {
        'bash': '\\[\\e%s\\]',
        'zsh': '%%{%s%%}',
        'bare': '%s',
    }

    def __init__(self, args, cwd):
        self.args = args
        self.cwd = cwd
        mode, shell = args.mode, args.shell
        self.showcolornumber = args.showcolornumber
        self.color_template = self.color_templates[shell]
        self.reset = self.color_template % '[0m'
        self.lock = Powerline.symbols[mode]['lock']
        self.separator = Powerline.symbols[mode]['separator']
        self.separator_thin = Powerline.symbols[mode]['separator_thin']
        self.segments = []

    def color(self, prefix, code):
        if code == 0:
           return ''
        else:
           return self.color_template % ('[%s;5;%sm' % (prefix, code))

    def fgcolor(self, code):
        return self.color('38', code)

    def bgcolor(self, code):
        return self.color('48', code)

    def append(self, content, fg, bg, separator=None, separator_fg=None):
        if self.showcolornumber:
           content = 'fg=%s bg=%s %s' % (fg, bg, content)
        self.segments.append((content, fg, bg, separator or self.separator,
            separator_fg or bg))

    def draw(self):
        return (''.join(self.draw_segment(i) for i in range(len(self.segments)))
                + self.reset).encode('utf-8')

    def draw_segment(self, idx):
        segment = self.segments[idx]
        next_segment = self.segments[idx + 1] if idx < len(self.segments)-1 else None

        drawoutput = ''.join((
            self.fgcolor(segment[1]),
            self.bgcolor(segment[2]),
            segment[0],
            self.bgcolor(next_segment[2]) if next_segment else self.reset,
            self.fgcolor(segment[4]),
            segment[3]))

        return drawoutput

def get_valid_cwd():
    """ We check if the current working directory is valid or not. Typically
        happens when you checkout a different branch on git that doesn't have
        this directory.
        We return the original cwd because the shell still considers that to be
        the working directory, so returning our guess will confuse people
    """
    try:
        cwd = os.getcwd()
    except:
        cwd = os.getenv('PWD')  # This is where the OS thinks we are
        parts = cwd.split(os.sep)
        up = cwd
        while parts and not os.path.exists(up):
            parts.pop()
            up = os.sep.join(parts)
        try:
            os.chdir(up)
        except:
            warn("Your current directory is invalid.")
            sys.exit(1)
        warn("Your current directory is invalid. Lowest valid directory: " + up)
    return cwd

#def ExecuteSegment(SegmentName, newcwd, CacheExpiryPeriod):
def ExecuteSegment(SegmentName):

   def handler(signum, frame):
      raise IOError("signal problem")

   t_start = time.time()
   MaxExecutionTime = 2
   if USERDATA.has_key('global') and type(USERDATA['global']) == dict:
      MaxExecutionTime = USERDATA['global'].get('MaxExecutionTime', MaxExecutionTime)

   if USERDATA.has_key('cache') and type(USERDATA['cache']) == dict:
      if USERDATA['cache'].has_key(SegmentName) and type(USERDATA['cache'][SegmentName]) == dict:
         CacheExpiryTime = USERDATA['cache'][SegmentName].get('CacheExpiryTime', 0)
         oldcwd          = USERDATA['cache'][SegmentName].get('oldcwd', '')
         oldps1          = USERDATA['cache'][SegmentName].get('oldps1', '')

         if (CacheExpiryTime > time.time())  and  (oldcwd == newcwd):
            pass
            #sys.stdout.write('** ' + oldps1)
            #sys.exit(0)


      MaxExecutionTime = USERDATA['global'].get('MaxExecutionTime', MaxExecutionTime)


   # Segment function name is constructed from segment name:
   SegmentFunction = "add_%s_segment" % SegmentName

   try:
      signal.signal(signal.SIGALRM, handler)
      signal.alarm(MaxExecutionTime)

      # execute function
      SegmentFunction = globals()[SegmentFunction]
      if hasattr(SegmentFunction, '__call__'):
         functionCallResult = SegmentFunction()
      signal.alarm(0)
      if ( type (functionCallResult) == list )  and (len(functionCallResult) == 3):
         powerline.append(functionCallResult[0], functionCallResult[1], functionCallResult[2])

   except OSError:
      pass

   except subprocess.CalledProcessError:
      pass

   except IOError:
      powerline.append(' %s ? ' % SegmentName, 11, 202)

   t_end   = time.time()
   delta   = t_end - t_start
   global persistentData
   persistentData[SegmentName] = {}
   persistentData[SegmentName]['execTime'] = delta

# #####################################################################################
#

# default.py:
class DefaultColor:
    """
    This class should have the default colors for every segment.
    Please test every new segment with this theme first.
    """
    SERVERSTATE_FG =  16
    SERVERSTATE_BG = 214

    USERNAME_FG =   3
    USERNAME_BG = 232

    DATETIME_FG = 241
    DATETIME_BG = 233

    HOSTNAME_FG = 11
    HOSTNAME_BG = 237

    HOME_SPECIAL_DISPLAY = True
    HOME_BG = 31  # blueish
    HOME_FG = 15  # white
    PATH_BG = 237  # dark grey
    PATH_FG = 250  # light grey
    CWD_FG = 254  # nearly-white grey
    SEPARATOR_FG = 244

    READONLY_BG = 220
    READONLY_FG =  18

    REPO_CLEAN_BG = 148  # a light green color
    REPO_CLEAN_FG = 0    # black
    REPO_READY_BG = 229  # yellow
    REPO_READY_FG = 28   # green
    REPO_DIRTY_BG = 161  # pink/red
    REPO_DIRTY_FG = 15   # white

    JOBS_FG = 39
    JOBS_BG = 238

    CMD_PASSED_BG = 234
    CMD_PASSED_FG = 15
    CMD_FAILED_BG = 161
    CMD_FAILED_FG = 15

    SVN_CHANGES_BG = 161
    SVN_CHANGES_FG = 15  # dark green

    VIRTUAL_ENV_BG = 35  # a mid-tone green
    VIRTUAL_ENV_FG = 00

class Color(DefaultColor):
    """
    This subclass is required when the user chooses to use 'default' theme.
    Because the segments require a 'Color' class for every theme.
    """
    pass





###THEMEFILES###


# #####################################################################################

# #####################################################################################
# ###USERDATA###
USERDATA = {'machinedisabled': {'BG': 195, 'FG': 208}, 'CacheExpiryPeriod': 3, 'username': {'marcel': {'FG': 3}, 'backup': {'BG': 51, 'FG': 18}, 'root': {'FG': 1}, 'operat': {'FG': 27}, 'allother': {'BG': 195, 'FG': 232}}, 'global': {'username': 'marcel', 'wshostname': 'thishost.yourdomain.com', 'MaxExecutionTime': 2}, 'tabtitle': {'EscapeCodeEnd': '\\a', 'EscapeCodeStart': '\\e]2;'}}

# #####################################################################################

# #####################################################################################
# ###SEGMENTFUNCTIONS###
# Segment: root
def add_root_segment():
    segment = 'root'

    root_indicators = {
        'bash': ' \\$ ',
        'zsh': ' \\$ ',
        'bare': ' $ ',
    }
    bg = Color.CMD_PASSED_BG
    fg = Color.CMD_PASSED_FG
    if powerline.args.prev_error != 0:
        fg = Color.CMD_FAILED_FG
        bg = Color.CMD_FAILED_BG

    return [root_indicators[powerline.args.shell], fg, bg]





# Segment: jobs
from stat import *
def add_jobs_segment():

    segment = 'jobs'

    # ps --ppid $$ --no-headers
    myppid = os.getppid()
    CountJobs = {}
    ProcessPid = -1

    for f in os.listdir('/proc'):
        pathname = os.path.join('/proc', f)
        fstat = os.stat(pathname)

        if fstat.st_uid != os.getuid():
            continue

        if S_ISDIR(fstat.st_mode):
            statfile = os.path.join(pathname, 'stat')
            if os.path.isfile(statfile):
                with open(statfile) as f:
                    statline = f.readline()
                    fields   = statline.split()
                    if len(fields) >= 3:
                        process_pid  = fields[0]
                        process_ppid = fields[3]

                        if process_pid == str(myppid):
                           ProcessPid = process_ppid

                        if CountJobs.has_key(process_ppid):
                           CountJobs[process_ppid] += 1
                        else:
                           CountJobs[process_ppid]  = 1

    num_jobs = CountJobs[str(ProcessPid)] - 1
    if num_jobs > 0:
        return [' %d ' % num_jobs, Color.JOBS_FG, Color.JOBS_BG]




# Segment: svn
def add_svn_segment():
    segment = 'svn'

    currentDir = os.getenv('PWD')
    currentDir = os.path.realpath(currentDir)
    parentDir  = ''

    is_svn = False
    for dirElement in currentDir.split('/'):
       parentDir = parentDir + '/' + dirElement
       if os.path.isdir(parentDir + '/' + '.svn'):
          is_svn = True

    if is_svn is False:
       return

    #"svn status | grep -c "^[ACDIMRX\\!\\~]"
    output    = subprocess.check_output(['svn', 'status'], shell=False)
    changes   = 0
    untracked = 0
    for line in output.split('\n'):
       if len(line) == 0:
          continue

       FC = line[0]
       if (
             ( FC == 'A' )  or ( FC == 'C' )  or
             ( FC == 'D' )  or ( FC == 'I' )  or
             ( FC == 'M' )  or ( FC == 'R' )  or
             ( FC == 'X' )  or ( FC == '!' )  or
             ( FC == '~' )
             ):
          changes += 1
       elif '?' in line:
          untracked += 1

    output = 'SVN'
    if untracked > 0:
       output += " U:%s" % untracked
    if changes   > 0:
       output += " M:%s" % changes

    if untracked + changes == 0:
       fg = Color.REPO_CLEAN_FG
       bg = Color.REPO_CLEAN_BG
    else:
       fg = Color.REPO_DIRTY_FG
       bg = Color.REPO_DIRTY_BG

    return [' %s ' % (output), fg, bg]




# Segment: git
def add_git_segment():
    segment = 'git'

    currentDir = os.getenv('PWD')
    currentDir = os.path.realpath(currentDir)
    parentDir = ''

    is_git = False
    for dirElement in currentDir.split('/'):
       parentDir = parentDir + '/' + dirElement
       if os.path.isdir(parentDir + '/' + '.git'):
          is_git = True

    if is_git is False:
       return

    branch          = ''
    origin_status   = ''
    count_modified_files  = 0
    count_untracked_files = 0
    # git status --branch --porcelain --ignore-submodules
    # ## master
    #  M segments/jobs.py

    count_changed_files   = 0
    count_notstaged_files = 0

    output = subprocess.check_output(['git', 'status', '--branch', '--short', '--ignore-submodules'], shell=False)
    for line in output.split('\n'):
       if len(line) <  2:
          continue

       if line[0:2] == '##':
          branch = line.split()[1]

          if '...' in branch:
             pos = branch.index('...')
             if pos > 0:
                branch = branch[:pos]


          if 'ahead' in line:
             ## master...origin/master [ahead 2]
             pos           = line.index('ahead')
             origin_status = line[pos + 6:]
             origin_status = ' %s%s' % (u'\u21E1', origin_status[:-1])


          elif 'behind' in line:
             ## master...origin/master [behind 2]
             pos           = line.index('behind')
             origin_status = line[pos + 7:]
             origin_status = ' %s%s' % (u'\u21E3', origin_status[:-1])

       elif (line[0] == ' ')  and  ( line[1] in 'AMDU' ):
          count_modified_files  += 1
          count_notstaged_files += 1

       elif (line[0] in 'MADRC')  and  ( line[1] == ' ' ):
          count_modified_files  += 1
          count_changed_files += 1

       elif line.find('??') >= 0:
          count_untracked_files += 1

       else:
          count_modified_files += 1

    branch += origin_status

    if count_untracked_files > 0:
       count = count_untracked_files
       branch += ' U:%s' % count

    if count_modified_files > 0:
       count = count_modified_files
       branch += ' M:%s' % count

    bg = Color.REPO_CLEAN_BG
    fg = Color.REPO_CLEAN_FG


    if count_untracked_files + count_notstaged_files + count_modified_files > count_changed_files:
        bg = Color.REPO_DIRTY_BG
        fg = Color.REPO_DIRTY_FG
    elif  count_changed_files > 0:
        bg = Color.REPO_READY_BG
        fg = Color.REPO_READY_FG

    return [' %s ' % branch, fg, bg]




# Segment: uptime
def add_uptime_segment():
    segment = 'uptime'

    FG = '231;1'
    BG = '69'

    if USERDATA.has_key(segment) and type(USERDATA[segment]) == dict:
       FG = USERDATA[segment].get('FG', FG)
       BG = USERDATA[segment].get('BG', BG)


    with open('/proc/uptime', 'r') as f:
       uptime = int(float(f.readline().split()[0]))

    if powerline.args.shell == 'bash':

       today   = datetime.date.today()
       weekday = datetime.date.weekday(today)



       if weekday == 0:
          deltadays = 2.7

       else:
          deltadays = 0.7

       # We donot want to see the reboot message so long on our own workstation:
       hostname = os.getenv('HOSTNAME').strip()
       if USERDATA.has_key('global') and type(USERDATA['global']) == dict  and  hostname == USERDATA['global'].get('wshostname', ''):
          deltadays = 0.0625

       if uptime < 86400 * deltadays:
          days    = int(  uptime           / 86400 )
          hours   = int( (uptime % 86400 ) /  3600 )
          minutes = int( (uptime % 3600  ) /    60 )

          if uptime > 86400:
            updatestring = "%1dd%1dh%02dm" % (days, hours, minutes)
          else:
            updatestring = "%1dh%02dm" % (hours, minutes)

          return [' REBOOTED %s ' % updatestring, FG, BG]

       elif uptime > 86400 * 800:
          days    = int(  uptime           / 86400 )
          updatestring = "%1dd" % (days)

          return [' UP %s ' % updatestring, FG, BG]





# Segment: diskusage
def add_diskusage_segment():
    segment = 'diskusage'

    FG        = '166;1'
    BG        = '14'
    threshold = 90

    diskusage = ''

    if USERDATA.has_key(segment) and type(USERDATA[segment]) == dict:
       FG        = USERDATA[segment].get('FG', FG)
       BG        = USERDATA[segment].get('BG', BG)
       threshold = USERDATA[segment].get('threshold', threshold)

    mountfile = open('/proc/mounts', 'r')
    for line in mountfile:

       fields = re.findall(r"^(/\S+)\s+(\S+)", line)
       if fields:
          mountpoint = fields[0][1]
          if os.path.isdir(mountpoint):
             statvfs = os.statvfs(mountpoint)
             f_blocks = statvfs[2]
             f_bavail = statvfs[4]

             if f_blocks == 0:
                continue

             percentage = ( 100.0  -  f_bavail ) / f_blocks  * 100

             if percentage <= threshold:
                continue

             if len(diskusage) == 0:
                diskusage = '%s:%0.1f%%' % (mountpoint, percentage)
             else:
                diskusage = '%s %s:%0.1f%%' % (diskusage, mountpoint, percentage)

    if len(diskusage) > 0:
       return [' %s ' % diskusage, FG, BG]

    return




# Segment: read_only
def add_read_only_segment():
    segment = 'read_only'

    cwd = powerline.cwd or os.getenv('PWD')

    if not os.access(cwd, os.W_OK):
        return [' %s ' % powerline.lock, Color.READONLY_FG, Color.READONLY_BG]




# Segment: username
def add_username_segment():
    segment = 'username'

    FG = Color.USERNAME_FG
    BG = Color.USERNAME_BG

    if powerline.args.shell == 'bash':

        username = os.getenv('USER').strip()
        userfound = False

        if USERDATA.has_key(segment) and type(USERDATA[segment]) == dict:
            for user in USERDATA[segment]:

                if username == user  and  type(USERDATA[segment][user]) == dict:
                    FG = USERDATA[segment][user].get('FG', FG)
                    BG = USERDATA[segment][user].get('BG', BG)
                    userfound = True

            if not userfound and USERDATA[segment].has_key('allother')  and  type(USERDATA[segment]['allother']) == dict:
                FG = USERDATA[segment]['allother'].get('FG', FG)
                BG = USERDATA[segment]['allother'].get('BG', BG)

        if username == 'marcel':
            username = 'mcmd'

        user_prompt = ' %s ' % username

    elif powerline.args.shell == 'zsh':
        user_prompt = ' %n '

    else:
        user = os.getenv('USER')
        if user == 'marcel':
           user = 'mcmd'
        user_prompt = ' %s ' % user

    return [user_prompt, FG, BG]




# Segment: machinedisabled
def add_machinedisabled_segment():
    segment = 'machinedisabled'

    FG = 226
    BG = 1

    if USERDATA.has_key(segment) and type(USERDATA[segment]) == dict:
        FG = USERDATA[segment].get('FG', FG)
        BG = USERDATA[segment].get('BG', BG)

    # Does this host have pcon, pcon.conf
    FPCON      = '/home/operat/bin/pcon'
    FPCONCONF  = '/home/operat/conf/pcon.conf'
    FMACHINEOK = '/dev/shm/pcon-machine-ok'

    PCONPRESENT     = True if os.path.isfile(FPCON)                                      else False
    PCONCONFPRESENT = True if os.path.isfile(FPCONCONF) and os.path.getsize(FPCONCONF)   else False
    MACHINEENABLE   = True if os.path.isfile(FMACHINEOK)                                 else False

    machine_prompt = ''

    if powerline.args.shell == 'bash':
        if PCONPRESENT and PCONCONFPRESENT and not MACHINEENABLE:
            machine_prompt = ' DISABLED '


    return [machine_prompt, FG, BG]




# Segment: hostname
def add_hostname_segment():
    segment = 'hostname'

    FG = Color.HOSTNAME_FG
    BG = Color.HOSTNAME_BG

    DNShostname = socket.gethostname().split('.')[0]
    username    = os.getenv('USER').strip()

    if powerline.args.shell == 'bash':
        hostname = '\\h'
        cname = os.getenv('UCMDB_CNAME')
        if cname is not None:
           if cname == 'unknown':

              if not 'uxcl' in DNShostname:
                 FG = 7
                 BG = 5

           else:

              hostname = cname

              if 'uab' in cname:
                 FG = 7
                 BG = 1

              elif 'uco' in cname:
                 FG = 0
                 BG = 6

              elif 'uix' in cname:
                 FG = 7
                 BG = 4

              elif 'ust' in cname:
                 FG = 254
                 BG =   4

              elif 'ush' in cname:
                 FG = 1
                 BG = 7

              elif 'utr' in cname:
                 FG = 7
                 BG = 4

        if USERDATA.has_key('global') and type(USERDATA['global']) == dict  and  username != USERDATA['global'].get('username', ''):
           (FG, BG) = (BG, FG)

        port = os.getenv('PORT')
        if port is not None:
            host_prompt = ' %s.%s ' % (hostname, port.strip())
        else:
            host_prompt = ' %s ' % (hostname)

    elif powerline.args.shell == 'zsh':
        host_prompt = ' %m '
    else:
        host_prompt = ' %s ' % socket.gethostname().split('.')[0]

    return [host_prompt, FG, BG]




# Segment: serverstate
def add_serverstate_segment():
    segment = 'serverstate'

    FG = Color.SERVERSTATE_FG
    BG = Color.SERVERSTATE_BG

    CNAME    = os.getenv('UCMDB_CNAME'  , '').strip()
    SERVICE  = os.getenv('UCMDB_SERVICE', '').strip()
    STATUS   = os.getenv('UCMDB_STATUS' , '').strip()
    TSO      = os.getenv('UCMDB_TSO'    , '').strip()

    # CNAME systems starting with 's' are mirrors:
    if CNAME[:1] == 's'  or  CNAME[2:4] == 'tr':
       FG =  17
       BG = 230

    if '_it_dev_nl' in TSO.lower():
       return [' DEV ', 23, 81]
    elif CNAME[0:2] == 'pu'  and   CNAME[8:11] == 'orc':
       return [' PROD ',  1, 15]
    elif CNAME[0:2] == 'su'  and   CNAME[8:11] == 'orc':
       return [' STBY ', 19, 15]

    if STATUS != 'Production':
       return

    if not '_it_ops_nl_trading' in TSO.lower():
       return

    return [' PROD ', FG, BG]




# Segment: datetime
def add_datetime_segment():
    segment = 'datetime'

    datetime = ''
    if powerline.args.shell == 'bash':
       datetime = ' \\D{%a %H:%M} '

    return [datetime, Color.DATETIME_FG, Color.DATETIME_BG]





# Segment: tabtitle
def add_tabtitle_segment():
    segment = 'tabtitle'

    hostname = socket.gethostname().split('.')[0]
    hostname = hostname.replace('op',  '')
    hostname = hostname.replace('am',  '')
    hostname = hostname.replace('ux',  '')

    username = os.getenv('USER').strip()

    if USERDATA.has_key('global') and type(USERDATA['global']) == dict  and  username == USERDATA['global'].get('username', ''):
       username = ''

    EscapeCodeStart = ''
    EscapeCodeEnd   = ''
    if USERDATA.has_key(segment) and type(USERDATA[segment]) == dict:
       EscapeCodeStart = USERDATA[segment].get('EscapeCodeStart', '')
       EscapeCodeEnd   = USERDATA[segment].get('EscapeCodeEnd',   '')

    cname = os.getenv('UCMDB_CNAME')
    if cname is not None:
       if cname != 'unknown':
          cname = cname.replace('puab', 'a')
          cname = cname.replace('pubo', 'b')
          cname = cname.replace('puco', 'c')
          cname = cname.replace('puix', 'i')
          cname = cname.replace('pust', 's')
          cname = cname.replace('putr', 't')
          cname = cname.replace('amat', 'a')
          cname = cname.replace('frix', 'f')

          hostname = cname

    if (len(EscapeCodeStart) != 0)  and (len(EscapeCodeEnd) != 0):
        return ['\\[%s%s %s%s\\]' % (EscapeCodeStart, username, hostname, EscapeCodeEnd), 0, 0]




# #####################################################################################

if __name__ == "__main__":
    time_psstart = time.time()
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('--cwd-only', action='store_true',
            help='Only show the current directory')
    arg_parser.add_argument('--cwd-max-depth', action='store', type=int,
            default=5, help='Maximum number of directories to show in path')
    arg_parser.add_argument('--colorize-hostname', action='store_true',
            help='Colorize the hostname based on a hash of itself.')
    arg_parser.add_argument('--mode', action='store', default='patched',
            help='The characters used to make separators between segments',
            choices=['patched', 'compatible', 'flat'])
    arg_parser.add_argument('--showcolornumber', action='store_true',
            help='Show color numbers in segment')
    arg_parser.add_argument('--shell', action='store', default='bash',
            help='Set this to your shell type', choices=['bash', 'zsh', 'bare'])
    arg_parser.add_argument('prev_error', nargs='?', type=int, default=0,
            help='Error code returned by the last command')
    args = arg_parser.parse_args()

    # Get persistent data
    persistentData = {}
    persistentDataFile = '%s/%s' % ( os.getenv('HOME'), '.powerlinedata' )
    if os.path.exists(persistentDataFile):
       try:
          pFile = open(persistentDataFile, 'rb')
          persistentData = cPickle.load(pFile)
          pFile.close()
       except:
          pass

    # Check whether we can use the cached data
    newcwd            = os.getcwd()
    oldcwd            = persistentData.get('oldcwd', '')
    oldps1            = persistentData.get('oldps1', '')
    CacheExpiryTime   = persistentData.get('CacheExpiryTime', 0)
    if (CacheExpiryTime > time.time())  and  (oldcwd == newcwd)  and (oldps1 != ''):
       sys.stdout.write(oldps1.replace(' ', '*', 3))
       sys.exit(0)


    # Invoke powerline
    powerline = Powerline(args, get_valid_cwd())

    # ##############################################
    # Invoke segments:
    ExecuteSegment('tabtitle')
    ExecuteSegment('datetime')
    ExecuteSegment('serverstate')
    ExecuteSegment('hostname')
    ExecuteSegment('machinedisabled')
    ExecuteSegment('username')
    ExecuteSegment('read_only')
    ExecuteSegment('diskusage')
    ExecuteSegment('uptime')
    ExecuteSegment('git')
    ExecuteSegment('svn')
    ExecuteSegment('jobs')
    ExecuteSegment('root')
    ###SEGMENTFUNCTIONCALLS###
    # ##############################################

    newps1 = powerline.draw()
    # Store persistent data
    try:

       CacheExpiryPeriod = USERDATA.get('CacheExpiryPeriod', 3)
       persistentData['oldcwd']          = os.getcwd()
       persistentData['CacheExpiryTime'] = time.time() + CacheExpiryPeriod

       persistentData['oldps1']          = newps1
       persistentData['totaltime']       = time.time() - time_psstart

       pFile = open(persistentDataFile, 'wb')
       cPickle.dump(persistentData, pFile, cPickle.HIGHEST_PROTOCOL)
       pFile.close()
    except:
       pass

    sys.stdout.write(newps1)


