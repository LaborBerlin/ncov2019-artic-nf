#!/bin/env perl
#
# This script modifies the SAM output from BWA for circumnavigating some peculiarities of the library
#
# Current modififications:
# - For reads starting at positions 21617 to 21619 (i.e. the forward read of amplicon containing del6970),
#   softclip the last 40 bases
#

use warnings;
use strict;

my $n_soft = 40;

while(<>) {
	if(/^@/) { print; next; }
	my @F = split(/\t/, $_);
	if($F[3] < 21617 or $F[3] > 21619) { print; next; }
	if(length($F[9]) < 100) { print; next; }
	if($F[5] eq "*") { print; next; }

	my $cigar = $F[5];
	my $out_cigar = "";
	# there are already at least $n_soft soft-clipped bases at the end of the CIGAR
	# then do nothing
	if($cigar =~ m/(\d+)S$/ and $1 >= $n_soft) {
		$out_cigar = $cigar;
	}
	else {
		# incrementally fetch the last part of the CIGAR and sum up their lengths until $n_soft is reached
		my $sum = 0;
		while(1) {
			if($cigar =~ m/((\d+[SMINDH])*)(\d+)([NDH])$/) { # hard clips, dels and ref skips are not counted
				$cigar = $1;
			}
			elsif($cigar =~ m/((\d+[SMINDH])*)(\d+)([SMI])$/) {
				$sum += $3;
				if($sum > $n_soft) {
					$out_cigar =  $1 . ($sum - $n_soft) . $4 . $n_soft . "S";
					last;
				}
				else {
					$cigar = $1;
				}
			}
			else { # last field was read, but number of bases in alignment is < $n_soft
				$out_cigar = $sum . "S";
				last;
			}
		}
		$F[5] = $out_cigar;
		print join("\t", @F)
	}

}

