package Text::vCard::Addressbook;

use Carp;
use strict;
use warnings;
use File::Slurp;
use Text::vFile::asData;
use Text::vCard;

# See this module for your basic parser functions
use base qw(Text::vFile::asData);

=head1 NAME

Text::vCard::Addressbook - a package to parse, edit and create multiple vCards (RFC 2426) 

=head1 SYNOPSIS

  use Text::vCard::Addressbook;

  # To read an existing address book file:

  my $address_book = Text::vCard::Addressbook->new({ 
    'source_file'  => '/path/to/address_book.vcf', 
  });

  foreach my $vcard ( $address_book->vcards() ) {
      print "Got card for " . $vcard->fullname() . "\n";
  }

  # To create a new address book file:

  my $address_book = Text::vCard::Addressbook->new();
  my $vcard        = $address_book->add_vcard;
  $vcard->fullname('Foo Bar');
  $vcard->EMAIL('foo@bar.com');

  # note that you should NOT use ':encoding(UTF-8)' when writing to a file
  # because the result of $address_book->export is already utf-8 encoded.  See
  # the ENCODING AND UTF-8 for more information.
  open my $out, '>', 'new_address_book.vcf' or die;
  print $out $address_book->export;


=head1 DESCRIPTION

This package provides an API to reading / editing and creating multiple vCards.
A vCard is an electronic business card. This package has been developed based
on rfc2426.

You will find that many applications (Apple Address book, MS Outlook, Evolution
etc) can export and import vCards. 


=head1 ENCODING AND UTF-8

=head2 Constructor Arguments

The 'encoding_in' and 'encoding_out' constructor arguments allow you to read
and create vCard files with any encoding.  Examples of valid values are
'UTF-8', 'Latin1', and 'none'.  

Both values default to 'UTF-8' and this should just work for the vast majority
of people.  The latest vCard RFC 6350 only allows UTF-8 as an encoding so most
people should not need to use either of these constructor arguments.

=head2 MIME encodings

vCard RFC 6350 only allows UTF-8 but it still permits 8bit MIME encoding
schemes such as Quoted-Printable and Base64 which are supported by this module.

If you wish to use a Quoted-Printable value 'encoding_out' must have a value of
'UTF-8'.

=head2 Manually setting values on a Text::vCard or Text::vCard::Node object

If you manually set values on a Text::vCard or Text::vCard::Node object they
must be decoded.  The only exception to this rule is if you are messing around
with the 'encoding_out' constructor arg.

=head2 Exporting your address book

The export() method will by default return a UTF-8 encoded string.  This means
you should use something like this:

  open $fh, '>', '/path/to/new/address_book.vcf' or die;

and NOT something like this:

  open $fh, '>:encoding(UTF-8)', '/path/to/new/address_book.vcf' or die;

=head1 METHODS FOR LOADING VCARDS

=head2 load()

  my $address_book = Text::vCard::Addressbook->load( 
    [ 'foo.vCard', 'Addresses.vcf' ],  # list of files to load
  );

This method will croak if it is unable to read in any of the files.

=cut

sub load {
    my ( $proto, $files, $constructor_args ) = @_;

    my $self = __PACKAGE__->new($constructor_args);

    my %encoding = $self->_slurp_encoding;

    foreach my $file ( @{$files} ) {
        croak "Unable to read file $file" unless -r $file;
        $self->import_data( scalar read_file( $file, %encoding ) );
    }

    return $self;

}

=head2 import_data()

  $address_book->import_data($string);

This method imports data directly from a string.  $string is assumed to be
decoded.

=cut

sub import_data {
    my ( $self, $value ) = @_;

    $self->_process_text($value);
}

=head2 new()

  # Create a new (empty) address book
  my $address_book = Text::vCard::Addressbook->new();
  
  # Load vcards from a single file
  my $address_book = Text::vCard::Addressbook->new({ 
    source_file => '/path/to/address_book.vcf'
  });

  # Load vcards from a a string
  my $address_book = Text::vCard::Addressbook->new({ 
    source_text => $source_text
  });

This method will croak if it is unable to read the source_file.

The constructor accepts 'encoding_in' and 'encoding_out' attributes.  The
default values for both are 'UTF-8'.  You can set them to 'none' if
you don't want your output encoded with Encode::encode().  But be aware the
latest vcard RFC (RFC6350) mandates utf-8.

=cut

sub new {
    my ( $proto, $conf ) = @_;
    my $class = ref($proto) || $proto;
    my $self = {};

    bless( $self, $class );

    # create some where to store out individual vCard objects
    $self->{'cards'} = [];
    $self->{encoding_in}  = $conf->{encoding_in}  || 'UTF-8';
    $self->{encoding_out} = $conf->{encoding_out} || 'UTF-8';

    # slurp in file contents
    if ( defined $conf->{'source_file'} ) {

        croak "Unable to read file $conf->{'source_file'}\n"
            unless -r $conf->{'source_file'};

        $conf->{'source_text'}
            = read_file( $conf->{'source_file'}, $self->_slurp_encoding );
    }

    # Process the text if we have it.
    $self->_process_text( $conf->{'source_text'} )
        if defined $conf->{'source_text'};

    return $self;
}

