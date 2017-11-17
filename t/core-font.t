use v6;
use Test;
plan 41;
use PDF::Grammar::Test :is-json-equiv;
use PDF::Content::Font;
use PDF::Content::Font::CoreFont;

is PDF::Content::Font::CoreFont.core-font-name('Helvetica,Bold'), 'helvetica-bold', 'core-font-name';
is PDF::Content::Font::CoreFont.core-font-name('Helvetica-BoldOblique'), 'helvetica-boldoblique', 'core-font-name';
is PDF::Content::Font::CoreFont.core-font-name('Arial,Bold'), 'helvetica-bold', 'core-font-name';
is-deeply PDF::Content::Font::CoreFont.core-font-name('Blah'), Nil, 'core-font-name';

my $tr-bold = PDF::Content::Font::CoreFont.load-font( :family<Times-Roman>, :weight<bold>);
is $tr-bold.font-name, 'Times-Bold', 'font-name';

my $tsym = PDF::Content::Font::CoreFont.load-font( :family<Symbol>, :weight<bold>);
is $tsym.font-name, 'Symbol', 'font-name';
is $tsym.enc, 'sym', 'enc';

my $hb-afm = PDF::Content::Font::CoreFont.load-font( 'Helvetica-Bold' );
isa-ok $hb-afm.metrics, 'Font::AFM'; 
is $hb-afm.font-name, 'Helvetica-Bold', 'font-name';
is $hb-afm.enc, 'win', '.enc';
is $hb-afm.height, 1190, 'font height';
is $hb-afm.height(:hanging), 925, 'font height hanging';
is-approx $hb-afm.height(12), 14.28, 'font height @ 12pt';
is-approx $hb-afm.height(12, :from-baseline), 11.544, 'font base-height @ 12pt';
is-approx $hb-afm.height(12, :hanging), 11.1, 'font hanging height @ 12pt';
is $hb-afm.encode("A♥♣✔B", :str), "AB", '.encode(...) sanity';

my $ab-afm = PDF::Content::Font::CoreFont.load-font( 'Arial-Bold' );
isa-ok $hb-afm.metrics, 'Font::AFM'; 
is $hb-afm.font-name, 'Helvetica-Bold', 'font-name';
is $hb-afm.encode("A♥♣✔B", :str), "AB", '.encode(...) sanity';

my $hbi-afm = PDF::Content::Font::CoreFont.load-font( :family<Helvetica>, :weight<Bold>, :style<Italic> );
is $hbi-afm.font-name, 'Helvetica-BoldOblique', ':font-family => font-name';

my $hb-afm-again = PDF::Content::Font::CoreFont.load-font( 'Helvetica-Bold' );
ok $hb-afm-again === $hb-afm, 'font caching';

my $hbi-afm-dict = $hbi-afm.to-dict;
is-json-equiv $hbi-afm-dict, { :BaseFont<Helvetica-BoldOblique>, :Encoding<WinAnsiEncoding>, :Subtype<Type1>, :Type<Font>}, "to-dict";

my $tr-afm = PDF::Content::Font::CoreFont.load-font( 'Times-Roman' );
is $tr-afm.stringwidth("RVX", :!kern), 2111, 'stringwidth :!kern';
is $tr-afm.stringwidth("RVX", :kern), 2111 - 80, 'stringwidth :kern';
is-deeply $tr-afm.kern("RVX" ), (['R', -80, 'VX'], 2031), '.kern(...)';

for (win => "Á®ÆØ",
     mac => "ç¨®¯") {
    my ($enc, $encoded) = .kv;
    my $fnt = PDF::Content::Font::CoreFont.load-font( 'helvetica', :$enc );
    my $decoded = "Á®ÆØ";
    my $re-encoded = $fnt.encode($decoded, :str);
    is $re-encoded, $encoded, "$enc encoding";
    is $fnt.decode($encoded, :str), $decoded, "$enc decoding";
    is-deeply $fnt.decode($encoded, ), buf16.new($decoded.ords), "$enc raw decoding";
}

my $zapf = PDF::Content::Font::CoreFont.load-font( 'ZapfDingbats' );
isa-ok $zapf.metrics, 'Font::Metrics::zapfdingbats';
is $zapf.enc, 'zapf', '.enc';
is $zapf.encode("♥♣✔", :str), "ª¨4", '.encode(...)'; # /a110 /a112 /a20
is $zapf.decode("ª¨4", :str), "♥♣✔", '.decode(...)';
is $zapf.decode("\o251\o252", :str), "♦♥", '.decode(...)';

isa-ok PDF::Content::Font::CoreFont.load-font('CourierNew,Bold').metrics, 'Font::Metrics::courier-bold';

my $sym = PDF::Content::Font::CoreFont.load-font( 'Symbol' );
isa-ok $sym.metrics, 'Font::Metrics::symbol';
is $sym.enc, 'sym', '.enc';
is $sym.encode("ΑΒΓ", :str), "ABG", '.encode(...)'; # /Alpha /Beta /Gamma
is $sym.decode("ABG", :str), "ΑΒΓ", '.decode(...)';

done-testing;