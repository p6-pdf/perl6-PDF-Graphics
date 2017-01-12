use v6;
use Test;
use lib '.';
use t::PDFTiny;
my $pdf = t::PDFTiny.new;
my $page = $pdf.add-page;

$page.graphics: -> $gfx {
    my $pattern = $page.tiling-pattern(:BBox[0, 0, 25, 25], );
    $pattern.graphics: {
        .FillColor = :DeviceRGB[.7, .7, .9];
        .Rectangle(|$pattern<BBox>);
        .Fill;
        my $img = .load-image("t/images/lightbulb.gif");
        .do($img, 5, 5 );
    }
    $pattern.finish;
    $gfx.FillColor = :Pattern($page.resource-key($pattern));
    $gfx.Rectangle(0, 20, 100, 250);
    $gfx.Fill;
    $gfx.transform: :translate[110, 10];
    $gfx.Rectangle(0, 20, 100, 250);
    $gfx.Fill;
}
$pdf.save-as: "t/patterns.pdf";