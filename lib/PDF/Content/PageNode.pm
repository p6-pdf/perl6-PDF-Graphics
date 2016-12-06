use v6;

use PDF::DAO::Tie::Hash;

role PDF::Content::PageNode {

    #| source: http://www.gnu.org/software/gv/
    my subset Box of Array;# where {.elems == 4}

    #| e.g. $.landscape(PagesSizes::A4)
    method to-landscape(Box $p --> Box) {
	[ $p[1], $p[0], $p[3], $p[2] ]
    }

    my subset BoxName of Str where 'media' | 'crop' | 'bleed' | 'trim' | 'art';

    method !bbox-name(BoxName $box) {
	{ :media<MediaBox>, :crop<CropBox>, :bleed<BleedBox>, :trim<TrimBox>, :art<ArtBox> }{$box}
    }

    method !get-prop(BoxName $box) is rw {
	my $bbox = self!bbox-name($box);
        self."$bbox"();
    }

    method bbox(BoxName $_) is rw {
	when 'media' { self.MediaBox //= [0, 0, 612, 792] }
	when 'crop'  { self.CropBox // self.bbox('media') }
	default      { self!get-prop($_) // self.bbox('crop') }
    }

    method media-box(|c) is rw { self.bbox('media', |c) }
    method crop-box(|c)  is rw { self.bbox('crop',  |c) }
    method bleed-box(|c) is rw { self.bbox('bleed', |c) }
    method trim-box(|c)  is rw { self.bbox('trim',  |c) }
    method art-box(|c)   is rw { self.bbox('art',   |c) }

    has Numeric $.width;
    has Numeric $.height;
    method width  { with $!width { $_ } else { self!size()[0] } }
    method height { with $!height { $_ } else { self!size()[1] } }
    method !size {
        my $bbox = self!media-box;
        $!width = $bbox[2] - $bbox[0];
        $!height = $bbox[3] - $bbox[1];
        ($!width, $!height);
    }
}
