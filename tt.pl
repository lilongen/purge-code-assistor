#!/usr/bin/perl
use strict;
use English;
use Data::Dumper;


my $GV = {
	
	LOG => 1,
	
	GREP_CMD_TPL => "grep -P -o '%s' '%s'",
	RE => {
		#ClassA varA = | varA = new ClassA
		VarDeclareOrNew => '(%s\s+\w+\s*=|\w+\s*=\s*new\s+%s)',
		
		#get var name "varA"
		#from 
		#ClassA varA = | varA = new ClassA
		CatchVarNameInVarDeclareOrNew => '(\s+(\w+)\s*=|(\w+)\s*=\s*new\s+)',
		
		#ClassA.abc...
		#ClassA.methodA()...
		#ClassA.getInstance().methodA()...
		CallStaticMethod => '\s+%s\.[^\s]+',
		
		#this.methodA(
		#methodA(
		#(?<!new)  -> not match -- new StringBuffer(
		CallClassInnerMethod => '(?<!new)\s+(this\.)?\w+\([^\)]+\);'
		
	},
	
	REFERED_INFO_FILE => 'files.which.import.waf.mail',
	WAF_MAIL_CLASSES_FILE => 'waf.mail.classes.name.sorted',
	PURGED_SELF => './waf/src/java/com/webex/common/mail/',
	PURGED_SELF_CLASSES_FILE => 'waf.mail.classes',
	OUT => 'out.xx',
	WAF_MAIL_CLASS => [],
	WAF_MAIL_CLASS_CNT => 0
};

my $line1 = "ClassB varB = new ClassA";
my $line2 = "ClassA varA = new ClassA";

if ($line1 =~ m/$GV->{RE}->{CatchVarNameInVarDeclareOrNew}/) {
	print(($2 || $3) . "\n");
} else {
	print "not found\n";
}
if ($line2 =~ m/$GV->{RE}->{CatchVarNameInVarDeclareOrNew}/) {
	print(($2 || $3) . "\n");
} else {
	print "not found\n";
}

my $hash1 = {
	a => 1
};

print "hash1 size: " . keys(%$hash1) ."\n";


my $a = "#A# #B#";
my $b = $a;

$b =~ s/#A#/aaa/;
$b =~ s/#B#/bbb/;

print $a . "   " . $b;