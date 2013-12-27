use Test::Most;

use Encode;
use Directory::Scratch;
use Path::Class;
use vCard;

my $tmp_file = Directory::Scratch->new->touch('.simple.vcf');
my $vcard    = vCard->new->load_hashref( hashref() );

is $vcard->as_string, expected_vcard(), "as_string()";

is $vcard->as_file($tmp_file)->stringify, $tmp_file->stringify, "as_file()";

is scalar $tmp_file->slurp, expected_vcard(), "file contents ok";

done_testing;

sub expected_vcard {
    return <<EOF
BEGIN:VCARD\r
FN;=:Bruce Banner\\, PhD\r
TITLE;=:Research Scientist\r
ADR;TYPE=WORK:;;部队街;Desert Base;New Mexico;55416;USA\r
ADR;TYPE=HOME:;;Main St;Desert Base;New Mexico;55416;USA\r
TEL;PREF=1;TYPE=WORK:651-290-1234\r
TEL;TYPE=CELL:651-290-1111\r
TZ;=:UTC-7\r
PHOTO;=:http://shh.supersecret.army.mil/bbanner.gif\r
EMAIL;PREF=1;TYPE=WORK:bbanner.work\@example.com\r
EMAIL;TYPE=HOME:bbanner.home\@example.com\r
BDAY;=:19700414\r
END:VCARD\r
EOF
}

sub hashref {
    {   fullname    => 'Bruce Banner, PhD',
        first_name  => 'Bruce',
        family_name => 'Banner',
        title       => 'Research Scientist',
        photo       => 'http://shh.supersecret.army.mil/bbanner.gif',
        birthday    => '19700414',
        timezone    => 'UTC-7',
        phones      => [
            {   type      => 'work',
                number    => '651-290-1234',
                preferred => 1,
            },
            {   type   => 'cell',
                number => '651-290-1111'
            },
        ],
        addresses => [
            {   type      => 'work',
                street    => decode( 'utf8', '部队街' ),
                city      => 'Desert Base',
                region    => 'New Mexico',
                post_code => '55416',
                country   => 'USA',
            },
            {   type      => 'home',
                street    => 'Main St',
                city      => 'Desert Base',
                region    => 'New Mexico',
                post_code => '55416',
                country   => 'USA',
            },
        ],
        email_addresses => [
            {   type      => 'work',
                address   => 'bbanner.work@example.com',
                preferred => 1
            },
            {   type    => 'home',
                address => 'bbanner.home@example.com',
            },
        ],
    };
}
