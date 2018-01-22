#!/usr/bin/perl -w
#
#
#  Author: Kata Gabor
#          gabor@lipn.univ-paris13.fr
#          LIPN Universite Paris 13
#
#  This is the official scorer for SemEval-2018 Task #7.
#  Based on the  official scorer for SemEval-2010 Task #8 by Preslav Nakov.
#
#  Last modified: Aug 14, 2017
#  Current version: 1.1
#
#  Use:
#     semeval2018_task7_scorer.v1.1pl <PROPOSED_ANSWERS> <ANSWER_KEY>
#
#  Example:
#     semeval2018_task7_scorer.v1.1.pl 1.1.test.answers1.txt 1.1.test.key.txt > 1.1.result.txt
#
#	
#     The first file can have predictions for a subset of the second file only. Repetitions 
#	  of relation instances (multiple lines with identical argument IDs) are not allowed.
#	  The input format for submissions for each subtask is :
#	  RELATION_NAME(argID1,argID2)
#	  e.g.:
#	  USAGE(P03-1068.1,P03-1068.2)
#     The lines do not have to be sorted. Relation instances are identified by the IDs of
#	  the arguments. Arguments have to be sorted in the order in which they appear in the
#	  text, i.e. ascending order of their IDs. 
#	  For the classification tasks, directionality is taken into account. It is encoded as
#	  follows: if the first argument of the semantic relation comes second in the text, the  
#	  REVERSE attribute has to be added:
#	  USAGE(P03-1068.1,P03-1068.2,REVERSRE)
#
# 	  In the classification tasks, a prediction with wrong directionality or a prediction 
#	  for an instance which is not in the gold standard will be considered as wrong. 
#	  
#	  In the extraction task, directionality and relation labels are not taken into account. 
#	  Pairs that are not in the gold standard are considered as wrong.	  
#
#     The scorer calculates and outputs the following statistics:
#		 (1) precision, recall, F1 measure for the extraction task       
#		 (2) number of instances in both files; number of wrong and skipped instances 
#        (3) coverage
#        (4) precision (P), recall (R), and F1-score for each relation
#        (5) micro-averaged P, R, F1
#        (6) macro-averaged P, R, F1
#
#
#     The official score is F1-score for the extraction task, and macro-averaged F1-score 
#	  for the classification task.

use strict;


###############
###   I/O   ###
###############

if ($#ARGV != 1) {
	die "Usage:\nsemeval2018_task7_scorer.v1.1.pl <PROPOSED_ANSWERS> <ANSWER_KEY>\n";
}

my $PROPOSED_ANSWERS_FILE_NAME = $ARGV[0];
my $ANSWER_KEYS_FILE_NAME      = $ARGV[1];


################
###   MAIN   ###
################

my (%confMatrix6way) = ();
my (%idsProposed, %idsAnswer) = ();
my (%idsExtracted, %idsToBeExtracted) = ();
my (%allLabels6waylAnswer, %allLabels6wayProposed) = ();

###  Read the file contents
my $totalAnswer = &readFileIntoHash($ANSWER_KEYS_FILE_NAME, \%idsAnswer, \%idsToBeExtracted);
my $totalProposed = &readFileIntoHash($PROPOSED_ANSWERS_FILE_NAME, \%idsProposed, \%idsExtracted);
	

### Evaluation of the extraction task
my ($correct,$totalExtracted,$totalToBeExtracted) = 0;
my %seen = ();
	
foreach my $instance (keys %idsExtracted, keys %idsToBeExtracted) {
		next if (defined $seen{$instance});
		if (defined $idsExtracted{$instance}) {$totalExtracted++;}
		if (defined $idsToBeExtracted{$instance}) {$totalToBeExtracted++;}	
		if ((defined $idsExtracted{$instance}) && (defined $idsToBeExtracted{$instance})) {$correct++;}	
		$seen{$instance} = 1;
	}
	
if (!defined($correct)) {$correct = 0;}
if (!defined($totalExtracted)) {$totalExtracted = 0;}
	
print "\n<<< RELATION EXTRACTION EVALUATION >>>\n\n";
	
### Output the precision of extraction
my $P  = (0 == ($correct * $totalExtracted)) ? 0 : 100.0 * $correct / $totalExtracted;
printf "%s%d%s%d%s%5.2f%s", 'Precision = ', $correct, '/', $totalExtracted, ' = ', $P, "\%\n";

### Output the recall of extraction
my $R  = (0 == ($correct * $totalToBeExtracted)) ? 0 : 100.0 * $correct / $totalToBeExtracted;
printf "%s%d%s%d%s%5.2f%s", 'Recall = ', $correct, '/', $totalToBeExtracted, ' = ', $R, "\%\n";

### F1-score
my $F1 = (0 == $P + $R) ? 0 : 2.0 * $P * $R / ($P + $R);
printf "F1 = %0.2f%s \n\n", $F1, '%';

