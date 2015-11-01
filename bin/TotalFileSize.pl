#!/usr/bin/perl
# vim: set autoindent filetype=perl tabstop=3 shiftwidth=3 softtabstop=3 number textwidth=175 expandtab:
#===============================================================================
#
#         FILE:  TotalFileSize.pl
#
#        USAGE:  ./TotalFileSize.pl
#
#  DESCRIPTION:  Passes objects log files which needs to be HCAP archived,
#                when using the -v switch.
#
#       AUTHOR:  Marcel (MCMD), mcmd1962@
#      COMPANY:  XXX, Amsterdam, NL
#      VERSION:  1.0
#      CREATED:  20120113 02:11:21 PM
#
#      HISTORY:
#                + 20120113/MCMD: Creation of script
#===============================================================================

use strict;
use warnings;

my $CummulativeFilesize   = 0;
my $CountExistingFiles    = 0;
my $CountNotExistingFiles = 0;

my @files = ();
foreach my $pattern ( @ARGV )  {
   push(@files, glob($pattern))
}


foreach my $file ( @files )  {
   if ( -r $file  )  {
      $CountExistingFiles  +=         1;
      $CummulativeFilesize +=  -s $file;
   }  else  {
      $CountNotExistingFiles += 1;
      print STDERR "ERROR: expected to find file $file, but didnot ...\n";
   }
}

printf "\nCount files: %3d files exists, %3d do not exist\n", $CountExistingFiles, $CountNotExistingFiles;
printf "Size existing files:\n\t%14s B / %10s KB / %6s MB / %6.2f GB\n", 
              TS($CummulativeFilesize), TS(int($CummulativeFilesize / 1024)), TS(int($CummulativeFilesize / 1024**2)), $CummulativeFilesize / 1024**3;


sub TS {
   my $number = shift;
   $number =~ s#(\d{1,3}?)(?=(\d{3})+$)#$1,#g;

   return $number;
}

