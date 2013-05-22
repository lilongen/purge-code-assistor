#!/usr/bin/perl -I ./cpa 
use strict;
use English;
use Data::Dumper;
use Util;


sub getShownReferer($$);
sub getShownMethod($$$);
sub applyInfoToReportTPL($$);
sub main();


my $PurgedPackage = $ARGV[0];
my $PurgedPackageLocation = $ARGV[1];
my $CpaMiddleFileLocation = ".cpa/$PurgedPackage";

my $gUtil = new Util();
my $gViewData = $gUtil->loadFile("$CpaMiddleFileLocation/view.data.bin");
my $gSelfClassesMethods = $gUtil->loadFile("$CpaMiddleFileLocation/self.classes.methods.bin");

my $RefereeDomTPL 	= "\n<li class='referee'><span class='operator minus'></span><span class='refereeName'>#RefereeName#</span>";
my $MethodDomTPL 	= "\n  <li class='method #MethodProperty#'><span class='operator plus'></span><span class='methodName'>#MethodName#</span>";
my $RefererDomTPL 	= "\n    <li class='referer'><span class='refererIcon'></span>#Referer#</li>";
my $CounterTPL = "<span class='counter'>%d</span>";
my $RefererCounterTPL = "<span class='refererCounter'>%d</span>";
my $MethodInvokedCounterByReferer = "<span class='methodInvokedCounterByReferer'> - %d</span>";

sub main() {
	filterInvalidMethodInRefererRefereeInfo();
	
	for my $type (keys %{$gViewData}) {
		if (index($type, 'Referer') != -1) {
			next;
		}
		
		my $refereeInfo = $gViewData->{$type};
		my $html = "";
		for my $class (sort keys %{$refereeInfo}) {
			my $firstLevelHtml = $RefereeDomTPL;
			$firstLevelHtml =~ s/#RefereeName#/$class/;
			if (keys(%{$refereeInfo->{$class}}) == 0) {
				$firstLevelHtml .= "\n</li>";
				$html .= $firstLevelHtml . "\n\n";		
				next;
			}
			
			$firstLevelHtml .= "\n  <ul>";
			for my $method (sort keys %{$refereeInfo->{$class}}) {
				my $methodInfo = $refereeInfo->{$class}->{$method};
				my $refererCounter = $methodInfo->{counter} ? keys(%{$methodInfo->{referer}}) : 0;
				my $shownMethod = getShownMethod($method, $methodInfo->{counter}, $refererCounter);
				
				my $secondLevelHtml = $MethodDomTPL;
				$secondLevelHtml =~ s/#MethodName#/$shownMethod/;
				
				my $methodProperty = "";
				my $plus2Minus = 0;
				if ($methodInfo->{counter} == 0 && $method ne $class) {
					$methodProperty = " noReferer";
					$plus2Minus = 1;
				}
				if ($method eq $class) {
					$methodProperty = " constructor";
					$plus2Minus = 1;
				}
				$plus2Minus && $secondLevelHtml =~ s/class='operator plus'/class='operator minus'/;
				
				$secondLevelHtml =~ s/#MethodProperty#/$methodProperty/;
				
				if ($methodInfo->{counter} == 0) {
					$secondLevelHtml .= "\n  </li>";
					$firstLevelHtml .= $secondLevelHtml . "\n";
					next;
				}
				
				$secondLevelHtml .= "\n    <ul class='hide'>";
				for my $referer (sort keys %{$methodInfo->{referer}}) {
					my $shownReferer = getShownReferer($referer, $methodInfo->{referer}->{$referer});
					my $thirdLevelHtml = $RefererDomTPL;
					$thirdLevelHtml =~ s/#Referer#/$shownReferer/;
					$secondLevelHtml .= $thirdLevelHtml;
				}
				$secondLevelHtml .= "\n    </ul>";
				$secondLevelHtml .= "\n  </li>";
				$firstLevelHtml .= $secondLevelHtml . "\n";
			}
			$firstLevelHtml .= "\n  </ul>";
			$firstLevelHtml .= "\n</li>";
			$html .= $firstLevelHtml . "\n\n";
		}
		applyInfoToReportTPL($type, \$html);
	}
}

sub filterInvalidMethodInRefererRefereeInfo() {
	for my $type (keys %{$gViewData}) {
		if (index($type, 'Referer') != -1) {
			next;
		}
		
		my $info = $gViewData->{$type};
		
		for my $class (keys %{$info}) {
			for my $method (keys %{$info->{$class}}) {
				if (!defined($gSelfClassesMethods->{$class}->{$method})) {
					delete $info->{$class}->{$method};
				}	
			}	
		}
	}
}

sub applyInfoToReportTPL($$) {
	my $type = shift;
	my $html = shift;
	
	my $separator = "#RefereeInfoHtml#";
	my $tpl = $gUtil->readFileAllContent("cpa/web/referee.report.html");
	my $separatorIndex = index($tpl, $separator);
	my $part1 = substr($tpl, 0, $separatorIndex);
	my $part2 = substr($tpl, $separatorIndex + length($separator));
	
	$part1 =~ s/#RefereeType#/$type/g;
	
	$gUtil->out2File("$CpaMiddleFileLocation/$type.report.html", $part1 . $$html . $part2);
}

sub getShownMethod($$$) {
	my $method = shift;
	my $counter = shift;
	my $refererCounter = shift;
	
	if ($counter == 0) {
		return $method;
	}
	
	return $method 
		. '<span class="methodSurfix">&nbsp;&nbsp;&nbsp;' 
		. sprintf($RefererCounterTPL, $refererCounter)
		. ', '
		. sprintf($CounterTPL, $counter) 
		. '</span>';
}

sub getShownReferer($$) {
	my $referer = shift;
	my $counter = shift;
	
	$referer =~ s/$\.\///;
	return '<span class="refererName">'
		. $referer . '</span>'
		. sprintf($MethodInvokedCounterByReferer, $counter);
}

main();