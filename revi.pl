#!/usr/bin/env perl

use warnings;
use strict;
use Digest::MD5;
use File::Basename;
use File::Copy;
use File::Find;

sub save {
	my ($parameter, $file);
	my @files = ();
	
	foreach $parameter (@_) {
		# Optional options possible.
		push @files, $parameter
	}

	foreach $file (@files) {
		if (-d $file) {
			
		} elsif (-f $file) {
			my $F;
			my ($filename, $dirs, $suffix) = fileparse($file);	
			
			open($F, "<", $file) or die "File could not be opened $file";
			my $hash = Digest::MD5->new->addfile($F)->hexdigest();
			my $size = (-s $file);
			my $date = time();
			close($F);

			mkdir($dirs . ".revi/", 0755) unless (-d $dirs . ".revi/");
			my $metadir = $dirs . ".revi/";
			copy($file, $metadir . $hash);
			open($F, '>>', $metadir . $filename);
			say $F join(':', $hash, $date, $size); 
			close($F);
		} else {
			die "File could not be found: $file"
		}
	}
}

sub load {
	print "load\n";
}

sub log_ {
	print "log\n";
}

my $help = << "END";
Usage: revi command [options]
Available commands:
	load 	- loads file from repository
	save 	- saves file to repository
	log 	- shows changes in file
END
my $command = shift(@ARGV) or die $help;

if ($command eq "save") { 
	save(@ARGV); 
} elsif ($command eq "load") {
	load(@ARGV); 
} elsif ($command eq "log") {
	log_(@ARGV); 
} else { 
	print $help; 
}

