#!/usr/bin/perl

# Last Edit: 2010  3月 30, 14時27分32秒
# $Id: /dic/branches/ctest/grade 1160 2007-03-29T09:31:06.466606Z greg  $

use strict;
use warnings;


use List::Util qw/max min sum/;

use Text::Template;
use IO::All;
use YAML qw/ LoadFile Dump DumpFile /;
# use Grades;

# my $league = League->new
my @yaml = glob "*.yaml";

my @examfiles = grep m/^round.yaml$/, @yaml;
die "too many examfiles" if $#examfiles;
my $examfile = $examfiles[0];
my $exam = LoadFile( $examfile );
my $league = LoadFile( "../../league.yaml" );
my @members = @{$league->{member}};
my %ids = map { $_->{name} => $_->{id} } @members;
my %names = map { $_->{id} => $_->{name} } @members;
my $groups = $exam->{group};
my $sixtypercentScore = $exam->{pass};
my $topGrade = $league->{examMax};
my $totalQuestions = $exam->{questions}->[0];

my @examinees = map { @{ $groups->{$_} } } keys %$groups;
my $absentees;
$absentees = $league->{absent} if $league->{absent}; 
push @$absentees, @{$exam->{absent}} if $exam->{absent};
my @absenteeIds = map { $ids{$_} } @$absentees;

my $assistants = $exam->{assistant};
$assistants = undef if grep m/No.*ne/i, @$assistants;
my @assistantIds = map { $ids{$_} } @$assistants;

my $scorefile = "scores.yaml";
my $scoresheet = LoadFile $scorefile;

my %groupName = map {
	my $groupId = $_;
	my $members = $groups->{$groupId};
	map { $_ => $groupId } @$members;
						} keys %$groups;
my $gradesheets = $league->{$exam};

my %indScores = ();
my %assistantRecords = ();
my %indScoresByScore = ();
my %groupScores = ();
my %groupScoresByScore = ();
my %points = ();
my %pointsByPoints = ();
my @number = qw/First Second Third Fourth Fifth Sixth/;

my $questions2grade = sub {
        my $questionsRight = shift;
	my $passingGrade = $topGrade * 60 / 100;
	# return sprintf '%.0f', ( $passingGrade +
        return ( $passingGrade +
		($questionsRight-$sixtypercentScore)*( $topGrade-$passingGrade)/
		($totalQuestions-$sixtypercentScore));
};

#my $grade2questions = sub {
#        my $grade = shift;
#        return 1 + int ( $passquestions +
#		($grade-$passGrade)*($totalQuestions-$passquestions)/
#		($perfectGrade-$passGrade));
#};

foreach my $group ( keys %$groups )
{
	my $members = $groups->{$group};
	my %group; @group{ 'A' .. 'D' } =  @$members; 
	my $letters = $scoresheet->{letters}->{$group};
	my $chinese = $scoresheet->{Chinese}->{$group};
	my $story = $scoresheet->{letters}->{$group}->{story};
	my %rolebearers = reverse %group;
	my @assistantPlayers;
	my (@noexam, $groupGrade);
	my $totalScore = 0;
	foreach my $player ( @$members )
	{
		my $playerId = $ids{$player};
		warn "$player has no id.\n" unless $playerId;
		my $role = $rolebearers{$player};
		warn "$player has no role.\n" if not defined $role;
		warn "$player has no letters.\n" if not defined
							$letters->{$playerId};
		my $personalScore = sum map
			{
				$letters->{$playerId}
			} 0;
		$totalScore += $personalScore;

		if (grep m/$playerId/, @assistantIds)
		{
			push @assistantPlayers, $playerId;
			my $assistantId = $playerId;
			my %assistedRecord;
			$assistedRecord{personalScore} = $personalScore,
			$assistedRecord{Chinese} = $chinese;
			$assistedRecord{group} = $group;
			$assistantRecords{$assistantId}->{$group} = 
				\%assistedRecord;
		}
		$indScores{$playerId} = $personalScore;
		push @{$indScoresByScore{$personalScore}},
							"$player $playerId\\\\";
	}
	foreach my $assistantId ( @assistantPlayers )
	{
		$assistantRecords{$assistantId}->{$group}->{totalScore} =
						$totalScore;
	}
	$groupScores{$group} = $totalScore;
	my @memberNames = values %group;
	my @groupsIds = @ids{@memberNames};
	my @memberScores = map { "$names{$_}($indScores{$_})" } @groupsIds;
	push @{$groupScoresByScore{$groupScores{$group}}},
				"$group. @memberScores. Chinese: $chinese\\\\ ";
	# $groupGrade = int (((60/100)*$topGrade/sqrt($sixtypercentScore)) *
	# 					sqrt($totalScore));
	# $groupGrade = int ((($totalScore/4)*( 9**2.3/$sixtypercentScore ))**(1/2.3) );
	$groupGrade = $questions2grade->($totalScore/4);
	$groupGrade = $groupGrade > $topGrade? $topGrade: $groupGrade;
	@points{ @groupsIds } = ($groupGrade) x @groupsIds;
	push @{$pointsByPoints{$groupGrade}},
		"$group. @names{@groupsIds} ($story)\\\\";
}

