# this module is used to extract maximum spanning tree from the graph constructed by a sentence
package MaxSpanningTree;

use featureList;
use featureExtraction;
use POSIX qw(ceil floor);

#Input: featureExtraction class, contains the edge matrix and the score matrix
#Output: an array, contains the tree


# several constant
$LOCKEDNODE = -1;
$INFINITESMALL = -1000;

sub new {
    @args = @_;

    # current object
    my $self = {};
    # featureExtraction instance
    my $fe;
    # class
    my $class;

    # featureExtraction object passed
    if ($#args == 1) {
        $class = $args[0];
        $fe = $args[1];
        $self->{fe} = $fe;
    } 

    bless($self, $class);

#    $self->printScoreMatrix();
    return $self;
}

# print score Matrix
sub printScoreMatrix {
    my $self = shift;
    my $weightMatrix = $self->{fe}->{weightMatrix};
    my $matrixRow = $weightMatrix->[0];
    print $#$matrixRow;

    print "Matrix:\n";
    for ($i = 0; $i <= $#$matrixRow; $i++) {
            print "$i|";
    }
    print "\n";
    for ($i = 0; $i <= $#$matrixRow; $i++) {
        print "\n\n";
        for ($j = 0; $j <= $#$matrixRow; $j++) {
            $newNO = $weightMatrix->[$i]->[$j]; 
            print "$i,$j,$newNO\n";
        }
    }
    print "\n"


}

