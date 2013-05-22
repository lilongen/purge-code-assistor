#!/usr/bin/perl -I ./cpa 
use strict;
use English;
use Data::Dumper;
use Util;

sub main() {
	my $PurgedPackage = $ARGV[0];
	my $PurgedPackageLocation = $ARGV[1];
	my $CpaMiddleFileLocation = ".cpa/$PurgedPackage";	
	
	my $util = new Util();
	my $refererRefereeInfo = $util->loadFile("$CpaMiddleFileLocation/gRefererRefereeInfo.bin");
	my $classesMethods = $util->loadFile("$CpaMiddleFileLocation/self.classes.methods.bin");
		
	for my $infoKey (keys %{$refererRefereeInfo}) {
		if (index($infoKey, 'Referer') != -1) {
			next;
		}
		
		my $refereeInfo = $refererRefereeInfo->{$infoKey};
		for my $class (keys %{$classesMethods}) {
			if (!defined($refereeInfo->{$class})) {
				$refereeInfo->{$class} = {};
			}
			
			for my $classMethod (keys %{$classesMethods->{$class}}) {
				if (!defined($refereeInfo->{$class}->{$classMethod})) {
					$refereeInfo->{$class}->{$classMethod} = {
						counter => 0
					};
				}				
			}
		}
	}
	
	$util->persistBinAndJsonVarToFile("$CpaMiddleFileLocation/view.data", $refererRefereeInfo);
}

main();