package Text::vCard::Node;

use strict;
use warnings;
use Carp;
use Encode;
use MIME::Base64 3.07;
use MIME::QuotedPrint 3.07;
use Unicode::LineBreak;
use Text::Wrap;
use vars qw ( $AUTOLOAD );

=head1 NAME

Text::vCard::Node - Object for each node (line) of a vCard

=head1 SYNOPSIS

  use Text::vCard::Node;

  my %data = (
    'param' => {
      'HOME,PREF' => 'undef',
    },
    'value' => ';;First work address - street;Work city;London;Work PostCode;CountryName',
  );

  my $node = Text::vCard::Node->new({
    node_type => 'address', # Auto upper cased
    fields => ['po_box','extended','street','city','region','post_code','country'],
    data => \%data,
  });

=head1 DESCRIPTION

Package used by Text::vCard so that each element: ADR, N, TEL etc are objects.

You should not need to use this module directly, L<Text::vCard> does it all for you.

=head1 METHODS

=head2 new()

  my $node = Text::vCard::Node->new({
    node_type => 'address', # Auto upper cased
    fields => \['po_box','extended','street','city','region','post_code','country'],
    data => \%data,
  });

=head2 value()

  # Get the value for a standard single value node 
  my $value = $node->value();

  # Or set the value
  $node->value('New value');
  
=head2 other()'s

  # The fields supplied in the conf area also methods.  
  my $po_box = $node->po_box(); # if the node was an ADR.
  
  # Set the value.
  my $street = $node->street('73 Sesame Street');

=cut

sub new {
    my ( $proto, $conf ) = @_;
    my $class = ref($proto) || $proto;
    my $self = {};
    carp "No fields defined" unless defined $conf->{'fields'};
    carp "fields is not an array ref"
        unless ref( $conf->{'fields'} ) eq 'ARRAY';

    bless( $self, $class );

    $self->{encoding_out} = $conf->{encoding_out} || 'UTF-8';

    $self->{node_type} = uc( $conf->{node_type} )
        if defined $conf->{node_type};
    $self->group( $conf->{group} ) if defined $conf->{group};

    # Store the field order.
    $self->{'field_order'} = $conf->{'fields'};

    # store the actual field names so we can look them up
    my %fields;
    map { $fields{$_} = 1 } @{ $self->{'field_order'} };
    $self->{'field_lookup'} = \%fields;

    if ( defined $conf->{'data'} ) {

        # Populate now, rather than later (via AUTOLOAD)
        # store values into object
        if ( defined $conf->{'data'}->{'params'} ) {
            my %params;

            # Loop through array
            foreach my $param_hash ( @{ $conf->{'data'}->{'params'} } ) {
                while ( my ( $key, $value ) = each %{$param_hash} ) {
                    my $t = 'type';

                    # go through each key/value pair
                    my $param_list = $key;
                    if ( defined $value ) {
                        $t = $key;

                        # use value, not key as its 'type' => 'CELL',
                        # not 'CELL' => undef
                        $param_list = $value;
                    }

                    # These values might as well be useful for
                    # something. Also get rid of any whitespace
                    # pollution.
                    for my $p ( split /\s*,\s*/, $param_list ) {
                        $p =~ s/^\s*(.*?)\s*$/\L$1/;
                        $p =~ s/\s+/ /g;
                        $params{$p} = lc $t;
                    }
                }
            }
            $self->{params} = \%params;
        }

        if ( defined $conf->{'data'}->{'value'} ) {

            # Store the actual data into the object

            if ( $self->is_type('q') or $self->is_type('quoted-printable') ) {

                my $value          = $conf->{data}{value};
                my $mime_decoded   = MIME::QuotedPrint::decode($value);
                my $encode_decoded = Encode::decode( 'UTF-8', $mime_decoded );
                my $unescaped      = $self->_unescape($encode_decoded);
                $conf->{'data'}->{'value'} = $unescaped;
            }

            if ( $self->is_type('b') or $self->is_type('base64') ) {

                # Don't Encode::decode() $mime_decoded because it is usually
                # (99% of the time) a binary value like a photo and not a
                # string.
                #
                # Also do not escape binary values.

                my $value        = $conf->{data}{value};
                my $mime_decoded = MIME::Base64::decode($value);
                $conf->{data}{value} = $mime_decoded;

                # mimic what goes on below
                @{$self}{ @{ $self->{field_order} } }
                    = ( $conf->{data}{value} );
            } else {

                # the -1 on split is so ;; values create elements in
                # the array
                my @elements = split /(?<!\\);/, $conf->{data}{value}, -1;
                if ( defined $self->{node_type}
                    && $self->{node_type} eq 'ORG' )
                {
                    my @unescaped = $self->_unescape_list(@elements);

                    $self->{'name'} = shift(@unescaped);
                    $self->{'unit'} = \@unescaped if scalar(@unescaped) > 0;
                }

                # no need for explicit scalar
                elsif ( @elements <= @{ $self->{field_order} } ) {
                    my @unescaped = $self->_unescape_list(@elements);

                    # set the field values as the data
                    # e.g. $self->{street} = 'The street'
                    @{$self}{ @{ $self->{field_order} } } = @unescaped;
                } else {
                    carp sprintf(
                        'Data value had %d elements expecting %d or less.',
                        scalar @elements,
                        scalar @{ $self->{field_order} }
                    );
                }
            }
        }
    }
    return $self;
}