printf "<<< The official score for the extraction scenario is F1 = %0.2f%s >>>\n\n", $F1, '%';


### Evaluation of the classification task, if the submission contains predictions

if ( %idsProposed) { 
my $wronginstances = 0;

### Calculate the confusion matrices
	foreach my $id (keys %idsProposed) {

	 	if (!defined($idsAnswer{$id})) { $wronginstances++;}
	
		### Update the confusion matrix
		my $labelProposed = $idsProposed{$id};
		my $labelAnswer   = $idsAnswer{$id};
		if (defined $labelAnswer) {$confMatrix6way{$labelProposed}{$labelAnswer}++;}  
		$allLabels6wayProposed{$labelProposed}++; 

	}
	### Calculate the ground truth distributions
	foreach my $id (keys %idsAnswer) {
		
		### Update the answer distribution
		my $labelAnswer = $idsAnswer{$id};
		$allLabels6waylAnswer{$labelAnswer}++;

	}
 
	###  Print evaluation score details
	print "\n<<< RELATION CLASSIFICATION EVALUATION >>>:\n\n";

	printf "Number of instances in submission: $totalProposed\n";
	printf "Number of instances in submission missing from gold standard: $wronginstances\n";

 	my $officialScore = &evaluate(\%confMatrix6way, \%allLabels6wayProposed, \%allLabels6waylAnswer, $totalProposed, $totalAnswer, $wronginstances);

 	### Output the official score
	printf "<<< The official score for the classification scenario is macro-averaged F1 = %0.2f%s >>>\n\n", $officialScore, '%';
	} 
	else { 

	print "\n<<< No classification predictions in the submission file: classification evaluation omitted. >>>\n\n";
}

################
###   SUBS   ###
################

sub getIDandLabel() {
	my $line = shift;
	if ($line =~ /^([A-Z].+?)\((.+)\)/) {
		my ($label,$id) = ($1, $2);
		return ($id, $label)
    	if (($label eq 'ANY') || ($label eq 'USAGE') || ($label eq 'TOPIC') || ($label eq 'RESULT') || ($label eq 'PART_WHOLE') || ($label eq 'COMPARE')  || ($label eq 'MODEL-FEATURE'));
	
		return (-1, ());
	}	
	else { die "Bad format in line: '$_'\n";}
}


sub readFileIntoHash() {
	my ($fname, $ids, $extracted) = @_; 
	open(INPUT, $fname) or die "Failed to open $fname for text reading.\n";
	my $lineNo = 0;
	my $classif_proposed = 0;
	
	while (<INPUT>) {
		my ($id, $label) = &getIDandLabel($_);
		die "Bad file format 1 on line $lineNo: '$_'\n" if ($id !~ /^[A-Z0-9]+-[0-9]+\.[0-9]+,[A-Z0-9]+-[0-9]+\.[0-9]+/);
		
		### line parsed for extraction
		my $extrid = ();
		my ($id1, $idnb1, $id2, $idnb2) = $id =~ /^(.+\.([0-9]+)),(.+\.([0-9]+)),?[A-Z]*$/;
		### normalize the order of arguments
		if ($idnb2 < $idnb1) {$extrid = "$id2,$id1";}
		else {$extrid = "$id1,$id2";}
		$$extracted{$id} = 1; 
		
		### line parsed for classification
		if ($label ne 'ANY') {
			$classif_proposed++;	

			if (defined $$ids{$id}) {
				s/[\n\r]*$//;
				die "Bad file format 2 on line $lineNo (ID $id is already defined): '$_'\n";
			}
			$$ids{$id} = $label;   
		}
		$lineNo++;		
	}
	close(INPUT) or die "Failed to close $fname.\n";
	if ($lineNo == 0) {die "Submission file is empty.\n"}
	return $classif_proposed;
}


