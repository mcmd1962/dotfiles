#!/usr/local/bin/perl -w

=head1 CheckSystem

Does several checks on the system and reports this to STDOUT

=head1 VERSION INFO

=over 8

=item I<Author>

Marcel

=item I<Date>

May 10, 2006

=item I<Version>

0.9

=back

=head1 SYNOPSIS

program [options]

 Options:
   -help            brief help message
   -man             full documentation
   -debug n         the higher n is the more info you will see (10)
   -debuglog s      optionally the log file in which debug output is placed, default this is STDERR

=head1 OPTIONS

=over 8

=item B<-help>

This tool is checking the health of a system and reports this in a file

=item B<-man>

Prints the manual page and exits.

=item B<-debug i>

default: 10

Give program flow information. The higher the value the more info is provided.
Debug levels 0-5 are reserved for error messages; levels 6-10 for warnings;
11-20 for informational messages and 21 and higher for debug messages.

=item B<-debuglog s>

default: STDERR

The file in which debug info is put into. By default this is STDERR, so to the screen.

=back

=head1 DESCRIPTION

B<This program> will do the following:

=item B<* File system check>

Check the file system on available file space. Defaults are preconfigured in this script for the
warning and error level, which can be overriden in file ~/.checksystemrc (format: /mountpoint:warning:error)

=item B<* Hardware raid controller>

Check the hardware raid controller. This process is triggered when program I</usr/sbin/raidctl> is
on the file system.

=item B<* Metadevice check>

Check the state of the metadevices

=back

B<NOTE:> it is important to set the I<-debug> flag and use at least level 10 to see all warning
and error messages. When a warning message is printed, than a default sleep of 1 second is triggered.
For the error message this is 2 seconds.

=head1 ROUTINES

=cut

require 5.6.0;

###############################################################################
# Define libraries
###############################################################################
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

###############################################################################
# Define subs
###############################################################################
sub debug($$);
sub SetDefaults(\%\%);
sub ReadRCfile();
sub CheckFiles();
sub CheckFileSystems();
sub CheckGAUSSlog();
sub CheckMetastat();
sub CheckPerformance();
sub CheckRaidCTL();

###############################################################################
# Secure environment
###############################################################################
$ENV{'PATH'} = "/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin";

###############################################################################
# Global variables and intialisations
###############################################################################
# Set defaults for commandline options
our %optDefaults = (debug    => 10,
                    debuglog => 'STDERR');
our %opt;

# Configuration options as defined in the RC file is stored in %c
my %c;

# Get the options
GetOptions('debug=i'    => \$opt{debug},
           'debuglog=s' => \$opt{debuglog},
           'help|?'     => \$opt{help},
           'man'        => \$opt{man},
           'opt1=s'     => \$opt{opt1},
           'opt2=s'     => \$opt{opt2},
  )
  or pod2usage(2);

pod2usage(1) if $opt{help};
pod2usage(-exitstatus => 0, -verbose => 2) if $opt{man};

SetDefaults(%opt, %optDefaults);

#
if ($opt{debuglog} ne "STDERR") {
   open(STDERR, "> $opt{debuglog}") or warn "Cannot open debug log file $opt{debuglog}: $!";
}

debug(20, "Program $0 has started");

###############################################################################
# Main section
###############################################################################

# start coding here

ReadRCfile;

CheckPerformance  if $c{'os-perf'}{'suppressed'}  != 0;
CheckMetastat     if $c{'metastat'}{'suppressed'} != 0;
CheckRaidCTL      if $c{'raidchk'}{'suppressed'}  != 0;
CheckFileSystems  if $c{'fs-size'}{'suppressed'}  != 0;
CheckFiles        if $c{'files'}{'suppressed'}    != 0;
#CheckGAUSSlog     if $c{'gauss'}{'suppressed'}    != 0;

# cleanly exit
debug(20, "Program $0 has ended");
exit(0);