sub _unescape {
    my ( $self, $value ) = @_;
    $value =~ s|\\([\\,;])|$1|g;
    return $value;
}

sub _unescape_list {
    my ( $self, @values ) = @_;
    return map { $self->_unescape($_) } @values;
}

=head2 node_type

Returns the type of the node itself, e.g. ADR.

=cut

sub node_type {
    $_[0]->{node_type};
}

=head2 unit()

  my @units = @{ $org_node->unit() };
  $org_node->unit( [ 'Division', 'Department', 'Sub-department' ] );

As ORG allows unlimited numbers of 'units' as well as and organisation
'name', this method is a specific case for accessing those values, they
are always returned as an array reference, and should always be set
as an array reference. 

=cut

sub unit {
    my ( $self, $val ) = @_;
    $self->{'unit'} = $val if $val && ref($val) eq 'ARRAY';
    return $self->{'unit'} if defined $self->{'unit'};
    return undef;
}

=head2 types()

  my @types = $node->types();

  # or
  my $types = $node->types();

This method will return an array or an array ref depending
on the calling context of types associated with the $node,
undef is returned if there are no types.

All types returned are lower case.

=cut 

sub types {
    my $self = shift;
    my @types;
    return undef unless defined $self->{params};
    foreach my $key ( sort keys %{ $self->{params} } ) {
        my $value = $self->{params}->{$key};
        push @types, lc $key if $value && $value eq 'type';
    }
    return wantarray ? @types : \@types;
}

=head2 is_type()

  if ( $node->is_type($type) ) {

      # ...
  }

Given a type (see types() for a list of those set)
this method returns 1 if the $node is of that type
or undef if it is not.

=cut 

sub is_type {
    my ( $self, $type ) = @_;
    if ( defined $self->{params} && exists $self->{params}->{ lc($type) } ) {

        # Make this always return true so as not to change the net
        # behaviour of the method. if for some wack (and
        # non-compliant) reason this value is undef, empty string or
        # zero, tough luck.
        return $self->{params}{ lc $type } || 1;
    }
    return undef;
}

=head2 is_pref();

  if ( $node->is_pref() ) {
      print "Preferred node";
  }

This method is the same as is_type (which can take a value of 'pref')
but it specific to if it is the preferred node. This method is used
to sort when returning lists of nodes.

=cut 

# A preferred node can be indicated in a vcard file 2 ways:
#
# 1. As 'PREF=1' which makes $self->{params} look like:
#   { 1 => 'pref', work => 'type' }
#
# 2. As 'TYPE=PREF' which makes $self->{params} look like:
#   { pref => 'type', work => 'type' }
#
sub is_pref {
    my $self   = shift;
    my $params = $self->{params};
    if (( defined $params ) &&    #
        ( defined $params->{1} && $params->{1} eq 'pref' ) ||    #
        ( defined $params->{pref} )
        )
    {
        return 1;
    }
    return undef;
}

