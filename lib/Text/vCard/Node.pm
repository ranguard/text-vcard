package Text::vCard::Node;

use strict;
use warnings;
use Carp;
use Encode;
use MIME::Base64;
use MIME::QuotedPrint;
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
                    for my $p (split /\s*,\s*/, $param_list) {
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

            if ( defined $self->{params}->{'quoted-printable'} ) {
                $conf->{'data'}->{'value'}
                    = MIME::QuotedPrint::decode($conf->{data}{value});
            }

            # do this first
            if (defined $self->{params}{base64}) {
                $conf->{data}{value}
                    = MIME::Base64::decode($conf->{data}{value});
                # mimic what goes on below
                @{$self}{@{$self->{field_order}}} = ($conf->{data}{value});
            }
            else {
                # the -1 on split is so ;; values create elements in
                # the array
                my @elements = split /(?<!\\);/, $conf->{data}{value}, -1;
                if (defined $self->{node_type}
                        && $self->{node_type} eq 'ORG') {
                    # cover ORG where unit is a list
                    $self->{'name'} = shift(@elements);
                    $self->{'unit'} = \@elements if scalar(@elements) > 0;
                }
                # no need for explicit scalar
                elsif (@elements <= @{$self->{field_order}}) {
                    # set the field values as the data
                    # e.g. $self->{street} = 'The street'
                    @{$self}{@{$self->{field_order}}} = @elements;
                }
                else {
                    carp sprintf(
                        'Data value had %d elements expecting %d or less.',
                        scalar @elements, scalar @{$self->{field_order}});
                }
            }
        }
    }
    return $self;
}

=head2 node_type

Returns the type of the node itself, e.g. ADR.

=cut

sub node_type {
    $_[0]->{node_type};
}

=head2 unit()

  my @units = @{$org_node->unit()};
  $org_node->unit(['Division','Department','Sub-department']);

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
	or
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
    @types = keys %{ $self->{params} };
    return wantarray ? @types : \@types;
}

=head2 is_type()

  if($node->is_type($type) {
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
        return $self->{params}{lc $type} || 1;
    }
    return undef;
}

=head2 is_pref();

  if($node->is_pref()) {
  	print "Prefered node"
  }

This method is the same as is_type (which can take a value of 'pref')
but it specific to if it is the prefered node. This method is used
to sort when returning lists of nodes.

=cut 

sub is_pref {
    my $self = shift;
    if ( defined $self->{params} && defined $self->{params}->{'pref'} ) {
        return 1;
    }
    return undef;
}

=head2 add_types()

 $address->add_types('home');
 
 my @types = qw(home work);
 $address->add_types(\@types);

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
 $address->remove_types(\@types);

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

  my $value = $node->export_data();

This method returns the value string of a node.
It is only needs to be called when exporting the information 
back out to ensure that it has not been altered.

=cut

sub export_data {
    my $self  = shift;
    my @lines = map {
        if ( defined $self->{$_} )
        {
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

=cut

sub _key_as_string {
    my ($self, $charset) = @_;
    my %t;
    for my $t ($self->types) {
        my $backwards = uc $self->is_type($t);
        $t{$backwards} ||= [];
        push @{$t{$backwards}}, uc $t;
    }

    # override charset
    $t{CHARSET} = [$charset] if $charset;
    # you know it would probably make sense to do some Encode stuff,
    # plus qp/base64 logic here.
    my $n = $self->group ?
        sprintf('%s.%s', $self->group, $self->node_type) : $self->node_type;
    return join ';', $n,
        map { sprintf('%s=%s', $_, join ',', @{$t{$_}}) } sort keys %t;
}


sub _escape {
    my $val = shift;
    # cover all the bases
    my %esc = ("\x0a" => 'n', "\x0d" => 'n', "\x0d\x0a" => 'n');
    $val =~ s/([\\;,]|\x0d?\x0a|\x0d)/sprintf("\\%s", $esc{$1}||$1)/ge;
    $val;
}

sub _value_as_string {
    my ($self, $charset, $key) = @_;
    $charset ||= 'utf-8';
    my @fields;
    for my $f (@{$self->{field_order}}) {
        next unless defined (my $v = $self->{$f});
        my $data = '';
        if (ref $v eq 'ARRAY') {
            $data = join ',', map { _escape(Encode::encode($charset, $_)) } @$v;
        }
        elsif ($self->is_type('quoted-printable')) {
            # have to reimplement the m:qp line wrap >:|
            my $enc = MIME::QuotedPrint::encode
                (Encode::encode($charset, $v), '');

            # 74 because minus initial space and terminal =
            my @lines;
            my $step = 74 - length $key; # 75 - key + :
            my ($i, $len) = (0, length $enc);
            while ($i <= $len) {
                # special case if step is initially negative, i.e. if
                # the key is longer than 76 chars
                if ($step < 0) {
                    $step = 74;
                    $data = "=\x0d\x0a ";
                }

                my $line = substr($enc, $i, $step);
                my ($a, $b) = ($line =~ /(.*?)(=[0-9A-Fa-f]?)$/);
                $line = $a if defined $a;
                push @lines, $line if length $line;

                # this says increase the step minus a partial escaped
                # character
                $i += $step - length($b || 0);
                # from now own, step is 74
                $step = 74;
            }
            $data .= join "=\x0d\x0a ", @lines;
        }
        elsif ($self->is_type('base64')) {
            # also this. it would be nice to be able to set the width
            # in a parameter.
            my $enc = MIME::Base64::encode($v, '');
            my @lines = '';
            for (my $i = 0; $i <= length $enc; $i += 72) {
                push @lines, ' ' . substr($enc, $i, 72);
            }
            $data = join "\x0d\x0a", @lines;
        }
        else {
            $data = _escape(Encode::encode($charset, $v));
        }
        push @fields, $data;
    }

    join ';', @fields;
}

sub _fold {
    my $str = shift;
    # already folded
    return $str if $str =~ /\x0d?\x0a/;

    my @lines;
    my ($i, $len, $step) = (0, length $str, 76);
    while ($i <= $len) {
        my $line = substr($str, $i, $step);
        push @lines, $line;

        # increment the position
        $i += $step;
        # step is 75 from now on
        $step = 75;
    }
    join "\x0d\x0a ", @lines;
}

sub as_string {
    my ($self, $charset) = @_;
    my $key = $self->_key_as_string($charset);
    my $val = $self->_value_as_string($charset, $key);
    return _fold("$key:$val");
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