# Two possible arguments: the edge list excluding the cycle and the cycle list
sub findTree {
    @args = @_;

    my $self = @args[0];
    my $edgeList = ();
    my $weights = $self->{fe}->{weightMatrix};
    my $foundcycle = ();
    my $tokens = ();
    my $senLength = 0;
    my $recoverEdges = {};

    if ($#args == 3) {
        $edgeList = $args[1];
        $foundcycle = $args[2];
        $recoverEdges = $args[3];
    }else {
        $tokens = $self->{fe}->{tokens};
        $senLength = $#$tokens+1;
        for (my $i = 0; $i < $senLength; $i++) {
            $edgeList->[$i] = 0;
        }
    }

    # first, use greedy algorithm to find the max incoming edge for every node, except the root node
    $self->findMaxEdge($edgeList); 

    # then, check if there is a cycle in it.
    # considered the problem of lock node, but may need more scrutiny
    #print "\nedgelist: \n";
#    for (my $i = 0; $i <= $#$edgeList; $i++) {
#        print "$i:$edgeList->[$i]\t";
    #
    # }
    my $cycle = ();
    $cycle = $self->findCycle($edgeList);

    # if there is a cycle
    if ($#$cycle >= 0 ) { 
        #     print join ("\t",@$cycle);
        # found a cycle, contract
        # first add a new node
        $edgeList->[$#$edgeList+1] = 0;

        # then calculate cycle's weight, for the contraction
        my $cycleWeight = 0;
        for (my $i = 0; $i < $#$cycle; $i++) {
            $cycleWeight += $weights->[$cycle->[$i]]->[$cycle->[$i+1]]; 
        }
        $cycleWeight += $weights->[$cycle->[$#$cycle]]->[$cycle->[0]];
        # print "cycle weight:$cycleWeight";
        # go through the weight list, update weights,of other nodes to the new node

        for (my $i = 0; $i < $#$edgeList; $i++ ) {
            next if ($edgeList[$i] == $LOCKEDNODE); 
            foreach $item(@$cycle) {
                next if ($i == $item);

                # if a node is not in the cycle, and the incoming node is in the cycle 
                my $incomingNode = $item;
                my $sourceNode = $i;
                if ($self->checkCycleNode($incomingNode, $cycle) == 1 && $self->checkCycleNode($sourceNode, $cycle) == 0) {
                    # calculate if it's the best edge
                    my $currentWeight = $weights->[$incomingNode]->[$sourceNode];
                    # print "$item:",$currentWeight,"|", $weights->[$#$edgeList]->[$sourceNode],">?\n";
                    # if it's, update the weight and record the edge
                    if ($currentWeight > $weights->[$#$edgeList]->[$sourceNode]) {
                        $weights->[$#$edgeList]->[$sourceNode] = $currentWeight; 
#                        $recoverEdges->{$sourceNode}->{$#$edgeList} = $incomingNode;
                        $recoverEdges->{$#$edgeList}->{$sourceNode} = $incomingNode;

                        # print "$#$edgeList->$sourceNode: $recoverEdges->{$#$edgeList}->{$sourceNode}, weight:$currentWeight\n" if ($#$edgeList == 14) ;
                    }
                }

                $incomingNode = $i;
                $sourceNode = $item;

                # if a node is in the cycle, but the incoming edge is not in the cycle
                if ($self->checkCycleNode($incomingNode, $cycle) == 0 && $self->checkCycleNode($sourceNode, $cycle) == 1) {
                    my $currentWeight = $weights->[$incomingNode]->[$sourceNode]+ $cycleWeight-$weights->[$self->predNode($sourceNode, $cycle)]->[$sourceNode];
                    #print "currentWeight:$incomingNode-$sourceNode:$currentWeight\n";
                    if ($currentWeight > $weights->[$incomingNode]->[$#$edgeList]) {
                        $weights->[$incomingNode]->[$#$edgeList] = $currentWeight;
#                        $recoverEdges->{$#$edgeList}->{$incomingNode} = $sourceNode;
                        $recoverEdges->{$incomingNode}->{$#$edgeList} = $sourceNode;
                        # print "$incomingNode->$#$edgeList: $recoverEdges->{$incomingNode}->{$#$edgeList}, weight:$currentWeight\n" if ($#$edgeList == 14) ;
                    }

                }
            }
        }

        # update lock cycle nodes
        foreach $item(@$cycle) {
            $edgeList->[$item] = $LOCKEDNODE;
        }

#        $self->printScoreMatrix if ($#$edgeList == 13);
        # then recursively do it again.
        # print "edgeList: @$edgeList\n";
        $self->findTree($edgeList, $cycle, $recoverEdges);

    }  

    #print "\nSo done finding cycle \n";
    if ($#$edgeList == $#$tokens) {
#        print "The final parsing result:\n",join("|",@$tokens),"\n",join("|", @$edgeList),"\n";
        my $rootExist = 0;
        for ($i = 1; $i <= $#$edgeList; $i++) {
            if ($$edgeList[$i] == 0) {
                $rootExist = 1;
            }
        }

        if ($rootExist == 0) {
            my $maxEdge = 0;
            my $maxWeight = -100;
            my $weightMatrix = $self->{weightMatrix};
            for($i = 1; $i <= $#$edgeList; $i++) {
                if ($weightMatrix->[0]->[$i] > $maxWeight) {
                    $maxWeight = $weightMatrix->[0]->[$i];
                    $maxEdge = $i;
                }
            }

            $$edgeList[$$edgeList[$maxEdge]] = 0;
        } 
        return $edgeList;
    }

    # no cycle
    # now time to decode
    #  $self->{finalGraph} = $edgeList;

    # replace the edge later added.
    # for edge's incoming node is cycle, replace the cycle with the selected node
#    print "decode begin: \ncycle:",join("\t", @$foundcycle),"\n";
#    print "The longest edgelist: ",join(" | ", @$edgeList),"\n";
    for (my $i = 0; $i <= $#$edgeList; $i++) {
        if ($edgeList->[$i] == $#$edgeList) {
            my $oldEdge = $recoverEdges->{$#$edgeList}->{$i};
            $edgeList->[$i] = $oldEdge;
        }

        # print join(" | ", @$edgeList),"\n";
        # for edges from outside to cycle
        # 1. add the cycle into the graph
        # 2. remove edges that will cause cycle
        if ($i == $#$edgeList) {
            my $oldEdge = $recoverEdges->{$edgeList->[$i]}->{$i};
            $$edgeList[$oldEdge] = $$edgeList[$i];
            my $preOldEdge = $self->predNode($oldEdge, $foundcycle);
            # print "preoldedge for $oldEdge is $preOldEdge";

            # add cycle into the graph
            # to save further substle, make a cycle for computer
            push(@$foundcycle, $$foundcycle[0]);

            for (my $i = 1; $i <= $#$foundcycle; $i++) {
                next if ($$foundcycle[$i-1] == $preOldEdge);
                $$edgeList[$$foundcycle[$i]] = $$foundcycle[$i-1];
            }

            pop(@$foundcycle);

        }
    }
    pop(@$edgeList);
}


# find the MaxEdge of a node
sub findMaxEdge {
    my $self = shift;
    my $edgeList = shift;


    my $weightMatrix =  $self->{fe}->{weightMatrix};

    for (my $i = 1; $i <= $#$edgeList; $i++) {

        my $currentMaxNode = $INFINITESMALL;
        my $currentMaxWeight = $INFINITESMALL;
        my $currentWeight = $INFINITESMALL;
        next if $edgeList->[$i] == $LOCKEDNODE;

        for (my $j = 0; $j <= $#$edgeList; $j++) {
            next if $edgeList->[$j] == $LOCKEDNODE;
            next if ($i == $j);

            $currentWeight = $weightMatrix->[$j]->[$i];

            if ($currentWeight > $currentMaxWeight) {
                $currentMaxWeight = $currentWeight;
                $currentMaxNode = $j;
            }
        }
#        print "findMaxEdge: $currentMaxNode->$i:$currentMaxWeight\n";
#        print "\n"; 
        $edgeList->[$i] = $currentMaxNode;
    }
    #print "------------------------------------------------------------\n";
}

# find cycles in a graph, use DFS
# the point of cycle is that if a unfinished node has been visited twice, then there is a cycle
sub findCycle {
    my $self = shift;
    my $edges = shift;

    # print "Looking for cycles\n";
    # three statuses for each node: unvisited:0, unfinished:1, finished:2
    my @status = ();
    # record the cycle
    my @cycle = ();

    for (my $i = 0; $i <= $#$edges; $i++) {
        $status[$i] = 0;
        if ($edges->[$i] == $LOCKEDNODE) {
            $status[$i] = 2;
        }
    }

    # for node 0, just finish it, we know it's a dead end
    $status[0] = 2;

    #print @status,"\n";
    # travsal the whole graph
    for (my $i = 1; $i <= $#$edges; $i++) {
        # if unvisited, visit
        if ($status[$i] == 0) {
            # find a cycle if return none zero, cycle contains all the edges
            $self->visit($i, \@status, $edges, \@cycle);

            # if there is a cycle 
            if ($#cycle >=  0) {
                return \@cycle; 
            }
        }
    }

    return 0;
}

# sub method for finding cycle
sub visit {
    my $self = shift;
    my $s = shift;
    my $status = shift;
    my $edges = shift;
    my $cycle = shift;

    $$status[$s] = 1;

    # check s's child, if it's unvisited, visit
    if ($$status[$$edges[$s]] == 0) {
        my $node = $self->visit($$edges[$s], $status, $edges, $cycle);
        # judge if there is a cycle
        if ($node != -1) {
            if ($s != $node) {
                push(@$cycle, $s);
                $$status[$s] = 2;
                return $node;
            }

            if ($s == $node) {
                push(@$cycle, $s);
                $$status[$s] = 2;
                return -1;
            }

        }
        # then mark it as finished
        $$status[$s] = 2;
    }

    # if it's unfinishied, find a cycle,and return the cycle
    if ($$status[$$edges[$s]] == 1) {
        push(@$cycle, $s);
        $$status[$s] = 2;
        #print $cycle->[$#$cycle];
        return $$edges[$s];
    }

    # if it's finished, return;
    if ($$status[$$edges[$s]] == 2) {
        $$status[$s] = 2;
        return -1; 
    }

}

# check if a node is in the cycle
sub checkCycleNode {
    my $self = shift;
    my $node = shift;
    my $cycle = shift;

    foreach $item(@$cycle) {
        if ($item == $node) {
            return 1;
        }
    }

    return 0;
}

# return previous node of a node
sub predNode {
    my $self = shift;
    my $node = shift;
    my $cycle = shift;

    for (my $i = 0; $i <= $#$cycle; $i++) {
        if ($cycle->[$i] == $node) {
            if ($i == 0) {
                return $cycle->[$#$cycle];
            }
            return $cycle->[$i-1];
        }
    }

    return -1;

}

1;
