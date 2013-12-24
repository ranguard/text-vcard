use v5.10.1;
use utf8;

use Test::Most;
use Text::vCard::Simple;
use Path::Class;

subtest 'load_hash()' => sub {
    my $vcard = Text::vCard::Simple->new;
    $vcard->load_hashref(
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
                    street    => 'Army St',
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
        }
    );

    file("./a")->spew( $vcard->as_string );

    my $expected = <<EOF;
BEGIN:VCARD\r
FN;=:Bruce Banner\\, PhD\r
TITLE;=:Research Scientist\r
ADR;TYPE=WORK:;;Army St;Desert Base;New Mexico;55416;USA\r
ADR;TYPE=HOME:;;Main St;Desert Base;New Mexico;55416;USA\r
TEL;PREF=1;TYPE=WORK:651-290-1234\r
TEL;TYPE=CELL:651-290-1111\r
PHOTO;=:http://shh.supersecret.army.mil/bbanner.gif\r
EMAIL;PREF=1;TYPE=WORK:bbanner.work\@example.com\r
EMAIL;TYPE=HOME:bbanner.home\@example.com\r
BDAY;=:19700414\r
END:VCARD\r
EOF
    file("./b")->spew($expected);
    is $vcard->as_string, $expected;
};

done_testing;
