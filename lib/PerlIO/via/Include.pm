package PerlIO::via::Include;

# Set the version info
# Make sure we do things by the book from now on

$VERSION = '0.02';
use strict;

# Set default before string
# Set default after string
# Set default regexp string

my $before = '^#include ';
my $after = "\n";
my $regexp;

# Satisfy -require-

1;

#-----------------------------------------------------------------------

# Class methods

#-----------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new value for default before string
# OUT: 1 current default before string

sub before {

# If new before string specified
#  Set it
#  Reset the regular expression
# Return current default before string

    if (@_ >1) {
        $before = $_[1];
        $regexp = undef;
    }
    $before;
} #before

#-----------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new value for default after string
# OUT: 1 current default after string

sub after {

# If new after string specified
#  Set it
#  Reset the regular expression
# Return current default after string

    if (@_ >1) {
        $after = $_[1];
        $regexp = undef;
    }
    $after;
} #after

#-----------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new value for default regular expression string
# OUT: 1 current default regular expression string

sub regexp {

# If new regular expression specified
#  Set it
#  Reset the before and after strings
# Return current default regular expression

    $regexp = $_[1] if @_ >1;
    if (@_ >1) {
        $regexp = $_[1];
        $before = $after = undef;
    }
    $regexp;
} #regexp

#-----------------------------------------------------------------------

# Subroutines for standard Perl features

#-----------------------------------------------------------------------
#  IN: 1 class to bless with
#      2 mode string (ignored)
#      3 file handle of PerlIO layer below (ignored)
# OUT: 1 blessed object

sub PUSHED { 

# Die now if strange mode
# Create the object with the right fields

#    die "Can only read or write with file inclusion" unless $_[1] =~ m#^[rw]$#;
    bless {
     regexp => $regexp ? $regexp : qr/$before(.*?)$after/,
    },$_[0];
} #PUSHED

#-----------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 handle to read from
# OUT: 1 processed string

sub FILL {

# Obtain local copy of the regular expression
# If there is a line to be read from the handle
#  Perform any inclusion
#  Return the result
# Return indicating end reached

    my $regexp = $_[0]->{'regexp'};
    if (defined( my $line = readline( $_[1] ) )) {
        $line =~ s#$regexp#_include( $1 )#gse;
	return $line;
    }
    undef;
} #FILL

#-----------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 buffer to be written
#      3 handle to write to
# OUT: 1 number of bytes written

sub WRITE {

# Obtain local copy of the regular expression
# For all of the lines in this bunch (includes delimiter at end)
#  Perform any inclusions
#  Print the line, return now if failed
# Return total number of octets handled

    my $regexp = $_[0]->{'regexp'};
    foreach (split( m#(?<=$/)#,$_[1] )) {
	s#$regexp#_include( $1 )#gse;
        return -1 unless print {$_[2]} $_;
    }
    length( $_[1] );
} #WRITE

#-----------------------------------------------------------------------
#  IN: 1 class for which to import
#      2..N parameters passed with -use-

sub import {

# Obtain the parameters
# Loop for all the value pairs specified

    my ($class,%param) = @_;
    $class->$_( $param{$_} ) foreach keys %param;
} #import

#-----------------------------------------------------------------------

# Internal subroutines

#-----------------------------------------------------------------------
#  IN: 1 filename to open and include
# OUT: 1 contents of the whole file

sub _include {

# Attempt to open the handle, return error message if failed

    open( my $handle,"<:via(Include)",$_[0] )
     or return "*** Could not open '$_[0]': $! ***";

# Initialize contents
# Localize $_ (make sure we can be recursive)
# Get all the contents of the file line by line
# Return the contents

    my $contents = '';
    local( $_ );
    $contents .= $_ while readline( $handle );
    $contents;
} #_include

#-----------------------------------------------------------------------

__END__

=head1 NAME

PerlIO::via::Include - PerlIO layer for including other files

=head1 SYNOPSIS

 use PerlIO::via::Include;
 PerlIO::via::Include->before( "^#include " );
 PerlIO::via::Include->after( "\n" );
 PerlIO::via::Include->regexp( qr/^#include(.*?)\n/ );

 use PerlIO::via::Include before => "^#include ", after => "\n";

 open( my $in,'<:via(Include)','file' )
  or die "Can't open file for reading: $!\n";
 
 open( my $out,'>:via(Include)','file' )
  or die "Can't open file for writing: $!\n";

=head1 DESCRIPTION

This module implements a PerlIO layer that includes other files, as indicated
by a special string, on input B<and> on output.  It is intended as a
development tool only, but may have uses outside of development.

The regular expression indicating the filename of a file to be included, can
be specified either with the L<before> and L<after> class methods, or as a
regular expression with the L<regexp> class method.

=head1 CLASS METHODS

The following class methods allow you to alter certain characteristics of
the file inclusion process.  Ordinarily, you would expect these to be
specified as parameters during the process of opening a file.  Unfortunately,
it is not yet possible to pass parameters with the PerlIO::via module.

Therefore an approach with class methods was chosen.  Class methods that can
also be called as key-value pairs in the C<use> statement.

Please note that the new value of the class methods that are specified, only
apply to the file handles that are opened (or to which the layer is assigned
using C<binmode()>) B<after> they have been changed.

=head2 before

 use PerlIO::via::Include before => "^#include ";
 
 PerlIO::via::Include->before( "^#include " );
 my $before = PerlIO::via::Include->before;

The class method "before" returns the string that should be before the file
specification in the regular expression that will be used to include other
files.  The optional input parameter specifies the string that should be
before the file specification in the regular expression that will be used
for any files that are opened in the future.  The default is '^#include '.

See the L<after> method for specifying the string after the filename
specification.  See the L<regexp> method for specifying the regular
expression as a regular expression.

=head2 after

 use PerlIO::via::Include after => "\n";
 
 PerlIO::via::Include->after( "\n" );
 my $after = PerlIO::via::Include->after;

The class method "after" returns the string that should be after the file
specification in the regular expression that will be used to include other
files.  The optional input parameter specifies the string that should be
after the file specification in the regular expression that will be used
for any files that are opened in the future.  The default is "\n" (indicating
the end of the line).

See the L<before> method for specifying the string before the filename
specification.  See the L<regexp> method for specifying the regular
expression as a regular expression.

=head2 regexp

 use PerlIO::via::Include regexp => qr/^#include(.*?)\n/;
 
 PerlIO::via::Include->regexp( qr/^#include(.*?)\n/ );
 my $regexp = PerlIO::via::Include->regexp;

The class method "regexp" returns the regular expression that will be used
to include other files.  The optional input parameter specifies the regular
expression that will be used for any files that are opened in the future.
The default is to use what is (implicitely) specified with L<before> and
L<after>.

=head1 EXAMPLES

Here will be some examples, some may even be useful.

=head1 SEE ALSO

L<PerlIO::via> and any other PerlIO::via modules on CPAN.

=head1 COPYRIGHT

Copyright (c) 2002-2003 Elizabeth Mattijsen.  All rights reserved.  This
library is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
