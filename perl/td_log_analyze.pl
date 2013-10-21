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


my @tdcell_info_print = (
							'name',     'tdcell_info_print',
							'start', 	'MSG_ID_RRC_FREQ_CELL_INFO_PRINT',
);

my @tdcell_camp = (
							'name',     'tdcell_camp',
							'start', 	'MSG_ID_RRC_FREQ_CELL_INFO_PRINT',
							'middle',   'MSG_ID_RRCC_CELL_CAMP_REQ',						
							'end',		'MSG_ID_RRCC_CELL_CAMP_COMP',
						
);

## my @tdcell_camp = (
## 							'name',     'tdcell_camp',
## 							'start', 	'MSG_ID_RRC_FREQ_CELL_INFO_PRINT',
## 							'middle',   'MSG_ID_RRCC_CELL_CAMP_REQ',						
## 							'end',		'MSG_ID_RRCC_CELL_CAMP_COMP',
## 						
## );


#patterns can be nested
# Example:
#my @tdcell_camp_1 = (
#							'name',     'tdcell_camp',
#							'start', 	'MSG_ID_RRCC_CELL_CAMP_REQ',
#							'not',      'MSG_ID_RRCC_CELL_CAMP_REQ',
#							'end',		'MSG_ID_RRCC_CELL_CAMP_COMP',
#);
#
#my @tdcell_camp = (
#							'name',     'tdcell_camp',
#							'start', 	'MSG_ID_RRC_FREQ_CELL_INFO_PRINT',
#							'end',		\@tdcell_camp_1,
#);


##############################################################################################


############################Main PROCESSING BLOCK#############################################

if ( @ARGV != 4 ) {
	print "usage: perl td_log_analy.pl input.tag cellinfo.csv reselction.csv serv_cell.ann\n";
	exit;
}


my $file_name= shift ( @ARGV ); #$ARGV[0]; #tag filename

my $cellinfo_file = shift ( @ARGV ); #$ARGV[1];
open CELL_INFO_FILE, ">$cellinfo_file" or die "can not open $cellinfo_file $!";

my $reselction_info_file = shift ( @ARGV ); #$ARGV[2];             #annotation file for dygraph annotation function
open RESELECTION_INFO_FILE, ">$reselction_info_file" or die "can not open $reselction_info_file $!";

my $serving_cell_ann_file = shift ( @ARGV ); #$ARGV[3];             #annotation file for serving cell
open SERVING_CELL_ANN_FILE, ">$serving_cell_ann_file" or die "can not open $serving_cell_ann_file $!";

my $log = TagLog->new();
my $parser = XML::LibXML->new();


if ($file_name =~ m/\.tag.*/ ) {				#deal with the tag file


	$log->load( $file_name );

	#extract the reselction info
	my $cell_reselction_info_ref = extract_reselction_info();
	save_reselction_info($cell_reselction_info_ref);
	
	#extract cell info
	my ($cell_info_db_ref, $cell_names_ref ) = extract_cell_info();	
	
	#make the serv cell annotation file
	save_serv_cell_annotation( $cell_info_db_ref );
	
	my $N = 5000 ; #in milliseconds # 5 seconds
	prune_cell_info( $cell_info_db_ref, $N ); #mark the entries around the cell change
	
	save_cell_info($cell_info_db_ref, $cell_names_ref);
	
	
	
	close CELL_INFO_FILE;
	close RESELECTION_INFO_FILE;
	close SERVING_CELL_ANN_FILE;
}	
else {
	print "the type of your input file is wrong!\n";
	print "usage: perl td_log_analy.pl input.tag cellinfo.csv reselction.txt\n"; 
}

exit();	
##########################################################################################################

sub prune_cell_info {
	my $cell_info_db_ref = shift;
	my $N = shift;
	for( my $i = 0; $i < @$cell_info_db_ref ; $i += 1) {
		#my $time = @$cell_info_db_ref[$i];
		my $data_hash_ref = @$cell_info_db_ref[$i];
		
		if ( exists $data_hash_ref->{'cell_change'} ) {
			mark_for_printing_around( $cell_info_db_ref, $i, $N );
		}		
	}
}

