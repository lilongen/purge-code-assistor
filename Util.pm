#!/usr/bin/perl
package Util;


use strict;
use English;
use Data::Dumper;
use Storable;
use JSON;

sub new() {
	my $pkg = shift;
	
    my $self = {};
    bless $self, $pkg;
 
    return $self;
}

sub dumpFile() {
	my $self = shift;	
	my $file = shift;
	my $obj = shift;
	store($obj, $file);
}

sub loadFile() {
	my $self = shift;	
	my $file = shift;
	return retrieve($file);
}

sub readFileIntoArray() {
	my $self = shift;	
	my $file = shift;
	my $inArray = shift;
	
	open(my $h, $file) or die "Fail to open $file";
	while (!eof($h)) {
		my $line = <$h>;
		$line =~ s/\n//g;
		push(@{$inArray}, $line);
	}
	
	close($h);
}

sub execAndLogCmd() {
	my $self = shift;	
	my $cmd = shift;
	system($cmd);
	$self->logInfo($cmd);
}

sub logInfo() {
	my $self = shift;	
	my $info = shift;
	my $newLine = shift;
	print($info . (defined($newLine) ? "" : "\n"));	
}

sub persistBinAndJsonVarToFile() {
	my $self = shift;	
	my $file = shift;
	my $var = shift;
	$self->dumpFile("$file.bin", $var);
	$self->jsonVariable2File("$file.json", $var);
}

sub jsonVariable2File() {
	my $self = shift;	
	my $file = shift;
	my $var = shift;	
	
	my $json = new JSON();
	$self->out2File($file, $self->toJSON($var));
}

sub toJSON() {
	my $self = shift;	
	my $var = shift;
	
	my $json = new JSON();
	return $json->pretty->encode($var);				
}

sub out2File() {
	my $self = shift;	
	my $file = shift;
	my $content = shift;	
	
	open(my $h, '>', $file) or die "Can not open $file\n";
	print $h $content;
	close($h);		
}

sub readFileContent() {
    my $self = shift;
    my $file = shift;
    my $start = shift;
    my $end = shift;
    
    if (!open(INPUT, "<", $file)) {
        return undef;   
    }
    seek(INPUT, $start, 0);
    
    my $content = "";
    my $a_len = read(INPUT, $content, $end - $start);
    close INPUT;

    return $content;
}

sub readFileAllContent() {
    my $self = shift;
    my $file = shift;
    my $start = shift;
    my $end = shift;
    
    return $self->readFileContent($file, 0, 2147483647);
}

#===============================================================================
#
# END of the module.
#
#===============================================================================
1;
__END__
