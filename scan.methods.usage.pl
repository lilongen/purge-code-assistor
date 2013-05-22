#!/usr/bin/perl -I ./cpa 
use strict;
use English;
use Data::Dumper;
use Util;

sub scanPurgedSelf();
sub scanOuterRefer();
sub isInterfaceFile($$);
sub getInvokedMethodsOfOneReferedClassVariablesInstance($$);
sub registerScanedFileClass($$);
sub main();

# int
# int[]
# int []
# Vector<int>
# Vector <int>
# Vector < int >
# Vector<int>[]
# Vector<int> []
# Vector<int[]> []
# Vector<int [] > []
#DataTypeRe='\w+\s*(<\s*[\w]+\s*(\[\])?\s*>)?\s*(\[\])?'

# ()
# (type1 var1
# (type1 var1, type2 var2
# (type1 var1, type2 var2, type3 var3
# (type1<type2> var1, type2<type3>[] var2, type3 var3
#FunctionParameterRe="($DataTypeRe|\,|\s)*"
my $gUtil = new Util();
my $gScanedFilesClasses = {};

my $DataTypeRe = '%s\s*(<\s*[\w]+\s*(\[\])?\s*>)?\s*(\[\])?';
my $FunctionParameterRe='(' . $DataTypeRe . '|\,|\s)*';

my $PurgedPackage = $ARGV[0];
my $PurgedPackageLocation = $ARGV[1];
my $CpaMiddleFileLocation = ".cpa/$PurgedPackage";

my $GV = {
	
	GREP_CMD_TPL => "grep -P -o '%s' '%s'",
	
	RE => {
		#ClassA varA = | varA = new ClassA
		#VarDeclareOrNew => '(%s\s+\w+\s*=|\w+\s*=\s*new\s+%s)',
		VarDeclareOrNew => '(' . $DataTypeRe . '\s*(\[\])?\s+\w+\s*=|\w+\s*=\s*new\s+%s)',
		
		#get var name "varA"
		#from 
		#ClassA varA = | varA = new ClassA
		CatchVarNameInVarDeclareOrNew => '(\s+(\w+)\s*=|(\w+)\s*=\s*new\s+)',
		
		#ClassA.abc...
		#ClassA.methodA()...
		#ClassA.getInstance().methodA()...
		CallStaticMethod => '\s+(return\s*)?%s\.[^\s]+',
		
		#this.methodA(
		#methodA(
		#(?<!new)  -> not match -- new StringBuffer(
		#CallClassInnerMethod => '(?<!new)\s+(this\.)?\w+\([^\)]+\);',
		#  method(...
		#  a = method(...
		#  (method(...
		#  (, method(...
		CallClassInnerMethod => '(^\s*|.*=\s*|\(\s*|\,\s*)(this\.)?\w+\(.*',
		
		#varA.method1(
		#varB.method2(
		VarCallMethod => '%s\.\w+\('
	},
	
	REFERERS_FILE => "$CpaMiddleFileLocation/referers",
	PURGED_SELF_SORTED_CLASS_NAME_FILE => "$CpaMiddleFileLocation/inner.classes.name.sorted",
	PURGED_SELF_CLASSES_FILE => "$CpaMiddleFileLocation/inner.classes",
	OUT => "$CpaMiddleFileLocation/methods.usage.out",
	PURFED_CLASSES => []
};

sub main() {
	$gUtil->readFileIntoArray($GV->{PURGED_SELF_SORTED_CLASS_NAME_FILE}, $GV->{PURFED_CLASSES});
	$gUtil->dumpFile("$CpaMiddleFileLocation/__gv", $GV);

	$gUtil->execAndLogCmd("echo \"\" > $GV->{OUT}");
	scanPurgedSelf();
	scanOuterRefer();
}

sub scanOuterRefer() {
	$gUtil->execAndLogCmd("echo -e \"OUTER_SCAN_START\n\" >> $GV->{OUT}");
	
	my $line;
	my $file;
	my $class;
	open(my $hReferedInfo, $GV->{REFERERS_FILE}) or die "Fail to open $GV->{REFERERS_FILE}";
	while (!eof($hReferedInfo)) {
		$line = <$hReferedInfo>;
		$line =~  m/^(.+):.*\.([^\.]+);[\r\n\s]*$/;
		$file = $1;
		$class = $2;

		if (index($file, $PurgedPackageLocation) != -1) {
			next;
		} else {
			if ($class eq "*") {
				for (my $i = 0; $i <= $#{$GV->{PURFED_CLASSES}}; $i++) {
					my $clsName = $GV->{PURFED_CLASSES}->[$i];
					getInvokedMethodsOfOneReferedClassVariablesInstance($file, $clsName);			
				}
			} else {
				getInvokedMethodsOfOneReferedClassVariablesInstance($file, $class);
			}
		}	
	}
	close($hReferedInfo);		
}

