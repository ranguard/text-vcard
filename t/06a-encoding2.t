use Test::Most;
use lib 'lib';

use Text::vCard::Addressbook;

my $card_type = 'encoding2.vcf';

my $address_book = Text::vCard::Addressbook    #
    ->new( { source_file => "t/$card_type" } );

foreach my $vcard ( $address_book->vcards() ) {
    my $string = $vcard->as_string();
    ok $string !~ /Gau=C3=83=C2=9F/, "no double encoding";
}

done_testing;
