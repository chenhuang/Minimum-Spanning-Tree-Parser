package featureExtraction;

use featureList;

######################################################################
# The fields in this class
# featureMatrix: this is a 2D array, stored the feature list of each edge, $self->{featureMatrix}->[i]->[j]
# weightMatrix: this should be the score matrix, 
# sentence: store the input sentence as a whole string
# pos: store the pos of the input sentence as an array reference
# features: this contain all features in the model, plus features extracted from new sentence
# weights: this stores all the weights correspond to each feature, in the form of array
# tokens: this array contains all words from a sentence
######################################################################

sub new {
    @args  = @_;
    $class = $args[0];
    $self  = {};

    # need five types of data:
    # sentence structure
    # feacture vector
    # weight vector
    # extracted feature matrix
    # extracted feature weight matrix 
    $self->{featureMatrix} = ();
    $self->{weightMatrix} = ();
    my $featureNames = $args[1];
    my $featureWeights = $args[2];

    #only sentence
    if ( $#args == 1 ) {    

    }
    elsif ( $#args == 2 ) {    # only have featureData and weightData

    } elsif ($#args == 4) {   # the address of weight vector and sentence
        my $sentence        = $args[3];
        my $POS = $args[4];
        # store the information into the instance
        # read in sentence strucutre
        $self->{sentence} = \$sentence;
        $self->{pos} = ();
        $posStringRef = \$POS;
        my @pos = ();
        $pos[0] = "<root-POS>";
        push(@pos, split(/\s/, $$posStringRef));

        $self->{pos} = \@pos;

    }
    open( DATAIN, $featureNames ) || die("Could not open featuredata!\n");
    open( WEIGHTIN, $featureWeights ) || die("Counld not open weightdata!\n");

    #read in feature information and weight information.
    print "reading in features, please wait:\n";
    my $featureNames = {};
    while (<DATAIN>) {
        chomp();
        ($featureName, $index) = split(/\t/, $_);
        $featureNames->{$featureName} = $index;
        $self->{$index} = $featureName;
    }
    print "Done!\nnow start reading weight data, please wait:\n";

    close(DATAIN);

    $count = 0;
    my $weights = [];

    while(<WEIGHTIN>) {
        chomp;
        $weights->[$count++] = $_;
    }

    print "Done!\nProcessed $count features!\n";

    close(WEIGHTIN);

    # store features and weights into $self
    $self->{features} = $featureNames;
    $self->{weights} = $weights;



    bless($self, $class);
    return $self;
}

# now extarct featurelist from the input sentence
# there will be two more DS: 
# feature matrix[len][len][2]
# score matrix[len][len][2]

sub extractFeatures {
    my $self = shift;
    # contain sentence and pos
    if ($#_ == 1) {
        #need to undefine a bunch of values
        undef $self->{sentence};
        undef $self->{pos};
        undef $self->{tokens};
        undef $self->{featureMatrix};
        undef $self->{weightMatrix};

        $self->{sentence} = shift;
        my $POS = shift;

        $self->{pos} = ();
        $posStringRef = \$POS;
        my @pos = ();
        $pos[0] = "<root-POS>";
        push(@pos, split(/\s/, $$posStringRef));

        $self->{pos} = \@pos;
    }

    # get the sentence
    my $sentence = $self->{sentence};
    my @tokens = ();
    $tokens[0] = "<root>";
    push(@tokens, split(/\t/, $sentence));
    $self->{tokens} = \@tokens;

    # generate featurelists
    for ($i=0; $i<=$#tokens; $i++) {
        for ($j = 0; $j <= $#tokens; $j++) {
            next if $i == $j;
            my $fListRef = $self->createEdgeFeature($i, $j);
            $self->{featureMatrix}->[$i]->[$j] = $fListRef;
        }

    }
    # $self->printFeatureList($fListRef);
    print "Done Extract features from the sentence!\n";

}

# now the task is to calculate the score of all possible edges,
# by adding up all scores for each edge.
# the socre is stored at $self->{

