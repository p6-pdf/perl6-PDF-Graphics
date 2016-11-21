use v6;
use Test;
use PDF::Grammar::Test :is-json-equiv;
use PDF::Content;
use PDF::Content::Ops :OpCode;

role Parent {
    has $!key = 'R0';
    has Str %!keys{Any};
    method find-resource(&match, :$type) {
        my $entry;

        with self{$type} -> $resources {

            for $resources.keys {
                my $resource = $resources{$_};
                if &match($resource) {
		    $entry = $resource;
                    last;
                }
            }
        }

        $entry;
     }
    method use-resource($obj) {
        %!keys{$obj} = ++ $!key;
        self{$obj<Type>}{$!key} = $obj;
        $obj;
    }
    method resource-key($obj) {
        $.use-resource($obj)
            unless %!keys{$obj}:exists;
        %!keys{$obj};
    }
    method resource-entry($a,$b) {
        self{$a}{$b};
    }
}
my $parent = { :Font{ :F1{} }, } does Parent;
my $g = PDF::Content.new: :$parent;

$g.op(Save);

is-json-equiv $g.CTM, [1, 0, 0, 1, 0, 0], '$g.CTM - initial';
$g.ConcatMatrix( 10, 1, 15, 2, 3, 4);
is-json-equiv $g.CTM, [10, 1, 15, 2, 3, 4], '$g.GraphicMatrix - updated';
$g.ConcatMatrix( 10, 1, 15, 2, 3, 4);
is-json-equiv $g.CTM, [115, 12, 180, 19, 93, 15], '$g.GraphicMatrix - updated again';

is-json-equiv $g.BeginText, (:BT[]), 'BeginText';

is-json-equiv $g.op('Tf', 'F1', 16), (:Tf[ :name<F1>, :real(16) ]), 'Tf';
is $g.font-size, 16, '$g.font-size';

is $g.StrokeColorSpace, 'DeviceGray', '$g.StrokeColorSpace - initial';
dies-ok { $g.op('SCN', .2, .3, .4) }, 'SCN (/DeviceGray)';

is-json-equiv $g.op('RG', .1, .2, .3), (:RG[ :real(.1), :real(.2), :real(.3) ] ), 'CS';
is-deeply $g.StrokeColor, (:DeviceRGB[.1, .2, .3]), '$g.StrokeColor - updated';
is $g.StrokeColorSpace, 'DeviceRGB', '$g.StrokeColorSpace - updated';
my $ops1 = +$g.ops;
$g.StrokeColor = :DeviceRGB[.4, .5, .6];
my $ops2 = +$g.ops;
ok $ops2 > $ops1, 'StrokColor Op added';
$g.StrokeColor = :DeviceRGB[.4, .5, .6];
is $ops2, +$g.ops, 'StrokeColor Op optimised';

is $g.StrokeColorSpace, 'DeviceRGB', '$g.StrokeColorSpace - initial';

dies-ok { $g.StrokeColor = :DeviceRGB[.4, .5, .6, .8] }, 'wrong number of colors - dies';

is-deeply $g.StrokeColor, (:DeviceRGB[.4, .5, .6]), '$g.StrokeColor - updated again';

lives-ok { $g.op('SCN', .2, .3, .4) }, 'SCN (/DeviceRGB)';

$g.StrokeColor = :DeviceN[.7, .8];
is-deeply $g.StrokeColor, (:DeviceN[.7, .8]), '$g.StrokeColor - deviceN';

is $g.FillColorSpace, 'DeviceGray', '$g.FillColorSpace - initial';
is-json-equiv $g.op('cs', 'DeviceRGB'), (:cs[ :name<DeviceRGB> ] ), 'CS';
is $g.FillColorSpace, 'DeviceRGB', '$g.FillColorSpace - updated';

