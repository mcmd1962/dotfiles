#!/usr/bin/perl -w

# eval `perl cd.pl options args`

# options:
# -h:        help
# -l:        list history
# -clear:    clear history
# -aliasfile:
# -historyfile:
# -statusfile:     file that stores the datastructure, by default ....
# -init:           clear data structure, read in alias file & history file,
#                  this will loose history and all DIRS entries.
# -createalias: (-ca), creates a directory alias
# -deletealias: (-da), deletes an existing directory alias
# -listalias:   (-la), list all directory aliases
# -mode:        dirs, popd, pushd or cd
# -d:        delete entry from history (can be number or directory name)
# -searchorder:  (-so): order to search for a directory. Can be:
#                D: physical directories
#                A: directory aliases
#                E: relative/absolute directory expansion
#                H: history
#                Default order: DAEH (case insensitive)
#
# -casesensitive: casesensitive mode, normally it is not case sensitive, unless
#             any part in the input contains an uppercase character, that part
#             is treated case sensitive
# -autosetup:  enable automatic setup when entering and leaving the directory.
# -interactive: start interactive mode (difficult to implement!)

# arg
# 1. exists as subdir -> cd to it!
# 2. exists as alias  -> cd to the expanded alias
# 3. when arg is a number, cd to the corresponding history entry
# 4. arg is a number of dots (....), this is expanded to ../../..
# 5. arg is interpreted character by character:
#    a. when first character is /, than interpret arg as an absolute path,
#       otherwise try first relative part, than absolute path
#    b. try to expand first non / character to a directory which start with
#       this letter (relative or absolute)
#    c. do this for the second non / character to a subdirectory of the
#       the previous found directory
#    d. repeat this for every character
#    e. when a character is a number, than
#       + first look whether there is a possible directory with this number,
#         if not
#       + use the number'th solution
# 6. look in history:
#    + do we have any entry in history with dir name ending with name 'arg'
#    + do we have any entry in history with intermediate directory name
#      equal to 'arg'
#    + do we have any item in history which does have arg in the ending
#      directory
#    + do we anything in history with 'arg' somewhere within
#    e. cd to the first found solution

# data structure:
# VERSION: version of datastructure
# ALIAS list:
#       + alias
#       + directory
#       + usage count
#       + timestamp created
#       + timestamp last access
# DIRS list:
#       + per PPID (to guarantee best that some other process is not changing
#         this list for this process)
#       + order number
#       + directory name
#       + timestamp
# HISTORY list:
#       + directory name
#       + order number
#       + timestamp created
#       + timestamp last access
#       + usage count
#       + status (locked entry)

=head1 NAME

Advanced unix 'cd' program with many options

=head1 VERSION INFO

=over 8

=item I<Author>

Marcel

=item I<Date>

June 25, 2006

=item I<Version>

0.9

=back

=head1 SYNOPSIS

cd [options]

 Options:
   -help            brief help message
   -man             full documentation
   -debug n         the higher n is the more info you will see (5)

   -aliasfile s     File containing all directory alias definitions
   -casesensitive   Switch on case sensitive checking
   -createalias|ca  Create a directory alias.
   -deletealias|da  Delete a directory alias
   -listalias|la    List all defined aliases
   -listhistory|lh  List all entries made in the past

   -historyfile=s   Read in information from the history file
   -initialize      Initialize the cached data structure
   -interactive     Interactive mode, not implemented (yet?)
   -list            List all directory information
   -mode=s          Force the mode to be either: cd, dirs, popd or pushd
   -searchorder|so=s Order for determining the chosen directory
   -statusfile=s    File to store cached status information into
   -verbose+        Show more detail. The more verboses used, the more info is provided.

=head1 OPTIONS

=over 8

=item B<-help>

Advanced unix 'cd' program. Should make life easier by using directory
aliases, history information, directory finding using characters, etc.

=item B<-man>

Prints the manual page and exits.

=item B<-debug i>

default: 5

Give program flow information. The higher the value the more info is provided.

=item B<-debuglog s>

default: STDERR

The file in which debug info is put into. By default this is STDERR, so to the screen.

=item B<-aliasfile s>

The file containing cd aliases. This file supports unix style formats, each line should have 2 fields:
the alias name and the directory name. The directory should exists, if not than the alias will not
be used.
Normally this option is not needed, as this information will be stored in a cached file. However,
for initialization this can be convenient!