sub isInterfaceFile($$) {
	my $file = $_[0];
	my $className = $_[1];
	my $result = qx/grep -o 'public interface $className' '$file'/;

	return defined($result) && length($result) > 0;
}

sub scanPurgedSelf() {
	$gUtil->execAndLogCmd("echo -e \"INNER_SCAN_START\n\" >> $GV->{OUT}");	

	my $CMD_OUT2FILE_TPL = "echo -e \"- %s -> %s [%s]\n\" >> $GV->{OUT}";
	open(my $hPurgedSelfClasses, $GV->{PURGED_SELF_CLASSES_FILE}) or die "Fail to open $GV->{PURGED_SELF_CLASSES_FILE}";
	while (!eof($hPurgedSelfClasses)) {
		my $file = <$hPurgedSelfClasses>;
		$file =~ s/\n//;
		$file =~ m/([^\/]+)\.java/;
		my $currFileClsName = $1;
		my $isInterface = isInterfaceFile($file, $currFileClsName);
		my $cmd = sprintf($CMD_OUT2FILE_TPL, 
			$file, 
			$currFileClsName, 
			($isInterface ? "I" : "")
		);
		$gUtil->execAndLogCmd($cmd);
		
		if ($isInterface) {
			next;
		}
		
		$cmd = sprintf($GV->{GREP_CMD_TPL}, $GV->{RE}->{CallClassInnerMethod}, $file) 
			. " | grep -v -P '" . '^\s*(if|for|while)' . "' | grep -P -o '" . '\w+\(.*'
			. "' >> $GV->{OUT}";
		$gUtil->execAndLogCmd($cmd);
		
		for (my $i = 0; $i <= $#{$GV->{PURFED_CLASSES}}; $i++) {
			my $clsName = $GV->{PURFED_CLASSES}->[$i];
			if ($clsName eq $currFileClsName) {
				next;
			}

			getInvokedMethodsOfOneReferedClassVariablesInstance($file, $clsName);			
		}
	}
	close($hPurgedSelfClasses);
}

sub registerScanedFileClass($$) {
	my $file 	= shift;
	my $class	= shift;
	
	if (!defined($gScanedFilesClasses->{$file})) {
		$gScanedFilesClasses->{$file} = {};
	}
	if (!defined($gScanedFilesClasses->{$file}->{$class})) {
		$gScanedFilesClasses->{$file}->{$class} = 0;
	}	
	$gScanedFilesClasses->{$file}->{$class}++;	
}

sub getInvokedMethodsOfOneReferedClassVariablesInstance($$) {
	my $file = shift;
	my $class = shift;
	
	registerScanedFileClass($file, $class);
	if ($gScanedFilesClasses->{$file}->{$class} > 1) {
		return;
	}
	
	my $cmd = "echo -e \"- $file -> $class\" >> $GV->{OUT}";
	$gUtil->execAndLogCmd($cmd);

	$cmd = sprintf($GV->{GREP_CMD_TPL},
		#'(%s\s+\w+\s*=|\w+\s*=\s*new\s+%s)'
		sprintf($GV->{RE}->{VarDeclareOrNew}, $class, $class),
		$file
	);
	my $tmpVars = "$CpaMiddleFileLocation/_tmpVars";
	$cmd = "$cmd > $tmpVars";
	$gUtil->execAndLogCmd($cmd);
	
	$cmd = "cat $tmpVars >> $GV->{OUT}";
	$gUtil->execAndLogCmd($cmd);
	
	my $varNames = {};
	my $lineTmpVars;
	open(my $hTmpVars, $tmpVars) or die "Fail to open $tmpVars";
	while (!eof($hTmpVars)) {
		$lineTmpVars = <$hTmpVars>;
		
		#'(\s+(\w+)\s*=|(\w+)\s*=\s*new\s+)'
		$lineTmpVars =~ m/$GV->{RE}->{CatchVarNameInVarDeclareOrNew}/;
		my $varName = $2 || $3;
		
		#Begin unique var name, if multi var name is same, just exec one time
		if (!defined($varNames->{$varName})) {
			$varNames->{$varName} = 0;
		}
		$varNames->{$varName}++;
		if ($varNames->{$varName} > 1) {
			next;
		}
		#End
		
		$cmd = sprintf($GV->{GREP_CMD_TPL}, 
			#'%s\.\w+\('
			sprintf($GV->{RE}->{VarCallMethod}, $varName), 
			$file
		);
		$cmd .= " >> $GV->{OUT}";
		$gUtil->execAndLogCmd($cmd);
	}
	close($hTmpVars);
	
	$cmd = sprintf($GV->{GREP_CMD_TPL},
		#'\s+%s\.[^\s]+'
		sprintf($GV->{RE}->{CallStaticMethod}, $class),
		$file
	);	
	$cmd .= " >> $GV->{OUT}";
	$gUtil->execAndLogCmd($cmd);
	
	$cmd = "echo -e \"\n\" >> $GV->{OUT}";
	$gUtil->execAndLogCmd($cmd);
}


main();