sub calculateScore{
    my $self = shift;

    my $array = $self->{tokens};
    my $senLength = $#$array+1;
    print "Start to calulate scores matrix:\n";
    my $score = 0;

    # for each edge, get the feature list and calculate the score
    for (my $i = 0; $i < $senLength; $i++) {
        for (my $j = 0; $j < $senLength; $j++) {
            next if ($i == $j);
            my $fl = $self->{featureMatrix}->[$i]->[$j];           
            while (defined $$fl->{index}){
                my $no = $$fl->{index};

                while ($self->{weights}->[$no] == 0) {
                    $fl = $$fl->{next};
                    $no = $$fl->{index};
                }

                $score += $self->{weights}->[$no] if ($no ne "");
                #print "$self->{$no}:$no:$self->{weights}->[$no]\n";
                $fl = $$fl->{next};
            }
            #update the data
            $self->{weightMatrix}->[$i]->[$j] = $score;
            $score = 0;
        }
    }
    print "Sorce Matrix generated!\n";
    #   print "--------------------------------------------------------------------------------------------\n";
}

sub printFeatureList {
    my $self = shift;
    my $fL;
    my $row = $self->{featureMatrix};

    for ($i = 0; $i <= $#$row; $i++) {
            next if ($i !=  8);
        for ($j = 0; $j<= $#$row;$j++) {
            next if ($j != 7);
            $fL = $self->{featureMatrix}->[$i]->[$j];

            my $score = 0;
            while (defined $$fL->{index}) {
                my $no = $$fL->{index};
                print $self->{$$fL->{index}},"|$$fL->{index}:$self->{weights}->[$no]\n" if ($$fL->{index} <= 193793);
                $fL = $$fL->{next};
                $feature = $self->{$$fL->{index}};
                $score +=$self->{weights}->[$no];
            }
            print "score $score\n";
        }
    }
}