=item B<casesensitive>

Search in directory expansion is by default done case insensitive, with this option case sensitivity
can be switched on.

=item B<createalias|ca>

Not yet implemented.

=item B<deletealias|da>

Not yet implemented.

=item B<listalias|la>

With this option a listing of all available directory aliases is given. Only correct entries are 
stored and will be displayed. By default the alias name with the corresponding directory is given. 
By adding (multiple) -v on the command line more information is given: the number of times the alias
was used, when it was created and when it was used for the last time.

=item B<historyfile=s>

Not yet implemented.

=item B<initialize>

This option will initialize the data structure used by this program, the effect will be a fresh start
with no history and/or alias information available.  

=item B<interactive>

Not yet implemented.

=item B<mode=s>

This tool should support the following modes (but doesnot yet):

=over 8

=item B<cd>

the default mode, changing directories as the normal B<cd> tool

=item B<pushd>

changing directories like B<pushd> does.

=item B<popd>

changing directories like B<popd> does.

=item B<dirs>

Listing directories in the directory stack. Note: each shell does have it's own stack!

=back

=item B<searchorder|so=s>

The tool will use the following methods to find a directory:

=over 8

=item B<d>

With this method the tool will try to find an existing (sub) directory on the file system using the 
argument on the command line as the name for a directory. This can be either a relative or absolute 
directory.

=item B<a>

With this method the tool will try to find a directory using alias expansion. This better be an
absolute directory location!

=item B<e>

With this method the tool will try to find an existing (sub) directory on the file system using the
letters from the argument as the first letter for a directory. E.g. when you have the following 
filesystem:

    /var/tmp
    /var/sadm
    /var/spool
    
vt would expand to /var/tmp. 
Sometimes this could lead to more than 1 result (e.g. For vs there are 2 options). The tool will 
report all options and numerize them. By adding the number as the 2nd argument on the command line,
the tool will pick up the directory. So 'vs 2' would expand to /var/spool.

Note 1: the tool will first try a relative search, when this is not successfull, than it will try to
find the directory starting from root (/).

Note 2: the search is by default done case insensitive.
    
=item B<h>

With this method the tool will try to find an existing (sub) directory on the file system using the
history information. Currently this method is not implemented.

=back

The default search order is: I<daeh>

=item B<statusfile=s>

=item B<verbose+>
  
  

=back

=head1 DESCRIPTION

B<This program> will do the following:
this is the point where can you actually describe this!

=head1 ROUTINES

=cut

# require 5.8.2;

###############################################################################
# Define libraries
###############################################################################
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Storable;

# ######
my $VERSION = 99;
my %data;
my %ldata;

###############################################################################
# Define subs
###############################################################################
sub debug($$);
sub PrintMessage($$);
sub SetDefaults(\%\%);

sub init();

sub InitDataStructure();
sub ReadDataStructure();
sub WriteDataStructure();

sub ReadAliasFile();
sub CreateAlias();
sub DeleteAlias();
sub ListAlias();

sub ClearHistory();
sub ReadHistoryFile();
sub ResolvePath($@);
sub ExpandSC($);
sub ListHistory();

sub dirs();
sub pushd(@);
sub popd();

sub ParseInput(@);

sub ReadHash();
sub WriteHash();

sub ChangeDirectory($);

sub SearchDirectories(@);
sub SearchAliases(@);
sub SearchExpansion(@);
sub SearchHistory(@);

###############################################################################
# Secure environment
###############################################################################
$ENV{'PATH'} = "/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin";

###############################################################################
# Global variables and intialisations
###############################################################################
# Set defaults for commandline options
our %optDefaults = (
   debug    => 5,
   debuglog => 'STDERR',
   verbose  => 0,
   silent   => 0,

   aliasfile   => '~/.cd_alias',
   historyfile => '~/.cd_history',
   statusfile  => '~/.cd_status',
   mode        => 'cd',
   searchorder => 'daeh'
);

our %opt;

# Get some defaults from the ENVIRONMENT:
$optDefaults{'ALIASFILE'} = (defined($ENV{CDALIASFILE} ? $ENV{CDALIASFILE} : $optDefaults{'ALIASFILE'}));

