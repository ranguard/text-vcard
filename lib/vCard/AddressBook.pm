package vCard::AddressBook;
use Moo;
use vCard;
use Path::Class;
use Carp;
use Text::vCard;

=head1 SYNOPSIS

    use vCard::AddressBook;

    # create the object
    my $address_book = vCard::AddressBook->new();

    $address_book->load_file('/path/file.vcf');
    $address_book->load_string($string);

    my $vcard = $adress_book->add_vcard; # returns a vCard object
    $vcard->fullname('Bruce Banner, PhD');
    $vcard->email_addresses([
        { type => 'work', address => 'bbanner@ssh.secret.army.mil' },
        { type => 'home', address => 'bbanner@timewarner.com'      },
    ]);

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

has vcards => ( is => 'rw', default => sub { [] } );

sub add_vcard {
    my ($self) = @_;
    my $vcard = vCard->new;
    push @{ $self->vcards }, $vcard;
    return $vcard;
}

sub load_file {
    my ( $self, $filename ) = @_;

    my $file = ref $filename eq 'Path::Class::File'    #
        ? $filename
        : file($filename);

    $self->load_string( scalar $file->slurp );

    return $self;
}

sub load_string {
    my ( $self, $string ) = @_;
    $self->_create_vcards($string);
    return $self;
}

sub _create_vcards {
    my ( $self, $string ) = @_;

    my $cards = $self->_parse_string($string);

    foreach my $card (@$cards) {
        carp "This file contains $card->{'type'} data which was not parsed"
            unless $card->{'type'} =~ /VCARD/i;

        my $vcard      = vCard->new;
        my $text_vcard = Text::vCard    #
            ->new( { 'asData_node' => $card->{'properties'} } );

        $self->_copy_simple_nodes( $text_vcard => $vcard );
        $self->_copy_phones( $text_vcard => $vcard );
        $self->_copy_addresses( $text_vcard => $vcard );
        $self->_copy_email_addresses( $text_vcard => $vcard );

        push @{ $self->vcards }, $vcard;
    }
}

sub _parse_string {
    my ( $self, $string ) = @_;

    my @lines = split /\n/, $string;

    my $asData = Text::vFile::asData->new;
    $asData->preserve_params(1);

    return $asData->parse_lines(@lines)->{'objects'};
}

sub _copy_simple_nodes {
    my ( $self, $text_vcard, $vcard ) = @_;

    foreach my $node_type ( vCard->_simple_node_types ) {
        next unless $text_vcard->$node_type;
        $vcard->$node_type( $text_vcard->$node_type );
    }
}

sub _copy_phones {
    my ( $self, $text_vcard, $vcard ) = @_;

    my @phones;
    my $nodes = $text_vcard->get('tel') || [];

    foreach my $node (@$nodes) {
        my $phone;
        $phone->{type}       = $node->types()->[0];      # FIXME
        $phone->{preference} = $node->is_pref ? 1 : 0;
        $phone->{number}     = $node->value;
        push @phones, $phone;
    }

    $vcard->phones( \@phones );
}

sub _copy_addresses {
    my ( $self, $text_vcard, $vcard ) = @_;

    my @addresses;
    my $nodes = $text_vcard->get('adr') || [];

    foreach my $node (@$nodes) {
        my $address;
        $address->{type}       = $node->types()->[0];         # FIXME
        $address->{preference} = $node->is_pref ? 1 : 0;
        $address->{po_box}     = $node->po_box || undef;
        $address->{street}     = $node->street || undef;
        $address->{city}       = $node->city || undef;
        $address->{post_code}  = $node->post_code || undef;
        $address->{region}     = $node->region || undef;
        $address->{country}    = $node->country || undef;
        $address->{extended}   = $node->extended || undef;
        push @addresses, $address;
    }

    $vcard->addresses( \@addresses );
}

sub _copy_email_addresses {
    my ( $self, $text_vcard, $vcard ) = @_;

    my @email_addresses;
    my $nodes = $text_vcard->get('email') || [];

    foreach my $node (@$nodes) {
        my $email_address;
        $email_address->{type}       = $node->types()->[0];      # FIXME
        $email_address->{preference} = $node->is_pref ? 1 : 0;
        $email_address->{address}    = $node->value;
        push @email_addresses, $email_address;
    }

    $vcard->email_addresses( \@email_addresses );
}

1;