$ops1 = +$g.ops;
is $g.TextLeading, 0, '$g.TextLeading - initial';
$g.TextLeading = 22;
$ops2 = +$g.ops;
ok $ops2 > $ops1, 'TextLeading Op added';
dies-ok { $g.TextLeading = 'nah' }, 'assigment type-checking';
is $ops2, +$g.ops, 'Op ignored';
$g.TextLeading = 22;
is $ops2, +$g.ops, 'TextLeading Op optimised';
is $g.TextLeading, 22, '$g.TextLeading - updated';

is $g.WordSpacing, 0, '$g.WordSpacing - initial';
$g.WordSpacing = 7.5;
is $g.WordSpacing, 7.5, '$g.WordSpacing - updated';

is $g.HorizScaling, 100, '$g.HorizScaling - initial';
$g.HorizScaling = 150;
is $g.HorizScaling, 150, '$g.HorizScaling - updated';

is $g.TextRise, 0, '$g.TextRise - initial';
$g.TextRise = 1.5;
is $g.TextRise, 1.5, '$g.TextRise - updated';

is $g.CharSpacing, 0, '$g.CharSpacing - initial';
$g.CharSpacing = -.5;
is $g.CharSpacing, -.5, '$g.CharSpacing - updated';

is $g.DashPattern, [[], 0], 'DashPattern - initial';
$g.DashPattern = [[3, 5], 6];
is $g.DashPattern, [[3, 5], 6], 'DashPattern - updated';

is-json-equiv $g.TextMatrix, [1, 0, 0, 1, 0, 0], '$g.TextMatrix - initial';
$g.TextMatrix = [ 10, 1, 15, 2, 3, 4];
is-json-equiv $g.TextMatrix, [10, 1, 15, 2, 3, 4], '$g.TextMatrix - updated';
$g.TextMatrix = ( 10, 1, 15, 2, 3, 4);
is-json-equiv $g.TextMatrix, [10, 1, 15, 2, 3, 4], '$g.TextMatrix - updated again';

$g.FillAlpha = 1.0;
nok Parent<ExtGState>, 'FillAlpha Optimized';
$g.FillAlpha = .4;
is $g.ops[*-1], (:gs([:name<R1>])), 'FillAlpha op';
is-json-equiv $parent<ExtGState><R1>, { :Type<ExtGState>, :ca(0.4)}, 'FillAlpha graphics resource';
$g.FillAlpha = 1.0;
is-json-equiv $parent<ExtGState><R2>, { :Type<ExtGState>, :ca(1.0)}, 'FillAlpha graphics resource';

is-json-equiv $g.op('scn', 0.30, 'int' => 1, 0.21, 'P2'), (:scn[ :real(.30), :int(1), :real(.21), :name<P2> ]), 'scn';
is-json-equiv $g.op('TJ', $[ 'hello', 42, 'world']), (:TJ[ :array[ :literal<hello>, :int(42), :literal<world> ] ]), 'TJ';
is-json-equiv $g.SetStrokeColorSpace('DeviceGray'), (:CS[ :name<DeviceGray> ]), 'Named operator';
dies-ok {$g.op('Tf', 42, 125)}, 'invalid argument dies';
dies-ok {$g.op('Junk', 42)}, 'invalid operator dies';
dies-ok {$g.content}, 'content with unclosed "BT" - dies';

is-json-equiv $g.op(EndText), (:ET[]), 'EndText';

is-json-equiv $g.TextMatrix, [1, 0, 0, 1, 0, 0, ], '$g.TextMatrix - outside of text block';
is-json-equiv $g.CTM, [115, 12, 180, 19, 93, 15], '$g.GraphicMatrix - outside of text block';

dies-ok {$g.content}, 'content with unclosed "q" (gsave) - dies';
$g.Restore;

is-json-equiv $g.CTM, [1, 0, 0, 1, 0, 0, ], '$g.GraphicMatrix - restored';
is-json-equiv $g.TextMatrix, [1, 0, 0, 1, 0, 0], '$g.TextMatrix - restored';
is $g.TextLeading, 0, '$g.TextLeading - restored';
is $g.StrokeColorSpace, 'DeviceGray', '$g.StrokeColorSpace - restored';

