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
total 948
-rwxrwxr-x 1 lilongen lilongen   1040 May 26 02:32 construct.view.data.pl
-rwxrwxr-x 1 lilongen lilongen   1839 May 26 02:32 cpa.pl
-rw-rw-r-- 1 lilongen lilongen 901120 May 26 02:32 cpa.tar
-rwxrwxr-x 1 lilongen lilongen   9222 May 26 02:32 digitalize.methods.usage.pl
-rwxrwxr-x 1 lilongen lilongen   1056 May 26 02:32 digitalize.self.classes.methods.pl
-rwxrwxr-x 1 lilongen lilongen   4593 May 26 02:32 generate.report.pl
-rwxrwxr-x 1 lilongen lilongen   1670 May 26 02:32 list.classes.methods.sh
-rwxrwxr-x 1 lilongen lilongen    981 May 26 02:32 pre.scan.sh
-rw-rw-r-- 1 lilongen lilongen     39 May 26 02:32 README.md
-rwxrwxr-x 1 lilongen lilongen   6418 May 26 02:32 scan.methods.usage.pl
-rwxrwxr-x 1 lilongen lilongen   1429 May 26 02:32 tt3.pl
-rwxrwxr-x 1 lilongen lilongen   1429 May 26 02:32 tt.pl
-rwxrwxr-x 1 lilongen lilongen   2203 May 26 02:32 Util.pm
drwxrwxr-x 6 lilongen lilongen   4096 May 26 02:32 web
