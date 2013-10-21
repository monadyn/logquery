####################################################################################
#this script can be used to generate the cell selection data and the rscp data														
#perl td_log_analy.pl test.tag cellinfo.csv	reselction.txt		
####################################################################################

use strict;
use warnings;
use XML::LibXML;
use Data::Dumper;
use TagLog;
use td_filter;

#####################################################################################
#Patterns are used to extract the information that you are interested, you need only#
#defince these patterns like below and the tool will take care of the rest			#
#####################################################################################


			
my $g_serv_freq = 0;
sub serv_cell_change { 
	my $msg = shift; 
	if ( $msg->has('MSG_ID_RRC_FREQ_CELL_INFO_PRINT')) {
	
		##if ( not defined $g_serv_freq) {
		##	$g_serv_freq = $msg->value('serv_freq');
		##	return;
		##}
		
		if ( $g_serv_freq ne $msg->value('serv_freq') ) {
			$g_serv_freq = $msg->value('serv_freq');
			return 1;
		}
		$g_serv_freq = $msg->value('serv_freq');
		
	}
	return;
}
			
my $serv_cell_change1 = {
				'start' => \&serv_cell_change,
};

my $serv_cell_change_query = {
				#'start' => sub { my $msg = shift; $msg->has('MSG_ID_RRC_FREQ_CELL_INFO_PRINT') },
				'start' => sub { my $msg = shift; return $msg->msg_id eq 'MSG_ID_RRC_FREQ_CELL_INFO_PRINT' },
				'not' =>   sub { my $msg = shift; $msg->has('MSG_ID_RRC_FREQ_CELL_INFO_PRINT'); },
				'end' => $serv_cell_change1,
};

my $q = {
	'start' => sub{my $msg = shift; return $msg->value('msg_id') eq 'MSG_ID_RRCC_CELL_CAMP_COMP';}
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

	my @a = $log->find_sequence( $serv_cell_change_query );
	my @b = @a;
	print "results:";	
	while( my ($s, $e) = splice(@a, 0, 2) ){
		print " ( ", "$s,$e", " ),";
		#for($s..$e) {
			#print $log->index($_)->string(), "\n";
		#}
	}
	#print "\n";
	#print $log->index($b[0])->string();
	#if ( $log->index($b[0])->has('MSG_ID_RRCC_CELL_CAMP_COMP') ) {
	#	print "\nhas\n";
	#}
	
}	
else {
	print "the type of your input file is wrong!\n";
	print "usage: perl td_log_analy.pl input.tag cellinfo.csv reselction.txt\n"; 
}

exit();	