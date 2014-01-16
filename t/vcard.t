use Test::Most;

use Encode;
use Directory::Scratch;
use Path::Class;
use vCard;

my $tmp_file = Directory::Scratch->new->touch('.simple.vcf');
my $hashref  = hashref();
my $vcard    = vCard->new->load_hashref($hashref);

subtest 'output methods' => sub {
    is $vcard->as_string, expected_vcard(), "as_string()";
    is $vcard->as_file($tmp_file)->stringify, "$tmp_file", "as_file()";

    my $tmp_contents = $tmp_file->slurp( iomode => '<:encoding(UTF-8)' );
    is $tmp_contents, expected_vcard(), "file contents ok";
};

subtest 'simple getters' => sub {
    foreach my $node_type ( vCard->_simple_node_types ) {
        is $vcard->$node_type, $hashref->{$node_type}, $node_type;
    }
};

subtest 'complex getters' => sub {
    is_deeply $vcard->family_names,       ['Banner'], 'family_names()';
    is_deeply $vcard->given_names,        ['Bruce'],  'given_names()';
    is_deeply $vcard->honorific_prefixes, ['Dr.'],    'prefixes';
    is_deeply $vcard->honorific_suffixes, ['PhD'],    'suffixes';

    my $phones = $vcard->phones;
    is_deeply $phones->[0]->{type}, ['work'], 'work phone';
    is_deeply $phones->[1]->{type}, ['cell'], 'cell phone';

    my $addresses = $vcard->addresses;
    is $addresses->[0]->{city}, 'Desert Base', 'work address';
    is $addresses->[1]->{city}, 'Desert Base', 'home address';

    my $emails = $vcard->email_addresses;
    is_deeply $emails->[0]->{type}, ['work'], 'work email address';
    is_deeply $emails->[1]->{type}, ['home'], 'home email address';
};

subtest 'load_file()' => sub {
    my $vcard2 = vCard->new->load_file($tmp_file);
    is ref $vcard2, 'vCard', 'object type is good';
    foreach my $node_type ( vCard->_simple_node_types ) {
        next if $node_type eq 'full_name';
        is $vcard2->$node_type, $hashref->{$node_type}, $node_type;
    }
};

subtest 'load_string()' => sub {
    my $tmp_contents = $tmp_file->slurp( iomode => '<:encoding(UTF-8)' );
    my $vcard3 = vCard->new->load_string($tmp_contents);
    is ref $vcard3, 'vCard', 'object type is good';
    foreach my $node_type ( vCard->_simple_node_types ) {
        next if $node_type eq 'full_name';
        is $vcard3->$node_type, $hashref->{$node_type}, $node_type;
    }
};

done_testing;

# everything below this line is test data

sub expected_vcard {
    my $string = <<EOF;
BEGIN:VCARD\r
N:Banner;Bruce;;Dr.;PhD\r
FN:Bruce Banner\\, PhD\r
ADR;TYPE=work:;;部队街;Desert Base;New Mexico;55416;USA\r
ADR;TYPE=home:;;Main St;Desert Base;New Mexico;55416;USA\r
BDAY:19700414\r
EMAIL;PREF=1;TYPE=work:bbanner.work\@example.com\r
EMAIL;TYPE=home:bbanner.home\@example.com\r
PHOTO:http://shh.supersecret.army.mil/bbanner.gif\r
TEL;PREF=1;TYPE=work:651-290-1234\r
TEL;TYPE=cell:651-290-1111\r
TITLE:Research Scientist\r
TZ:UTC-7\r
END:VCARD\r
EOF

    return Encode::decode( 'UTF-8', $string );
}

sub hashref {
    {   full_name          => 'Bruce Banner, PhD',
        given_names        => ['Bruce'],
        family_names       => ['Banner'],
        honorific_prefixes => ['Dr.'],
        honorific_suffixes => ['PhD'],
        title              => 'Research Scientist',
        photo              => 'http://shh.supersecret.army.mil/bbanner.gif',
        birthday           => '19700414',
        timezone           => 'UTC-7',
        phones             => [
            {   type      => ['work'],
                number    => '651-290-1234',
                preferred => 1,
            },
            {   type   => ['cell'],
                number => '651-290-1111'
            },
        ],
        addresses => [
            {   type      => ['work'],
                street    => decode( 'utf8', '部队街' ),
                city      => 'Desert Base',
                region    => 'New Mexico',
                post_code => '55416',
                country   => 'USA',
            },
            {   type      => ['home'],
                street    => 'Main St',
                city      => 'Desert Base',
                region    => 'New Mexico',
                post_code => '55416',
                country   => 'USA',
            },
        ],
        email_addresses => [
            {   type      => ['work'],
                address   => 'bbanner.work@example.com',
                preferred => 1
            },
            {   type    => ['home'],
                address => 'bbanner.home@example.com',
            },
        ],
    };
}
