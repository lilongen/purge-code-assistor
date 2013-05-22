#!/usr/bin/perl -I ./cpa 
use strict;
use English;
use Data::Dumper;
use Util;

sub main();
sub resetFlag();
sub setFileClassInfo($$);
sub storegFileReferInfo();
sub setClassMethodInvokedInfo($$$);
sub initSpecialFileClassInfo($$$);
sub initSpecialClassUsageInfo($$$);
sub initFileClassMethodInvokedInfo($$$);
sub initClassUsageMethodInvokedInfo($$$);
sub filteUselessInfo();
sub constructRefererRefereeData();
sub handleStaticInvoking($$$);

my $PurgedPackage = $ARGV[0];
my $PurgedPackageLocation = $ARGV[1];
my $CpaMiddleFileLocation = ".cpa/$PurgedPackage";	

my $gUtil = new Util();
my $GV = $gUtil->loadFile("$CpaMiddleFileLocation/__gv");

my $gInfo = {
	FileRefer => {},
	InnerFileRefer => {},
	OuterFileRefer => {},
	
	ClassUsage => {},
	InnerClassUsage => {},
	OuterClassUsage => {}	
};

my $gRefererRefereeInfo = {
	Referer => {},
	InnerReferer => {},
	OuterReferer => {},
	
	Referee => {},
	InnerReferee => {},
	OuterReferee => {}	
};

my $gInfo2RefererRefereeInfoMap = {
	FileRefer => 'Referer',
	InnerFileRefer => 'InnerReferer',
	OuterFileRefer => 'OuterReferer',
	
	ClassUsage => 'Referee',
	InnerClassUsage => 'InnerReferee',
	OuterClassUsage => 'OuterReferee'
};
	



my $gFlag = {}; 

sub resetFlag() {
	$gFlag->{FileIsInterface} = 0;
	$gFlag->{ClassSelfRefer} = 0;
}

sub filteUselessInfo() {
	for my $infoKey (keys %{$gInfo}) {
		my $level1EmptyItems = [];
		for my $level1ItemKey (keys %{$gInfo->{$infoKey}}) {
			my $level2EmptyItems = [];
			for my $level2ItemKey (keys %{$gInfo->{$infoKey}->{$level1ItemKey}}) {
				if (!keys(%{$gInfo->{$infoKey}->{$level1ItemKey}->{$level2ItemKey}})) {
					push(@{$level2EmptyItems}, $level2ItemKey);
				}
			}
			
			for (my $i = 0; $i <= $#{$level2EmptyItems}; $i++) {
				delete $gInfo->{$infoKey}->{$level1ItemKey}->{$level2EmptyItems->[$i]};
			}
			
			if (!keys(%{$gInfo->{$infoKey}->{$level1ItemKey}})) {
				push(@{$level1EmptyItems}, $level1ItemKey);
			}
		}
		
		for (my $i = 0; $i <= $#{$level1EmptyItems}; $i++) {
			delete $gInfo->{$infoKey}->{$level1EmptyItems->[$i]};
		}			
	}
}

sub constructRefererRefereeData() {
	for my $infoKey (keys %{$gInfo}) {
		if (index($infoKey, 'FileRefer') != -1) {
			next;
		}
		
		my $refereeInfo = $gRefererRefereeInfo->{$gInfo2RefererRefereeInfoMap->{$infoKey}};
		for my $level1ItemKey (keys %{$gInfo->{$infoKey}}) {
			if (!defined($refereeInfo->{$level1ItemKey})) {
				$refereeInfo->{$level1ItemKey} = {};
			}
			for my $level2ItemKey (keys %{$gInfo->{$infoKey}->{$level1ItemKey}}) {
				for my $level3ItemKey (keys %{$gInfo->{$infoKey}->{$level1ItemKey}->{$level2ItemKey}}) {
					if (!defined($refereeInfo->{$level1ItemKey}->{$level3ItemKey})) {
						$refereeInfo->{$level1ItemKey}->{$level3ItemKey} = {
							counter => 0,
							referer => {}	
						};
					}
					my $referencedTimes = $gInfo->{$infoKey}->{$level1ItemKey}->{$level2ItemKey}->{$level3ItemKey};
					$refereeInfo->{$level1ItemKey}->{$level3ItemKey}->{counter} += $referencedTimes;
					$refereeInfo->{$level1ItemKey}->{$level3ItemKey}->{referer}->{$level2ItemKey} = $referencedTimes;
				}
			}
		}
	}		
}

