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
    is scalar $tmp_file->slurp, expected_vcard(), "file contents ok";
};

subtest 'simple getters' => sub {
    foreach my $node_type ( vCard->_simple_node_types ) {
        is $vcard->$node_type, $hashref->{$node_type}, $node_type;
    }
};

subtest 'complex getters' => sub {
    is $vcard->phones->[0]->{type},    'work',        'work phone';
    is $vcard->phones->[1]->{type},    'cell',        'cell phone';
    is $vcard->addresses->[0]->{city}, 'Desert Base', 'work address';
    is $vcard->addresses->[1]->{city}, 'Desert Base', 'home address';
    is $vcard->email_addresses->[0]->{type}, 'work', 'work email address';
    is $vcard->email_addresses->[1]->{type}, 'home', 'home email address';
};

subtest 'load_file()' => sub {
    my $vcard2 = vCard->new->load_file($tmp_file);
    is ref $vcard2, 'vCard', 'object type is good';
    foreach my $node_type ( vCard->_simple_node_types ) {
        next if $node_type eq 'fullname';
        is $vcard2->$node_type, $hashref->{$node_type}, $node_type;
    }
};

subtest 'load_string()' => sub {
    my $vcard3 = vCard->new->load_string( scalar $tmp_file->slurp );
    is ref $vcard3, 'vCard', 'object type is good';
    foreach my $node_type ( vCard->_simple_node_types ) {
        next if $node_type eq 'fullname';
        is $vcard3->$node_type, $hashref->{$node_type}, $node_type;
    }
};

done_testing;

# everything below this line is test data

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
