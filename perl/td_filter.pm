#define the rules to extract the msg you want
use strict;
use warnings;
use XML::LibXML;
use Data::Dumper;

use TagLog;

sub trace_string {
	my $xml = shift;
	my $tag = shift;
	
	##my $msg_name = $xml->findvalue('//info/msg');
	my $trace_str = $xml->findvalue('//Message/Str');
	
	#$trace_str =~ s/\"(.*)\"/$1/g;
	#$trace_str =~ s/\"/\ /g;
	
	#$tag->add("Str", '"'.$trace_str.'"');
	if ( $trace_str ne "" ) {
		$tag->add("trace_str", $trace_str);
	}  
  	
	my $trace_val = $xml->findvalue('//Message/Val');
	if ( $trace_val ne "" ) {
		$tag->add("trace_id", $trace_val);
	}
}

sub msg_name {
	my $xml = shift;
	my $tag = shift;
	
	##my $msg_name = $xml->findvalue('//info/msg');
	my $msg_name = $xml->findvalue('//Message/msg_id');
	
	if ( $msg_name eq "\"Trace\"" || $msg_name eq "\"TraceID\"" ) {
		#$tag->add("Trace");
		return
	}
	
	if ($msg_name !~ "MSG_ID") {
		$msg_name = "MSG_ID_".$msg_name
	}
	$tag->add($msg_name);
}

sub sn_time_pc {
	my $xml = shift;
	my $tag = shift;
	
	my $sn = $xml->findvalue('//Message/frame_seq');
	$tag->add("sn", $sn);
	
	my $arm_time = $xml->findvalue('//Message/time_stamp');
	if ( $arm_time ne "" ) {
		#$tag->add("Trace");
		$tag->add("arm_time", $arm_time);
	}
		
	my $pc_time = $xml->findvalue('//Message/time_stamp');    #findvalue('//Message/pc_time');	
  if ( $pc_time ne "" ) {
		#$tag->add("Trace");
		$tag->add("pc_time", $pc_time);
	}
			
	
}
sub rau_req {
	my $xml = shift;
	my $tag = shift;

	if ( $tag->has('MSG_ID_GMM_AS_3G_SIG_EST_REQ') 
				|| $tag->has('MSG_ID_LLGMM_UNITDATA_REQ') ) {
		if ( defined ( my $msg_type = $xml->findvalue('//Peer_Param/msg_type') ) ) {

			my $cn_domain_id = $xml->findvalue('//local_params/cn_domain_id');
			
			if ( ($msg_type eq "0x8") && ($cn_domain_id eq "0x1") ) {
				$tag->add("msg_type_", $msg_type);
				$tag->add(" cn_domain_id_", $cn_domain_id);
				my $rau_type = $xml->findvalue('//Peer_Param/update_type/update_type_val');
				$tag->add(" rau_req_type_", $rau_type);
				sn_time_pc($xml,$tag);
			}
		}
	}
}

sub rau_rsp {
	my $xml = shift;
	my $tag = shift;
	
	if ( $tag->has('MSG_ID_GMMAS_DATA_IND') 
				|| $tag->has('MSG_ID_LLGMM_UNITDATA_IND') ) {
		if ( defined ( my $msg_type = $xml->findvalue('//Peer_Param/msg_type') ) ) {
		
			my $cn_domain_id = $xml->findvalue('//local_params/cn_domain_id');	
			if ($cn_domain_id eq "0x1") {
				if ($msg_type eq "0x9") {
					$tag->add("msg_type_", $msg_type);
					$tag->add(" rau_rsp_suc");
					sn_time_pc($xml,$tag);
				}
				elsif ($msg_type eq "0xb") {
					$tag->add("msg_type_" , $msg_type);
					$tag->add(" cn_domain_id_" , $cn_domain_id);
					my $rau_rej_cause = $xml->findvalue('//Peer_Param/gmm_cause');
					$tag->add(" rau_rsp_rej_cause_" , $rau_rej_cause);
					sn_time_pc($xml,$tag);
				}
			}
		}
	}
}