=head2 add_types()

  $address->add_types('home');

  my @types = qw(home work);
  $address->add_types( \@types );

Add a type to an address, it can take a scalar or an array ref.

=cut

sub add_types {
    my ( $self, $type ) = @_;
    unless ( defined $self->{params} ) {

        # no params, create a hash ref in there
        my %params;
        $self->{params} = \%params;
    }
    if ( ref($type) eq 'ARRAY' ) {
        map { $self->{params}->{ lc($_) } = 1 } @{$type};
    } else {
        $self->{params}->{ lc($type) } = 1;
    }
}

=head2 remove_types()

  $address->remove_types('home');

  my @types = qw(home work);
  $address->remove_types( \@types );

This method removes a type from an address, it can take a scalar 
or an array ref.

undef is returned when in scalar context and the type does not match,
or when in array ref context and none of the types match, true is
returned otherwise.

=cut

sub remove_types {
    my ( $self, $type ) = @_;
    return undef unless defined $self->{params};

    if ( ref($type) eq 'ARRAY' ) {
        my $to_return = undef;
        foreach my $t ( @{$type} ) {
            if ( exists $self->{params}->{ lc($t) } ) {
                delete $self->{params}->{ lc($t) };
                $to_return = 1;
            }
        }
        return $to_return;
    } else {
        if ( exists $self->{params}->{ lc($type) } ) {
            delete $self->{params}->{ lc($type) };
            return 1;
        }
    }
    return undef;
}

=head2 group()

  my $group = $node->group();

If called without any arguments, this method returns the group 
name if a node belongs to a group. Otherwise undef is returned.

If an argument is supplied then this is set as the group name.

All group names are always lowercased.

For example, Apple Address book used 'itemN' to group it's
custom X-AB... nodes with a TEL or ADR node.

=cut

sub group {
    my $self = shift;
    if ( my $val = shift ) {
        $self->{group} = lc($val);
    }
    return $self->{group} if defined $self->{group};
    return undef;
}

=head2 export_data()

NOTE: This method is deprecated and should not be used

  my $value = $node->export_data();

This method returns the value string of a node.
It is only needs to be called when exporting the information 
back out to ensure that it has not been altered.

=cut

sub export_data {
    my $self  = shift;
    my @lines = map {
        if ( defined $self->{$_} ) {
            if ( ref( $self->{$_} ) eq 'ARRAY' ) {

                # Handle things like org etc which have 'units'
                join( ',', @{ $self->{$_} } );
            } else {
                $self->{$_};
            }
        } else {
            '';
        }
    } @{ $self->{'field_order'} };

    # Should escape stuff here really, but waiting to see what
    # T::vfile::asData does
    return join( ';', @lines );

}

=head2 as_string

Returns the node as a formatted string.

=cut

sub _key_as_string {
    my ($self) = @_;

    my $n = '';
    $n .= $self->group . '.' if $self->group;
    $n .= $self->node_type;
    $n .= $self->_params     if $self->_params;

    return $n;
}

# returns a string of params formatted for saving to a vcard file
# returns false if there are no params
sub _params {
    my ($self) = @_;

    my %t;
    for my $t ( sort keys %{ $self->{params} } ) {
        my $backwards = uc $self->is_type( lc $t );
        $t{$backwards} ||= [];
        push @{ $t{$backwards} }, lc $t;
    }

    $t{CHARSET} = [ lc $self->{encoding_out} ]
        if $self->{encoding_out} ne 'none'
        && $self->{encoding_out} ne 'UTF-8'
        && !$self->is_type('b')
        && !$self->is_type('base64');

    my @params = map { sprintf( '%s=%s', $_, join ',', @{ $t{$_} } ) }    #
        sort keys %t;

    return @params ? ';' . join( ';', @params ) : undef;
}

