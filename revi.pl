#!/usr/bin/env perl
#
# Wiktor Ślęczka
# Anno Domini 2014
# 
# Revi - simple local repository file.
# Project realised for classes at Warsaw University of Technology.
#
# TODO: Comments to tracked files.
# TODO: Remove duplicate entries in metafile.
# TODO: Directory support.
# TODO: File restore.

use warnings;
use strict;
use Date::Format;
use Digest::MD5;
use File::Basename;
use File::Copy;
use File::Find;

sub formatSize {
    my $size = shift;
    my @units = qw(B KB MB GB TB PB);
	my $unit;
    for (@units) {
		$unit = $_;
        last if $size < 1024;
        $size /= 1024;
    }
    return sprintf("%.2f%s", $size, $unit);
}

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
	my ($parameter, $file);
	my @files = ();
	
	foreach $parameter (@_) {
		# Optional options possible.
		push @files, $parameter
	}

	foreach $file (@files) {
		my ($filename, $dirs, $suffix) = fileparse($file);	
		my $metafile = $dirs . ".revi/" . $filename;
		
		if (-f $metafile) {
			open(F, "<", $metafile) or die "File could not be opened $file";

			print "History for $filename:\n";
			my $index = 0;
			for (<F>) {
				my @meta = split ':';
				my $time = time2str("%c", $meta[1]);
				my $size = formatSize($meta[2]);
				print "\t", $index++, ": $time $size\n"
			}
			close(F);
		} else {
			print "File is not being tracked: $file\n"
		}
	}

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

