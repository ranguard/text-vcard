use Test::Most;
use Text::vCard::Addressbook;
use Path::Class;

note "utf-8 encoded files";
foreach my $filename (qw|complete.vcf quotedprintable.vcf|) {
    note "Importing $filename with Addressbook->load()";
    my $in_file = file( 't', $filename );

    # load() uses ':encoding('UTF-8')' by default to slurp $in_file
    my $address_book = Text::vCard::Addressbook->load( [$in_file] );
    my $vcard = $address_book->vcards->[0];

    # This returns a decoded value:
    #    $file->slurp( iomode => ":encoding('UTF-8')" );
    # This returns a utf-8 encoded value if the file is utf-8
    #    $file->slurp();
    # So $expected_content below is UTF-8 encoded
    my $expected_content = $in_file->slurp();

    # This returns UTF-8 encoded content
    my $actual_content = $vcard->as_string();

    # These are comparing 2 things that are both UTF-8 encoded
    is $actual_content, $expected_content, 'vCard->as_string()';
    is $address_book->export(), $actual_content, 'Addressbook->export()';
}

note "latin1 encoded files";
foreach my $filename (qw|latin1.vcf|) {
    note "Importing $filename with Addressbook->load()";
    my $in_file = file( 't', $filename );

    my $address_book = Text::vCard::Addressbook->load( [$in_file],
        { encoding_in => 'none', encoding_out => 'none' } );
    my $vcard            = $address_book->vcards->[0];
    my $expected_content = $in_file->slurp();
    my $actual_content   = $vcard->as_string();

    is $actual_content, $expected_content, 'vCard->as_string()';
    is $address_book->export(), $actual_content, 'Addressbook->export()';
}

done_testing;