=head1 OTHER METHODS

=head2 add_vcard()

  my $vcard = $address_book->add_vcard();

This method creates a new empty L<Text::vCard> object, stores it in the
address book and return it so you can add data to it.

=cut

sub add_vcard {
    my $self = shift;
    my $vcard = Text::vCard->new( { encoding_out => $self->{encoding_out} } );
    push( @{ $self->{cards} }, $vcard );
    return $vcard;
}

=head2 vcards()

  my $vcards = $address_book->vcards();
  my @vcards = $address_book->vcards();

This method returns a reference to an array or an array of
vcards in this address book. This could be an empty list
if there are no entries in the address book.

=cut

sub vcards {
    my $self = shift;
    return wantarray ? @{ $self->{cards} } : $self->{cards};
}

=head2 set_encoding()

DEPRECATED.  Use the 'encoding_in' and 'encoding_out' constructor arguments.

=cut

sub set_encoding {
    my ( $self, $coding ) = @_;
    $self->{'encoding'} |= '';
    $self->{'encoding'} = ";charset=$coding" if ( defined $coding );
    return $self->{'encoding'};
    die "DEPRECATED.  Use the 'encoding_in' and 'encoding_out'"
        . " constructor arguments";
}

=head2 export()

  my $string = $address_book->export()

This method returns the vcard data as a string in the vcf file format.  By
default the string returned is UTF-8 encoded.  See the ENCODING AND UTF-8
section for more information.

Please note there is no validation, you must ensure that the correct nodes
(FN,N,VERSION) are already added to each vcard if you want to comply with 
RFC 2426.

=cut

sub export {
    my $self = shift;
    my $string;
    $string .= $_->as_string for $self->vcards;
    return $string;
}

# PRIVATE METHODS

# PerlIO layers should look like ':encoding(UTF-8)'
# The ':encoding()' part does character set and encoding transformations.
# Without it you are just declaring the stream to be of a certain encoding.
# See PerlIO, PerlIO::encoding docs.
sub _slurp_encoding {
    my ($self) = @_;
    return () if $self->{encoding_in} eq 'none';
    return ( binmode => ':encoding(' . $self->{encoding_in} . ')' );
}

# Process a chunk of text, create Text::vCard objects and store in the address book
sub _pre_process_text {
    my ( $self, $text ) = @_;

    # As data may handle \r - must ask richard
    $text =~ s/\r//g;

    if ( $text =~ /quoted-printable/i ) {

      # Edge case for 2.1 version
      #
      # http://tools.ietf.org/html/rfc2045#section-6.7 point (5),
      # lines containing quoted-printable encoded data can contain soft-line
      # breaks. These are indicated as single '=' sign at the end of the line.
      #
      # No longer needed in version 3.0:
      # http://tools.ietf.org/html/rfc2426 point (5)

        my $joinline = 0;

        my $out;
        foreach my $line ( split( "\n", $text ) ) {
            chomp($line);

            if ($joinline) {
                if ( $line =~ /=$/ ) {
                    $line =~ s/=$//;
                    $out .= $line;
                } else {
                    $joinline = 0;
                    $out .= $line . "\n";
                }
                next;
            }

            # find continued QP lines - could be done better
            if ( $line =~ /ENCODING=QUOTED-PRINTABLE/i && $line =~ /=$/ ) {

                $joinline = 1;    # join lines...

                $line =~ s/=$//;
                $out .= $line;
            } else {

                # add regular line;
                $out .= $line . "\n";
            }
        }
        $text = $out;

    }

    # Add error checking here ?
    my $asData = Text::vFile::asData->new;
    $asData->preserve_params(1);

    # FIXME: whats up with the \n stuff???
    my @lines = split "\n", $text;
    return $asData->parse_lines(@lines)->{objects};

}

sub _process_text {
    my ( $self, $text ) = @_;

    my $cards = $self->_pre_process_text($text);

    foreach my $card (@$cards) {

        # Run through each card in the data
        if ( $card->{'type'} =~ /VCARD/i ) {
            my $vcard = Text::vCard->new(
                {   'asData_node' => $card->{'properties'},
                    encoding_in   => $self->{encoding_in},
                    encoding_out  => $self->{encoding_out}
                }
            );
            push( @{ $self->{'cards'} }, $vcard );
        } else {
            carp
                "This file contains $card->{'type'} data which was not parsed";
        }
    }

    return $self->{cards};
}

=head1 AUTHOR

Leo Lapworth, LLAP@cuckoo.org

=head1 COPYRIGHT

Copyright (c) 2003 Leo Lapworth. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

The authors of L<Text::vFile::asData> for making my life so much easier.

=head1 SEE ALSO

L<Text::vCard>, L<Text::vCard::Node>

=cut

1;
