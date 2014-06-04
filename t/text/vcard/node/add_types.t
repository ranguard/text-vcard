use Test::Most;
use Text::vCard::Addressbook;

my $address_book = Text::vCard::Addressbook->new;
my $vcard = $address_book->add_vcard();
$vcard->version('2.07');
$vcard->fullname("My Name");

my $mail_node = $vcard->add_node({'node_type' => 'EMAIL'});
$mail_node->add_types('INTERNET');
$mail_node->value( "john\@example.org" );

my $string = $address_book->export;

like $string, qr/TYPE=internet/, 'add_types() works';

done_testing;
