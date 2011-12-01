# $Id: CaptureOutput.pm,v 1.3 2005/03/25 12:44:14 simonflack Exp $
package IO::CaptureOutput;
use strict;
use vars qw/$VERSION @ISA @EXPORT_OK %EXPORT_TAGS $CarpLevel/;
use Exporter;
use Carp qw/croak/;
@ISA = 'Exporter';
@EXPORT_OK = qw/capture capture_exec qxx capture_exec_combined qxy/;
%EXPORT_TAGS = (all => \@EXPORT_OK);
$VERSION = '1.1102';
$VERSION = eval $VERSION; ## no critic
$CarpLevel = 0; # help capture report errors at the right level

sub _capture (&@) { ## no critic
    my ($code, $output, $error, $output_file, $error_file) = @_;

    # check for valid combinations of input
    {
      local $Carp::CarpLevel = 1;
      my $error = _validate($output, $error, $output_file, $error_file);
      croak $error if $error;
    }

    # if either $output or $error are defined, then we need a variable for 
    # results; otherwise we only capture to files and don't waste memory
    if ( defined $output || defined $error ) {
      for ($output, $error) {
          $_ = \do { my $s; $s = ''} unless ref $_;
          $$_ = '' if $_ != \undef && !defined($$_);
      }
    }

    # merge if same refs for $output and $error or if both are undef -- 
    # i.e. capture \&foo, undef, undef, $merged_file
    # this means capturing into separate files *requires* at least one
    # capture variable
    my $should_merge = 
      (defined $error && defined $output && $output == $error) || 
      ( !defined $output && !defined $error ) || 
      0;

    my ($capture_out, $capture_err);

    # undef means capture anonymously; anything other than \undef means 
    # capture to that ref; \undef means skip capture
    if ( !defined $output || $output != \undef ) { 
        $capture_out = IO::CaptureOutput::_proxy->new(
            'STDOUT', $output, undef, $output_file
        );
    }
    if ( !defined $error || $error != \undef ) { 
        $capture_err = IO::CaptureOutput::_proxy->new(
            'STDERR', $error, ($should_merge ? 'STDOUT' : undef), $error_file
        );
    }

    # now that output capture is setup, call the subroutine
    # results get read when IO::CaptureOutput::_proxy objects go out of scope
    &$code();
}

# Extra indirection for symmetry with capture_exec, etc.  Gets error reporting
# to the right level
sub capture (&@) { ## no critic
    return &_capture; 
}

sub capture_exec {
    my @args = @_;
    my ($output, $error);
    my $exit = _capture sub { system _shell_quote(@args) }, \$output, \$error;
    my $success = ($exit == 0 ) ? 1 : 0 ;
    $? = $exit;
    return wantarray ? ($output, $error, $success, $exit) : $output;
}

*qxx = \&capture_exec;

sub capture_exec_combined {
    my @args = @_;
    my $output;
    my $exit = _capture sub { system _shell_quote(@args) }, \$output, \$output;
    my $success = ($exit == 0 ) ? 1 : 0 ;
    $? = $exit;
    return wantarray ? ($output, $success, $exit) : $output;
}

*qxy = \&capture_exec_combined;

