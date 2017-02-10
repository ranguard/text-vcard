use Test::Most;

use Encode;
use Path::Tiny qw/tempfile path/;
use vCard;

my $tmp_file = tempfile('.simple.vcfXXXX');
my $hashref  = hashref();
my $vcard    = vCard->new->load_hashref($hashref);

subtest 'output methods' => sub {
    is $vcard->as_string, expected_vcard(), "as_string()";
    is $vcard->as_file($tmp_file)->stringify, "$tmp_file", "as_file()";

    my $tmp_contents = $tmp_file->slurp_utf8;
    is $tmp_contents, expected_vcard(), "file contents ok";
};

subtest 'simple getters' => sub {
    foreach my $node_type ( vCard->_simple_node_types ) {
        is $vcard->$node_type, $hashref->{$node_type}, $node_type;
    }
};

subtest 'photo' => sub {
    $vcard->photo( $hashref->{photo} );
    is ref( $vcard->photo ), 'URI::http', 'returns a URI::http object';

    $vcard->photo( URI->new( $hashref->{photo} ) );
    is ref( $vcard->photo ), 'URI::http', 'returns a URI::http object';

    is $vcard->photo, $hashref->{photo}, 'photo';
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

subtest 'load_file() with chaining' => sub {
    my $vcard2 = vCard->new->load_file($tmp_file);
    test_simple_node_types($vcard2);
};

subtest 'load_file() w/o chaining' => sub {
    my $vcard2 = vCard->new;
    $vcard2->load_file($tmp_file);
    test_simple_node_types($vcard2);
};

subtest 'load_string() with chaining' => sub {
    my $tmp_contents = $tmp_file->slurp_utf8;
    my $vcard3 = vCard->new->load_string($tmp_contents);
    test_simple_node_types($vcard3);
};

subtest 'load_string() w/o chaining' => sub {
    my $tmp_contents = $tmp_file->slurp_utf8;
    my $vcard3 = vCard->new;
    $vcard3->load_string($tmp_contents);
    test_simple_node_types($vcard3);
};

# \r\n must be used as line endings.  This is required by the RFC.
subtest 'load_string() w/no carriage returns' => sub {
    my $string = raw_vcard();
    $string =~ s/\r//g;
    throws_ok { vCard->new->load_string($string) } qr/ERROR/, 
        'caught exception for a string with no carriage returns';
};

done_testing;

sub test_simple_node_types {
    my ($vcard) = @_;

    is ref $vcard, 'vCard', 'object type is good';

    foreach my $node_type ( vCard->_simple_node_types ) {
        next if $node_type eq 'full_name';
        is $vcard->$node_type, $hashref->{$node_type}, $node_type;
    }
}

# everything below this line is test data

sub raw_vcard {
    return <<EOF;
BEGIN:VCARD\r
VERSION:4.0\r
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
}

sub expected_vcard {
    return Encode::decode( 'UTF-8', raw_vcard() );
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