# for each pair of words, calcuate the features and link them together
# return the feature matrix
# input: POS vector, sentence vector, position i, position j 
sub createEdgeFeature {
    my @args = @_;

    my $self = $args[0];
    my $posAdd = $self->{pos};
    my @pos = @$posAdd; 
    my @posA = ();

    #generate array posA
    for ($item=0; $item <= $#pos; $item++) {
        $posA[$item] = substr $pos[$item], 0, 1;
    } 


    my $tokensAdd = $self->{tokens};
    my @tokens = @$tokensAdd;
    my $i = $args[1];
    my $j = $args[2];

    # direction of the edge
    my $direction;
    # distance between the two tokens
    my $dist;
    # distance gram between the two tokens
    my $distGram = 0;
    # postion of the small and large token
    my $small;
    my $large;
    # featureList
    my $fList;

    # first, decide the direction of the edge, and the distance of the token pair
    if ($i < $j) {
        $direction = "RA";   
        $dist = $j - $i;
        $small = $i;
        $large = $j;
    }
    else {
        $direction = "LA";
        $dist = $i - $j;
        $small = $j;
        $large = $i;
    }

    # based on the distance of the tokens, define the dist gram 
    if ($dist > 1) {
        $distGram = 1;
    } 
    if ($dist > 2) {
        $distGram = 2;
    }
    if ($dist > 3) {
        $distGram = 3;
    }
    if ($dist > 4) {
        $distGram = 4;
    }
    if ($dist > 5) {
        $distGram = 5;
    }
    if ($dist > 10) {
        $distGram = 10;
    }

    # the feature representation of direction and distance
    $dirDist = "&$direction&$distGram";

    # p-pos-1
    my $pLeft = $small>0?$pos[$small-1]:"STR";
    # c-pos+1
    my $pRight = $large<$#pos?$pos[$large+1]:"END";
    # b-pos: small+1
    my $pLeftRight = $small < $large-1? $pos[$small+1]:"MID";
    # b-pos: large-1
    my $pRightLeft = $large > $small+1? $pos[$large-1]:"MID";
    # brief of p-pos-1
    my $pLeftA = $small > 0? $posA[$small-1]:"STR";
    # brief of pRight
    my $pRightA = $large < $#pos?$posA[$large+1]:"END"; 
    # brief of pLeftRight
    my $pLeftRightA = $small < $large-1? $posA[$small+1]:"MID";
    # brief of pRightLeft
    my $pRightLeftA = $large>$small+1? $posA[$large-1]:"MID"; 
    # featureList, this is the root
    my $fl;
    #feature
    my $feature;

    # feature posR posMid posL
    for ($i = $small+1; $i < $large; $i++) {
        $allPos = "$pos[$small] $pos[$i] $pos[$large]";
        $allPosA = "$posA[$small] $posA[$i] $posA[$large]";

        $feature = "PC=$allPos$dirDist";
        $fl = $self->addFeature($feature, $fl);

        $feature = "1PC=$allPos";
        $fl = $self->addFeature($feature, $fl);

        $feature = "XPC=$allPosA$dirDist";
        $fl = $self->addFeature($feature, $fl);
        $feature = "X1PC=$allPosA";
        $fl = $self->addFeature($feature, $fl);
    }

    # feature posL-1 posL posR posR+1

    $feature = "PT=$pLeft $pos[$small] $pos[$large] $pRight$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "PT1=$pos[$small] $pos[$large] $pRight$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "PT2=$pLeft $pos[$small] $pos[$large]$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "PT3=$pLeft $pos[$large] $pRight$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "PT4=$pLeft $pos[$small] $pRight$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "1PT=$pLeft $pos[$small] $pos[$large] $pRight";
    $fl = $self->addFeature($feature, $fl);

    $feature = "1PT1=$pos[$small] $pos[$large] $pRight";
    $fl = $self->addFeature($feature, $fl);

    $feature = "1PT2=$pLeft $pos[$small] $pos[$large]";
    $fl = $self->addFeature($feature, $fl);

    $feature = "1PT3=$pLeft $pos[$large] $pRight";
    $fl = $self->addFeature($feature, $fl);

    $feature = "1PT4=$pLeft $pos[$small] $pRight";
    $fl = $self->addFeature($feature, $fl);

    $feature = "XPT=$pLeftA $posA[$small] $posA[$large] $pRightA$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "XPT1=$posA[$small] $posA[$large] $pRightA$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "XPT2=$pLeftA $posA[$small] $posA[$large]$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "XPT3=$pLeftA $posA[$large] $pRightA$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "XPT4=$pLeftA $posA[$small] $pRightA$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "X1PT=$pLeftA $posA[$small] $posA[$large] $pRightA";
    $fl = $self->addFeature($feature, $fl);

    $feature = "X1PT1=$posA[$small] $posA[$large] $pRightA";
    $fl = $self->addFeature($feature, $fl);

    $feature = "X1PT2=$pLeftA $posA[$small] $posA[$large]";
    $fl = $self->addFeature($feature, $fl);

    $feature = "X1PT3=$pLeftA $posA[$large] $pRightA";
    $fl = $self->addFeature($feature, $fl);

    $feature = "X1PT4=$pLeftA $posA[$small] $pRightA";
    $fl = $self->addFeature($feature, $fl);

    # feature posL posL+1 posR-1 posR
    $feature = "APT=$pos[$small] $pLeftRight $pRightLeft $pos[$large]$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "APT1=$pos[$small] $pRightLeft $pos[$large]$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "APT2=$pos[$small] $pLeftRight $pos[$large]$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "APT3=$pLeftRight $pRightLeft $pos[$large]$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "APT4=$pos[$small] $pLeftRight $pRightLeft$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "1APT=$pos[$small] $pLeftRight $pRightLeft $pos[$large]";
    $fl = $self->addFeature($feature, $fl);

    $feature = "1APT1=$pos[$small] $pRightLeft $pos[$large]";
    $fl = $self->addFeature($feature, $fl);

    $feature = "1APT2=$pos[$small] $pLeftRight $pos[$large]";
    $fl = $self->addFeature($feature, $fl);

    $feature= "1APT3=$pLeftRight $pRightLeft $pos[$large]";
    $fl = $self->addFeature($feature, $fl);

    $feature = "1APT4=$pos[$small] $pLeftRight $pRightLeft";
    $fl = $self->addFeature($feature, $fl);

    $feature = "XAPT=$posA[$small] $pLeftRightA $pRightLeftA $posA[$large]$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "XAPT1=$posA[$small] $pRightLeftA $posA[$large]$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "XAPT2=$posA[$small] $pLeftRightA $posA[$large]$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "XAPT3=$pLeftRightA $pRightLeftA $posA[$large]$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "XAPT4=$posA[$small] $pLeftRightA $pRightLeftA$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "X1APT=$posA[$small] $pLeftRightA $pRightLeftA $posA[$large]";
    $fl = $self->addFeature($feature, $fl);

    $feature = "X1APT1=$posA[$small] $pRightLeftA $posA[$large]";
    $fl = $self->addFeature($feature, $fl);

    $feature = "X1APT2=$posA[$small] $pLeftRightA $posA[$large]";
    $fl = $self->addFeature($feature, $fl);

    $feature = "X1APT3=$pLeftRightA $pRightLeftA $posA[$large]";
    $fl = $self->addFeature($feature, $fl);

    $feature = "X1APT4=$posA[$small] $pLeftRightA $pRightLeftA";
    $fl = $self->addFeature($feature, $fl);

    # feature posL-1 PosL posR-1 posR
    # feature posL posL+1 posR posR+1
    $feature = "BPT=$pLeft $pos[$small] $pRightLeft $pos[$large]$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "1BPT=$pLeft $pos[$small] $pRightLeft $pos[$large]";
    $fl = $self->addFeature($feature, $fl);

    $feature = "CPT=$pos[$small] $pLeftRight $pos[$large] $pRight$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "1CPT=$pos[$small] $pLeftRight $pos[$large] $pRight";
    $fl = $self->addFeature($feature, $fl);

    $feature = "XBPT=$pLeftA $posA[$small] $pRightLeftA $posA[$large]$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "X1BPT=$pLeftA $posA[$small] $pRightLeftA $posA[$large]";
    $fl = $self->addFeature($feature, $fl);

    $feature = "XCPT=$posA[$small] $pLeftRightA $posA[$large] $pRightA$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "X1CPT=$posA[$small] $pLeftRightA $posA[$large] $pRightA";
    $fl = $self->addFeature($feature, $fl);

    # also consider the actual words
    if ($direction eq "RA") {
        $head = $tokens[$small];
        $headP = $pos[$small];
        $child = $tokens[$large];
        $childP = $pos[$large];
    }
    else {
        $head = $tokens[$large];
        $headP = $pos[$large];
        $child = $tokens[$small];
        $childP = $pos[$small];
    }
    #print $head, "|", $headP, "|", $child, "|", $childP, "\n";

    $all = "$head $headP $child $childP";
    $hPos = "$headP $child $childP";
    $cPos = "$head $headP $childP";
    $hP = "$headP $child";
    $cP = "$head $childP";
    $oPos = "$headP $childP";
    $oLex = "$head $child";

    # Uni=gram features
    $feature = "A=$all$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "B=$hPos$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "C=$cPos$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "D=$hP$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "E=$cP$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "F=$oLex$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "G=$oPos$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "H=$head $headP$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "I=$headP$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "J=$head$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "K=$child $childP$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "L=$childP$dirDist";
    $fl = $self->addFeature($feature, $fl);

    $feature = "M=$child$dirDist";
    $fl = $self->addFeature($feature, $fl);

    #uni-gram features without direction and distance information
    $feature = "AA=$all";
    $fl = $self->addFeature($feature, $fl);

    $feature = "BB=$hPos";
    $fl = $self->addFeature($feature, $fl);

    $feature = "CC=$cPos";
    $fl = $self->addFeature($feature, $fl);

    $feature = "DD=$hP";
    $fl = $self->addFeature($feature, $fl);

    $feature = "EE=$cP";
    $fl = $self->addFeature($feature, $fl);

    $feature = "FF=$oLex";
    $fl = $self->addFeature($feature, $fl);

    $feature = "GG=$oPos";
    $fl = $self->addFeature($feature, $fl);

    $feature = "HH=$head $headP";
    $fl = $self->addFeature($feature, $fl);

    $feature = "II=$headP";
    $fl = $self->addFeature($feature, $fl);

    $feature = "JJ=$head";
    $fl = $self->addFeature($feature, $fl);

    $feature = "KK=$child $childP";
    $fl = $self->addFeature($feature, $fl);

    $feature = "LL=$childP";
    $fl = $self->addFeature($feature, $fl);

    $feature = "MM=$child";
    $fl = $self->addFeature($feature, $fl);

    # 5-gram stuff
    if (length $head > 5 || length $child > 5) {
        $hL = length $head;
        $cL = length $child;

        $head = substr $head, 0, 5 if $hL > 5;
        $child = substr $child, 0, 5 if $cL > 5;

        $all = "$head $headP $child $childP";
        $hPos = "$headP $child $childP";
        $cPos = "$head $headP $childP";
        $hP = "$headP $child";
        $cP = "$head $childP";
        $oPos = "$headP $childP";
        $oLex = "$head $child";

        # S stands for short
        $feature = "SA=$all$dirDist";
        $fl = $self->addFeature($feature, $fl);


        $feature = "SF=$oLex$dirDist";
        $fl = $self->addFeature($feature, $fl);

        $feature = "SAA=$all";
        $fl = $self->addFeature($feature, $fl);

        $feature = "SFF=$oLex";
        $fl = $self->addFeature($feature, $fl);

        if ($cL > 5) {
            $feature = "SB=$hPos$dirDist";
            $fl = $self->addFeature($feature, $fl);

            $feature = "SD=$hP$dirDist";
            $fl = $self->addFeature($feature, $fl);

            $feature = "SK=$child $childP$dirDist";
            $fl = $self->addFeature($feature, $fl);

            $feature = "SM=$child$dirDist";
            $fl = $self->addFeature($feature, $fl);
            $feature = "SBB=$hPos";
            $fl = $self->addFeature($feature, $fl);

            $feature = "SDD=$hP";
            $fl = $self->addFeature($feature, $fl);

            $feature = "SKK=$child $childP";
            $fl = $self->addFeature($feature, $fl);

            $feature = "SMM=$child";
            $fl = $self->addFeature($feature, $fl);
        }

        if ($hL > 5) {

            $feature = "SC=$cPos$dirDist";
            $fl = $self->addFeature($feature, $fl);

            $feature = "SE=$cP$dirDist";
            $fl = $self->addFeature($feature, $fl);

            $feature = "SH=$head $headP$dirDist";
            $fl = $self->addFeature($feature, $fl);

            $feature = "SJ=$head$dirDist";
            $fl = $self->addFeature($feature, $fl);

            $feature = "SCC=$cPos";
            $fl = $self->addFeature($feature, $fl);

            $feature = "SEE=$cP";
            $fl = $self->addFeature($feature, $fl);

            $feature = "SHH=$head $headP";
            $fl = $self->addFeature($feature, $fl);

            $feature = "SJJ=$head";
            $fl = $self->addFeature($feature, $fl);
        }

    }

    return $fl;
}

sub addFeature {
    @args = @_;
    my $self = $args[0];
    my $feature = $args[1];
    my $fl;

    if ($#args == 2) {
        $fl = $args[2];
    }

    my $weights= $self->{weights};
    $count = $#$weights;

    # check to see if it's in the training set, if not, add 
    if (!exists $self->{features}->{$feature}) {
        $self->{features}->{$feature} = $count+1; 
        $self->{$count+1} = $feature;

        $self->{weights}->[$count+1] = 0;
        $count++;
    }

    # create feature list
    $index = $self->{features}->{$feature};
    if ($#args == 2) {
#        print $index, "\t", $self->{weights}->[$index], $$fl, "\n";
        $fList = new featureList($index, 1, $fl);
    }
    else {
#        print $index, "\t", $self->{weights}->[$index], $$fl, "\n";
        $fList = new featureList($index, 1);
    }

    # then return the featureList 
    return $fList;

}

1;
