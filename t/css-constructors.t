use v6;
use PDF::Basic;
use PDF::Basic::CSS;
use PDF::Basic::Units :ALL;
use Test;

my $css;

sub to-hash(PDF::Basic::CSS::Edges $edge) {
    my %h;
    for <top left bottom right> -> $e {
        %h{$e} = $_ with $edge."$e"();
    }
    %h;
}

$css = PDF::Basic::CSS.new( :border-width(2px) );
is-deeply to-hash($css.border-width), { :top(2px), :left(2px), :bottom(2px), :right(2px) }, "Numeric -> Edge coercement";

$css = PDF::Basic::CSS.new( :border-width[2px, 3px] );
is-deeply to-hash($css.border-width), { :top(2px), :left(3px), :bottom(2px), :right(3px) }, "Array -> Edge coercement";

$css = PDF::Basic::CSS.new( :border-width{ :top(2px), :right(3px) } );
is-deeply to-hash($css.border-width), { :top(2px), :left(3px), :bottom(2px), :right(3px) }, "Hash -> Edge coercement";

my $border-width = $css.border-width;
$css = Nil;

$css = PDF::Basic::CSS.new( :$border-width );
is-deeply to-hash($css.border-width), { :top(2px), :left(3px), :bottom(2px), :right(3px) }, "Construction from Edget object";

done-testing;
