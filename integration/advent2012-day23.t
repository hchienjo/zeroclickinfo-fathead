# http://perl6advent.wordpress.com/2012/12/23/day-23-macros/
use v6;
use Test;

plan 2;

sub capture-said($code) {
    my $output;
    temp $*OUT = class {
	method print(*@args) {
	    $output ~= @args.join;
	}
    }
    $code();
    return $output
}

macro checkpoint {
  my $i = ++(state $n);
  quasi { say "CHECKPOINT $i"; }
}

my $checkpoint-output = capture-said( {
    checkpoint;
    for ^5 { checkpoint; }
    checkpoint;
});

is $checkpoint-output, q:to"END", 'checkpoint example';
CHECKPOINT 1
CHECKPOINT 2
CHECKPOINT 2
CHECKPOINT 2
CHECKPOINT 2
CHECKPOINT 2
CHECKPOINT 3
END

constant LOGGING = True;

macro LOG($message) {
  if LOGGING {
    quasi { say {{{$message}}} };
  }
}

sub time-consuming-computation() {42}

my $output = capture-said {LOG "The answer is { time-consuming-computation() }";}
is $output.chomp, 'The answer is 42', 'LOG macro';
