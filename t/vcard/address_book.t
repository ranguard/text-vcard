use Test::Most;

use Encode;
use Directory::Scratch;
use Path::Class;
use vCard::AddressBook;

my $in_file      = file('t/vcard.vcf');
my $out_file     = Directory::Scratch->new->touch('.vcard.out.vcf');
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
    is $vcard->fullname, 'Bruce Banner, PhD',  'fullname()';
    is $vcard->title,    'Research Scientist', 'title()';
    is $vcard->photo, 'http://shh.supersecret.army.mil/bbanner.gif',
        'photo()';
    is $vcard->birthday, '19700414', 'birthday()';
    is $vcard->timezone, 'UTC-7',    'timezone()';

    note "complex getters and setters";
    is_deeply $vcard->phones,    expected_phones(),    'phones()';
    is_deeply $vcard->addresses, expected_addresses(), 'addresses()';
    is_deeply $vcard->email_addresses, expected_email_addresses(),
        'email_addresses()';
};

subtest 'output address book' => sub {
    my $in_file_string = $in_file->slurp;
    $address_book->load_string($in_file_string);

    $address_book->as_file($out_file);
    is scalar $out_file->slurp, $in_file_string, 'as_file()';

    is $address_book->as_string('boop.vcf'), $in_file_string, 'as_string()';

    is scalar @{ $address_book->vcards }, 5, 'created the right # of vcards';
    is ref $_, 'vCard', 'object reference' for @{ $address_book->vcards };
};

done_testing;

# everything below this line is test data

sub expected_phones {
    [   { type => 'home', number => '651-290-1234', preference => 0 },
        { type => 'cell', number => '651-290-1111', preference => 0 }
    ];
}

sub expected_addresses {
    [   {   type       => 'work',
            preference => 0,
            po_box     => undef,
            street     => '部队街',
            city       => 'Desert Base',
            region     => 'New Mexico',
            post_code  => '55416',
            country    => 'USA',
            extended   => undef,
        },
        {   type       => 'home',
            preference => 0,
            po_box     => undef,
            street     => 'Main St',
            city       => 'Desert Base',
            region     => 'New Mexico',
            post_code  => '55416',
            country    => 'USA',
            extended   => undef,
        }
    ];
}

sub expected_email_addresses {
    [   {   type       => 'work',
            address    => 'bbanner.work@example.com',
            preference => 0
        },
        {   type       => 'home',
            address    => 'bbanner.home@example.com',
            preference => 0
        }
    ];
}

