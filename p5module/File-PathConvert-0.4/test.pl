#!/usr/local/bin/perl -w

use Cwd;
use File::PathConvert qw(realpath abs2rel rel2abs);

$| = 1;
open(LOG, ">LOG") || die("cannot make log file");
print "PathConvert TEST START.";
$errcount = 0;
#
# abs2rel
#
$current = '/t1/t2/t3';
%data = (
	# INPUT		   OUTPUT
	'/t1/t2/t3'	=> '.',
	'/t1/t2/t4'	=> '../t4',
	'/t1/t2'	=> '..',
	'/t1/t2/t3/t4'	=> 't4',
	'/t4/t5/t6'	=> '../../../t4/t5/t6',
	'../t4'		=> '../t4',
	'/'		=> '../../..',
	'///'		=> '../../..',
	'/.'		=> '../../..',
	'/./'		=> '../../..',
	'/../'		=> '../../..',
	't1'		=> 't1',
	'.'		=> '.',
);
foreach $in (keys(%data)) {
	$out = abs2rel($in, $current);
	if ($out eq $data{$in}) {
		print ".";
	} else {
		$errcount++;
		print "X";
		print LOG "<<<ERROR>>>\n";
		print LOG "Result: $out = abs2rel($in, $current);\n";
		print LOG "Expected: $data{$in} = abs2rel($in, $current);\n";
	}
}
#
# rel2abs
#
$current = '/t1/t2/t3';
%data = (
	# INPUT		   OUTPUT
	't4'		=> '/t1/t2/t3/t4',
	't4/t5'		=> '/t1/t2/t3/t4/t5',
	'.'		=> '/t1/t2/t3',
	'..'		=> '/t1/t2',
	'../t4'		=> '/t1/t2/t4',
	'../../t5'	=> '/t1/t5',
	'../../../t6'	=> '/t6',
	'../../../../t7'=> '/t7',
	'../t4/t5/../t6'=> '/t1/t2/t4/t6',
	'/t1'		=> '/t1',
);
foreach $in (keys(%data)) {
	$out = rel2abs($in, $current);
	if ($out eq $data{$in}) {
		print ".";
	} else {
		$errcount++;
		print "X";
		print LOG "<<<ERROR>>>\n";
		print LOG "Result: $out = rel2abs($in, $current);\n";
		print LOG "Expected: $data{$in} = rel2abs($in, $current);\n";
	}
}
#----------------------------------------------------------------------
#
# From now on, use real directory tree.
# make test environment
# test/t1/ta -> t4/t5
# test/t1/t2/t3/tb -> ../../t1/ta
# test/t1/t2/tc -> t3/tb
#
#----------------------------------------------------------------------
$cdir = cwd();
use File::Path;
-d 'test/t1/t2/t3' || mkpath('test/t1/t2/t3') || die("cannot mkpath");
-d 'test/t1/t4/t5' || mkpath('test/t1/t4/t5') || die("cannot mkpath");
open(FILE, ">test/t1/t4/t5/file") || die("cannot create");
close(FILE);
chdir("$cdir/test/t1") || die("cannot chdir");
-l 'ta' || symlink('t4/t5', 'ta') || die("cannot symlink");
chdir("$cdir/test/t1/t2/t3") || die("cannot chdir");
-l 'tb' || symlink('../../../t1/ta', 'tb') || die("cannot symlink");
chdir("$cdir/test/t1/t2") || die("cannot chdir");
-l 'tc' || symlink('t3/tb', 'tc') || die("cannot symlink");
chdir("$cdir") || die("cannot chdir");
#
# realpath
#
%data = (
	# INPUT		   OUTPUT
	'/'			=> '/',
	'///'			=> '/',
	'/.'			=> '/',
	'.'			=> "$cdir",
	"test"			=> "$cdir/test",
	"file"			=> "$cdir/file",
	"test/./t1"		=> "$cdir/test/t1",
	"test/t1/../t1/file"	=> "$cdir/test/t1/file",
	"test/t1/ta"		=> "$cdir/test/t1/t4/t5",
	"test/t1/t2/t3/tb"	=> "$cdir/test/t1/t4/t5",
	"test/t1/t2/tc"		=> "$cdir/test/t1/t4/t5",
	"test/t1/t2/tc/file"	=> "$cdir/test/t1/t4/t5/file",
);
foreach $in (keys(%data)) {
	$out = realpath($in);
	if ($out eq $data{$in}) {
		print ".";
	} else {
		$errcount++;
		print "X";
		print LOG "<<<ERROR>>>\n";
		print LOG "Result: $out = realpath($in);\n";
		print LOG "Expected: $data{$in} = realpath($in);\n";
	}
}
#
# print LOG
#
close(LOG);
if ($errcount) {
	print "FAILED. $errcount errors occured.\n";
	open(LOG, "LOG") || die("cannot open LOG file.");
	@log = <LOG>;
	print @log;
	close(LOG);
	exit(1);
}
print "COMPLETED.\n";
exit(0);
