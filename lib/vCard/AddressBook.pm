package vCard::AddressBook;

use Moo;
use Text::vCard;
use Path::Class;

=head1 SYNOPSIS

    use vCard::AddressBook;

    # create the object
    my $address_book = vCard::AddressBook->new();

    $address_book->load_file('/path/file.vcf');
    $address_book->load_string($string);

    my $vcard = $adress_book->add_vcard; # returns a vCard object
    $vcard->fullname('Bruce Banner, PhD');
    $vcard->email_addresses({
        { type => 'work', address => 'bbanner@ssh.secret.army.mil' },
        { type => 'home', address => 'bbanner@timewarner.com'      },
    });

    # $address_book->vcards() returns a L<vCard> object
    foreach my $vcard ( $address_book->vcards() ) {
        print $vcard->fullname() . "\n";
        print $vcard->email_addresses->[0]->{address} . "\n";
    }

    my $file   = $address_book->as_file('/path/file.vcf'); # write to a file
    my $string = $address_book->as_string();


=head1 DESCRIPTION

A vCard is a digital business card.  vCard and vCard::AddressBook provide an
API for parsing, editing, and creating vCards.

This module is built on top of Text::vCard and provides a more intuitive user
interface.  

=head1 METHODS

=cut

1;
