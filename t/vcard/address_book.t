use Test::Most;

use Path::Tiny qw/path tempfile/;
use vCard::AddressBook;
use Encode;

my $in_file  = path('t/complete.vcf');
my $out_file = tempfile('.vcard.out.vcfXXXX');
##my $out_file     = path('.vcard.out.vcf');
my $address_book = vCard::AddressBook->new;

subtest 'load an address book' => sub {
    note 'add_vcard()';
    $address_book->add_vcard;
    $address_book->add_vcard;
    $address_book->add_vcard;

    note 'load_file()';
    $address_book->load_file($in_file);
    my $vcard = $address_book->vcards->[3];

    note "simple getters and setters";
    is $vcard->full_name, 'Bruce Banner, PhD',  'full_name()';
    is $vcard->title,     'Research Scientist', 'title()';
    is $vcard->photo, 'http://shh.supersecret.army.mil/bbanner.gif',
        'photo()';
    is ref $vcard->photo, 'URI::http', 'photo() returns a URI::http obj';
    is $vcard->birthday, '19700414', 'birthday()';
    is $vcard->timezone, 'UTC-7',    'timezone()';

    note "complex getters and setters";
    is_deeply $vcard->family_names,       ['Banner'], 'family_names()';
    is_deeply $vcard->given_names,        ['Bruce'],  'given_names()';
    is_deeply $vcard->honorific_prefixes, ['Dr.'],    'prefixes';
    is_deeply $vcard->honorific_suffixes, ['PhD'],    'suffixes';
    is_deeply $vcard->phones,    expected_phones(),    'phones()';
    is_deeply $vcard->addresses, expected_addresses(), 'addresses()';
    is_deeply $vcard->email_addresses, expected_email_addresses(),
        'email_addresses()';
};

subtest 'output address book' => sub {
    my $in_file_string = $in_file->slurp_utf8;

    $address_book->load_string($in_file_string);
    $address_book->as_file($out_file);

    my $contents = $out_file->slurp_utf8;

    is $contents, expected_out_file(), 'as_file()';

    is scalar @{ $address_book->vcards }, 5, 'created the right # of vcards';
    is ref $_, 'vCard', 'object reference' for @{ $address_book->vcards };
};

done_testing;

sub expected_phones {
    [   { type => ['work'], number => '651-290-1234', preferred => 1 },
        {   type      => [ 'cell', 'text' ],
            number    => '651-290-1111',
            preferred => 0
        }
    ];
}

sub expected_addresses {
    [   {   type      => ['home'],
            preferred => 0,
            po_box    => undef,
            street    => 'Main St',
            city      => 'Desert Base',
            region    => 'New Mexico',
            post_code => '55416',
            country   => 'USA',
            extended  => undef,
        },
        {   type      => ['work'],
            preferred => 0,
            po_box    => undef,
            street    => Encode::decode( 'UTF-8', '部队街' ),
            city      => 'Desert Base',
            region    => 'New Mexico',
            post_code => '55416',
            country   => 'USA',
            extended  => undef,
        },
    ];
}

sub expected_email_addresses {
    [   {   type      => ['work'],
            address   => 'bbanner.work@example.com',
            preferred => 1
        },
        {   type      => ['home'],
            address   => 'bbanner.home@example.com',
            preferred => 0
        }
    ];
}

sub expected_out_file {
    my $in_file_string = $in_file->slurp_utf8;
    return
          "BEGIN:VCARD\x0D\x0AVERSION:4.0\x0D\x0AEND:VCARD\x0D\x0A" x 3
        . $in_file_string
        . $in_file_string;
}

