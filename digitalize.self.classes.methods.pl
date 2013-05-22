#!/usr/bin/perl -I ./cpa 
use strict;
use English;
use Data::Dumper;
use Util;

sub main() {
	my $PurgedPackage = $ARGV[0];
	my $PurgedPackageLocation = $ARGV[1];
	my $CpaMiddleFileLocation = ".cpa/$PurgedPackage";	
	
	my $classesFunctions = {};
	my $line;
	my $file;
	my $class;
	my $function;
	my $SELF_CLASSES_METHODS_FILE="$CpaMiddleFileLocation/self.classes.methods";
	open(my $h, $SELF_CLASSES_METHODS_FILE) or die "Fail to open $SELF_CLASSES_METHODS_FILE";
	while (!eof($h)) {
		$line = <$h>;
		$line =~ s/[\s\n]+$//;
		if (length($line) == 0) {
			next;
		}

		if ($line =~ m/^(\..*\/(\w+)\.java)$/) {
			$file = $1;
			$class = $2;
			$classesFunctions->{$class} = {};
			next;
		}
		
		if ($line =~ m/\s(\w+)\(/) {
			$function = $1;
			if (!defined($classesFunctions->{$class}->{$function})) {
				$classesFunctions->{$class}->{$function} = 0;
			}
			$classesFunctions->{$class}->{$function}++;
			next;
		}
		
	}
	close($h);
	my $util = new Util();
	$util->persistBinAndJsonVarToFile($SELF_CLASSES_METHODS_FILE, $classesFunctions);
}

main();
