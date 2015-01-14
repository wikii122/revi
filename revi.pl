#!/usr/bin/env perl
#
# Wiktor Ślęczka
# Anno Domini 2014
#
# Revi - simple local repository file.
# Project realised for classes at Warsaw University of Technology.
#

use warnings;
use strict;
use Date::Format;
use Digest::MD5;
use File::Basename;
use File::Copy;
use File::Find;
use v5.10;

sub save {
	my @files = ();
	
	for (@_) {
		# Optional options possible.
		push @files, $_;
	}

	die "Usage: ./revi.pl save file [file]" if (scalar @files == 0);

	for my $file (@files) {
		my ($filename, $dirs, $suffix) = fileparse($file);	
		if (-d $file) {
			my ($F, @listing, @paths);

			if ($filename eq ".revi") {
				next;
			}
			
			opendir($F, $file);
			@listing = grep { !/^\.\.?$/ } readdir($F);
			closedir($F);

			@paths = ();
			for (@listing) {
				my $name = $_;
				push @paths, ($file . "/" . $name);
			}
			
			save(@paths);

		} elsif (-f $file) {
			my ($F, $hash, $size, $date, $metadir);
			
			open($F, "<", $file) or die "File could not be opened $file";
			$hash = Digest::MD5->new->addfile($F)->hexdigest();
			$size = (-s $file);
			$date = time();
			close($F);

			mkdir($dirs . ".revi/", 0755) unless (-d $dirs . ".revi/");
			$metadir = $dirs . ".revi/";
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
	my ($file, $index, @line, @lines, $hash, $filename, $dirs, $suffix, $metafile);
	$file = shift;
	$index = shift;

	die "Usage: ./revi.pl load file revision" unless defined($file) and defined($index);
	

	($filename, $dirs, $suffix) = fileparse($file);	
	$metafile = $dirs . ".revi/" . $filename;
	
	die "File is not being tracked: $file" unless (-f $metafile);
	
	open(F, "<", $metafile) or die "File could not be opened $file";
	
	@lines = <F>;
	@line = split(':', $lines[$index]);
	$hash = $line[0];
	copy($dirs . ".revi/" . $hash, $file);
}

sub formatSize {
	my ($size, @units, $unit);
    $size = shift;
    @units = qw(B KB MB GB TB PB);
    for (@units) {
		$unit = $_;
        last if $size < 1024;
        $size /= 1024;
    }
    return sprintf("%.2f%s", $size, $unit);
}

sub log_ {
	my @files = ();
	
	for (@_) {
		# Optional options possible.
		push @files, $_;
	}

	die "Usage: ./revi.pl log file [file]" if (scalar @files == 0);

	for my $file (@files) {
		my ($filename, $dirs, $suffix) = fileparse($file);	
		my $metafile = $dirs . ".revi/" . $filename;

		if (-d $file) {
			my ($F, @listing, @paths);

			if ($filename eq ".revi") {
				next;
			}

			opendir($F, $file);
			@listing = grep { !/^\.\.?$/ } readdir($F);
			closedir($F);

			@paths = ();
			for (@listing) {
				my $name = $_;
				push @paths, ($file . "/" . $name);
			}
			
			log_(@paths);

		} elsif (-f $metafile) {
			open(F, "<", $metafile) or die "File could not be opened $file";

			say "History for $filename:";
			my $index = 0;
			for (<F>) {
				my @meta = split ':';
				my $time = time2str("%c", $meta[1]);
				my $size = formatSize($meta[2]);
				say "\t", $index++, ": $time $size"
			}
			close(F);
		} else {
			say"File is not being tracked: $file"
		}
	}
}

sub remove {
	my @files = ();
	
	for (@_) {
		# Optional options possible.
		push @files, $_;
	}

	die "Usage: ./revi.pl remove file" if (scalar @files == 0);

	for my $file (@files) {
		my ($filename, $dirs, $suffix) = fileparse($file);
		my $metafile = $dirs . ".revi/" . $filename;
		
		if (-f $metafile) {
			open(F, "<", $metafile) or die "File could not be opened $file";

			my $index = 0;
			for (<F>) {
				my @meta = split ':';
				my $hash = $meta[0];
				unlink($dirs . ".revi/" . $hash);
			}
			close(F);
			unlink($metafile);
		} else {
			say "File is not being tracked: $file"
		}
	}
}

my $help = << "END";
Usage: revi command [options]
Available commands:
	load 	- loads file from repository
	save 	- saves file to repository
	log 	- shows changes in file
	remove	- removes file from tracking repository
END

my $command = shift(@ARGV) or die $help;

if ($command eq "save") {
	save(@ARGV);
} elsif ($command eq "load") {
	load(@ARGV);
} elsif ($command eq "log") {
	log_(@ARGV);
} elsif ($command eq "remove") {
	remove(@ARGV);
} else {
	print $help;
}