# extra quoting required on Win32 systems
*_shell_quote = ($^O =~ /MSWin32/) ? \&_shell_quote_win32 : sub {@_};
sub _shell_quote_win32 {
    my @args;
    for (@_) {
        if (/[ \"]/) { # TODO: check if ^ requires escaping
            (my $escaped = $_) =~ s/([\"])/\\$1/g;
            push @args, '"' . $escaped . '"';
            next;
        }
        push @args, $_
    }
    return @args;
}

# detect errors and return an error message or empty string;
sub _validate {
    my ($output, $error, $output_file, $error_file) = @_;

    # default to "ok"
    my $msg = q{};

    # \$out, \$out, $outfile, $errfile
    if (    defined $output && defined $error  
        &&  defined $output_file && defined $error_file
        &&  $output == $error
        &&  $output != \undef
        &&  $output_file ne $error_file
    ) {
      $msg = "Merged STDOUT and STDERR, but specified different output and error files";
    }
    # undef, undef, $outfile, $errfile
    elsif ( !defined $output && !defined $error  
        &&  defined $output_file && defined $error_file
        &&  $output_file ne $error_file
    ) {
      $msg = "Merged STDOUT and STDERR, but specified different output and error files";
    }

    return $msg;
}

# Captures everything printed to a filehandle for the lifetime of the object
# and then transfers it to a scalar reference
package IO::CaptureOutput::_proxy;
use File::Temp 'tempfile';
use File::Basename qw/basename/;
use Symbol qw/gensym qualify qualify_to_ref/;
use Carp;

sub _is_wperl { $^O eq 'MSWin32' && basename($^X) eq 'wperl.exe' }

sub new {
    my $class = shift;
    my ($orig_fh, $capture_var, $merge_fh, $capture_file) = @_;
    $orig_fh       = qualify($orig_fh);         # e.g. main::STDOUT
    my $fhref = qualify_to_ref($orig_fh);  # e.g. \*STDOUT

    # Duplicate the filehandle
    my $saved_fh;
    {
        no strict 'refs'; ## no critic - needed for 5.005
        if ( defined fileno($orig_fh) && ! _is_wperl() ) {
            $saved_fh = gensym;
            open $saved_fh, ">&$orig_fh" or croak "Can't redirect <$orig_fh> - $!";
        }
    }

    # Create replacement filehandle if not merging
    my ($newio_fh, $newio_file);
    if ( ! $merge_fh ) {
        $newio_fh = gensym;
        if ($capture_file) {
            $newio_file = $capture_file;
        } else {
            (undef, $newio_file) = tempfile;
        }
        open $newio_fh, "+>$newio_file" or croak "Can't write temp file for $orig_fh - $!";
    }
    else {
        $newio_fh = qualify($merge_fh);
    }

    # Redirect (or merge)
    {
        no strict 'refs'; ## no critic -- needed for 5.005
        open $fhref, ">&".fileno($newio_fh) or croak "Can't redirect $orig_fh - $!";
    }

    bless [$$, $orig_fh, $saved_fh, $capture_var, $newio_fh, $newio_file, $capture_file], $class;
}

sub DESTROY {
    my $self = shift;

    my ($pid, $orig_fh, $saved_fh, $capture_var, $newio_fh, 
      $newio_file, $capture_file) = @$self;
    return unless $pid eq $$; # only cleanup in the process that is capturing

    # restore the original filehandle
    my $fh_ref = Symbol::qualify_to_ref($orig_fh);
    select((select ($fh_ref), $|=1)[0]);
    if (defined $saved_fh) {
        open $fh_ref, ">&". fileno($saved_fh) or croak "Can't restore $orig_fh - $!";
    }
    else {
        close $fh_ref;
    }

    # transfer captured data to the scalar reference if we didn't merge
    # $newio_file is undef if this file handle is merged to another
    if (ref $capture_var && $newio_file) {
        # some versions of perl complain about reading from fd 1 or 2
        # which could happen if STDOUT and STDERR were closed when $newio
        # was opened, so we just squelch warnings here and continue
        local $^W; 
        seek $newio_fh, 0, 0;
        $$capture_var = do {local $/; <$newio_fh>};
    }
    close $newio_fh if $newio_file;

    # Cleanup
    return unless defined $newio_file && -e $newio_file;
    return if $capture_file; # the "temp" file was explicitly named
    unlink $newio_file or carp "Couldn't remove temp file '$newio_file' - $!";
}

1;

__END__

=pod

=begin wikidoc

= NAME

IO::CaptureOutput - capture STDOUT and STDERR from Perl code, subprocesses or XS

= VERSION

This documentation describes version %%VERSION%%.

= SYNOPSIS

    use IO::CaptureOutput qw(capture qxx qxy);

    # STDOUT and STDERR separately
    capture { noisy_sub(@args) } \$stdout, \$stderr;

    # STDOUT and STDERR together
    capture { noisy_sub(@args) } \$combined, \$combined;

    # STDOUT and STDERR from external command
    ($stdout, $stderr, $success) = qxx( @cmd );

    # STDOUT and STDERR together from external command
    ($combined, $success) = qxy( @cmd );

= DESCRIPTION

This module provides routines for capturing STDOUT and STDERR from perl 
subroutines, forked system calls (e.g. {system()}, {fork()}) and from 
XS or C modules.

= FUNCTIONS

The following functions will be exported on demand.

== capture()

    capture \&subroutine, \$stdout, \$stderr;

Captures everything printed to {STDOUT} and {STDERR} for the duration of
{&subroutine}. {$stdout} and {$stderr} are optional scalars that will contain
{STDOUT} and {STDERR} respectively. 

{capture()} uses a code prototype so the first argument can be specified directly within 
brackets if desired.

    # shorthand with prototype
    capture { print __PACKAGE__ } \$stdout, \$stderr;

Returns the return value(s) of {&subroutine}. The sub is called in the same
context as {capture()} was called e.g.:

    @rv = capture { wantarray } ; # returns true
    $rv = capture { wantarray } ; # returns defined, but not true
    capture { wantarray };       # void, returns undef

{capture()} is able to capture output from subprocesses and C code, which
traditional {tie()} methods of output capture are unable to do.

*Note:* {capture()} will only capture output that has been written or flushed
to the filehandle.

If the two scalar references refer to the same scalar, then {STDERR} will be
merged to {STDOUT} before capturing and the scalar will hold the combined
output of both.

    capture \&subroutine, \$combined, \$combined;

Normally, {capture()} uses anonymous, temporary files for capturing output.
If desired, specific file names may be provided instead as additional options.

    capture \&subroutine, \$stdout, \$stderr, $out_file, $err_file;

Files provided will be clobbered, overwriting any previous data, but
will persist after the call to {capture()} for inspection or other manipulation.

By default, when no references are provided to hold STDOUT or STDERR, output
is captured and silently discarded.

    # Capture STDOUT, discard STDERR
    capture \&subroutine, \$stdout;

    # Discard STDOUT, capture STDERR
    capture \&subroutine, undef, \$stderr;

However, even when using {undef}, output can be captured to specific files.

    # Capture STDOUT to a specific file, discard STDERR
    capture \&subroutine, \$stdout, undef, $outfile;

    # Discard STDOUT, capture STDERR to a specific file
    capture \&subroutine, undef, \$stderr, undef, $err_file;

    # Discard both, capture merged output to a specific file
    capture \&subroutine, undef, undef, $mergedfile;

It is a fatal error to merge STDOUT and STDERR and request separate, specific
files for capture.

    # ERROR:
    capture \&subroutine, \$stdout, \$stdout, $out_file, $err_file;
    capture \&subroutine, undef, undef, $out_file, $err_file;

If either STDOUT or STDERR should be passed through to the terminal instead of
captured, provide a reference to undef -- {\undef} -- instead of a capture
variable.

    # Capture STDOUT, display STDERR
    capture \&subroutine, \$stdout, \undef;

    # Display STDOUT, capture STDERR
    capture \&subroutine, \undef, \$stderr;

== capture_exec()

    ($stdout, $stderr, $success, $exit_code) = capture_exec(@args);

Captures and returns the output from {system(@args)}. In scalar context,
{capture_exec()} will return what was printed to {STDOUT}. In list context,
it returns what was printed to {STDOUT} and {STDERR} as well as a success
flag and the exit value.

    $stdout = capture_exec('perl', '-e', 'print "hello world"');

    ($stdout, $stderr, $success, $exit_code) = 
        capture_exec('perl', '-e', 'warn "Test"');

{capture_exec} passes its arguments to {system()} and on MSWin32 will protect
arguments with shell quotes if necessary.  This makes it a handy and slightly
more portable alternative to backticks, piped {open()} and {IPC::Open3}.

The {$success} flag returned will be true if the command ran successfully and
false if it did not (if the command could not be run or if it ran and
returned a non-zero exit value).  On failure, the raw exit value of the
{system()} call is available both in the {$exit_code} returned and in the {$?}
variable.

  ($stdout, $stderr, $success, $exit_code) = 
      capture_exec('perl', '-e', 'warn "Test" and exit 1');

  if ( ! $success ) {
      print "The exit code was " . ($exit_code >> 8) . "\n";
  }

See [perlvar] for more information on interpreting a child process
exit code.

== capture_exec_combined()

    ($combined, $success, $exit_code) = capture_exec_combined(
        'perl', '-e', 'print "hello\n"', 'warn "Test\n"
    );

This is just like {capture_exec()}, except that it merges {STDERR} with {STDOUT}
before capturing output.

*Note:* there is no guarantee that text printed to {STDOUT} and {STDERR} in the
subprocess will be appear in order. The actual order will depend on how IO
buffering is handled in the subprocess.

== qxx()

This is an alias for {capture_exec()}.

== qxy()

This is an alias for {capture_exec_combined()}.

= SEE ALSO

* [IPC::Open3]
* [IO::Capture]
* [IO::Utils]
* [IPC::System::Simple]

= AUTHORS

* Simon Flack <simonflk _AT_ cpan.org> (original author)
* David Golden <dagolden _AT_ cpan.org> (co-maintainer since version 1.04)

= COPYRIGHT AND LICENSE

Portions copyright 2004, 2005 Simon Flack.  Portions copyright 2007, 2008 David
Golden.  All rights reserved.

You may distribute under the terms of either the GNU General Public License or
the Artistic License, as specified in the Perl README file.

=end wikidoc 

=cut
