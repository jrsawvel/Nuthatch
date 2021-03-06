#!/usr/bin/perl -wT

use CouchDB::Client;
use Data::Dumper;


my $db = "veerydvlp1";

my $view_js;

my $c = CouchDB::Client->new();
$c->testConnection or die "The server cannot be reached";

$rc = $c->req('GET', $db . '/_design/views');

my $perl_hash = $rc->{'json'};


##############################################

# javascript view code to add

# tag search on the tag array
$view_js = <<VIEWJS9;
function(doc) {
  if( doc.type === 'post' && doc.post_status === 'public' && doc.tags.length > 0) {
    doc.tags.forEach(function(i) {
      emit( [i, doc.updated_at ], {slug: doc._id, title: doc.title, text_intro: doc.text_intro, more_text_exists: doc.more_text_exists, tags: doc.tags, post_type: doc.post_type, author: doc.author, updated_at: doc.updated_at, reading_time: doc.reading_time});
    });
  }
}
_count 
VIEWJS9
$perl_hash->{'views'}->{'tag_search'}->{'map'} = $view_js;

##############################################



# update the view doc entry
$rc = $c->req('PUT', $db . '/_design/views', $perl_hash);
print Dumper $rc;