lives-ok {$g.content}, 'content with matching BT ... ET  q ... Q - lives';

$g = PDF::Content.new;

$g.ops("175 720 m 175 700 l 300 800 400 720 v h S");
is-json-equiv $g.ops, [:m[:int(175), :int(720)],
                       :l[:int(175), :int(700)],
                       :v[:int(300), :int(800), :int(400), :int(720)],
                       :h[],
                       :S[],
    ], 'basic parse';

my $image-block = 'BI                  % Begin inline image object
    /W 17           % Width in samples
    /H 17           % Height in samples
    /CS /RGB        % Colour space
    /BPC 8          % Bits per component
    /F [/A85 /LZW]  % Filters
ID                  % Begin image data
J1/gKA>.]AN&J?]-<HW]aRVcg*bb.\eKAdVV%/PcZ
%…Omitted data…
%R.s(4KE3&d&7hb*7[%Ct2HCqC~>
EI';

my @image-lines = q:to"EI".lines;;
J1/gKA>.]AN&J?]-<HW]aRVcg*bb.\eKAdVV%/PcZ
%…Omitted data…
%R.s(4KE3&d&7hb*7[%Ct2HCqC~>
EI

$g.ops($image-block);
is-json-equiv $g.ops[*-3], {:BI[:dict{
                                    :W(:int(17)),
                                    :H(:int(17)),
                                    :CS(:name<RGB>),
                                    :BPC(:int(8)),
                                    :F(:array[:name<A85>, :name<LZW>]),
                                     }]}, 'Image BI';

is-json-equiv [$g.ops[*-2]<ID>[0]<encoded>.lines], @image-lines, 'Image ID';
is-json-equiv $g.ops[*-1], (:EI[]), 'Image EI';

my @inline-images = $g.inline-images;

is-json-equiv @inline-images, [{:BitsPerComponent(8), :ColorSpace<RGB>, :Filter<A85 LZW>, :Height(17), :Width(17),
                                :Length(86), :Subtype<Image>, :Type<XObject> },], 'inline-images';
is-deeply [@inline-images[0].encoded.lines], @image-lines, 'image lines';

BEGIN our $compile-time = PDF::Content::Ops.parse("BT/F1 16 Tf\n(Hi)Tj ET");
is-json-equiv $compile-time[*-1], (:ET[]), 'compile time ops parse';
$g.ops( $compile-time);
is-json-equiv [ $g.ops[*-4..*] ], [
    :BT[],
    :Tf[:name<F1>, :int(16)],
    :Tj[:literal<Hi>],
    :ET[],
], 'Text block parse';

$g = PDF::Content.new :comment-ops;

$g.ops("175 720 m 175 700 l 300 800 400 720 v h S");
is-json-equiv $g.ops, [
    :m[:int(175), :int(720), :comment<MoveTo>, ],
    :l[:int(175), :int(700), :comment<LineTo>, ],
    :v[:int(300), :int(800), :int(400), :int(720), :comment<CurveToInitial>, ],
    :h[ :comment<ClosePath>, ],
    :S[ :comment<Stroke>, ],
], 'parse and comment';

is-deeply $g.content-dump, $(
    '175 720 m % MoveTo',
    '175 700 l % LineTo',
    '300 800 400 720 v % CurveToInitial',
    'h % ClosePath',
    'S % Stroke'
), 'content with comments';

my $g1 = PDF::Content.new;
lives-ok {$g1.ops: $g.ops}, "comments import";
is-json-equiv $g1.ops[0], (:m[ :int(175), :int(720), :comment<MoveTo>, ]), 'comments import';

$g.Save;
$g.CTM = [0, -2, 2, 0, 40, -20];
is-deeply [ $g.CTM.list ], [0.0, -2.0, 2.0, 0.0, 40.0, -20.0], 'graphics matrix assignment';
$g.Restore;

lives-ok { $g.?Junk }, 'unknown method/operator: .? invocation';
dies-ok { $g.Junk }, 'unknown method/operator: . invocation';

done-testing;
