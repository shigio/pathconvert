#!/usr/bin/perl
#
# Test script for abs2rel(3) and rel2abs(3).
#
$logfile = 'err';
#
#       target          base directory  result
#       --------------------------------------
@abs2rel = (
	'.		/		.',
	'a/b/c		/		a/b/c',
	'a/b/c		/a		a/b/c',
	'/a/b/c		a		ERROR',
);
@rel2abs = (
	'.		/a		/a',
	'.		/		/',
	'./		/		/',
	'/a/b/c		/		/a/b/c',
	'/a/b/c		/a		/a/b/c',
	'a/b/c		a		ERROR',
	'..		/a		/',
	'../		/a		/',
	'../..		/a		/',
	'../../		/a		/',
	'../../..	/a		/',
	'../../../	/a		/',
	'../b		/a		/b',
	'../b/		/a		/b/',
	'../../b	/a		/b',
	'../../b/	/a		/b/',
	'../../../b	/a		/b',
	'../../../b/	/a		/b/',
	'../b/c		/a		/b/c',
	'../b/c/	/a		/b/c/',
	'../../b/c	/a		/b/c',
	'../../b/c/	/a		/b/c/',
	'../../../b/c	/a		/b/c',
	'../../../b/c/	/a		/b/c/',
);
@common = (
	'/a/b/c		/a/b/c		.',
	'/a/b/c		/a/b/		c',
	'/a/b/c		/a/b		c',
	'/a/b/c		/a/		b/c',
	'/a/b/c		/a		b/c',
	'/a/b/c		/		a/b/c',
	'/a/b/c		/a/b/c		.',
	'/a/b/c		/a/b/c/		.',
	'/a/b/c/	/a/b/c		./',
	'/a/b/		/a/b/c		../',
	'/a/b		/a/b/c		..',
	'/a/		/a/b/c		../../',
	'/a		/a/b/c		../..',
	'/		/a/b/c		../../../',
	'/a/b/c		/a/b/z		../c',
	'/a/b/c		/a/y/z		../../b/c',
	'/a/b/c		/x/y/z		../../../a/b/c',
);
print "TEST start ";
open(LOG, ">$logfile") || die("cannot open log file '$logfile'.\n");
$cnt = 0;
$progname = 'abs2rel';
foreach (@abs2rel) {
	@d = split;
	chop($result = `./$progname $d[0] $d[1]`);
	if ($d[2] eq $result) {
		print '.';
	} else {
		print 'X';
		print LOG "$progname $d[0] $d[1] -> $result (It should be '$d[2]')\n";
		$cnt++;
	}
}
foreach (@common) {
	@d = split;
	chop($result = `./$progname $d[0] $d[1]`);
	if ($d[2] eq $result) {
		print '.';
	} else {
		print 'X';
		print LOG "$progname $d[0] $d[1] -> $result (It should be '$d[2]')\n";
		$cnt++;
	}
}
$progname = 'rel2abs';
foreach (@rel2abs) {
	@d = split;
	chop($result = `./$progname $d[0] $d[1]`);
	if ($d[2] eq $result) {
		print '.';
	} else {
		print 'X';
		print LOG "$progname $d[0] $d[1] -> $result (It should be '$d[2]')\n";
		$cnt++;
	}
}
foreach (@common) {
	@d = split;
	chop($result = `./$progname $d[2] $d[1]`);
	if ($d[0] eq $result) {
		print '.';
	} else {
		print 'X';
		print LOG "$progname $d[2] $d[1] -> $result (It should be '$d[0]')\n";
		$cnt++;
	}
}
close(LOG);
if ($cnt == 0) {
	print " COMPLETED.\n";
} else {
	print " $cnt errors detected.\n";
	open(LOG, $logfile) || die("log file not found.\n");
	while (<LOG>) {
		print;
	}
	close(LOG);
}