sub mark_for_printing_around {
	my $cell_info_db_ref = shift;
	my $i = shift;
	my $N = shift; #time
	
	my $data_hash_ref = @$cell_info_db_ref[$i];
	
	my $time = $data_hash_ref->{'arm_time'};
	my $from_time = $time - $N;
	my $to_time = $time + $N;
	
	#print "$time $from_time $to_time\n";
	
	#mark before the change
	my $k = $i;
	while ( $k != 0  && $data_hash_ref->{'arm_time'} > $from_time ) {
		$data_hash_ref = @$cell_info_db_ref[$k];
		$data_hash_ref->{'print'} = 1; #mark for printing
		$k -= 1;
		#print $k," ", $data_hash_ref->{'arm_time'}," ", $from_time, "\n";
	}
	
	#mark after the change
	$k = $i;
	$data_hash_ref = @$cell_info_db_ref[$i];
	while ( $k < @$cell_info_db_ref && $data_hash_ref->{'arm_time'} < $to_time ) {
		$data_hash_ref = @$cell_info_db_ref[$k];
		$data_hash_ref->{'print'} = 1; #mark for printing
		$k += 1;
	}
}


sub save_serv_cell_annotation {
	my $cell_info_db_ref = shift;
	
	#start the javascript file.
	print SERVING_CELL_ANN_FILE "var serv_cell_annotations = [ \n";
	
	
	my $prev_serv_freq= "";
	my $prev_serv_cell= "";
	my $prev_arm_time = "";
	#we need to loop over all the arm_time and find out the points where there is a change in serv cell.
	for( my $i = 0; $i < @$cell_info_db_ref ; $i += 1) {
		#my $time = @$cell_info_db_ref[$i];
		my $data_hash_ref = @$cell_info_db_ref[$i];	
		
		#take out the cell names
		my $this_serv_freq = $data_hash_ref->{'serv_freq'};
		my $this_serv_cell = $data_hash_ref->{'serv_cell'};
		my $this_arm_time  = $data_hash_ref->{'arm_time'};
		
		if ( $prev_serv_freq eq "" ) { #first time 
			$prev_serv_freq = $this_serv_freq;
			$prev_serv_cell = $this_serv_cell;
			$prev_arm_time  = $this_arm_time;
		}
		#print "$this_serv_freq $this_serv_cell $this_arm_time", "\n";
		
		if ( $prev_serv_freq ne $this_serv_freq || $prev_serv_cell ne $this_serv_cell ) {
			#XXXXX Serving cell change.
			print_serv_cell_annotation_at_index( $cell_info_db_ref, $i, $prev_serv_freq, $prev_serv_cell, $this_serv_freq, $this_serv_cell);
			#also mark this point
			$data_hash_ref->{'cell_change'} = 1;
		}	
			
		$prev_serv_freq = $this_serv_freq;
		$prev_serv_cell = $this_serv_cell;
		$prev_arm_time  = $this_arm_time;

	}
	
	#close the javascript file.
	print SERVING_CELL_ANN_FILE "]; \n";
}

sub cell_name {
	my $freq = shift;
	my $cell = shift;
	return hex($freq) . "_" . hex($cell);
	
	#return "freq_$freq(cell_$cell)";
}

sub find_rscp {
	my $cell_info_db_ref = shift;
	my $index = shift;
	my $freq = shift;
	my $cell = shift;
	my $data_hash_ref = @$cell_info_db_ref[$index];
	
	my $name = cell_name($freq, $cell) ; #"freq_$freq(cell_$cell)";
	
	if ( exists $data_hash_ref->{ $name } ) {
		return $data_hash_ref->{ $name };
	}
	return undef;
}

sub find_value {
	my $cell_info_db_ref = shift;
	my $index = shift;
	my $name = shift;

	my $data_hash_ref = @$cell_info_db_ref[$index];
	
	if ( exists $data_hash_ref->{ $name } ) {
		return $data_hash_ref->{ $name };
	}
	return undef;
}

sub print_annotation {
	my $freq = shift;
	my $cell = shift;
	my $arm_time = shift;
	#print the old cell annotation.
	my $name = cell_name($freq, $cell);
	print SERVING_CELL_ANN_FILE << "END";
	{
		series: "$name",
		x: $arm_time,
		text: "$name",
		shortText: "S"
	},
END
	## print SERVING_CELL_ANN_FILE "{", "\n";
	## print SERVING_CELL_ANN_FILE "series: \"freq_$pfreq(cell_$pcell)\",", "\n";
	## print SERVING_CELL_ANN_FILE "x: $arm_time,", "\n";
	## print SERVING_CELL_ANN_FILE "text: \"$pfreq $pcell\",", "\n";
	## print SERVING_CELL_ANN_FILE "shortText: \"S\",", "\n";
	## print SERVING_CELL_ANN_FILE "},", "\n";
}

