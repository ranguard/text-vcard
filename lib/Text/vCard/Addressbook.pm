package Text::vCard::Addressbook;

use Carp;
use strict;
use warnings;
use Path::Tiny;
use Text::vFile::asData;
use Text::vCard;

# See this module for your basic parser functions
use base qw(Text::vFile::asData);

=head1 NAME

Text::vCard::Addressbook - a package to parse, edit and create multiple vCards (RFC 2426) 

=head1 WARNING

L<vCard::AddressBook> is built on top of this module and provides a more
intuitive user interface.  Please try that module first.

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

  open my $out, '>:encoding(UTF-8)', 'new_address_book.vcf' or die;
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
and write vCard files with any encoding.  Examples of valid values are
'UTF-8', 'Latin1', and 'none'.  

Both values default to 'UTF-8' and this should just work for the vast majority
of people.  The latest vCard RFC 6350 only allows UTF-8 as an encoding so most
people should not need to use either of these constructor arguments.

=head2 MIME encodings

vCard RFC 6350 only allows UTF-8 but it still permits 8bit MIME encoding
schemes such as Quoted-Printable and Base64 which are supported by this module.

=head2 Manually setting values on a Text::vCard or Text::vCard::Node object

If you manually set values on a Text::vCard or Text::vCard::Node object they
must be decoded values.  The only exception to this rule is if you are messing
around with the 'encoding_out' constructor arg.


=head1 METHODS FOR LOADING VCARDS

=head2 load()

  my $address_book = Text::vCard::Addressbook->load( 
    [ 'foo.vCard', 'Addresses.vcf' ],  # list of files to load
  );

This method will croak if it is unable to read in any of the files.

=cut

sub load {
    my ( $proto, $filenames, $constructor_args ) = @_;

    my $self = __PACKAGE__->new($constructor_args);

    foreach my $filename ( @{$filenames} ) {

        croak "Unable to read file $filename" unless -r $filename;

        my $file   = $self->_path($filename);
        my $string = $file->slurp( $self->_iomode_in );

        die <<EOS
ERROR: Either there is no END in this vCard or there is a problem with the line
endings.  Note that the vCard RFC requires line endings delimited by \\r\\n
regardless of your operating system.  Windows :crlf mode will strip out the \\r
so don't use that.
EOS
            unless $string =~ m/\r\n/m;

        $self->import_data($string);
    }

    return $self;

}

=head2 import_data()

  $address_book->import_data($string);

This method imports data directly from a string.  $string is assumed to be
decoded (but not MIME decoded).

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
latest vCard RFC 6350 mandates UTF-8.

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

        my $filename = $conf->{source_file};
        my $file     = $self->_path($filename);
        $conf->{source_text} = $file->slurp( $self->_iomode_in );
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

This method returns the vcard data as a string in the vcf file format.  

Please note there is no validation, you must ensure that the correct nodes
(FN,N,VERSION) are already added to each vcard if you want to comply with 
RFC 2426.

=cut

sub export {
    my $self   = shift;
    my $string = '';
    $string .= $_->as_string for $self->vcards;
    return $string;
}

# PRIVATE METHODS

# PerlIO layers should look like ':encoding(UTF-8)'
# The ':encoding()' part does character set and encoding transformations.
# Without it you are just declaring the stream to be of a certain encoding.
# See PerlIO, PerlIO::encoding docs.
sub _iomode_in {
    my ($self) = @_;
    return { binmode => ':raw' } if $self->{encoding_in} eq 'none';
    return { binmode => ':raw:encoding(' . $self->{encoding_in} . ')' };
}

# Filename can be a string, a Path::Tiny obj, or a Path::Class obj.
# Returns a Path::Tiny obj.
sub _path {
    my ( $self, $filename ) = @_;
    return ref $filename eq 'Path::Class::File'    #
        ? path("$filename")
        : path($filename);    # works for strings and Path::Tiny objects
}

# Process a chunk of text, create Text::vCard objects and store in the address book
sub _pre_process_text {
    my ( $self, $text ) = @_;

    if ( $text =~ /quoted-printable/i ) {

        # Edge case for 2.1 version
        #
        # http://tools.ietf.org/html/rfc2045#section-6.7 point (5),
        # lines containing quoted-printable encoded data can contain soft line
        # breaks. These are indicated as single '=' sign at the end of the
        # line.
        #
        # No longer needed in version 3.0:
        # http://tools.ietf.org/html/rfc2426 point (5)
        #
        # 'perldoc perlport' says using \r\n is wrong and confusing for a few
        # reasons but mainly because the value of \n is different on different
        # operating systems.  It recommends \x0D\x0A instead.

        my $out;
        my $inside = 0;
        foreach my $line ( split( "\x0D\x0A", $text ) ) {

            if ($inside) {
                if ( $line =~ /=$/ ) {
                    $line =~ s/=$//;
                } else {
                    $inside = 0;
                }
            }

            if ( $line =~ /ENCODING=QUOTED-PRINTABLE/i ) {
                $inside = 1;
                $line =~ s/=$//;
            }
            $out .= $line . "\x0D\x0A";
        }
        $text = $out;

    }

    # Add error checking here ?
    my $asData = Text::vFile::asData->new;
    $asData->preserve_params(1);

    my @lines = split "\x0D\x0A", $text;
    my @lines_with_newlines = map { $_ . "\x0D\x0A" } @lines;
    return $asData->parse_lines(@lines_with_newlines)->{objects};
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
Eric Johnson (kablamo), github ~!at!~ iijo dot org

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
