
#message_tag.pm
use strict;
use warnings;
use Carp;


###############################################################################
#Calss to store the tags of a single log message. 
#This is a single log message converted to tags by the filters.
#Internally the tags are stored in an array. 
#eg: ["one", "two", "three" ]    <- one log msg.
package TagMsg; 
use strict;
use warnings;
use Carp qw(cluck confess croak);

sub new {
	my ($class) = shift; #perl will automatically pass this
    #my @tags_a = @_;     #collect if some tags are passed	
	my $tags = shift || {} ; #if nothing is passed init with an empty arr re

	bless $tags, ref($class) || $class;
    return $tags;
}


#adds a tag to the tag store. 				
sub add {
	my $self  = shift;
	
	#DELIMITER as \t
	#remove all \t from the incoming values;
	if ( grep /\t/, @_ ) {
		confess "values cannot contain tabs\n";
	}
	
	my %tag_values;
	if ( @_ == 1 ) { #only one value
		$tag_values{$_[0]} = 1;
	}
	else {
		%tag_values = @_;
	}
	foreach my $t (@_) {
		if ( not defined $t or $t eq "" ) {
			confess "empty tag or value: $t\n";
		}
	}
	@{$self}{keys %tag_values} = values %tag_values;
	
}


#checking if the tag store has a particular tag or value.
sub has {
	my $self  = shift;
	my $tag = shift;
	
	foreach ( keys %$self, values %$self ) {
		if ($_ eq $tag) {
			return 1;
		}
	}
	return;
}

#returns the tag value if given earlier; If not found, return undef
sub value {
	my $self  = shift;
	my $tag = shift;	
	if ( exists $self->{$tag} ) {
		return $self->{$tag};
	}
	return;
}

#returns all the names of the message tag.
sub tags {
	my $self  = shift;
	return keys %$self ;
}


sub string {
	my $self  = shift;
	#DELIMITER as \t
	return join "\t" , map "$_\t$self->{$_}", sort keys %$self; 
}

#small perl magic. We want to have a short cut to $msg->value( 'ddd' )
#it is nice if we can do like this: $msg->ddd to get its value.
# This fucntion will do that. 
sub AUTOLOAD {
	my $self  = shift;
	use vars '$AUTOLOAD';
	my $tagname = $AUTOLOAD;
	$tagname =~ s/.*:://;
	return $self->value( $tagname );
}

###############################################################################
# This is the class that stores all the msg summaries. 
# It is just and array of TagMsg objects,

package TagLog;
use strict;
use warnings;
use Carp qw(cluck confess croak);

sub new {
	my ($class) = shift; #perl will automatically pass this     	
	my $log_array = shift || [];
	
	bless  $log_array, ref($class) || $class;
    return $log_array;
}

#sub array {
#	my $self  = shift;
#	return $self->{'summary_array'}
#}

sub add { #add msg summary to the array
	my $self  = shift;
	my $tag_msg   = shift; 

	push @$self, $tag_msg;
}

sub end {
	my $self  = shift;

	return scalar( @$self ) - 1; #last index is one less than size.
}

sub index {
	my $self  = shift;
	my $index = shift;

	return $self->[$index];
}


sub save { #save to a file
	my $self  = shift;
	my $filename = shift;
	open my $file, ">", $filename or die "cannot save to $filename: $!";
	for my $i ( 0 .. $self->end()) {
		if ( $self->index($i) ) {
			my $str = $self->index($i)->string();
			if ($str !~ m/^\s*$/) { #empty string
				print $file $str, "\n";
			}
		}
	}
}

sub load { #load msg summary from a file
	my $self  = shift;
	my $filename = shift;
	open my $file, "<", $filename or die "cannot load from $filename: $!";
	my @lines = <$file>;
	load_array($self, \@lines);
}

sub load_array { #loads from an array
	my $self  = shift;
	my $array_ref = shift;
	foreach my $line ( @$array_ref ) {
		chomp ($line);
		#DELIMITER as \t
		my @tags = split("\t",$line); #we use , as a field seperator
		next if not @tags; #skip blank lines
		#create a new msg_tag object
		my %h = @tags;
		my $tag_msg = TagMsg->new( \%h ); 
		$self->add ( $tag_msg ); #add the tags to Array.
	}
}


#This function searches for a pattern in the log and returns the start and end index.
#The pattern is a regular expression with (start,middle,not,end))
#start and end index are optional.


sub find_sequence {
	my $log   = shift; #self
	my $query = shift;
	my $start = shift || 0;
	my $end   = shift || $log->end();	
	
	return LogSearch::find_sequence($log, $query, $start, $end );

}


# This is not a class but just a module to hold the search functions.
package LogSearch;
use strict;
use warnings;
use Carp qw(cluck confess croak);

#This is a little complicated function.
#It takes an array with markers like start, end, not, and middle. 
#