#at index there was a cell change; But we need to find the valid positions with non zero rscp previous to this index
#for the previous cell
#and on or after this index for the next serving cell. 
sub print_serv_cell_annotation_at_index {
	my $cell_info_db_ref = shift;
	my $index = shift;
	my $pfreq = shift;
	my $pcell = shift;
	my $nfreq = shift;
	my $ncell = shift;
	
	for(my $i = 1; $i<10; $i++) { #we just check for the previous 10 entries
		my $rscp = find_rscp($cell_info_db_ref, $index-$i, $pfreq, $pcell);
		if ( not $rscp ) {
			next;
		}	
		#we found the rscp
		my $arm_time = find_value($cell_info_db_ref, $index-$i, 'arm_time');
		
		#print the old cell annotation.
		print_annotation($pfreq, $pcell, $arm_time);
		last; #we dont need the loop any more
	}
	
	for(my $i = 0; $i<10; $i++) { #we just check for the next 10 entries
		my $rscp = find_rscp($cell_info_db_ref, $index+$i, $nfreq, $ncell);
		if ( not $rscp ) {
			next;
		}	
		#we found the rscp
		my $arm_time = find_value($cell_info_db_ref, $index+$i, 'arm_time');
		
		#print the new cell annotation.
		print_annotation($nfreq, $ncell, $arm_time);
		last; #we dont need the loop any more
	}

}



sub extract_reselction_info {
	my @start_and_end = $log->find_sequence( \@tdcell_camp ); #find start and end index of your pattern 
	
	my @cell_reselction_info; #armtime, sfreq, cellid, dfreq, cell id, status 
	
	while ( @start_and_end ) {
		my $start = shift(@start_and_end);
		my $end = shift(@start_and_end);
		
		my ($serv_freq, $serv_cell);        #from MSG_ID_RRC_FREQ_CELL_INFO_PRINT
		my ($arm_time, $cell_id, $uarfcn ); #from MSG_ID_RRCC_CELL_CAMP_REQ
		my $rsp;                            #from MSG_ID_RRCC_CELL_CAMP_COMP
		my $first = 0;
		for my $i ($start .. $end) {
			my $msg_tag = $log->index($i);
						
			if ( $first == 0 && $msg_tag->has('MSG_ID_RRC_FREQ_CELL_INFO_PRINT') ){
				$serv_freq= $msg_tag->value('serv_freq');
				$serv_cell= $msg_tag->value('serv_cell');
				$first = 1; #we need only the first one. The last ones may hve the new serv freq. We want the initial serv cell.
			}	
			if ( $msg_tag->has('MSG_ID_RRCC_CELL_CAMP_REQ') ){
				$arm_time = str_arm_time( $msg_tag->value('arm_time') );
				#$arm_time    = time2ms($arm_time);
				$cell_id  = $msg_tag->value('cell_id');
				$uarfcn   = $msg_tag->value('uarfcn');
			}
			if ( $msg_tag->has('MSG_ID_RRCC_CELL_CAMP_COMP') ){
				$rsp      = $msg_tag->value('tdcell_camp_rsp');
			}
		}	
		#print "seq $start to $end: freq( $serv_freq $uarfcn ) cell( $serv_cell $cell_id ) rsp: $rsp\n";		
		#if either freq or cell id is different, then it's a cell reselection
		if (($uarfcn ne $serv_freq) || ($cell_id ne $serv_cell)) {
			my %reselection;
			$reselection{'arm_time'} = $arm_time;
			$reselection{'status'} = $rsp;
			$reselection{'serv_freq'} = $serv_freq;
			$reselection{'serv_cell'} = $serv_cell;
			$reselection{'uarfcn'} = $uarfcn;
			$reselection{'cell_id'} = $cell_id;
			push @cell_reselction_info, \%reselection;
		}
	}
	return \@cell_reselction_info;
}

sub save_reselction_info {
	my $info_ref = shift;
	print RESELECTION_INFO_FILE  "var serv_cell_reselection = [\n";
	while( @$info_ref) {
		my $reselection_hash_ref = shift(@$info_ref); #take out the hash
		print RESELECTION_INFO_FILE << "END";
		{
			time: $reselection_hash_ref->{'arm_time'},
			status: "$reselection_hash_ref->{'status'}"
		},
END
	}
	print RESELECTION_INFO_FILE  "];\n";
}

