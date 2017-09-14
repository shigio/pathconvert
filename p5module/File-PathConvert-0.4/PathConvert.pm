#
# Copyright (c) 1996, 1997, 1998 Shigio Yamaguchi. All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#	File::PathConvert.pm
#
#				8-Mar-1998 Shigio Yamaguchi
#
package File::PathConvert;
$VERSION = '0.4';

require 5.002;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(realpath abs2rel rel2abs $maxsymlinks $verbose $SL $resolved);
use Cwd;
#
# instant configration
#
$maxsymlinks = 32;		# allowed symlink number in a path
$verbose = 0;			# 1: verbose on, 0: verbose off
$SL = '/';			# separator
#
# realpath: returns the canonicalized absolute path name
#
# Interface:
#	i)	$path	path
#	r)		resolved name on success else undef
#	go)	$resolved
#			resolved name on success else the path name which
#			caused the problem.
	$resolved = '';
#
#	Note: this implementation is based 4.4BSD version realpath(3).
#
sub realpath($;) {
    ($resolved) = @_;
    my($backdir) = cwd();
    my($dirname, $basename, $links, $reg);

    regularize($resolved);
LOOP:
    {
	#
	# Find the dirname and basename.
	# Change directory to the dirname component.
	#
	if ($resolved =~ /$SL/) {
	    $reg = '^(.*)' . $SL . '([^' . $SL . ']*)$';
	    ($dirname, $basename) = $resolved =~ /$reg/;
	    $dirname = $SL if (!$dirname);
	    $resolved = $dirname;
	    unless (chdir($dirname)) {
		warn("realpath: chdir($dirname) failed: $! (in ${\cwd()}).") if $verbose;
		chdir($backdir);
		return undef;
	    }
	} else {
	    $dirname = '';
	    $basename = $resolved;
	}
	#
	# If it is a symlink, read in the value and loop.
	# If it is a directory, then change to that directory.
	#
	if ($basename) {
	    if (-l $basename) {
		unless ($resolved = readlink($basename)) {
		    warn("realpath: readlink($basename) failed: $! (in ${\cwd()}).") if $verbose;
		    chdir($backdir);
		    return undef;
		}
		$basename = '';
		if (++$links > $maxsymlinks) {
		    warn("realpath: too many symbolic links: $links.") if $verbose;
		    chdir($backdir);
		    return undef;
		}
		redo LOOP;
	    } elsif (-d _) {
		unless (chdir($basename)) {
		    warn("realpath: chdir($basename) failed: $! (in ${\cwd()}).") if $verbose;
		    chdir($backdir);
		    return undef;
		}
		$basename = '';
	    }
	}
    }
    #
    # Get the current directory name and append the basename.
    #
    $resolved = cwd();
    if ($basename) {
	$resolved .= $SL if ($resolved ne $SL);
	$resolved .= $basename
    }
    chdir($backdir);
    return $resolved;
}
#
# abs2rel: make a relative pathname from an absolute pathname
#
# Interface:
#	i)	$path	absolute path(needed)
#	i)	$base	base directory(optional)
#	r)		relative path of $path
#
#	Note:	abs2rel doesn't check whether the specified path exist or not.
#
sub abs2rel($;$;) {
    my($path, $base) = @_;
    my($reg, $common);

    $reg = '^' . $SL;
    if ($path !~ /$reg/) {
	warn("abs2rel: nothing to do.($path)") if $verbose;
	return $path;
    }
    if (!$base) {
	$base = cwd();
    } elsif ($base !~ /$reg/) {
	$base = cwd() . $SL . $base;
    }
    regularize($path);
    regularize($base);
    $reg = $SL . '[^' . $SL . ']+' . $SL . '\.\.';
    while ($base =~ /$reg/) {
	$base =~ s/$reg//;			# trim path/..
    }
    $common = common($path, $base);
    $path =~ s/$common//;
    $base =~ s/$common//;
    $reg = '^'. $SL;
    $path =~ s/$reg//;
    $base =~ s/$reg//;
    $reg = '[^' . $SL . ']+';
    $base =~ s/$reg/../g;
    if (!($path . $base)) {
	$path = '.';
    } elsif ($path && $base) {
	$path = $base . $SL . $path;
    } else {
	$path = $base . $path;
    }
    regularize($path);
    $path;
}

#
# rel2abs: make an absolute pathname from a relative pathname
#
# Interface:
#	i)	$path	relative path (needed)
#	i)	$base	base directory 	(optional)
#	r)		absolute path of $path
#
#	Note:	rel2abs doesn't check whether the specified path exist or not.
#
sub rel2abs($;$;) {
    my($path, $base) = @_;
    my($reg);

    $reg = '^' . $SL;
    if ($path =~ /$reg/) {
	warn("rel2abs: nothing to do.($path)") if $verbose;
        return $path;
    }
    regularize($path);
    if (!$base) {
        $base = cwd();
    }
    $reg = '^' . $SL;
    if ($base !~ /$reg/) {
	$base = cwd() . '/' . $base;
    }
    $path = $base . $SL . $path;
    $reg = $SL . '[^' . $SL . ']+' . $SL . '\.\.';
    while ($path =~ /$reg/) {
	$path =~ s/$reg//;			# trim path/..
    }
    regularize($path);
    $path;
}

