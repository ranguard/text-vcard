use Test::Most;

use Encode;
use Directory::Scratch;
use Path::Class;
use vCard::AddressBook;

my $in_file = file('t/simple.vcf');

#my $tmp_file     = Directory::Scratch->new->touch('.simple.vcf');
my $address_book = vCard::AddressBook->new;
$address_book->add_vcard;
$address_book->add_vcard;
$address_book->add_vcard;

# TODO: get rid of the undef tests by loading a vcf which tests every field
subtest 'load_file()' => sub {
    $address_book->load_file($in_file);
    my $vcard = $address_book->vcards->[3];

    note "simple getters and setters";
    is $vcard->fullname, 'T-firstname T-surname', 'fullname()';
    is $vcard->title,    undef,                   'title()';
    is $vcard->photo,    undef,                   'photo()';
    is $vcard->birthday, undef,                   'birthday()';
    is $vcard->timezone, undef,                   'timezone()';

    note "complex getters and setters";
    is_deeply $vcard->phones,
        [
        { type => 'home', number => '020 666 6666',  preference => 0 },
        { type => 'cell', number => '0793 777 7777', preference => 0 }
        ],
        'phones()';
    is_deeply $vcard->addresses,
        [
        {   type       => 'home',
            preference => 0,
            po_box     => undef,
            street     => 'Test Road',
            city       => 'Test City',
            region     => undef,
            post_code  => 'Test Postcode',
            country    => 'Test Country',
            extended   => undef,
        },
        {   type       => 'home',
            preference => 1,
            po_box     => undef,
            street     => 'Pref Test Road',
            city       => 'Pref Test City',
            region     => undef,
            post_code  => 'Pref Test Postcode',
            country    => 'Pref Test Country',
            extended   => undef,
        }
        ],
        'addresses()';
    is_deeply $vcard->email_addresses, [], 'email_addresses()';
    ##is_deeply $vcard->email_addresses,
    ##    [
    ##    {   type       => 'work',
    ##        address    => 'jqpublic@xyz.example.com',
    ##        preference => 0
    ##    }
    ##    ],
    ##    'email_addresses()';
};

$address_book->load_string( scalar $in_file->slurp );

#$address_book->as_file('boop.vcf');
#$address_book->as_string('boop.vcf');

is scalar @{ $address_book->vcards }, 5, 'created the right number of vcards';
is ref $_, 'vCard', 'object reference' for @{ $address_book->vcards };

done_testing;
