#! /usr/bin/perl

use featureExtraction;
use MaxSpanningTree;

$featureData = "./modelData/featureList";
$weightData= "./modelData/featureWeights";
$testFile = "./testData/test.lab";
$testOutput = "./out.txt";
$TEST = 1;

if ($#ARGV == 2) {
	$featureData = shift;
	$weightData = shift;
	$testFile = shift;
}

if ($#ARGV == 0) {
	$testFile = shift;
}


$test = new featureExtraction($featureData, $weightData);

# then read in the test file
open (FILE, "<", $testFile) || die $!;

# record all the sentences and arrays
my @sentences;
my @POSs;
my @correctResult;
my @myResult;

while (my $input = <FILE>) {
#sentence
	chomp($input);
	my $sentence = $input;
	$sentence =~ s/\b\d+(.\d+)?\b/<num>/g;
#POS
	$input = <FILE>;
	chomp($input);
	my $POS = $input;

	push (@sentences, $sentence);
	push (@POSs, $POS);

	if (<FILE> == 0) {
		break;
	}

	$input = <FILE>;
	chomp($input);
	push (@correctResult, $input);

	if (<FILE> == 0) {
		break;
	}

}
close(FILE);

# output the result into 
open (FILE, ">", $testOutput) || die "output failed $!\n";

for (my $i = 0; $i <= $#sentences; $i++) {
	$test->extractFeatures($sentences[$i], $POSs[$i]);
	$test->calculateScore();
#    $test->printFeatureList();

	my $findTree = new MaxSpanningTree($test);
	my $edgeList = $findTree->findTree();
	shift(@$edgeList);
	my $output = join("\t",@$edgeList);
	print FILE $sentences[$i],"\n",$POSs[$i],"\n",$output,"\n\n";
	print "Sentence $i Done!\n------------------------\n";
	push (@myResult, $output);
}

if (TEST) {
	my $count = 0;
	my @mine = ();
	my @correct = ();
	my $total = 0;
	my $correctNodes = 0;
	my $i = 0;

	for ($i = 0; $i <=$#myResult; $i++) {
		@mine = split("\t", $myResult[$i]);
		@correct = split("\t", $correctResult[$i]);
		print $i,"\n";

		if ($myResult[$i] eq $correctResult[$i]) {
			$count++;
			$total += $#mine+1;
			$correctNodes += $#mine+1;
		}
		else {
			$total+= $#correct+1;
			$correctNodes += diff(\@mine, \@correct);
		}
	}
#    print "Processed:",$#myResult+1, " corrected sentence:$count, rate:", $count/($#myResult+1), ", total nodes: $total, corrected nodes: $correctNodes rate: ", $correctNodes/$total;
}

close (FILE);

sub diff {
	my $mine = shift;
	my $correct = shift;
	my $count = $#$mine+1;
	my $j = 0;

	for ($j =0;$j<=$#$mine;$j++) {
		if ($$mine[$j] ne $$correct[$j]) {
			$count--;
		}

	}

	return $count;

}