# The vCard RFC requires commas, semicolons, and backslashes to be escaped.
# See http://tools.ietf.org/search/rfc6350#section-3.4
#
# Line breaks which are part of a value and are intended to be seen by humans
# must have a value of '\n'.
# See http://tools.ietf.org/search/rfc6350#section-4.1
#
# Line breaks which happen because the RFC requires a line break after 75
# characters have a value of '\r\n'.  These line breaks are not handled by
# this method.  See _newline() and
# http://tools.ietf.org/search/rfc6350#section-3.2
#
# Don't escape anything if this is a base64 node.  Escaping only applies to
# strings not binary values.
sub _escape {
    my ( $self, $val ) = @_;
    return $val if ( $self->is_type('b') or $self->is_type('base64') );
    $val =~ s/(\r\n|\r|\n)/\n/g;
    $val =~ s/([,;|])/\\$1/g;
    return $val;
}

sub _escape_list {
    my ( $self, @list ) = @_;
    return map { $self->_escape($_) } @list;
}

# The vCard RFC says new lines must be \r\n
# See http://tools.ietf.org/search/rfc6350#section-3.2
sub _newline {
    my ($self) = @_;
    return "\r\n" if $self->{encoding_out} eq 'none';
    return Encode::encode( $self->{encoding_out}, "\r\n" );
}

sub _encode_string {
    my ( $self, $string ) = @_;
    return $string if $self->{encoding_out} eq 'none';
    return Encode::encode( $self->{encoding_out}, $string );
}

sub _encode_list {
    my ( $self, @list ) = @_;
    return @list if $self->{encoding_out} eq 'none';
    return map { $self->_encode_string($_) } @list;
}

# The vCard RFC says lines should be wrapped (or 'folded') at 75 octets
# excluding the line break.  The line is continued on the next line with a
# space as the first character. See
# http://tools.ietf.org/search/rfc6350#section-3.1 for details.
#
# Note than an octet is 1 byte (8 bits) and is not necessarily equal to 1
# character, 1 grapheme, 1 codepoint, or 1 column of output.  Actually none of
# those things are necessarily equal.  See
# http://www.perl.com/pub/2012/05/perlunicook-string-length-in-graphemes.html
#
# MIME::QuotedPrint does line wrapping but it assumes the line length must be
# <= 76 chars which doesn't work for us.
#
# Can't use Unicode::LineBreak because it wraps by counting characters and the
# vCard spec wants us to wrap by counting octets.
sub _wrap {
    my ( $self, $key, $value ) = @_;

    #PHOTO;ENCODING=b;TYPE=x-evolution-unknown:R0lGODlhlgAyALMPAAAAAP9BAP////9
    return $self->_wrap_naively( $key, $value )
        unless $self->{encoding_out} eq 'UTF-8';

    if ( $self->is_type('q') or $self->is_type('quoted-printable') ) {
        ## See the Quoted-Printable RFC205
        ## https://tools.ietf.org/html/rfc2045#section-6.7 (rule 5)
        my $newline
            = $self->_encode_string("=")
            . $self->_newline
            . $self->_encode_string(" ");
        my $max
            = 73; # 75 octets per line max including '=' and ' ' from $newline
        return $self->_wrap_utf8( $key, $value, $max, $newline );
    }

    my $newline = $self->_newline . $self->_encode_string(" ");
    my $max = 74;    # 75 octets per line max including " " from $newline
    return $self->_wrap_utf8( $key, $value, $max, $newline );
}

sub _wrap_utf8 {
    my ( $self, $key, $value, $max, $newline ) = @_;

    my $gcs = Unicode::GCString->new( $key . $value );
    return $key . $value if $gcs->length <= $max;

    my $start = 0;
    my @wrapped_lines;

    # first line is 1 character longer than the others because it doesn't
    # begin with a " "
    my $first_max = $max + 1;

    #use v5.10.1;
    #say "length: " . $gcs->length;

    while ( $start <= $gcs->length ) {
        my $len = 1;

        #say $start;

        while ( ( $start + $len ) <= $gcs->length ) {

            my $line = $gcs->substr( $start, $len );
            my $bytes = bytes::length( $line->as_string );

            #say "len: $len    bytes: " . $bytes;

            # is this a good place to line wrap?
            if ( $first_max && $bytes <= $first_max ) {
                ## no its not a good place to line wrap
                ## this if statement is only hit on the first line wrap
                $len++;
                next;
            }
            if ( $bytes <= $max ) {
                ## no its not a good place to line wrap
                $len++;
                next;
            }

            # wrap the line here
            $line = $gcs->substr( $start, $len - 1 )->as_string;
            push @wrapped_lines, $line;
            $start += $len - 1;
            last;
        }

        if ( ( $start + $len - 1 ) >= $gcs->length ) {
            my $line = $gcs->substr( $start, $len - 1 )->as_string;
            push @wrapped_lines, $line;
            last;
        }

        #say ">> start: $start,  len: $len,  length: " . $gcs->length;
        $first_max = undef;
    }

    return join $newline, @wrapped_lines;
}

