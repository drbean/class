#!/usr/bin/perl

use strict;
use warnings;

use Grades;
use YAML qw/LoadFile DumpFile/;

my $script = Grades::Script->new_with_options;

my $comp = $script->round;
my $league = LoadFile 'league.yaml';
my %members = map { $_->{id} => $_ } @{ $league->{member} };

my $opponents = LoadFile "${comp}/opponent.yaml";
my $correct = LoadFile "${comp}/correct.yaml";
my $points;

# $p->{absent} = $c->{absent};
# $p->{late} = $c->{late};
# $p->{opponent} = $c->{opponent};
# $p->{correct} = $c->{correct};

for my $player ( keys %$opponents ) {
       if ( $opponents->{$player} =~ m/bye/i ) {
		$points->{$player} = 5;
		next;
	}
	if ( $opponents->{$player} =~ m/unpaired/i ) {
		$points->{$player} = 0;
		next;
	}
	my $opponent = $opponents->{$player};
	my $opponentopponent = $opponents->{$opponent};
	die
"${player}'s opponent is $opponent, but
${opponent}'s opponent is $opponentopponent" unless
	$opponent and $opponentopponent and $player eq $opponentopponent;
	die "$player returned quiz card?" unless exists $correct->{$player};
	my $ourcorrect = $correct->{$player};
	die "$opponent returned card against $player?" unless exists $correct->{$opponent} or $opponent eq 'Bye';
	my $theircorrect = $correct->{$opponent};
	if ( not defined $ourcorrect ) {
		$points->{$player} = 0;
		next;
	}
	if ( not defined $theircorrect ) {
		$points->{$player} = 5;
		next;
	}
	$points->{$player} = $ourcorrect > $theircorrect? 5:
				$ourcorrect < $theircorrect? 3: 4
}

DumpFile "${comp}/points.yaml", $points;
