#!/usr/bin/perl -I ./cpa 
use strict;
use English;
use Data::Dumper;
use Util;

sub strictInputParmater();
sub help();
sub main();

sub help() {
print $ARGV[0];
	print <<"Usage"
./cpa/cpa.pl "%purgePackage%" "%purgedPackageLocation%"

Example:
./cpa/cpa.pl "com.webex.common.mail" "./waf/src/java/com/webex/common/mail"


Usage
}

my $gUtil = new Util();
my $ProcessorLocation = "./cpa";
my $Processor = [
	{
		name => "pre scan",
		type => "bash",
		cmd => "pre.scan.sh"
	},
	{
		name => "list purged classes methods",
		type => "bash",
		cmd => "list.classes.methods.sh"
	},
	{
		name => "digitalize purged classes methods",
		type => "perl",
		cmd => "digitalize.self.classes.methods.pl"
	},
	{
		name => "scan method usage",
		type => "perl",
		cmd => "scan.methods.usage.pl"
	},	
	{
		name => "digitalize methods usage",
		type => "perl",
		cmd => "digitalize.methods.usage.pl"
	},
	{
		name => "construct view data",
		type => "perl",
		cmd => "construct.view.data.pl"
	},	
	{
		name => "generate report",
		type => "perl",
		cmd => "generate.report.pl"
	}
];

sub main() {
	if (($#ARGV + 1) < 2) {
		help();
		return 1;
	}
	
	my $pms = strictInputParmater();
	for (my $i = 0; $i <= $#{$Processor}; $i++) {
		print " $Processor->[$i]->{name} start...\n";
		my $cmd = "$Processor->[$i]->{type} $ProcessorLocation/$Processor->[$i]->{cmd} \"$pms->{purgedPackage}\" \"$pms->{purgedPackageLocation}\"";
		$gUtil->execAndLogCmd($cmd);
		print "finished!\n\n\n";
	}
	print "all finished!\n\n";
	
	return 0;
}

sub strictInputParmater() {
	my $purgedPackage = $ARGV[0];
	my $purgedPackageLocation = $ARGV[1];
	
	$purgedPackage =~ s/\.\*?$//;
	$purgedPackageLocation =~ s/^(\w+)/\.\/$1/;
	$purgedPackageLocation =~ s/(\w+)$/$1\//;

	return {
		purgedPackage => $purgedPackage,
		purgedPackageLocation => $purgedPackageLocation
	};
}

main();