###############################################################################
# Section with subroutines
###############################################################################
# #####################################
sub ReadRCfile() {

   # Threshold can be stored in ~/.checksystemrc
   # format:
   #    FS:warn:err

   my $routine = 'ReadRCfile';

   #my $userhomedir = (getpwnam(getpwuid($<)))[7];
   #my $rcfile      = "$userhomedir/.checksystemrc";
   my $rcfile      = "~marceld/.checksystemrc";
   $rcfile      = "/tmp/marcel/.checksystemrc"  if ! -r $rcfile;

   # before we process the rc file, just define some default values first:

   
   
   # default for File Ssytem size warnings and errors:
   %{$c{'fs-size'}} = ('/'       => {'warn' => 60, 'err' => 85},
                       '/tmp'    => {'warn' => 30, 'err' => 50},
                       '/var'    => {'warn' => 82, 'err' => 94},
                       'default' => {'warn' => 70, 'err' => 90},
                      );

   # default for performance stats:
   %{$c{'os-perf'}} = ('namelookup'  => {'warn' => 90, 'err' => 80},
                       'inodecache'  => {'warn' => 40, 'err' => 70},
                      );


   # default for GAUSSlog file:
   %{$c{'gauss'}{'RE'}} = (
           're-01'  => '(bt006w|bt007w).*(anandbu|brenno|eandrade|gwoolrid|jarmitag|marceld|ndijke|root|tienwang|wbleker)',
           're-02'  => 'path104.*(marceld|ndijke|wbleker)',
                    );

   # Which routines will be processed and which not
   $c{'os-perf'}{'suppressed'} = 1;    #  CheckPerformance by default done
   $c{'fs-size'}{'suppressed'} = 1;    #  CheckFileSystems by default done
   $c{'files'}{'suppressed'} = 1;      #  CheckFiles       by default done
   $c{'raidchk'}{'suppressed'} = 0;    #  CheckRaidCTL     by default off
   $c{'metastat'}{'suppressed'} = 1;   #  CheckMetaStat    by default done
   $c{'gauss'}{'suppressed'} = 1;      #  CheckGAUSS    by default done
                       
                    
   if (-r $rcfile) {
      debug(21, "INFO/$routine: Found rc file $rcfile");

      open(FIN, $rcfile) or debug(21, "Couldnot open file $rcfile: $!");
      while (<FIN>) {
         chomp;

         next if m{^\s*#|^\s*$};      # not interested in comment or empty lines

         s/#.*//;     # remove comments in line
         s#^\s+##;    # remove leading white space
         s#\s+$##;    # remove trailing white space

         debug(21, "INFO/$routine: processing line $_  in file $rcfile");

         my @f = split(/\s*:\s*/);
         if ( $#f >= 2 ) {
            my $group = lc($f[0]);
            my $param = lc($f[1]);

            if ( $param eq 'suppressed') {
               # Process the groups we want to suppress (or NOT)
               next unless $f[2] =~ m#^\d+$#;     # accept only numeric data
               $c{$group}{'suppressed'} = $f[2];
               
            } elsif ( $group eq 'fs-size') {
               # fs-size:/ : 72 : 85->warning level for fs / = 72% and error level at 85%
               next unless $f[2] =~ m#^\d+$#;     # accept only numeric data
               next unless $f[3] =~ m#^\d+$#;     # accept only numeric data
               
               $c{'fs-size'}{$f[1]}{'warn'} = $f[2];
               $c{'fs-size'}{$f[1]}{'err'}  = $f[3];

            } elsif ( $group eq 'os-perf') {
               # OS-perf:namelookup:80:90  
               # OS-perf:inodecache:40:70  
               next unless $f[2] =~ m#^\d+$#;     # accept only numeric data
               next unless $f[3] =~ m#^\d+$#;     # accept only numeric data
               
               $c{'os-perf'}{$f[1]}{'warn'} = $f[2];
               $c{'os-perf'}{$f[1]}{'err'}  = $f[3];
            } elsif ( $group eq 'gauss' ) {
               my $REname = lc($f[2]);
               $c{'gauss'}{$REname} = $f[3];
            }
         }

      }
      close(FIN);
   } else {
      debug(31, "INFO/$routine: Couldnot find rc file $rcfile");

   }
   
   #foreach my $k (keys %{$c{'fs-size'}}) {
   #   print "$k - $c{'fs-size'}{$k}{'warn'} - $c{'fs-size'}{$k}{'err'}\n";
   #}
}

# #####################################
sub CheckPerformance() {

   my $routine  = 'PERF';
   my $OS = '';
   
   my $uname = 'uname';
   
   # First determine what OS we are:
   $OS = qx/uname -s/;
   chomp($OS);

   debug(21, "INFO/$routine: I am $OS");
   
   if ( $OS eq 'SunOS' )  {

      # Check the name lookups cache hit as seen with vmstat -s command
      my $CH = qx/vmstat -s/;
      my ($HR) = $CH =~ m/total name lookups \(cache hits (\d+)\%\)/; 
      
      if ( $HR < $c{'os-perf'}{'namelookup'}{'err'} ) {
         debug(00, "ERROR/$routine: Name lookup cache hit rate is to low ($HR%), check kernel parameters ncsize");
      } elsif ($HR <= $c{'os-perf'}{'namelookup'}{'warn'} ) {
         debug(06, "WARN/$routine: Name lookup cache hit rate is rather low ($HR%), check kernel parameter ncsize");
      } else {
         debug(16, "INFO/$routine: Name lookup cache hit rate is $HR%");
      }
      
      # Check the ufs inode cache with netstat -k inode_cache command
      my $IC = qx|netstat -k inode_cache 2> /dev/null |;
      if ( $IC =~ m#size (\d+) maxsize (\d+) hits (\d+) misses (\d+)# )  {
         my ($size, $maxsize, $hits, $misses) = ($1, $2, $3, $4);
         my $ratio = int(100 * $misses / ($hits + $misses));
      
         if ( ($ratio >= $c{'os-perf'}{'inodecache'}{'err'})  && ($size > (0.95 * $maxsize)) ) {
            debug(00, "ERROR/$routine: poor hit rate for inode cache : $ratio% (max cache size $maxsize), check kernel parameter ufs_ninode");
         } elsif ( ($ratio >= $c{'os-perf'}{'inodecache'}{'warn'}) && ($size > (0.95 * $maxsize) ) ) {
            debug(00, "WARN/$routine: poor hit rate for inode cache : $ratio% (max cache size $maxsize)");
         } else {
            debug(16, "INFO/$routine: hit rate inode cache(max cache size $maxsize) : $ratio%");
         }
      } else {
         debug(16, "INFO/$routine: inode cache not investigated as command doesnot give expected results ($IC)");
      }
   
   }
   
}

# #####################################
sub CheckGAUSSlog() {

   my $routine  = 'GAUSS';
   
   my $GAUSSlogfile = '/var/spool/GAUSS/GAUSS.log';
   if (!-r $GAUSSlogfile) {
      debug(11, "INFO/$routine: Couldnot find GAUSS logfile ($GAUSSlogfile), skipping checks now");
      return 1;
   }
   
   open(FIN, $GAUSSlogfile);
   
   my $message = '';
   LINE: while ( <FIN> ) {
      chomp;
      
      next unless m#^--(WARN|ALERT|FAIL|ERROR|INFO|SUPP)--#;
      last if     m#^--(INFO|SUPP)--#;
      
      my $hit = 0;
      foreach my $RE (keys %{$c{'gauss'}{'RE'}} ) {
          $hit = 1 if  m#$c{'gauss'}{'RE'}{$RE}#;
      }
      $message .= "\t$_\n" if $hit == 0;

   }
   
   if ($message ne '' ) {
      debug(06, "WARN/$routine: Found following GAUSS messages:\n$message")
   
   }
}

# #####################################
sub CheckMetastat() {

   my $MetaStat = '/usr/sbin/metastat';
   my $MetaDB   = '/usr/sbin/metadb';
   my $routine  = 'MS';

   if (!-x $MetaStat) {
      debug(11, "INFO/$routine: Couldnot find metastat($MetaStat), skipping checks now");
      return 1;
   }

   # First check how the disks are build
   open(FMS, " $MetaStat -p 2> /dev/null | ") or debug(06, "WARN/$routine: Couldnot execute $MetaStat");
   while (<FMS>) {
      chomp;
      debug(11, "INFO/$routine: $_");
   }
   close(FMS);

   # Now check on errors with metastat
   my $device = '';
   open(FMS, " $MetaStat -t 2> /dev/null | ") or debug(06, "WARN/$routine: Couldnot execute $MetaStat");
   while (<FMS>) {
      chomp;
      if (/^(\S+)\:/) {
         $device = $1;
      } elsif (/^\s+State:\s+(\S+)\s+(.*)/) {

         if ($1 ne 'Okay') {
            debug(00, "ERROR/MetaStat: $device $1 - $2");
         } else {
            debug(11, "INFO/MetaStat: $device $1 - $2");
         }
      }

   }
   close(FMS);

   # Now check on errors with metadb

   my %md;     # Keeps track on found correct working meta devices
   my %me;     # Keeps track on printed error messaga for a meta device
   open(FMD, " $MetaDB  2> /dev/null | ") or debug(06, "WARN/$routine: Couldnot execute $MetaDB");
   while (<FMD>) {
      chomp;
      
      next if m#flags.*first blk#;
      

      # try to match the following:
      #     a m  p  luo        16              1034            /dev/dsk/c1t0d0s7
      #    M     p             unknown         unknown         /dev/dsk/c1t1d0s7

      my ($flags, $firstBlk, $BlkCount, $device) = m{
         ^
         (.{19})  # Match the first 20 characters, in this we expect the flags to be set
         \s+
         (\S+)  # first blk
         \s+
         (\S+)  # block count
         \s+
         (\S+)  # /dev/dsk/c1..
      }x;

      # Flags meaning:
      # o - replica active prior to last mddb configuration change
      # u - replica is up to date
      # l - locator for this replica was read successfully
      # c - replica's location was in /etc/lvm/mddb.cf
      # p - replica's location was patched in kernel
      # m - replica is master, this is replica selected as input
      # W - replica has device write errors
      # a - replica is active, commits are occurring to this replica
      # M - replica had problem with master blocks
      # D - replica had problem with data blocks
      # F - replica had format problems
      # S - replica is too small to hold current data base
      # R - replica had device read errors
      my $ErrorFlags = '';    # the uppercase characters in $flags are related to errors
      foreach my $ErrorFlag (qw/D F M R S W/) {
          $ErrorFlags .= $ErrorFlag  if  $flags =~ m#$ErrorFlag#;
      }

      my $NeededFlags = '';    
      foreach my $NeededFlag (qw/a l u o/) {
         $NeededFlags .= $NeededFlag  if  $flags =~ m#$NeededFlag#;
      }

      if ( $ErrorFlags ne '')  {
         debug(00, "ERROR/MetaDB: metadb replica error found on device $device: $ErrorFlags. Check metadb now!") 
           unless defined($me{$device}) ;
      } else {
         # I want to see here flags a,l,u,o. When not seen, than this is an error
         if ($NeededFlags eq 'aluo' ) {
            debug(15, "INFO/MetaDB: aluo flags seen on  device $device.")
              unless defined($me{$device}) ;
            $md{$device} += 1;
         } else {
            debug(06, "WARN/MetaDB: not all aluo flags seen on  device $device. We have now: $NeededFlags")
               unless defined($me{$device}) ;
         }
      }
      
      $me{$device} += 1;
      

   }
   close(FMD);
   
   # Let's check that we have at least 2 different working devices with metadb databases on it:
   my $DevCount = 0;
   foreach my $device (keys %md) {
      $DevCount += 1;
   }
      
   if ($DevCount < 2 ) {
      debug(06, "WARN/MetaDB: MetaDB databases only on $DevCount device(s), that is not good");
   } else {
      debug(15, "INFO/MetaDB: MetaDB databases found on $DevCount devices");
   }

}

# #####################################
sub CheckFiles() {
   # Check whether certain files/directories are present which you donot want to see
   my @files = qw(/var/tmp/8_Recommended.zip /var/tmp/supplementairy_patch_cluster.zip );
   my @directories = qw(/var/tmp/8_Recommended /var/tmp/supplementary_patch_cluster);
   
   my $routine = 'FILES';
   
   foreach my $file (sort @files ) {
      if ( -r $file ) {
         debug(06, "WARN/$routine: File $file seen on filesystem, maybe better to delete?");
      }
   }

   foreach my $dir (sort @directories ) {
      if ( -d $dir ) {
         debug(06, "WARN/$routine: Directory $dir seen on filesystem, maybe better to delete?");
      }
   }
}

# #####################################
sub CheckFileSystems() {

   # Check File systems

   my $df      = '/bin/df';
   my $routine = 'FS';

   if (!-x $df) {
      debug(06, "WARN/$routine: Couldnot find df($df), skipping checks now");
      return 1;
   }


   # First check how the disks are build
   open(FMS, " $df -k | ") or debug(06, "WARN/$routine: Couldnot execute $df");
   while (<FMS>) {
      chomp;
      debug(11, "INFO/$routine: $_");

      next unless m#^/|^swap#;
      next if m#/proc#;

      my ($device, $capacity, $used, $avail, $percentage, $mount) = split(/\s+/);
      $device     =~ s#.*/##;
      $percentage =~ s#%##;

      my $threshold_warn = $c{'fs-size'}{'default'}{'warn'};
      my $threshold_err  = $c{'fs-size'}{'default'}{'err'};

      if (defined $c{'fs-size'}{$mount}{'warn'}) {
         $threshold_warn = $c{'fs-size'}{$mount}{'warn'};
         $threshold_err  = $c{'fs-size'}{$mount}{'err'};
      }

      debug(22, "INFO/$routine: Checking device $device, mountpoint $mount with capacity $percentage " .
                "for warning level at $threshold_warn and error level $threshold_err");

      if ($percentage >= $threshold_err) {
         debug(00, "ERROR/$routine: File system $mount ($device) is too full : " .
                   "$percentage % (threshold $threshold_err%)");
      } elsif ($percentage >= $threshold_warn) {
         debug(06, "WARN/$routine: File system $mount ($device) is rather full : $percentage% " .
                   "(threshold $threshold_warn%)");
      }
   }
   close(FMS);

}

# #####################################
sub CheckRaidCTL() {

   my $routine = " CR ";
   
   my $raidctl = '/usr/sbin/raidctl';
   if (!-x $raidctl) {
      debug(11, "INFO/$routine: raidctl command not found, probably not in use on this system");
      return;
   }

   if ( $< != 0 ) {
      debug(11, "WARN/$routine: raidctl command can only be executed by root");
      return;
   }

   open(RAID, " $raidctl | ") or debug(06, "WARN/$routine: Couldnot execute $raidctl");
   while (<RAID>) {
      next if !m#(c\d+t\d+d\d+)\s+(\S+)#;
      if ($2 ne 'OK') {
         debug(00, "ERROR/$routine: RAID problem on device $1, found state: $2");
      }
   }

}

# #####################################
sub debug ($$) {

=head2 debug

The debug subroutine will display debug information to STDERR based on severity setting

=head3 input parameters

=over 8

=item B<$1>

Level, the higher the (debug) level the more debug info should be seen

=item B<$2>

Message, this will be printed

=back

=head3 output parameters

none

=head3 output

The date, debug level and message are printed to STDERR

-head3 example

Wed Sep 29 13:39:52 2004 - 020 - Program ./template.pl has started

=cut

   my $level   = shift;
   my $message = shift;

   my $date = gmtime();

   if ($level <= $opt{debug}) {
      printf STDERR " % s - %3.3d - %s\n", $date, $level, $message;
      sleep 2 if $level <= 5;
      sleep 1 if (($level > 5) && ($level <= 10));
   }
}

# #####################################
sub SetDefaults(\%\%) {

=head2 SetDefaults

The SetDefaults subroutine will set the option values to be used by the script

=head3 input parameters

=over 8

=item B<\%1>

The options I<associative array> containing the options

=item B<\%2>

The default options I<associative array> which will be used when an argument in B<\%1> has not been defined

=back

=head3 output parameters

none

=head3 output

none

=cut

   for my $key (keys(%{$_[1]})) {
      if (!defined($_[0]{$key})) {
         $_[0]{$key} = $_[1]{$key};
      }
   }
}

__END__

=head1 AUTHOR

Marcel; email: E<lt>Marcel@E<gt>.

=head1 ACKNOWLEDGEMENTS

Without the help of eclipse this script would never have been written!

=cut
