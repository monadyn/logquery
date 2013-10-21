####################################################################################
#this script can be used to generate the rrc state data														
#perl rrc_state_query.pl test.tag ****		
####################################################################################

use strict;
use warnings;
use XML::LibXML;
use Data::Dumper;
use TagLog;
use td_filter;

#1/ conditions for querying NULL state data
sub rrc_null_state_msgs { 
	my $msg = shift;  
	if ($msg->msg_id eq 'MSG_ID_DM_RAT_CHG_TO_GSM_CNF' ) {				
		my $v = $msg->value('ho_status');
		if ( $v eq 'DM_HO_SUCCESS' ) {
			return 1;
		}
	}	
	elsif ( ($msg->msg_id eq 'MSG_ID_RR_PLM_3G_RAT_CHANGE_CNF')
	     || ($msg->msg_id eq 'MSG_ID_PLM_AS_3G_DEACT_CNF' ) ) {
		return 1;
	}
	return 0;
}

#2/ conditions for querying TRY_PLMN state data
sub rrc_try_plmn_state_msgs { 
	my $msg = shift;  
  if ( ($msg->msg_id eq 'MSG_ID_RRCC_CELL_SRCH_REQ')
    || ($msg->msg_id eq 'MSG_ID_CPHY_RF_MEAS_IND' )
    || ($msg->msg_id eq 'MSG_ID_CPHY_CELL_SEARCH_IND' )
    || ($msg->msg_id eq 'MSG_ID_RRCC_CPHY_CELL_SRCH_REQ' )
    || ($msg->msg_id eq 'MSG_ID_RRCC_CPHY_RF_MEAS_REQ' )
    || ($msg->msg_id eq 'MSG_ID_RRCC_CPHY_ABORT_CELL_SRCH_REQ' )    
    || ($msg->msg_id eq 'MSG_ID_RRCC_CPHY_RF_SRCH_REQ' )
	  || ($msg->msg_id eq 'MSG_ID_RRCC_CPHY_ABORT_RF_SRCH_REQ' ) ) {
		return 1;
	}
	return 0;
}

#3/ conditions for querying IDLE state data
sub rrc_idle_state_msgs { 
	my $msg = shift;  
  if ($msg->msg_id eq 'MSG_ID_RRCC_CELL_CAMP_REQ') {
  	my $v = $msg->value('target_state');
  	if ( $v and $v  eq 'RRC_IDLING ' ) 
  	{
			return 1;
		}		
	}
	return 0;
}

#4/ conditions for querying CONNEST state data
sub rrc_connest_state_msgs { 
	my $msg = shift;  
  if ($msg->msg_id eq 'MSG_ID_RRCC_CELL_CAMP_REQ') {
  	my $v = $msg->value('target_state');
  	if ( $v and $v  eq 'RRC_CONNEST' ) {
			return 1;
		}		
	}
	return 0;
}

#5/ conditions for querying CELL_PCH state data
sub rrc_cell_pch_state_msgs { 
	my $msg = shift;  
  if ($msg->msg_id eq 'MSG_ID_RRCC_CELL_CAMP_REQ') {
  	my $v = $msg->value('target_state');
  	if ( $v and $v  eq 'RRC_CELL_PCH' ) {
			return 1;
		}		
	}
	return 0;
}

#6/ conditions for querying URA_PCH state data
sub rrc_ura_pch_state_msgs { 
	my $msg = shift;  
  if ($msg->msg_id eq 'MSG_ID_RRCC_CELL_CAMP_REQ') {
  	my $v = $msg->value('target_state');
  	if ( $v and $v  eq 'RRC_URA_PCH' ) {
			return 1;
		}		
	}
	return 0;
}

#7/ conditions for querying CELL_FACH state data
sub rrc_cell_fach_state_msgs { 
	my $msg = shift;  
  if ($msg->msg_id eq 'MSG_ID_RRCC_CELL_CAMP_REQ') {
  	my $v = $msg->value('target_state');
  	if ( $v and $v  eq 'RRC_CELL_FACH' ) {
			return 1;
		}		
	}
	return 0;
}