sub evaluate() {

	my ($confMatrix, $allLabelsProposed, $allLabelsAnswer, $totalProposed, $totalAnswer, $wronginstances) = @_;

	### Create a merged list from Proposed and from Answer
	my @allLabels = ();
	&mergeLabelLists($allLabelsAnswer, $allLabelsProposed, \@allLabels);

	my $freqCorrect = 0;
	my $ind = 1;
	foreach my $labelAnswer (sort keys %{$allLabelsAnswer}) {

		my $sumProposed = 0;
		foreach my $labelProposed (@allLabels) {
			$$confMatrix{$labelProposed}{$labelAnswer} = 0
				if (!defined($$confMatrix{$labelProposed}{$labelAnswer}));
			$sumProposed += $$confMatrix{$labelProposed}{$labelAnswer};
		}

		my $ans = defined($$allLabelsAnswer{$labelAnswer}) ? $$allLabelsAnswer{$labelAnswer} : 0;
		$ind++;

		$$confMatrix{$labelAnswer}{$labelAnswer} = 0
			if (!defined($$confMatrix{$labelAnswer}{$labelAnswer}));
		$freqCorrect += $$confMatrix{$labelAnswer}{$labelAnswer};
	}


	### Print stats

	printf "Number of instances in gold standard: %4d\nNumber of instances in gold standard missing from submission: %4d\n\n", $totalAnswer, $totalAnswer - $totalProposed;

	my $coverage = 100.0 * ($totalProposed - $wronginstances) / $totalAnswer;
	printf "%s%d%s%d%s%5.2f%s", 'Coverage (predictions for a correctly extracted instance with correct directionality) = ', ($totalProposed - $wronginstances), '/', $totalAnswer, ' = ', $coverage, "\%\n";

	### Output P, R, F1 for each relation
	my ($macroP, $macroR, $macroF1) = (0, 0, 0);
	my ($microCorrect, $microProposed, $microAnswer) = (0, 0, 0);
	print "\nResults for the individual relations:\n";
	foreach my $labelAnswer (sort keys %{$allLabelsAnswer}) {

		### Prevent Perl complains about unintialized values
		if (!defined($$allLabelsProposed{$labelAnswer})) {
			$$allLabelsProposed{$labelAnswer} = 0;
		}

		### Calculate P/R/F1
		my $P  = (0 == $$allLabelsProposed{$labelAnswer}) ? 0
				: 100.0 * $$confMatrix{$labelAnswer}{$labelAnswer} / ($$allLabelsProposed{$labelAnswer});
		my $R  = (0 == $$allLabelsAnswer{$labelAnswer}) ? 0
				: 100.0 * $$confMatrix{$labelAnswer}{$labelAnswer} / $$allLabelsAnswer{$labelAnswer};
		my $F1 = (0 == $P + $R) ? 0 : 2.0 * $P * $R / ($P + $R);

		### Output P/R/F1
		printf "%25s%s%4d%s%4d%s%6.2f", $labelAnswer,
				" :    P = ", $$confMatrix{$labelAnswer}{$labelAnswer}, '/', ($$allLabelsProposed{$labelAnswer}), ' = ', $P;
		printf"%s%4d%s%4d%s%6.2f%s%6.2f%s\n",
		  	 "%     R = ", $$confMatrix{$labelAnswer}{$labelAnswer}, '/', $$allLabelsAnswer{$labelAnswer},   ' = ', $R,
			 "%     F1 = ", $F1, '%';

		### Accumulate statistics for micro/macro-averaging
			$macroP  += $P;
			$macroR  += $R;
			$macroF1 += $F1;
			$microCorrect += $$confMatrix{$labelAnswer}{$labelAnswer};
			$microProposed += $$allLabelsProposed{$labelAnswer};
			$microAnswer += $$allLabelsAnswer{$labelAnswer};
	}

	### Output the micro-averaged P, R, F1
	my $microP  = (0 == $microProposed)    ? 0 : 100.0 * $microCorrect / $microProposed;
	my $microR  = (0 == $microAnswer)      ? 0 : 100.0 * $microCorrect / $microAnswer;
	my $microF1 = (0 == $microP + $microR) ? 0 :   2.0 * $microP * $microR / ($microP + $microR);
	print "\nMicro-averaged result :\n";
	printf "%s%4d%s%4d%s%6.2f%s%4d%s%4d%s%6.2f%s%6.2f%s\n",
		      "P = ", $microCorrect, '/', $microProposed, ' = ', $microP,
		"%     R = ", $microCorrect, '/', $microAnswer, ' = ', $microR,
		"%     F1 = ", $microF1, '%';

	### 10. Output the macro-averaged P, R, F1
	my $distinctLabelsCnt = keys %{$allLabelsAnswer}; 
	
	$macroP  /= $distinctLabelsCnt; 
	$macroR  /= $distinctLabelsCnt;
 	$macroF1 = (0 == $macroP + $macroR) ? 0 :   2.0 * $macroP * $macroR / ($macroP + $macroR);
	print "\nMacro-averaged result :\n";
	printf "%s%6.2f%s%6.2f%s%6.2f%s\n\n\n\n", "P = ", $macroP, "%\tR = ", $macroR, "%\tF1 = ", $macroF1, '%';

	### 11. Return the official score
	return $macroF1;
}


sub getShortRelName() {
	my ($relName, $hashToCheck) = @_;
	
	die "relName='$relName'" if ($relName !~ /^(...)/);
	my $result = (defined $$hashToCheck{$relName}) ? "$1" : "*$1";
	return $result;
}

sub mergeLabelLists() {
	my ($hash1, $hash2, $mergedList) = @_;
	foreach my $key (sort keys %{$hash1}) {
		push @{$mergedList}, $key;
	}
	foreach my $key (sort keys %{$hash2}) {
		push @{$mergedList}, $key if (!defined($$hash1{$key}));
	}	
}
