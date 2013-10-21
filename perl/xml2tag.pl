#############################################################################
#this script can be used on the xml file to output the tag file 
#usage :																																		
#
#perl xml2summary.pl test.xml test.tag										
###############################################################################

use strict;
use warnings;
use XML::LibXML;
use Data::Dumper;
use TagLog;
use td_filter;

###############################################################################
############################Main PROCESSING BLOCK##############################

if ( @ARGV != 2 ) {
	print "usage: perl xml2summary.pl xmlfile.xml outfile.tag\n";
	exit();
}



my $file_name= shift ( @ARGV ); #$ARGV[0];  
my $log = TagLog->new();
my $parser = XML::LibXML->new();

if ( $file_name =~ m/\.xml/ ) {               #deal with the xml file
	my $file_id;
	open($file_id, "$file_name") or die "cannot open xml file $file_name\n";
		
	my $xml;
	while ( my $data = get_next_xml($file_id) ) {
		$xml = $parser->parse_string($data);
		$log->add ( td_xml_to_tag($xml) );
	}
	close $file_id;
	
	#print "Done Stage 1 ", $log->end(), "\n";
	my $tag_file_name= shift ( @ARGV ); #$ARGV[1];
	$log->save($tag_file_name);
} 

exit();	
##########################################################################################################