sub lu_req {
	my $xml = shift;
	my $tag = shift;
	
	if ( $tag->has('MSG_ID_GMM_AS_3G_SIG_EST_REQ')  
				|| $tag->has('MSG_ID_GMM_AS_GPRS_SIG_EST_REQ') ) {
		if ( defined ( my $msg_type = $xml->findvalue('//Peer_Param/msg_type') ) ) {
			
			my $cn_domain_id = $xml->findvalue('//local_params/cn_domain_id');
			
			if (($msg_type eq "0x8") && ($cn_domain_id eq "0x0")) {
				$tag->add("msg_type_" , $msg_type);
				$tag->add(" cn_domain_id_" , $cn_domain_id);
				my $lu_type = $xml->findvalue('//Peer_Param/loc_update_type/lu_type');
				$tag->add(" lu_req_type_" , $lu_type);
				sn_time_pc($xml,$tag);
			}
		}
	}
}

sub lu_rsp {
	my $xml = shift;
	my $tag = shift;
	
	if ( $tag->has('MSG_ID_GMMAS_DATA_IND') ) {
		if ( defined ( my $msg_type = $xml->findvalue('//Peer_Param/msg_type') ) ) {

			my $cn_domain_id = $xml->findvalue('//local_params/cn_domain_id');	

			if ($cn_domain_id eq "0x0") {
				if ($msg_type eq "0x2") {
					$tag->add("msg_type_" , $msg_type);
					$tag->add(" lu_rsp_suc");
					sn_time_pc($xml,$tag);
				}
				elsif ($msg_type eq "0x4") {
					$tag->add("msg_type_" , $msg_type);
					$tag->add(" cn_domain_id_" , $cn_domain_id);
					my $lu_rej_cause = $xml->findvalue('//Peer_Param/cause');
					$tag->add(" lu_rsp_rej_cause_" , $lu_rej_cause);
					sn_time_pc($xml,$tag);
				}
			}
		}
	}
}

sub attach_req {
	my $xml = shift;
	my $tag = shift;
	
	if ( $tag->has('MSG_ID_LLGMM_UNITDATA_REQ') ) {
		if ( defined ( my $msg_type = $xml->findvalue('//Peer_Param/msg_type') ) ) {	
			if ($msg_type eq "0x1") {
				$tag->add("msg_type_" , $msg_type);
				my $attach_type = $xml->findvalue('//Peer_Param/attach_type/attach_type');
				$tag->add(" attach_req_type_" , $attach_type);
				sn_time_pc($xml,$tag);
			}
		}
	}
}

sub attach_rsp {
	my $xml = shift;
	my $tag = shift;
	
	if ( $tag->has('MSG_ID_LLGMM_UNITDATA_IND') ) {
		if ( defined ( my $msg_type = $xml->findvalue('//Peer_Param/msg_type') ) ) {
			if ($msg_type eq "0x2") {
				$tag->add(" attach_rsp_suc");
			}
			if ($msg_type eq "0x4") {
				$tag->add("msg_type_" , $msg_type);
				my $attach_rej_cause = $xml->findvalue('//Peer_Param/cause');
				$tag->add(" attach_rsp_rej_cause_" , $attach_rej_cause);
				sn_time_pc($xml,$tag);
			}
		}
	}
}

sub call_req {
	my $xml = shift;
	my $tag = shift;
	
	if ( $tag->has('MSG_ID_MMCC_DATA_REQ') || $tag->has('MSG_ID_MMCC_EST_IND') ) {
		if ( defined ( my $cc_msg_type = $xml->findvalue('//Peer_Param/cc_msg_type') ) ) {
			if ($cc_msg_type eq "0x5") {
				$tag->add(" call_req");
				sn_time_pc($xml,$tag);
			}
		}
	}
}

sub call_rsp {
	my $xml = shift;
	my $tag = shift;
	
	if ( $tag->has('MSG_ID_MMCC_DATA_REQ') || $tag->has('MSG_ID_MMCC_DATA_IND')) {
		if ( defined ( my $cc_msg_type = $xml->findvalue('//Peer_Param/cc_msg_type') ) ) {
			if ($cc_msg_type eq "0x25") {
				my $call_rsp = $xml->findvalue('//Peer_Param/cause/value');
				my @cause = split(',', $call_rsp); 
				if ($cause[1] eq "0x90") {
					$tag->add(" call_rsp_suc_" , $cause[1]);
				} else {
					$tag->add(" call_rsp_rej_" , $cause[1]);
				}
				sn_time_pc($xml,$tag);
			}
		}
	}
}