sub find_sequence {
	my ($log, $query, $start, $end) = @_; #arguments. start and end are optional.
	$start = 0 if not defined $start;
	$end = $log->end() if not defined $end;
	
	#print "in find_sequence with $query\n";
	
	if ( ( $start > $end ) || ( $end > $log->end() ) ) { #check the start and end index
		return undef; #did not find.
	}

	my @starts = find_pattern( $log, $query->{'start'}, $start, $end );
	#print join(" ", @starts), "\n"; 
	
	return if ( not @starts );
	
	#print "found start\n";
	
	if ( not exists $query->{'end'} ) {
		return @starts; #only start pattern is present.
	}	
	my @ends = find_pattern( $log, $query->{'end'}, $starts[1]+1, $end );
	#print join(" ", @ends), "\n";
	
	
	my @middles;
	if ( exists $query->{'middle'} ) {
		@middles = find_pattern( $log, $query->{'middle'}, $starts[1]+1, $end );
	}
	
	my @nots;
	if ( exists $query->{'not'} ) {
		@nots = find_pattern( $log, $query->{'not'}, $starts[1]+1, $end );
	}
	
	my @results;
	my $s = 0;	#a value lower than 0 sothat get next will start from 0	
	while ( my ($s_start, $s_end) = get_next( \@starts, $s) ) {
	
		#print "starts from $s : $s_start, $s_end\n";
	
		my $e = $s_end + 1;			
		while ( my ($e_start, $e_end) = get_next( \@ends, $e ) ) {
			my $ok = 1;
			#print "ends from $e : $e_start, $e_end\n";
			
			if ( exists $query->{'middle'} and not (my $pos = is_present( \@middles, $s_end+1, $e_start-1)) ) {
				$s_end = $e_end; #just to update the $s at the end of the loop.
				#we need to continuw the loop of ends.
				$ok = 0;
			}
			
			if (  exists $query->{'not'} and (my $pos = is_present( \@nots, $s_end+1, $e_start-1)) ) {
				#now this whole start is invalid. Because with this start we will never find a match. 
				#we have to begin again with a start just after the not.
				$s_end = $pos->[0] - 1; #this is the start of not. #-1 is to offset the +1 at the end of the loop.
				last;
				$ok = 0;
			}
			
			#if ( middle_present( $log, $query, $s_end+1, $e_start-1) and not not_present( $log, $query, $s_end+1, $e_start-1) ) {
			if ( $ok ) {
				push @results, $s_start, $e_end;
				#update the start pointer
				$s_end = $e_end; #just to update the $s at the end of the loop.
				last;
			}
			$e = $e_end + 1; #move the end pointer.
		}
		$s = $s_end + 1; 
	}
	return @results;	
}


sub get_next {
	my $a = shift;
	my $v = shift;
	for( my $i = 0 ; $i < @$a; $i += 2) {
		if ( $a->[$i] >= $v ) {
			return ($a->[$i], $a->[ $i+1 ]);
		}
	}
	return;
}

sub is_present {
	my $a = shift;
	my $s = shift;
	my $e = shift;
	for( my $i = 0 ; $i < @$a; $i += 2) {
		if ( $a->[$i] >= $s && $a->[$i+1] <= $e) {
			return [$a->[$i], $a->[$i+1]];
		}
	}
	return;
}

sub find_pattern {
	my ($log, $pattern, $start, $end) = @_; #arguments. start and end are optional.
	$start = 0 if not defined $start;
	$end = $log->end() if not defined $end;
	
	#Pattern can be in 1 different ways.
	#1. Single match sub
	#2. An array of patterns
	#3. Another query
	
	#Another query
	if ( ref $pattern eq 'HASH' ) {
		return find_sequence( $log, $pattern, $start, $end );
	}
	elsif ( ref $pattern eq 'CODE' ) {
		return find_sub_pattern( $log, $pattern, $start, $end );
	}
	elsif ( ref $pattern eq 'ARRAY' ) {
		return find_multi_pattern( $log, $pattern, $start, $end );
	}
	else {
		confess "unknown match pattern\nmatch pattern must be a sub or another query or an array of queries\n";
	}
	
}

sub find_sub_pattern {
	my ($log, $match_sub, $start, $end) = @_; #arguments. start and end are optional.
	$start = 0 if not defined $start;
	$end = $log->end() if not defined $end;
	
	my @result;
	no strict "refs"; #to call the code_ref
	for my $i ( $start .. $end ) {
		if ( $match_sub->( $log->index($i) ) ) { # $match_sub has the code that was in the query.
			push @result, $i, $i;
		}
	}
	return @result;
}

#this function is to match multiple patters in start eg: start => [ $q1, $q2] 
#we need to match all the patterns given.
sub find_multi_pattern {
	my ($log, $pattern_array_ref, $start, $end) = @_; #arguments. start and end are optional.
	$start = 0 if not defined $start;
	$end = $log->end() if not defined $end;
	
	my @result;
	foreach my $p ( @$pattern_array_ref ) {
		my @r = find_pattern( $log, $p, $start, $end );
		if ( @r ) {
			push @result, @r;
		}
		#print $p, "\n";	
		#we need to check if the patter is a simple one or complex one. 
		#if simple it will be a CODE ref other wise ARRAY
		##if (ref ($p) eq 'CODE') { #$p is the sub to check for True/False on each message. 
		##	for my $i ( $start .. $end ) {
		##		if ( $p->( $log->index($i) ) ) { # $p has the code that was in the query.
		##			push @result, $i, $i;
		##		}
		##	}
		##}
		##else { #$p is a complex query; we need to call the find_sequence.
		##	my @r = find_sequence( $log, $p, $start, $end );
		##	if ( @r ) { #if not match we still need  to check the other patterns in the array.
		##		push @result, @r; 
		##		#print "r = ", join(" ", @result), "\n";
		##	}
		##}
	}
	return @result;
}



1;