#!/usr/bin/perl
use strict;

use URI;
use DBI;
use Web::Scraper;
use Data::Dumper;

my $causes = scraper {
	process "h2.termHeading", "causes[]" => scraper {
        	process 'a', url => '@href';
		process 'em', 'cause' => 'TEXT';
		process 'strong.cause', 'causes' => 'TEXT';
		process 'strong.prevent', 'prevents' => 'TEXT';
	};
};


my $dbh = DBI->connect("dbi:SQLite:dbname=cancer.db","","");
my $sth = $dbh->prepare("INSERT INTO cancer (cause, url, causes, prevents) VALUES(?, ?, ?, ?)");

$dbh->do("DELETE FROM cancer") or die $dbh->errstr;;

for my $letter ('a' .. 'z'){
	my $url = "http://kill-or-cure.herokuapp.com/a-z/$letter";
	print "Scraping $url\n";
	my $res = $causes->scrape( URI->new($url) );

	for my $cause (@{$res->{causes}}) {
		$sth->execute( $cause->{cause}, $cause->{url}, ( (defined $cause->{causes})?1:0 ), ( (defined $cause->{prevents})?1:0 ) ) or die $sth->errstr;
	}
}