sub service_req {
	my $xml = shift;
	my $tag = shift;
	
	if ( $tag->has('MSG_ID_GMM_AS_3G_SIG_EST_REQ') ) {
		if ( defined ( my $msg_type = $xml->findvalue('//Peer_Param/msg_type') ) ) {
			if ($msg_type eq "0xc") {
				$tag->add("msg_type_" , $msg_type);
				my $service_type = $xml->findvalue('//Peer_Param/service_type/service_type');
				$tag->add(" service_req_type_" , $service_type);
				sn_time_pc($xml,$tag);
			}
		}
	}
}

sub service_rsp {
	my $xml = shift;
	my $tag = shift;
	
	if ( $tag->has('MSG_ID_GMMAS_DATA_IND') ) {
		if ( defined ( my $msg_type = $xml->findvalue('//Peer_Param/msg_type') ) ) {
			if ($msg_type eq "0xd") {
				$tag->add("msg_type_" , $msg_type);
				$tag->add(" service_rsp_suc");
				sn_time_pc($xml,$tag);
			}
			elsif ($msg_type eq "0xe") {
				$tag->add("msg_type_" , $msg_type);
				my $service_rej_cause = $xml->findvalue('//Peer_Param/gmm_cause');
				$tag->add(" service_rsp_rej_cause_" , $service_rej_cause);
				sn_time_pc($xml,$tag);
			}
		}
	}
}

sub tdcell_camp_req {
	my $xml = shift;
	my $tag = shift;
	if ( $tag->has('MSG_ID_RRCC_CELL_CAMP_REQ') || $tag->has('MSG_ID_BCFE_CELL_CAMP_REQ') ) {
#		$tag->add("tdcell_camp_req");
		my $uarfcn = $xml->findvalue('//local_params/uarfcn');
		$tag->add("uarfcn" , $uarfcn);
		my $cell_id = $xml->findvalue('//local_params/cell_param_id');
		$tag->add("cell_id" , $cell_id);
	}	
}

sub tdcell_camp_rsp {
	my $xml = shift;
	my $tag = shift;
	if ( $tag->has('MSG_ID_RRCC_CELL_CAMP_COMP') ||  $tag->has('MSG_ID_BCFE_CELL_CAMP_COMP')) {
		my $status = $xml->findvalue('//local_params/status');
		$tag->add("status" , $status);
		my $barred_cause = $xml->findvalue('//local_params/barred_cause');
		$tag->add("barred_cause" , $barred_cause);
		
		if ( ($status eq "RRCC_PROC_RESULT_SUCCESS" && $barred_cause eq "RRCC_CELL_NOT_BARRED")
		      || ($status eq "RRC_BCFE_PROC_RESULT_SUCCESS" && $barred_cause eq "RRC_BCFE_CELL_NOT_BARRED") ) {
			$tag->add("tdcell_camp_rsp","suc");
		} else {
			$tag->add("tdcell_camp_rsp","rej");
		}
	}
}

sub rrc_freq_cell_info {
	my $xml = shift;
	my $tag = shift;
	if ( $tag->has('MSG_ID_RRC_FREQ_CELL_INFO_PRINT') ) {
		my $serv_freq = $xml->findvalue('//local_params/serv_freq');
		$tag->add("serv_freq" , $serv_freq);
		my $serv_cell = $xml->findvalue('//local_params/serv_cell');
		$tag->add("serv_cell" , $serv_cell);
		
		my $sec_serv_freq = $xml->findvalue('//local_params/sec_serv_freq');
		$tag->add("sec_serv_freq" , $sec_serv_freq);
		my $sec_serv_cell = $xml->findvalue('//local_params/sec_serv_cell');
		$tag->add("sec_serv_cell" , $sec_serv_cell);		
		
		foreach my $freq_item ($xml->findnodes('//local_params/freq_info_print/ElemNode')) {	
			if ( (my $uarfcn = $freq_item->findvalue('./uarfcn')) ne "0xffff") {
				
				my $no_cell_info = $freq_item->findvalue('./no_cell_info');
				my $no_cell = hex($no_cell_info);
				my @cell_item = $freq_item->findnodes('./cell_info_print/ElemNode');
				for( my $i=0; $i < $no_cell; ++$i ) {
					my $rscp = $cell_item[$i]->findvalue('./rscp');
					if (hex($rscp) > 0) {
						$tag->add("uarfcn" , $uarfcn);
						my $cell_param_id = $cell_item[$i]->findvalue('./cell_param_id');
						$tag->add("cell_param_id" , $cell_param_id);
						$tag->add("rscp" , $rscp);
					}
				}
			}
		}
	}
}