sub save_cell_info {
	my $cell_info_db_ref = shift; #array of (datahash_ref )
	my $cell_names_ref = shift;
	
	print CELL_INFO_FILE "var cell_labels = [\n";
	print CELL_INFO_FILE "\"Time\",";
	map {print CELL_INFO_FILE  "\"$_\","} sort(keys( %$cell_names_ref ));	
	print CELL_INFO_FILE "\"Serving Cell\",\"SecServing Cell\"";
	print CELL_INFO_FILE "\n];\n";
	#first print the header
	#print CELL_INFO_FILE "Time,", join(",", sort(keys( %$cell_names_ref )) );
	
	#At the end of the header line let us print the Serving Cell Power ans Second Serving Cell
	#print CELL_INFO_FILE ",Serving Cell,SecServing Cell", "\n";
	print CELL_INFO_FILE "var cell_info_array = [\n";
	#then for each time, print the data;
	for( my $i = 0; $i < @$cell_info_db_ref ; $i += 1) {
		my $data_hash_ref = @$cell_info_db_ref[$i];
		
		#skip if not marked for printing.
		if ( not exists $data_hash_ref->{'print'} ) {
			next; #we dont need to print this line.
		}
		
		my $time = $data_hash_ref->{'arm_time'};
		print CELL_INFO_FILE "[ $time";
		foreach my $n ( sort(keys( %$cell_names_ref )) ) {
			if ( exists $data_hash_ref->{ $n } ) {
				print CELL_INFO_FILE ",", hex ( $data_hash_ref->{ $n } );
			}
			else {
				print CELL_INFO_FILE ",NaN";
			}
		}
		
		#put the rscp of serving cell at the end
		my $serv_cell_name = cell_name($data_hash_ref->{ 'serv_freq' }, $data_hash_ref->{ 'serv_cell' }); #"freq_" . $data_hash_ref->{ 'serv_freq' } . "(cell_" . $data_hash_ref->{ 'serv_cell' } . ")";
		if ( exists $data_hash_ref->{ $serv_cell_name } ) {
				print CELL_INFO_FILE ",", hex ( $data_hash_ref->{ $serv_cell_name} );
			}
			else {
				print CELL_INFO_FILE ",NaN";
		}
		
		#put the rscp of sec serving cell at the end
		my $sec_serv_cell_name = cell_name($data_hash_ref->{ 'sec_serv_freq' }, $data_hash_ref->{ 'sec_serv_cell' }); 
		if ( exists $data_hash_ref->{ $sec_serv_cell_name } ) {
				print CELL_INFO_FILE ",", hex ( $data_hash_ref->{ $sec_serv_cell_name} );
			}
			else {
				print CELL_INFO_FILE ",NaN";
		}
		
		print CELL_INFO_FILE " ],\n";
	}
	print CELL_INFO_FILE " ];\n";
}

sub ___save_cell_info {
	my $cell_info_db_ref = shift; #array of (datahash_ref )
	my $cell_names_ref = shift;
	
	#first print the header
	print CELL_INFO_FILE "Time,", join(",", sort(keys( %$cell_names_ref )) );
	
	#At the end of the header line let us print the Serving Cell Power ans Second Serving Cell
	print CELL_INFO_FILE ",Serving Cell,SecServing Cell", "\n";
	
	#then for each time, print the data;
	for( my $i = 0; $i < @$cell_info_db_ref ; $i += 1) {
		my $data_hash_ref = @$cell_info_db_ref[$i];
		my $time = $data_hash_ref->{'arm_time'};
		print CELL_INFO_FILE "$time";
		foreach my $n ( sort(keys( %$cell_names_ref )) ) {
			if ( exists $data_hash_ref->{ $n } ) {
				print CELL_INFO_FILE ",", hex ( $data_hash_ref->{ $n } );
			}
			else {
				print CELL_INFO_FILE ",NaN";
			}
		}
		
		#put the rscp of serving cell at the end
		my $serv_cell_name = cell_name($data_hash_ref->{ 'serv_freq' }, $data_hash_ref->{ 'serv_cell' }); #"freq_" . $data_hash_ref->{ 'serv_freq' } . "(cell_" . $data_hash_ref->{ 'serv_cell' } . ")";
		if ( exists $data_hash_ref->{ $serv_cell_name } ) {
				print CELL_INFO_FILE ",", hex ( $data_hash_ref->{ $serv_cell_name} );
			}
			else {
				print CELL_INFO_FILE ",NaN";
		}
		
		#put the rscp of sec serving cell at the end
		my $sec_serv_cell_name = cell_name($data_hash_ref->{ 'sec_serv_freq' }, $data_hash_ref->{ 'sec_serv_cell' }); 
		if ( exists $data_hash_ref->{ $sec_serv_cell_name } ) {
				print CELL_INFO_FILE ",", hex ( $data_hash_ref->{ $sec_serv_cell_name} );
			}
			else {
				print CELL_INFO_FILE ",NaN";
		}
		
		print CELL_INFO_FILE "\n";
	}
}




