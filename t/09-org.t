use strict;
use warnings;
use Path::Tiny;

use Test::More tests => 3;

use lib qw(./lib);

use vCard;

my $vc = vCard->new();

my $in_file = path( 't', 'org.vcf' );
my $expected_content = $in_file->slurp_utf8;

$vc->org([{ value => 'Bubba Gump Shrimp Co.' }]);
is $vc->as_string, $expected_content, 'org(Str)';                       # 1

$vc->organizations([{ value => 'Bubba Gump Shrimp Co.' }]);
is $vc->as_string, $expected_content, 'organizations(Str)';             # 2

$in_file = path( 't', 'org_utf8.vcf' );
$expected_content = $in_file->slurp_utf8;

use utf8;
$vc->org([{ value => '一期一会' }]);
is $vc->as_string, $expected_content, 'org(Str with utf8)';             # 3

done_testing;