sub gsm_freq_cell_info {
	my $xml = shift;
	my $tag = shift;
	if ( $tag->has('MSG_ID_RRC_GSM_FREQ_CELL_INFO_PRINT') ) {
		my $no_cell_info = $xml->findvalue('//local_params/no_cell_info');
		if (hex($no_cell_info) > 0) {
			foreach my $freq_item ($xml->findnodes('//local_params/cell_info_print/item')) {	
				if ( (my $uarfcn = $freq_item->findvalue('./freq_band')) ne "CPHY_GSM_BAND_INVALID") {
					
					my $arfcn = $freq_item->findvalue('./arfcn');
					$tag->add("arfcn" , $arfcn);
					my $bsic = $freq_item->findvalue('./bsic');
					$tag->add("bsic" , $bsic);
					my $rssi = $freq_item->findvalue('./rssi');
					$tag->add("rssi" , $rssi);
				}
			}
		}
	}
}

sub gsmcell_camp_req {
	my $xml = shift;
	my $tag = shift;
	if ( $tag->has('MSG_ID_RRCC_GSM_CELL_CAMP_REQ') ) {
		my $cell_resel_type = $xml->findvalue('//local_params/cell_resel_type');
		$tag->add("cell_resel_type" , $cell_resel_type);
		my $arfcn = $xml->findvalue('//local_params/gsm_cell_param/arfcn');
		$tag->add("arfcn" , $arfcn);
		my $bsic = $xml->findvalue('//local_params/gsm_cell_param/bsic');
		$tag->add("bsic" , $bsic);
	}	
}

sub gsmcell_camp_rsp {
	my $xml = shift;
	my $tag = shift;
	if ( $tag->has('MSG_ID_DM_RAT_CHG_TO_GSM_CNF') ) {
		my $ho_type = $xml->findvalue('//local_params/ho_type');
		$tag->add("ho_type" , $ho_type);
		my $ho_status = $xml->findvalue('//local_params/ho_status');
		$tag->add("ho_status" , $ho_status);	
		my $ho_failure_cause = $xml->findvalue('//local_params/ho_failure_cause');
		$tag->add("ho_failure_cause" , $ho_failure_cause);
	}
	
}

#can add more rules here. 
#can add more rules here. 

###############################
#get one xml block each time  #
###############################
sub get_next_xml {
	my $file_id = shift;
	my $flag = 0;
	##my $beg = "<log>";
	##my $end = "</log>";
	my $beg = "<Message ";
	my $end = "</Message>";
	
	use feature 'state';
	state $store = "";
	
	#if store has the pattern; return it.
	#else
	#read from the file and replenish store.
	
	if ( $store =~ s!.*?($beg.*?$end)!!sm ) { #remove the matched xml from store
	#if ( $store =~ s!($beg.*?$end)!!sm ) {
			my $xml = $1; #the matched xml
			return $xml;
	}
	
	my $data;
	my $n;
	while ( ($n = read $file_id, $data, 1024) != 0 ) {
		$store .= $data;
		if ( $store =~ s!.*?($beg.*?$end)!!sm ) { #remove the matched xml from store
		#if ( $store =~ s!($beg.*?$end)!!sm ) { #should not put g flag;
			my $xml = $1; #the matched xml
			return $xml;
		}
	}
	return;
}

###############################################################################

my @td_tag_rules = (
					\&msg_name,
					\&sn_time_pc,
					\&trace_string,
#					\&rau_req,
#					\&rau_rsp,
#					\&lu_req,
#					\&lu_rsp,
#					\&attach_req,
#					\&attach_rsp,
#					\&call_req,
#					\&call_rsp,
#					\&service_req,
#					\&service_rsp,
					\&tdcell_camp_req,
					\&tdcell_camp_rsp,
					\&rrc_freq_cell_info,
					#\&gsm_freq_cell_info,
					#\&gsmcell_camp_req,
					#\&gsmcell_camp_rsp,
				);
				
sub td_xml_to_tag {
	my $xml = shift;
	my $new_tag = TagMsg->new(); #create a new tag

	foreach my $rule ( @td_tag_rules ) {
		$rule->( $xml, $new_tag );
	}
	#print $new_tag->string(), "\n";
	return( $new_tag );
}


############################# end #####################
1; #need this for "use lte_tag_rules;"