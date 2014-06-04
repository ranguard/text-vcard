use Test::Most;
use Text::vCard::Addressbook;
use Path::Tiny;

# This test makes sure that the files we export are the same as what we
# imported.  This property is not true for every possible vcard, but it should
# always be true for the vcards that are tested below.

note "utf-8 encoded files";
foreach my $filename (qw|complete.vcf quotedprintable.vcf|) {
    note "Importing $filename with Addressbook->load()";
    my $in_file = path( 't', $filename );

    # load() uses ':encoding('UTF-8')' by default to slurp $in_file
    my $address_book = Text::vCard::Addressbook->load( [$in_file] );
    my $vcard = $address_book->vcards->[0];

    # This returns UTF-8 decoded content
    my $expected_content = $in_file->slurp_utf8;

    # This returns UTF-8 decoded content
    my $actual_content = $vcard->as_string();

    # These are comparing 2 things that are both UTF-8 decoded
    is $actual_content, $expected_content, 'vCard->as_string()';
    is $address_book->export(), $actual_content, 'Addressbook->export()';
}

note "latin1 encoded files";
foreach my $filename (qw|latin1.vcf|) {
    note "Importing $filename with Addressbook->load()";
    my $in_file = path( 't', $filename );

    my $address_book = Text::vCard::Addressbook->load( [$in_file],
        { encoding_in => 'none', encoding_out => 'none' } );
    my $vcard            = $address_book->vcards->[0];
    my $expected_content = $in_file->slurp_raw();
    my $actual_content   = $vcard->as_string();

    is $actual_content, $expected_content, 'vCard->as_string()';
    is $address_book->export(), $actual_content, 'Addressbook->export()';
}

done_testing;