# -casesensitive: casesensitive mode, normally it is not case sensitive, unless
#             any part in the input contains an uppercase character, that part
#             is treated case sensitive
# -interactive: start interactive mode (difficult to implement!)
GetOptions(
   'debug=i'    => \$opt{debug},
   'debuglog=s' => \$opt{debuglog},
   'help|?'     => \$opt{help},
   'man'        => \$opt{man},

   'aliasfile=s'      => \$opt{aliasfile},
   'casesensitive'    => \$opt{case},

   'createalias|ca'   => \$opt{ca},
   'deletealias|da'   => \$opt{da},
   'listalias|la'     => \$opt{la},

   'listhistory|lh'   => \$opt{lh},
   'historyfile=s'    => \$opt{historyfile},
   'initialize'       => \$opt{initialize},
   'interactive'      => \$opt{interactive},
   'list'             => \$opt{list},
   'mode=s'           => \$opt{mode},
   'searchorder|so=s' => \$opt{searchorder},
   'statusfile=s'     => \$opt{statusfile},
   'verbose+'         => \$opt{verbose},
   'silent'           => \$opt{silent},
  )
  or pod2usage(2);

pod2usage(-exitval => 1, -output => \*STDERR ) if $opt{help};
pod2usage(-exitval => 0, -output => \*STDERR, -verbose => 2) if $opt{man};

SetDefaults(%opt, %optDefaults);

#print STDERR "DD: $optDefaults{aliasfile}\n";
#foreach my $e ( sort keys %opt )  {
#my $value = (defined($opt{$e}) ?  $opt{$e}  :  'NA');
#printf STDERR "\tDD: %-15s: %s\n", $e, $value;
#}
#
if ($opt{debuglog} ne "STDERR") {
   open(STDERR, "> $opt{debuglog}") or warn "Cannot open debug log file $opt{debuglog}: $!";
}

debug(20, "Program $0 has started");

###############################################################################
# Main section
###############################################################################

# start coding here

init;

ReadHash;

if (defined($opt{initialize})) {
   InitDataStructure;
   ReadAliasFile;
   ReadHistoryFile;
   WriteHash;
   exit 0;
} elsif (defined($opt{la})) {
   ListAlias;
   exit 0;
} elsif (defined($opt{aliasfile})  &&  $opt{aliasfile} ne '' ) {
   ReadAliasFile;
} elsif (defined($opt{lh})) {
   ListHistory;
   exit 0;
}

ClearHistory if defined($opt{CLEAR});
CreateAlias  if defined($opt{ca});
DeleteAlias  if defined($opt{da});


my $newdir = '';
if ( $opt{mode} eq 'dirs'  or $0 =~ m#dirs# ) {
   dirs;
} elsif ($opt{mode} eq 'popd'  or $0 =~ m#popd# ) {
   $newdir = popd;
} elsif ($opt{mode} eq 'pushd' or $0 =~ m#pushd# ) {
  $newdir = pushd(@ARGV);
} elsif ($opt{mode} eq 'cd' or $0 =~ m#cd# )  {

   $newdir = ParseInput(@ARGV);
}

if ( -d $newdir) {
   ChangeDirectory($newdir) if -d $newdir;
} else {
   PrintMessage(0, "No new directory found");
}
WriteHash;

# cleanly exit
debug(20, "Program $0 has ended");
exit(0);

###############################################################################
# Section with subroutines
###############################################################################
# -searchorder:  (-so): order to search for a directory. Can be:
#                D: physical directories
#                A: directory aliases
#                E: relative/absolute directory expansion
#                H: history
#                Default order: DAEH (case insensitive)

# #####################################
sub SearchDirectories(@) {
   debug(43, "Trying SearchDirectories now");
   my @args = @_;

   if ($#args == 0) {
      if (!defined($args[0])) {
         debug(11, "No argument is given (a), changing now to home directory");

         return $ldata{HOME};

      } elsif (-d $args[0]) {
         debug(11, "Argument is an existing directory, changing to it now");
         return $args[0];

      } elsif ($args[0] =~ m#^[\.]{3,}$#) {
         debug(11, "Argument is an existing directory, changing to it now");

         (my $dir = $args[0]) =~ s#^..##;
         $dir =~ s#\.#\.\./#g;
         $dir .= '../';

         return $dir;

      } elsif ($args[0] =~ '-') {
         debug(11, "Argument is -, previous directory, changing to it now");
      }
   } elsif ($#args == -1) {
      debug(11, "No argument is given, changing now to home directory");

      return $ldata{HOME};
   }
   debug(43, "\tfailed");
   return '';

}