#
# regularize a path.
#
sub regularize {
    my($reg);

    $reg = '^' . $SL . '\.\.' . $SL;
    while ($_[0] =~ /$reg/) {		# ^/../	-> /
	$_[0] =~ s/$reg/$SL/;
    }
    $reg = $SL . '\.' . $SL;
    while ($_[0] =~ /$reg/) {
	$_[0] =~ s/$reg/$SL/;		# /./ -> /
    }
    $reg = $SL . '+';
    $_[0] =~ s/$reg/$SL/g;		# ///  -> /
    $reg = '(.+)' . $SL . '$';
    $_[0] =~ s/$reg/$1/;		# remove last /
    $reg = '(.+)' . $SL . '\.$';
    $_[0] =~ s/$reg/$1/g;		# remove last /.
    $_[0] = '/' if $_[0] eq '/.';
}

#
# extract common part of two paths.
#
sub common {
    my($p1, $p2) = @_;
    my(@p1, @p2, @common);

    @p1 = split($SL, $p1);
    @p2 = split($SL, $p2);
    while (@p1 && @p2 && $p1[0] eq $p2[0]) {
	push @common, shift @p1;
	shift @p2;
    }
    join($SL, @common);
}

1;

__END__

=head1 NAME

realpath - make a canonicalized absolute path name

abs2rel - make a relative path from an absolute path

rel2abs - make an absolute path from a relative path

=head1 SYNOPSIS

    use File::PathConvert qw(realpath abs2rel rel2abs);

    $path = realpath($path);

    $path = abs2rel($path);
    $path = abs2rel($path, $base);

    $path = rel2abs($path);
    $path = rel2abs($path, $base);

    use File::PathConvert qw($resolved);
    $path = realpath($path) || die "resolution stopped at $resolved";

=head1 DESCRIPTION

The PathConvert module provides three functions.

=over 4

=item realpath

C<realpath> makes a canonicalized absolute pathname and
resolves all symbolic links, extra ``/'' characters, and references
to /./ and /../ in the path.
C<realpath> resolves both absolute and relative paths.
It returns the resolved name on success, otherwise it returns undef
and sets the valiable C<$File::PathConvert::resolved> to the pathname
that caused the problem.

All but the last component of the path must exist.

This implementation is based on 4.4BSD realpath(3).

=item abs2rel

C<abs2rel> makes a relative path name from an absolute path name.
By default, the base is the current directory.
If you specify a second parameter, it's assumed to be the base.

The returned path may include symbolic links.
C<abs2rel> doesn't check whether or not any path exists.

=item rel2abs

C<rel2abs> makes an absolute path name from a relative path name.
By default, the base directory is the current directory.
If you specify a second parameter, it's assumed to be the base.

The returned path may include symbolic links.
C<abs2rel> doesn't check whether or not any path exists.

=head1 EXAMPLES

=item realpath

    If '/sys' is a symbolic link to '/usr/src/sys':

    chdir('/usr');
    $path = realpath('../sys/kern');

or in anywhere ...

    $path = realpath('/sys/kern');

yields:

    $path eq '/usr/src/sys/kern'

=item abs2rel

    chdir('/usr/local/lib');
    $path = abs2rel('/usr/src/sys');

or in anywhere ...

    $path = abs2rel('/usr/src/sys', '/usr/local/lib');

yields:

    $path eq '../../src/sys'

Similarly,

    $path1 = abs2rel('/usr/src/sys', '/usr');
    $path2 = abs2rel('/usr/src/sys', '/usr/src/sys');

yields:

    $path1 eq 'src/sys'
    $path2 eq '.'

=item rel2abs

    chdir('/usr/local/lib');
    $path = rel2abs('../../src/sys');

or in anywhere ...

    $path = rel2abs('../../src/sys', '/usr/local/lib');

yields:

    $path eq '/usr/src/sys'

Similarly,

    $path = rel2abs('src/sys', '/usr');
    $path = rel2abs('.', '/usr/src/sys');

yields:

    $path eq '/usr/src/sys'

=back

=head1 BUGS

If the base directory includes symbolic links, C<abs2rel> produces the
wrong path.
For example, if '/sys' is a symbolic link to '/usr/src/sys',

    $path = abs2rel('/usr/local/lib', '/sys');

yields:

    $path eq '../usr/local/lib'		# It's wrong!!

You should convert the base directory into a real path in advance.

    $path = abs2rel('/sys/kern', realpath('/sys'));

yields:

    $path eq '../../../sys/kern'	# It's correct but ...

That is correct, but a little redundant. If you wish get the simple
answer 'kern', do the following.

    $path = abs2rel(realpath('/sys/kern'), realpath('/sys'));

C<realpath> assures correct result, but don't forget that C<realpath>
requires that all but the last component of the path exist.

=head1 AUTHOR

Shigio Yamaguchi <shigio@tamacom.com>

=cut
