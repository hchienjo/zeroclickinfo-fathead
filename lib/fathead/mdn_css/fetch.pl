#!/usr/bin/env perl

use strict;
use warnings;
use v5.10.0;

use Carp 'croak';
use File::Spec::Functions;
use Mojo::UserAgent;
use Mojo::Util 'spurt';
use Mojo::URL;

=begin
This script extracts data from Mozilla CSS Reference
https://developer.mozilla.org/en-US/docs/Web/CSS/Reference and is called by the
fetch.sh script since it is more efficient to fetch and parse the DOM using
something other than BASH to ease development and maintenance in the future.
=cut

my $ua = Mojo::UserAgent->new()->max_redirects(4);
my $reference_url =
  Mojo::URL->new('https://developer.mozilla.org/en-US/docs/Web/CSS/Reference');
my $tx = $ua->get($reference_url);

my @keyword_urls;

if ( $tx->success ) {

=begin
  We extract the collection of links to keywords from the DOM. The links wanted
  are found from this part of the DOM:
  <div class="index">
    <span>A</span>
    <ul>
      <li>
        <a href="/en-US/docs/Web/CSS/:active"><code>:active</code></a>
      </li>
    </ul>
    ...
  </div>
=cut

    my $divs = $tx->res->dom->find('div.index, div.column-half');
    for my $div ( $divs->each ) {
        for my $ul ( $div->find('ul')->each ) {
            $ul->find('li')->map(
                sub {
                    my $li           = shift;
                    my $relative_url = $li->at('a')->attr('href');
                    my $absolute_url = $reference_url->path($relative_url);
                    say "--> $absolute_url";
                    push @keyword_urls, $absolute_url;
                }
            );
        }
    }
}
elsif ( my $error = $tx->error ) {
    croak sprintf "Error: %d %s while fetching %s", $error->{code} || 0,
      $error->{message},
      $tx->req->url;
}

my $current_active_connections = 0;

#name each file downloaded using this increasing
#counter to avoid spending extra functionality removing
#special characters from html_file names like / that might
#be interpreted as path
my $file_name = 1;

$ua = Mojo::UserAgent->new()->max_redirects(4);
Mojo::IOLoop->recurring(
    1 => sub {
        if ( my $url = shift @keyword_urls ) {
            $ua->get( $url => \&get_callback );
        }
        else {
            Mojo::IOLoop->stop if Mojo::IOLoop->is_running;
        }
    }
);
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

sub get_callback {
    my ( undef, $tx ) = @_;
    --$current_active_connections;

    #extract if only if request was successful
    return unless $tx->success;
    say sprintf( "--> %d %s %s",
        $tx->res->code, $tx->res->message, $tx->req->url );
    spurt $tx->res->body, catfile( 'download', "$file_name.html" );
    ++$file_name;
}