#8/ conditions for querying DCH state data
sub rrc_dch_state_msgs { 
	my $msg = shift;  
	#rrc con setup
  if ($msg->msg_id eq 'MSG_ID_RRCA_AS_RLC_DATA_IND') {
  	my $v = $msg->value('rrc_StateIndicator');
  	if ( $v and $v  eq 'RRC_StateIndicator_CELL_DCH' )
  	{
			return 1;
		}		
	}
	return 0;
}


####################################################################################
#1/ querying NULL state data
my $rrc_null_state_search = {
							'start',   \&rrc_null_state_msgs,
						  #'not',    \&,
						  #'middle', \&,
							#'end',		 \&,						
};
#2/ querying TRY_PLMN state data
my $rrc_try_plmn_state_search = {
							'start',   \&rrc_try_plmn_state_msgs,
						  #'not',    \&,
						  #'middle', \&,
							#'end',		 \&,						
};
#3/ querying IDLE state data
my $rrc_idle_state_search = {
							'start',   \&rrc_idle_state_msgs,
						  #'not',    \&,
						  #'middle', \&,
							#'end',		 \&,						
};
#4/ querying DCH state data
my $rrc_connect_state_search = {
							'start',   \&rrc_connest_state_msgs,
						  #'not',    \&,
						  #'middle', \&,
							#'end',		 \&,						
};
#5/ querying CELL_PCH state data
my $rrc_cell_pch_state_search = {
							'start',   \&rrc_cell_pch_state_msgs,
						  #'not',    \&,
						  #'middle', \&,
							#'end',		 \&,						
};
#6/ querying URA_PCH state data
my $rrc_ura_pch_state_search = {
							'start',   \&rrc_ura_pch_state_msgs,
						  #'not',    \&,
						  #'middle', \&,
							#'end',		 \&,						
};
#7/ querying CELL_FACH state data
my $rrc_cell_fach_state_search = {
							'start',   \&rrc_cell_fach_state_msgs,
						  #'not',    \&,
						  #'middle', \&,
							#'end',		 \&,	 					
};
#8/ querying DCH state data
my $rrc_dch_state_search = {
							'start',   \&rrc_dch_state_msgs,
						  #'not',    \&,
						  #'middle', \&,
							#'end',		 \&,						
};

#####################################################################################
# start to query rrc states data                                                      #
#####################################################################################

my $file_name= shift ( @ARGV ); #$ARGV[0]; #tag filename

my $log = TagLog->new();
my $parser = XML::LibXML->new();

if ($file_name =~ m/\.tag.*/ ) {				#deal with the tag file
  print "log->load: ",$log,"\n";
	$log->load( $file_name );
  
  my @rrc_states_functions = ($rrc_null_state_search,$rrc_try_plmn_state_search,$rrc_idle_state_search,$rrc_connect_state_search,$rrc_cell_pch_state_search,$rrc_ura_pch_state_search,$rrc_cell_fach_state_search,$rrc_dch_state_search);
  my $rrc_states_numbers = scalar(@rrc_states_functions);
  print "rrc states numbers: ", $rrc_states_numbers,"\n\n" ;

	#my @a = $log->find_sequence( $rrc_null_state_search);
	
  for my $i (0..$rrc_states_numbers - 1) {
  	print "i = ",$i,"\n";
		my @a = $log->find_sequence( $rrc_states_functions[$i]);		
		print "results:   ", join( " " , @a), "\n\n";
		
		while( my ($s, $e) = splice(@a, 0, 2) ){		
			for my $j ($s..$e) {
				print $log->index($j)->string(),"\n";
			}
		}	
		print "\n\n\n";
	}
}	
else {
	print "the type of your input file is wrong!\n";
	print "usage: perl td_log_analy.pl input.tag cellinfo.csv reselction.txt\n"; 
}

exit();	