@indScores{@assistantIds} = map {
		my $assistant = $_;
		my $score = max map { $assistantRecords{$assistant}->{$_}->{personalScore} }
			keys %{$assistantRecords{$assistant}};
		$score;
				} @assistantIds if $assistants;
@points{@assistantIds} = map {
		my $assistant = $_;
		my $points = max map {
			my $totalScore = $assistantRecords{$assistant}->{$_}->{totalScore};
		my $groupGrade = $questions2grade->($totalScore/4);
		# my $groupGrade = int ((($totalScore/4)*( 9**2.3/$sixtypercentScore ))**(1/2.3) );
			$groupGrade > $topGrade? $topGrade: $groupGrade;
		} keys %{$assistantRecords{$assistant}};
		$points;
		} @assistantIds;

# @indScores{@absenteeIds} = (0)x@absenteeIds;
# push @{$indScoresByScore{0}}, "$names{$_} $_\\\\" foreach @absenteeIds;
# @points{ @absenteeIds } = (0)x@absenteeIds;
# push @{$pointsByPoints{0}}, "$names{$_} $_\\\\" foreach @absenteeIds;

my %adjusted = map
	{
	die "$_?" unless exists $points{$ids{$_}} && exists
			$scoresheet->{Chinese}->{$groupName{$_}};
	$ids{$_} => $points{$ids{$_}} - 
			$scoresheet->{Chinese}->{$groupName{$_}}
	} @examinees;
@adjusted{@assistantIds} = map
	{
		my $assistant = $_;
		my @adjusted =
			map { die "$assistant Chinese: $assistantRecords{$assistant}->{$_}->{Chinese}?"
				unless defined $assistantRecords{$assistant}->{$_}->{Chinese};
			my $totalScore = $assistantRecords{$assistant}->{$_}->{totalScore};
			my $groupGrade = $questions2grade->($totalScore/4);
			my $adjusted = $groupGrade -
				$assistantRecords{$assistant}->{$_}->{Chinese}
			}
					keys %{$assistantRecords{$assistant}};
		max @adjusted;
	} @assistantIds;
# @adjusted{@absenteeIds} = (0)x@absenteeIds;
my %adjustedByGrades = ();
map
{
	# die "$names{$_} $_?" unless exists $adjusted{$_}
					# && exists $names{$_} && defined $_;
	push @{$adjustedByGrades{$adjusted{$_}}}, "$names{$_} $_ \\\\ "
		unless $points{$_} == 0;
} values %ids;

print Dump \%adjusted;

@{$pointsByPoints{$_}} = sort @{$pointsByPoints{$_}} foreach keys %pointsByPoints;
@{$adjustedByGrades{$_}} = sort @{$adjustedByGrades{$_}}
						foreach keys %adjustedByGrades;
my @indReport = map
	{ "\\begin{small}\\vspace{-0.4cm} \\item [$_:] \\hspace*{0.5cm}\\\\@{$indScoresByScore{$_}}\\end{small}" }
		sort {$a<=>$b} keys %indScoresByScore;
my @groupReport = map 
	{ "\\vspace{-0.4cm} \\item [$_:] \\hspace*{0.5cm}\\\\@{$groupScoresByScore{$_}}" }
		sort {$a<=>$b} keys %groupScoresByScore;
my @pointReport = map 
	{ "\\vspace{-0.4cm} \\item [$_:] \\hspace*{0.5cm}\\\\@{$pointsByPoints{$_}}" }
		sort {$a<=>$b} keys %pointsByPoints;
my @adjustedReport = map 
	{ "\\vspace{-0.4cm} \\item [$_:] \\hspace*{0.5cm}\\\\@{$adjustedByGrades{$_}}" }
		sort {$a<=>$b} keys %adjustedByGrades;

my $report;
$report->{id} = $league->{id};
$report->{league} = $league->{league};
$report->{week} = $exam->{week};
$report->{round} = $exam->{round};
$report->{indScores} = join '', @indReport;
$report->{groupScores} = join '', @groupReport;
$report->{points} = join '', @pointReport;
$report->{grades} = join '', @adjustedReport;



$report->{autogen} = "% This file, report.tex was autogenerated on " . localtime() . "by grader.pl out of report.tmpl";
my $template = Text::Template->new(TYPE => 'FILE', SOURCE => 'report.tmpl'
				, DELIMITERS => [ '<TMPL>', '</TMPL>' ] );
open TEX, ">report.tex";
print TEX $template->fill_in( HASH => $report );

=begin comment text
sub scores2grade {
	my $score = shift;
	$groupGrade = int ((($totalScore/4)*( 9**2.3/$sixtypercentScore ))**(1/2.3) );
	$groupGrade = $groupGrade > $topGrade? $topGrade: $groupGrade;
	return $groupGrade;
}

