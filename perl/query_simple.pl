####################################################################################
#this script can be used to generate the cell selection data and the rscp data														
#perl td_log_analy.pl test.tag cellinfo.csv	reselction.txt		
####################################################################################

use strict;
use warnings;
use XML::LibXML;
use Data::Dumper;
use TagLog;
#use td_filter;

#####################################################################################
#Patterns are used to extract the information that you are interested, you need only#
#defince these patterns like below and the tool will take care of the rest			#
#####################################################################################

sub my_search_sub { 
	my $msg = shift;  
	if ( $msg->arm_time eq '3627408' ) {
		return 1;
	}
	return 0;
}

sub my_search_sub2 { 
	my $msg = shift;  
	if ( $msg->msg_id eq 'XXXXXXXXXXXXXXXXX' ) {
		return 1;
	}
	return 0;
}

sub my_search_sub3 { 
	my $msg = shift;  
	if ( $msg->msg_id eq 'MSG_ID_CMAC_CONFIG_CNF' ) {
		return 1;
	}
	return 0;
}


my $tdcell_camp = {
							'name',     'tdcell_camp',
							'start', 	sub { $_[0]->has('MSG_ID_RRC_FREQ_CELL_INFO_PRINT') },
							'middle', sub { $_[0]->has('MSG_ID_RRCC_CELL_CAMP_REQ' ) },						
							'end',		sub { $_[0]->has('MSG_ID_RRCC_CELL_CAMP_COMP') },
						
};

#We can write the same query like this also.
my $tdcell_camp2 = {
							'name',     'tdcell_camp',
							'start', 	  sub { my $msg = shift;  $msg->has('MSG_ID_RRC_FREQ_CELL_INFO_PRINT') },
							'middle',   sub { my $msg = shift;  $msg->has('MSG_ID_RRCC_CELL_CAMP_REQ' ) },						
							'end',		  sub { my $msg = shift;  $msg->has('MSG_ID_RRCC_CELL_CAMP_COMP') },
						
};			

#We can write the same query like this also.
my $tdcell_camp3 = {
							'name',     'tdcell_camp',
							'start', 	sub { my $msg = shift;  $msg->msg_id eq 'MSG_ID_RRC_FREQ_CELL_INFO_PRINT' },
							'middle', sub { my $msg = shift;  $msg->msg_id eq 'MSG_ID_RRCC_CELL_CAMP_REQ'  },						
							'end',		sub { my $msg = shift;  $msg->msg_id eq 'MSG_ID_RRCC_CELL_CAMP_COMP' },
						
};

my $arm_time_search = {
							'start', 	$tdcell_camp,
						  #'not',    \&my_search_sub2,
						  #'middle', \&my_search_sub3,
							'end',		sub { my $msg = shift;  $msg->arm_time eq '3743236' },
						
};


##############################################################################################


############################Main PROCESSING BLOCK#############################################

#if ( @ARGV != 4 ) {
	#print "usage: perl td_log_analy.pl input.tag cellinfo.csv reselction.csv serv_cell.ann\n";
	#exit;
#}

my $file_name= shift ( @ARGV ); #$ARGV[0]; #tag filename

my $log = TagLog->new();
my $parser = XML::LibXML->new();


if ($file_name =~ m/\.tag.*/ ) {				#deal with the tag file

	$log->load( $file_name );

	print "done loading\n";

	my @a = $log->find_sequence( $arm_time_search );
	
	print "results:", join( " " , @a), "\n";
	
	while( my ($s, $e) = splice(@a, 0, 2) ){
		for my $i ($s..$e) {
			#print $log->index($i)->string(), "\n";
		}
	}
	
}	
else {
	print "the type of your input file is wrong!\n";
	print "usage: perl script.pl input.tag \n"; 
}

exit();	