sub main() {
	resetFlag();
	
	my $line;
	my $file;
	my $class;
	my $isInterfaceFile;
	open(my $h, $GV->{OUT}) or die "Fail to open $GV->{OUT}";
	while (!eof($h)) {
		$line = <$h>;
		$line =~ s/[\s\n]+$//;
		if (length($line) == 0) {
			next;
		}

		if ($line eq 'INNER_SCAN_START') {
			$gFlag->{Inner} = 1;
			next;
		}
		if ($line eq 'OUTER_SCAN_START') {
			$gFlag->{Inner} = 0;
			next;
		}
		
		#- waf/src/java/com/webex/common/mail/EmailEngineTicket.java -> AsynPopulateEmailData 
		#- waf/src/java/com/webex/common/mail/EmailEngineTicket.java -> EmailEngineTicket []
		#- waf/src/java/com/webex/common/mail/WbxMailListener.java -> WbxMailListener [I]	
		if ($line =~ m/^- (.*) -> (\w+)( \[(I?)\])?$/) {
			resetFlag();
			
			$file = $1;
			$class = $2;
			
			setFileClassInfo($file, $class);
			setClassUsageInfo($file, $class);
			
			$gFlag->{ClassSelfRefer} = defined($3);
			$gFlag->{FileIsInterface} = defined($4) && length($4);
			if ($gFlag->{FileIsInterface}) {
				next;
			}
					
			next;
		}
		
		#- ./waf/src/java/com/webex/common/mail/mobile/MobileMailProcessor.java -> MeetingMailUtil
		# MeetingMailUtil.convertHtmlTag(host.getDisplayName()));
		# MeetingMailUtil.convertHtmlTag(host.getDisplayName()));		
		# MeetingMailUtil.getInstance().convertHtmlTag(host.getDisplayName()));
		my $classStaticCallRe = '^\s*' . $class . '\.\w+\(.*';
		if ($line =~ m/$classStaticCallRe/) {
			handleStaticInvoking($file, $class, $line);
		}		
		

		#- waf/src/java/com/webex/common/mail/MailFormat.java -> MailFormat []
		# convertVlaueInDefault(param, value);
		# getMailReplaceKey(rawKey, ENCODE_TYPE_SAFETAG);		
		if ($gFlag->{Inner}
		&& $gFlag->{ClassSelfRefer}
		&& $line =~ m/^\s*(\w+)\(/) {
			my $invokedMethod = $1;
			setClassMethodInvokedInfo($file, $class, $invokedMethod);
			next;		
		}

		#- waf/src/java/com/webex/common/mail/meeting/MeetingMailProcessor.java -> WbxDefaultRecipientSpecificInfo 
		#to = new WbxDefaultRecipientSpecificInfo
		#to = new WbxDefaultRecipientSpecificInfo
		#to.setLocale(
		#to.setTemplateValues(
		if (!$gFlag->{ClassSelfRefer} && $line =~ m/^\s*\w+.*\.(\w+)\(/) {
			my $invokedMethod = $1;
			setClassMethodInvokedInfo($file, $class, $invokedMethod);
			next;
		}
	}
	close($h);
	
	$gUtil->persistBinAndJsonVarToFile("$CpaMiddleFileLocation/gInfo.raw", $gInfo);
	filteUselessInfo();
	$gUtil->persistBinAndJsonVarToFile("$CpaMiddleFileLocation/gInfo.filted", $gInfo);
	
	constructRefererRefereeData();
	$gUtil->persistBinAndJsonVarToFile("$CpaMiddleFileLocation/gRefererRefereeInfo", $gRefererRefereeInfo);
}

sub handleStaticInvoking($$$) {
	my $file = shift;
	my $class = shift;
	my $line = shift;
	
	my @matches = $line =~ /(?<=\.)(\w+)(?=\()/;
	foreach my $invokedMethod (@matches) {
		setClassMethodInvokedInfo($file, $class, $invokedMethod);
	}
}

sub setFileClassInfo($$) {
	my $file = shift;
	my $class = shift;
	initSpecialFileClassInfo($gInfo->{FileRefer}, $file, $class);
	
	if ($gFlag->{Inner}) {
		initSpecialFileClassInfo($gInfo->{InnerFileRefer}, $file, $class);							
	} else {
		initSpecialFileClassInfo($gInfo->{OuterFileRefer}, $file, $class);				
	}
}

sub setClassUsageInfo($$) {
	my $file = shift;
	my $class = shift;
	initSpecialClassUsageInfo($gInfo->{ClassUsage}, $file, $class);	
	if ($gFlag->{Inner}) {
		initSpecialClassUsageInfo($gInfo->{InnerClassUsage}, $file, $class);							
	} else {
		initSpecialClassUsageInfo($gInfo->{OuterClassUsage}, $file, $class);				
	}
	
	$gInfo->{ClassUsage}->{$class}->{$file} = {};
	if ($gFlag->{Inner}) {
		$gInfo->{InnerClassUsage}->{$class}->{$file} = {};
	} else {
		$gInfo->{OuterClassUsage}->{$class}->{$file} = {};
	}
}

sub initSpecialFileClassInfo($$$) {
	my $specialFileReferInfo = shift;
	my $file = shift;
	my $class = shift;
	
	if (!defined($specialFileReferInfo->{$file})) {
		$specialFileReferInfo->{$file} = {};
	}
	if (!defined($specialFileReferInfo->{$file}->{$class})) {
		$specialFileReferInfo->{$file}->{$class} = {};	
	}
}

sub initSpecialClassUsageInfo($$$) {
	my $specialClassUsageInfo = shift;
	my $file = shift;
	my $class = shift;
	
	if (!defined($specialClassUsageInfo->{$class})) {
		$specialClassUsageInfo->{$class} = {};
	}
}

sub setClassMethodInvokedInfo($$$) {
	my $file = shift;
	my $class = shift;
	my $invokedMethod = shift;
	
	initFileClassMethodInvokedInfo($file, $class, $invokedMethod);
	initClassUsageMethodInvokedInfo($file, $class, $invokedMethod);
	
	$gInfo->{FileRefer}->{$file}->{$class}->{$invokedMethod}++;
	if ($gFlag->{Inner}) {
		$gInfo->{InnerFileRefer}->{$file}->{$class}->{$invokedMethod}++;
	} else {
		$gInfo->{OuterFileRefer}->{$file}->{$class}->{$invokedMethod}++;	
	}
	
	$gInfo->{ClassUsage}->{$class}->{$file}->{$invokedMethod}++;
	if ($gFlag->{Inner}) {
		$gInfo->{InnerClassUsage}->{$class}->{$file}->{$invokedMethod}++;
	} else {
		$gInfo->{OuterClassUsage}->{$class}->{$file}->{$invokedMethod}++;
	}	
}

sub initFileClassMethodInvokedInfo($$$) {
	my $file = shift;
	my $class = shift;
	my $invokedMethod = shift;
	
	if (!defined($gInfo->{FileRefer}->{$file}->{$class}->{$invokedMethod})) {
		$gInfo->{FileRefer}->{$file}->{$class}->{$invokedMethod} = 0;
	}
	if ($gFlag->{Inner}) {
		if (!defined($gInfo->{InnerFileRefer}->{$file}->{$class}->{$invokedMethod})) {
			$gInfo->{InnerFileRefer}->{$file}->{$class}->{$invokedMethod} = 0;
		}
	} else {
		if (!defined($gInfo->{OuterFileRefer}->{$file}->{$class}->{$invokedMethod})) {
			$gInfo->{OuterFileRefer}->{$file}->{$class}->{$invokedMethod} = 0;
		}		
	}		
}

sub initClassUsageMethodInvokedInfo($$$) {
	my $file = shift;
	my $class = shift;
	my $invokedMethod = shift;

	if (!defined($gInfo->{ClassUsage}->{$class}->{$file}->{$invokedMethod})) {
		$gInfo->{ClassUsage}->{$class}->{$file}->{$invokedMethod} = 0;
	}
	if ($gFlag->{Inner}) {
		if (!defined($gInfo->{InnerClassUsage}->{$class}->{$file}->{$invokedMethod})) {
			$gInfo->{InnerClassUsage}->{$class}->{$file}->{$invokedMethod} = 0;
		}		
	} else {
		if (!defined($gInfo->{OuterClassUsage}->{$class}->{$file}->{$invokedMethod})) {
			$gInfo->{OuterClassUsage}->{$class}->{$file}->{$invokedMethod} = 0;
		}		
	}		
}

main();