# #####################################
sub SearchAliases(@) {
   debug(43, "Trying SearchAliases now");

   my $alias = shift;
   
   if ( exists($data{ALIAS}{$alias})  &&  defined($data{ALIAS}{$alias}{DIR})  )   {
      my $dir = $data{ALIAS}{$alias}{DIR};
      
      if ( -d $dir ) {
         PrintMessage (2, "Found alias $alias, expands to $dir");

         $data{ALIAS}{$alias}{AT}     = time();
         $data{ALIAS}{$alias}{COUNT} += 1;
         
         $data{ALIAS}{COUNTUSAGE}   += 1;
         $data{ALIAS}{LASTTIMEREAD}  = time();

         return $dir;
      } else {
         debug(11, "Directory $dir of alias $alias doesnot exist");
         PrintMessage (2, "Alias $alias is pointing to $dir which is not a directory or doesnot exist");
      }
   }
   
   debug(43, "\tfailed");
   return '';
}

# #####################################
sub SearchExpansion(@) {
   debug(43, "Trying SearchExpansion now");
   my $pattern = shift;
   my $DirNr = (defined($_[0]) && $_[0] =~ m#^\d+$# ? $_[0] : '');

   my @dirs;

   if (length($pattern) < 1) {
      debug(06, "WARN/sorry, you should give some argument");
      PrintMessage (1, "sorry, you should give some argument, without any I can only stop");
      exit 1;
   }

   my $startdir = '.';

   if (substr($pattern, 0, 1) eq '/') {
      $startdir = '/';
      $pattern = substr($pattern, 1);
   }

   my @dirparts = ();
   if ($pattern =~ m#/#) {
      @dirparts = split(/\//, $pattern);
      shift(@dirparts) if $dirparts[0] eq '';
   } else {
      @dirparts = split(//, $pattern);
   }

   if (substr($pattern, 0, 1) ne '/') {
      debug(14, "INFO/Trying to find directories with $pattern relative from here:");
      @dirs = ResolvePath('.', @dirparts);
   }

   if ($#dirs == -1) {
      debug(14, "INFO/Trying to find directories with $pattern from the root now\n");
      $pattern = substr($pattern, 1) if substr($pattern, 0, 1) eq '/';
      @dirs = ResolvePath('/', @dirparts);
   }

   if ($#dirs == -1) {

      # Didnot find anything

   } elsif ($#dirs == 0) {

      return $dirs[0];

   } else {
      my $NrItems = $#dirs + 1;
      PrintMessage (0, "Directory expansion did lead to multiple entries ($NrItems)");
      
      if ($DirNr =~ m#(\d+)$# ) {
         # here is assumed that the last numbers is a hint of which directory is used in the 
         # found list:
         my $i = $1 - 1;
         
         if ($i <= $#dirs ) {
            return $dirs[$i];
         } else {
            PrintMessage(1, "Asked for item $i, while we only have $NrItems.");
         }
         
      }

         my $i = 0;
         foreach my $dir (@dirs) {
            $i++;
            PrintMessage(1, sprintf("   %2d: %s", $i, $dir) );
         }

   }

   debug(43, "\tfailed");
   return '';
}

# #####################################
sub SearchHistory(@) {
   # 6. look in history:
   #    + do we have any entry in history with dir name ending with name 'arg'
   #    + do we have any entry in history with intermediate directory name
   #      equal to 'arg'
   #    + do we have any item in history which does have arg in the ending
   #      directory
   #    + do we anything in history with 'arg' somewhere within
   #    e. cd to the first found solution

   my $historydir = shift;   
 
   debug(43, "Trying SearchHistory now");
   # $data{HISTORY}{$newdir}{LASTACCESS} = time;
   # $data{HISTORY}{$newdir}{COUNT} += 1;
   
   # First try to find this in history entries ending with what is being asked:
   foreach my $dir ( sort {$data{HISTORY}{DATA}{$b}{LASTACCESS} <=> $data{HISTORY}{DATA}{$a}{LASTACCESS} }
                     keys %{$data{HISTORY}{DATA} } )  {

      next  unless $historydir =~ m#/$dir$|^$dir$#i;

      PrintMessage (3, "Found argument in history 1: $dir");
      return $dir ;                           
   }
   

   # Ok, let's try harder and try to find this in history entries with one of the subdirectories of what is being asked:
   foreach my $dir ( sort {$data{HISTORY}{DATA}{$b}{LASTACCESS} <=> $data{HISTORY}{DATA}{$a}{LASTACCESS} }
                     keys %{$data{HISTORY}{DATA} } )  {

      next  unless $historydir =~ m#/$dir/#i;

      PrintMessage (3, "Found argument in history 2: $dir");
      return $dir ;                           
   }
   

   # Ok, let's use brute force and try to find this in history entries even when it is partial part
   foreach my $dir ( sort {$data{HISTORY}{DATA}{$b}{LASTACCESS} <=> $data{HISTORY}{DATA}{$a}{LASTACCESS} }
                     keys %{$data{HISTORY}{DATA}} )  {

      next  unless $historydir =~ m#$dir#i;

      PrintMessage (3, "Found argument in history 3: $dir");
      return $dir ;                           
   }
   

   debug(43, "\tfailed");
   return '';
}

# #####################################
sub ParseInput(@) {

   my @args = @_;

   my @order = split(//, lc($opt{searchorder}));

   my $newdir = '';

   foreach my $order (@order) {
      $newdir = SearchDirectories(@args) if ($order eq 'd')  &&  ($newdir eq '');
      $newdir = SearchAliases(@args)     if ($order eq 'a')  &&  ($newdir eq '');
      $newdir = SearchExpansion(@args)   if ($order eq 'e')  &&  ($newdir eq '');
      $newdir = SearchHistory(@args)     if ($order eq 'h')  &&  ($newdir eq '');
   }

   return $newdir;
}

# #####################################
sub init() {

   my @userdetails = getpwnam(getpwuid($<));

   $ldata{HOME} = $userdetails[7];
   $ldata{PPID} = getppid;
   
   $ldata{PWD} =    ( defined($ENV{PWD})    ? $ENV{PWD}    : '');

}

# #####################################
sub ClearHistory() {
   PrintMessage (3, "Clear history now");
}

# #####################################
sub ChangeDirectory($) {
   my $newdir = shift;

   PrintMessage( 1, "Changing directory to $newdir now");
   $data{HISTORY}{DATA}{$newdir}{LASTACCESS} = time;
   $data{HISTORY}{DATA}{$newdir}{COUNT} += 1;
   
   print "cd $newdir\n";

   #exit;
}

# #####################################
sub ReadHash() {
   my $filename = ( $opt{statusfile} ne '' ? <$opt{statusfile}> : undef);

   return undef      unless (defined $filename);
   InitDataStructure unless -r $filename;

   PrintMessage (3, "Reading hash from $filename now");

   my $dataref;

   if (-e $filename) {
      $dataref = retrieve($filename);
      %data    = %{$dataref};
      debug(03, "Unable to open $filename: $! CONFIG") unless (defined $dataref);
      if ($data{GLOBAL}{VERSION} != $VERSION) {
         PrintMessage(0, "The stored data file is using version $data{GLOBAL}{VERSION} while I am at version $VERSION\n" .
             "It is better to do the following:\n" .
             "   $0 -initialize"
         );
      }
   }

   $data{GLOBAL}{ReadCount} += 1;
   $data{PROCESS}{$ldata{PPID}}{LastAccess} = time;

   if (!defined($data{PROCESS}{$ldata{PPID}}{LastDirectory})) {
      $data{PROCESS}{$ldata{PPID}}{LastDirectory} = '';
      $data{PROCESS}{$ldata{PPID}}{DIRSTACK}      = [];
   }

   $data{GLOBAL}{LASTACCESSED} = time  unless defined($data{GLOBAL}{LASTACCESSED});
   
   debug(30, "Timestamp status file: " . localtime($data{GLOBAL}{LASTACCESSED}) );

   foreach my $key (keys %{$data{GLOBAL}}) {
      debug(35, "RH/GLOBAL: $key  $data{GLOBAL}{$key}");
   }

   foreach my $key (keys %{$data{ALIAS}}) {
      debug(35, "RH/ALIAS: $key $data{ALIAS}{$key}");
   }

   foreach my $key (keys %{$data{PROCESS}}) {
      debug(35, "\nRH/Process number $key\n" . 
         "RH/PROCESS: LastAccess    " . localtime($data{PROCESS}{$key}{LastAccess}) . "\n" .
         "RH/PROCESS: LastDirectory $data{PROCESS}{$key}{LastDirectory}\n" .
         "RH/PROCESS: DIRSTACK      @{$data{PROCESS}{$key}{DIRSTACK}}");

   }

   debug(35, "RH/HISTORY: $data{HISTORY}{ITEM}{COUNT}");
   foreach my $key (%{$data{HISTORY}{NR}}) {
      debug(35, "RH/HISTORY: $key $data{HISTORY}{$key}");
   }

   return $dataref;
}

# #####################################
sub WriteHash() {

   # FAQ 4 for an example
   my $filename = ( $opt{statusfile} ne '' ? <$opt{statusfile}> : undef);

   return undef unless (defined $filename);

   PrintMessage(4, "Writing hash to $filename now");

   $data{GLOBAL}{LASTACCESSED}      = time;
   $data{GLOBAL}{ProcessLastAccess} = $ldata{PPID};
   $data{GLOBAL}{PWD}               = $ldata{PWD};

   # clean up old process data, this is data older than 7 days
   my $now = time();
   foreach my $PID ( keys %{$data{PROCESS}} )  {
      my $delta =  $now - $data{PROCESS}{$PID}{LastAccess};
      
      if ($delta > ( 7 * 24 * 3600) )  {
         PrintMessage(4, "Cleaning up data for PID $PID now");
         delete($data{PROCESS}{$PID}{DIRSTACK})      if defined($data{PROCESS}{$PID}{DIRSTACK});
         delete($data{PROCESS}{$PID}{LastAccess})    if defined($data{PROCESS}{$PID}{LastAccess});
         delete($data{PROCESS}{$PID}{LastDirectory}) if defined($data{PROCESS}{$PID}{LastDirectory});
         delete($data{PROCESS}{$PID})                if defined($data{PROCESS}{$PID});
      }
   }

   # clean up old history information.
   # strategy:
   # . last access more than 14 days ago than remove!
   
   foreach my $dir ( keys %{$data{HISTORY}{DATA}}  ) {

      next if $dir =~ m#^(ITEM|NR)$#;
    
      if ( $data{HISTORY}{DATA}{$dir}{LASTACCESS} <= (time() - 14 * 24 * 3600) ) {
         PrintMessage(4, "Cleaning up historic data for dir $dir now");
         delete($data{HISTORY}{DATA}{$dir}{LASTACCESS});
         delete($data{HISTORY}{DATA}{$dir}{COUNT});
         delete($data{HISTORY}{DATA}{$dir});
      }
   }

   my $ref = \%data;

   if (defined $ref) {
      store($ref, $filename)
        or debug(03, "SCRIPT-RESULT #NoResource 2 360 Unable to store data in $filename CONFIG");
   }
}

# #####################################
sub InitDataStructure() {
   %data = ();    # clear the datastructure

   $data{GLOBAL}{VERSION}           = $VERSION;
   $data{GLOBAL}{ReadCount}         = 0;
   $data{GLOBAL}{LastAccess}        = time;
   $data{GLOBAL}{ProcessLastAccess} = $ldata{PPID};

   $data{ALIAS}{COUNTUSAGE}   = 0;
   $data{ALIAS}{LASTTIMEREAD} = 0;

   $data{PROCESS}{$ldata{PPID}}{LastAccess}    = time;
   $data{PROCESS}{$ldata{PPID}}{LastDirectory} = '';
   $data{PROCESS}{$ldata{PPID}}{DIRSTACK}      = [];

   $data{HISTORY}{ITEM}{COUNT} = 0;

   # VERSION: version of datastructure
   # ALIAS list:
   #       + alias
   #       + directory
   #       + usage count
   #       + timestamp created
   #       + timestamp last access
   # DIRS list:
   #       + per PPID (to guarantee best that some other process is not changing
   #         this list for this process)
   #       + order number
   #       + directory name
   #       + timestamp
   # HISTORY list:
   #       + directory name
   #       + order number
   #       + timestamp created
   #       + timestamp last access
   #       + usage count
   #       + status (locked entry)

}

# #####################################
sub ReadAliasFile() {
   # Read alias file 

   my $filename = ( $opt{aliasfile} ne '' ? <$opt{aliasfile}> : undef);
   
   return undef      unless (defined $filename);

   PrintMessage (3, "Reading aliases from $filename now");

   if (open(FIN, $filename)) {
    
       while ( <FIN> )  {
          next if m/^\s*#/;
          next unless m#\s*(\S+)\s+(\S+)#;

          my ($alias, $value) = ($1, $2);
          my $ForceAliasUsage = '';
          
          if ( $alias =~ m#\s*\*# )  {
             $ForceAliasUsage = '*';
             $alias =~ s#\s*\*##;
          }
          
          
          if ( (! -d $value)  &&  ($ForceAliasUsage ne '*') ) {
             PrintMessage (0, "Directory $value doesnot exist (alias: $alias)");
             next;
          }
          
          if ( defined($data{ALIAS}{$alias}{DIR})  &&  ($data{ALIAS}{$alias}{DIR} ne $value) ) {
             PrintMessage (2, "Updating alias $alias with value $value now (previous value: $data{ALIAS}{A}{$alias}");
             $data{ALIAS}{$alias}{DIR} = $value;
             $data{ALIAS}{$alias}{AT} = time();
             $data{ALIAS}{$alias}{CT} = time();
             $data{ALIAS}{$alias}{COUNT} = 0;
          
          } elsif  ( ! defined($data{ALIAS}{$alias}{DIR}) )  {
             PrintMessage (2, "Adding new alias $alias with value $value now.");
             $data{ALIAS}{$alias}{DIR} = $value;
             $data{ALIAS}{$alias}{AT} = time();
             $data{ALIAS}{$alias}{CT} = time();
             $data{ALIAS}{$alias}{COUNT} = 0;
             PrintMessage (2, "Alias details: $alias -> $data{ALIAS}{$alias}{DIR} $data{ALIAS}{$alias}{AT} - $data{ALIAS}{$alias}{CT} $data{ALIAS}{$alias}{COUNT}");
             
          } ;
          
       }
       close FIN;
    
   } else {
      PrintMessage(1, "Couldnot open alias file $filename for reading");
      
   }
   
   
}

# #####################################
sub ReadHistoryFile() {
   # Read history file 

   my $filename = ( $opt{historyfile} ne '' ? <$opt{historyfile}> : undef);
   
   return undef      unless (defined $filename);

   PrintMessage (3, "Reading history from $filename now");
}

# #####################################
sub CreateAlias() {
   PrintMessage (3, "Creating alias now");
}

# ##########
sub ResolvePath ($@) {
   my $startDIR = shift;
   my @pattern  = @_;

   my $ID = "|$startDIR | @pattern|";

   return () if (!-d $startDIR) or ($#pattern == -1) or (length($pattern[0]) == 0);

   # find all directories in subdir $startDIR
   my @dirs = ();
   my $ci   = '';    # case (in)sensitive search, use PERL (?i) RE modifier for this
   $ci = '(?i)' unless $pattern[0] =~ m#[A-Z]# or $opt{case};
   opendir(DIR, $startDIR) or return ();
   @dirs = grep { $_ ne '.' && $_ ne '..' && m#${ci}^$pattern[0]# && -d "$startDIR/$_" } readdir(DIR);
   closedir DIR;

   # ok, now we know the subdirectories, do we need to know more for other subdirectories,
   # or can we stop?
   my @newpattern = @pattern;
   shift(@newpattern);    # get rid of the 1st element

   if ($#newpattern == -1) {

      # here we can stop, first correct the directories by adding the startPATH to it, and
      # remove double //
      for (my $i = 0 ; $i <= $#dirs ; $i++) {
         $dirs[$i] = "$startDIR/$dirs[$i]";
         $dirs[$i] =~ s#//#/#g;
      }
      return @dirs;
   } else {

      # here we have to find other directories below the found ones:
      my @subdirs = ();

      foreach my $dir (@dirs) {
         my $subdir = ($startDIR ne '/' ? $startDIR : '');
         push(@subdirs, ResolvePath("$subdir/$dir", @newpattern));
      }
      return @subdirs;
   }

}

# #####################################
sub ExpandSC($) {

}

# #####################################
sub DeleteAlias() {
}

# #####################################
sub ListAlias() {

   # This routine will print out all defined aliases
   PrintMessage (3, "Listing known aliases now");

   PrintMessage (0, "Aliases usage: $data{ALIAS}{COUNTUSAGE}, last time used: " . localtime($data{ALIAS}{LASTTIMEREAD}) );
   PrintMessage (0, "");
   my $details = '   #';
   $details = sprintf("%25s %4s",  "Access time", "#") if $opt{verbose} == 2;
   $details = sprintf("%25s %25s %4s",  "Access time", "Create time", "#") if $opt{verbose} >= 3;
   PrintMessage (0, sprintf("%5s     %-50s  %-36s", "alias", "dir", $details));

   foreach my $alias ( sort keys %{$data{ALIAS}} )  {
      next if $alias =~ m#^(COUNTUSAGE|LASTTIMEREAD)$#;

      my $dir     = ( defined($data{ALIAS}{$alias}{DIR}) ?  $data{ALIAS}{$alias}{DIR} : 'NODIR' );
      my $time_at = ( defined($data{ALIAS}{$alias}{AT}) ? localtime($data{ALIAS}{$alias}{AT}) : 'NOAT');
      my $time_ct = ( defined($data{ALIAS}{$alias}{CT}) ? localtime($data{ALIAS}{$alias}{CT}) : 'NOCT');
      my $count   = ( defined($data{ALIAS}{$alias}{COUNT}) ? $data{ALIAS}{$alias}{COUNT}  : -1 );

      my $details = '';
      $details = sprintf("%25s %25s %4d", $time_at, $time_ct, $count)    if $opt{verbose} >= 3;
      $details = sprintf("%25s %4d",      $time_at, $count)              if $opt{verbose} == 2;
      $details = sprintf("%4d",           $count)                        if $opt{verbose} == 1;

      my $ReadFlag = ( -r $dir ? '' : '*');
      PrintMessage(0, sprintf("%5s%1s -> %-50s  %-36s", $alias, $ReadFlag, $dir, $details) );

   }
   PrintMessage (0, "");
   PrintMessage (0, "     *  : directories are NOT readable.");

}

# #####################################
sub ListHistory() {
   # This routine will print out the history information
   PrintMessage (3, "Listing history now");
   PrintMessage (0, sprintf("%-24s %3s  %s", 'Date', '#', 'Directory'));

   foreach my $dir ( sort {$data{HISTORY}{DATA}{$b}{LASTACCESS} <=> $data{HISTORY}{DATA}{$a}{LASTACCESS} }
                     keys %{$data{HISTORY}{DATA}} )  {

      next if $dir =~ m#^(ITEM|NR)$#;

      my $time_at = localtime($data{HISTORY}{DATA}{$dir}{LASTACCESS});
      my $count = $data{HISTORY}{DATA}{$dir}{COUNT};
      PrintMessage(0, sprintf("%24s %3d  %s", $time_at, $count, $dir) );

   }

}

# #####################################
sub dirs() {
   debug (35, "mode: dirs");

   if (defined(@{$data{PROCESS}{$ldata{PPID}}{DIRSTACK}})) {
      foreach my $dir (@{$data{PROCESS}{$ldata{PPID}}{DIRSTACK}}) {
         print "$dir\n";
      }
   }
   exit;
}

# #####################################
sub pushd(@) {
   debug (35, "mode: pushd");

   my $dir = ParseInput(@_);
   push(@{$data{PROCESS}{$ldata{PPID}}{DIRSTACK}}, $dir) if $dir ne '';
   return $dir;
}

# #####################################
sub popd() {
   debug (35, "mode: popd");

   my $dir = '';

   if ($#{$data{PROCESS}{$ldata{PPID}}{DIRSTACK}}) {
      $dir = pop(@{$data{PROCESS}{$ldata{PPID}}{DIRSTACK}});
   } else {
      PrintMessage(1, "There is really nothing on the stack now, so cannot help you here!");
   }

   return $dir;
}


# #####################################
sub PrintMessage($$) {
    my $level = shift;
    my $message = shift;
    
    print STDERR "$message\n"  if $level <= $opt{verbose}  && ! $opt{silent};
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

   my $date = localtime();

   printf STDERR "%s - %3.3d - %s\n", $date, $level, $message if $level <= $opt{debug};
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