# BUG: This will fail to line wrap properly for wide characters.  The problem
# is it naively wraps lines by counting the number of characters but the vcard
# spec wants us to wrap after 75 octets (bytes).  However clever vCard readers
# may be able to deal with this.
sub _wrap_naively {
    my ( $self, $key, $value ) = @_;

    $Text::Wrap::columns   = 75;                 # wrap after 75 chars
    $Text::Wrap::break     = qr/[.]/;            # allow lines breaks anywhere
    $Text::Wrap::separator = $self->_newline;    # use encoded new lines

    my $first_prefix = $key;    # this text is placed before first line
    my $prefix       = " ";     # this text is placed before all other lines
    return Text::Wrap::wrap( $first_prefix, $prefix, $value );
}

sub _mime_encode {
    my ( $self, $value ) = @_;

    if ( $self->is_type('q') or $self->is_type('quoted-printable') ) {

        # Encode with Encode::encode()
        my $encoded_value = $self->_encode_string($value);
        return MIME::QuotedPrint::encode( $encoded_value, '' );

    } elsif ( $self->is_type('b') or $self->is_type('base64') ) {

        # Scenarios where MIME::Base64::encode() works:
        #  - for binary data (photo) -- 99% of cases
        #  - if $value is a string with wide characters and the user has
        #    encoded it as UTF-8.
        #  - if $value is a string with no wide characters
        #
        # Scenario where MIME::Base64::encode() will die:
        #  - if $value is a string with wide characters and the user has not
        #    encoded it as UTF-8.
        return MIME::Base64::encode( $value, '' );

    } else {
        $value = $self->_encode_string($value);
    }

    return $value;
}

# This method does the following:
# 1. Escape and concatenate values
# 2. Encode::encode() values
# 3. MIME encode() values
# 4. wrap lines to 75 octets
#
# assumes there is only ever one MIME::Quoted-Printable field.
# assumes there is only ever one MIME::Base64 field.
#
# If either of the above assumptions is false, line wrapping may be incorrect.
# However clever vCard readers may still be able to read vCards with incorrect
# line wrapping.
sub as_string {
    my ($self) = @_;
    my $key = $self->_key_as_string();

    # Build up $raw_value from field values
    my @field_values;
    my $field_names = $self->{field_order};
    foreach my $field_name (@$field_names) {
        next unless defined( my $field_value = $self->{$field_name} );

        # escape stuff
        $field_value = ref $field_value eq 'ARRAY'    #
            ? join( ';', $self->_escape_list(@$field_value) )
            : $self->_escape($field_value);

        push @field_values, $field_value;
    }
    my $raw_value = join ';', @field_values;

    # MIME::*::encode() value
    my $value = $self->_mime_encode($raw_value);

    # Line wrap everything to 75 octets
    return $self->_wrap( $key . ":", $value );
}

# Because we have autoload
sub DESTROY {
}

# creates methods for a node object based on the field_names in the config
# hash of the node.

sub AUTOLOAD {
    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    carp "$name method which is not valid for this node"
        unless defined $_[0]->{field_lookup}->{$name};

    if ( $_[1] ) {

        # set it
        $_[0]->{$name} = $_[1];
    }

    # Return it
    return $_[0]->{$name};
}

=head2 NOTES

If a node has a param of 'quoted-printable' then the
value is escaped (basically converting Hex return into \r\n
as far as I can see).

=head2 EXPORT

None by default.

=head1 AUTHOR

Leo Lapworth, LLAP@cuckoo.org

=head1 SEE ALSO

L<Text::vCard> L<Text::vCard::Addressbook>

=cut

1;