sub extract_cell_info {
	#my @start_and_end = $log->find_sequence( make_regex_pattern(@tdcell_info_print)); #find start and end index of your pattern 
	my @start_and_end = $log->find_sequence( \@tdcell_info_print ); #find start and end index of your pattern 
	
	my @cell_info_db; #( time, datahash_ref )
	my %cell_names;   #names of all the cells ( "freq cellparam" )
	
	while ( @start_and_end ) {
		my $start = shift(@start_and_end);
		my $end = shift(@start_and_end);
		
		#there will be only one line
		my $msg_tag = $log->index($start);
				
		my $arm_time= str_arm_time ( $msg_tag->value('arm_time') );
		#push @cell_info_db, $arm_time;		
		
		my %data;
		#my $serv_freq= $msg_tag->value('serv_freq');
		#my $serv_cell= $msg_tag->value('serv_cell');
		$data{'arm_time'}  = $arm_time;
		$data{'serv_freq'} = $msg_tag->value('serv_freq'); #$serv_freq;
		$data{'serv_cell'} = $msg_tag->value('serv_cell'); #$serv_cell;
		$data{'sec_serv_freq'} = $msg_tag->value('sec_serv_freq'); 
		$data{'sec_serv_cell'} = $msg_tag->value('sec_serv_cell');
		
		my @uarfcn = $msg_tag->value('uarfcn');
		my @cell_param_id = $msg_tag->value('cell_param_id');
		my @rscp = $msg_tag->value('rscp');
		
		#print "$serv_freq,$serv_cell,$arm_time";
		my $i = 0;
		while( $i < @uarfcn ) {
			#print ",$uarfcn[$i],$cell_param_id[$i],$rscp[$i]";
			if ( hex($rscp[$i]) != 255 ) {
				my $name = cell_name($uarfcn[$i], $cell_param_id[$i]); #"freq_$uarfcn[$i](cell_$cell_param_id[$i])";
				$data{ $name } = $rscp[$i];
				$cell_names{ $name } = 1;  #store the name for future use
			}
			$i++;
		}
		#print "\n";
		push @cell_info_db, \%data;
	}
	#print Data::Dumper->Dump([@cell_info_db], [qw(cell_info_db)]);	
	return (\@cell_info_db, \%cell_names );
}


sub str_arm_time {
	my $arm_time = shift; #this is in millisec. We convert it to hh:mm:ss:lll
	
	#XXXXXX
	#idea did not work
	return $arm_time;
	
	use POSIX qw( strftime ); 
	my $time = strftime("%H:%M:%S:", localtime($arm_time/1000)); # hh:mm:ss:
	my $milli = $arm_time%1000 ;
	
	#XXXXX
	#$milli = ( $milli / 100 ) % 60
	return $time;
	
	return $time . $milli; #format: hh:mm:ss:lll
	
}

##  function data_temp() {
##  return "" +
##  "Time,freq_0x2760(cell_0x3c),freq_0x2760(cell_0x1),freq_0x2788(cell_0x4c)\n" +
##  "1256047,99;99;99,4;4;4,11;12;13\n"+
##  "1257148,12;12;12,5;5;5,9;10;11\n"+
##  "1258251,7;9;10  ,     ,8;8;8\n"+
##  "1264650,12;13;14,     ,5;5;5\n"+
##  "1265290,12;13;14,7;7;7,5;5;5\n"+
##  "1265930,12;13;14,9;10;11,6;6;6\n"+
##  "1267211,7;7;7   ,10;11;12,4;4;4\n"
##  }

##  time     
##  "1267211, 7;7;7, 10;11;12 , 4;4;4 \n"
