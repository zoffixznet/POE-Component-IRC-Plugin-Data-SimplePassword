package POE::Component::IRC::Plugin::Data::SimplePassword;

use warnings;
use strict;

our $VERSION = '0.0102';

use base 'POE::Component::IRC::Plugin::BasePoCoWrap';
use POE::Component::Data::SimplePassword;

sub _make_default_args {
    return (
        chars            => [ grep /[[:graph:]]/, map chr, 0..127 ],
        default_length   => 10,
        response_event   => 'irc_data_pass',
        trigger          => qr/^pass\s*/i,
    );
}

sub _make_poco {
    return POE::Component::Data::SimplePassword->spawn(
        debug => shift->{debug},
    );
}

sub _make_response_message {
    my $self   = shift;
    my $in_ref = shift;

    my $prefix = '';
    if ( $in_ref->{_type} eq 'public' ) {
        $prefix = (split /!/, $in_ref->{_who})[0] . ', ';
    }
    return "${prefix}$in_ref->{out}";
}

sub _make_poco_call {
    my $self = shift;
    my $data_ref = shift;

    my $length = delete $data_ref->{what};
    $length =~ tr/0-9//cd;

    length $length or $length = $self->{default_length};
    $length > 300 and $length = 300;
    $length < 1   and $length = 1;

    $self->{poco}->make_password( {
            event       => '_poco_done',
            chars       => $self->{chars},
            length      => $length,
            map +( "_$_" => $data_ref->{$_} ),
                keys %$data_ref,
        }
    );
}

sub _message_into_response_event { 'pass'; }

1;
__END__

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::Data::SimplePassword - plugin for generating passwords on IRC

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::Data::SimplePassword);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'PassBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'PassBot',
    );

    POE::Session->create(
        package_states => [
            main => [ qw(_start irc_001) ],
        ],
    );

    $poe_kernel->run;

    sub _start {
        $irc->yield( register => 'all' );

        $irc->plugin_add(
            'PassBot' =>
                POE::Component::IRC::Plugin::Data::SimplePassword->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
    }


    <Zoffix> PassBot, pass
    <PassBot> Zoffix, %FNZc5t{Sb

    <Zoffix> PassBot, pass 100
    <PassBot> Zoffix, qxopdfN&&U}FG/s."5]1)]M,M(0vGEzD1_Cx8IB*.tC(F'OGcRxaHCZ5wp\
                        1*m+PGR(HcZG"'NKoEKCAbnd+'/N^/+5G{gIf9|g^

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides interface to
to generate random passwords on IRC.
It accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

=head1 IRC USAGE

Providing the plugin run with all of its defaults, you have two modes:

    <Zoffix> PassBot, pass
    <PassBot> Zoffix, %FNZc5t{Sb

    <Zoffix> PassBot, pass 100
    <PassBot> Zoffix, qxopdfN&&U}FG/s."5]1)]M,M(0vGEzD1_Cx8IB*.tC(F'OGcRxaHCZ5wp\
                        1*m+PGR(HcZG"'NKoEKCAbnd+'/N^/+5G{gIf9|g^

That is, any digits that are left after stripping the trigger will be regarded as the length
of the password to make. See C<trigger> and C<default_length> constructor arguments for
details.

=head1 CONSTRUCTOR

=head2 C<new>

    # plain and simple
    $irc->plugin_add(
        'PassGen' => POE::Component::IRC::Plugin::Data::SimplePassword->new
    );

    # juicy flavor
    $irc->plugin_add(
        'PassGen' =>
            POE::Component::IRC::Plugin::Data::SimplePassword->new(
                auto             => 1,
                chars            => [ grep /[[:graph:]]/, map chr, 0..127 ],
                default_length   => 10,
                response_event   => 'irc_data_pass',
                banned           => [ qr/aol\.com$/i ],
                addressed        => 1,
                root             => [ qr/mah.net$/i ],
                trigger          => qr/^pass\s*/i,
                triggers         => {
                    public  => qr/^pass\s*/i,
                    notice  => qr/^pass\s*/i,
                    privmsg => qr/^pass\s*/i,
                },
                listen_for_input => [ qw(public notice privmsg) ],
                eat              => 1,
                debug            => 0,
            )
    );

The C<new()> method constructs and returns a new
C<POE::Component::IRC::Plugin::Data::SimplePassword> object suitable to be
fed to L<POE::Component::IRC>'s C<plugin_add> method. The constructor
takes a few arguments, but I<all of them are optional>. The possible
arguments/values are as follows:

=head3 C<auto>

    ->new( auto => 0 );

B<Optional>. Takes either true or false values, specifies whether or not
the plugin should auto respond to requests. When the C<auto>
argument is set to a true value plugin will respond to the requesting
person with the results automatically. When the C<auto> argument
is set to a false value plugin will not respond and you will have to
listen to the events emited by the plugin to retrieve the results (see
EMITED EVENTS section and C<response_event> argument for details).
B<Defaults to:> C<1>.

=head3 C<chars>

    ->new( chars => [ grep /[[:graph:]]/, map chr, 0..127 ], )

B<Optional>. Takes an arrayref of characters to be used for generating passwords.
B<Defaults to:> C<[ grep /[[:graph:]]/, map chr, 0..127 ]>

=head3 C<default_length>

    ->new( default_length => 10, )

B<Optional>.
The plugin can be triggered from IRC without the length argument (see IRC USAGE section above).
If that's the case than the length of the password to generate will be taken from
C<default_length> argument. B<Defaults to:> C<10>

=head3 C<response_event>

    ->new( response_event => 'event_name_to_recieve_results' );

B<Optional>. Takes a scalar string specifying the name of the event
to emit when the results of the request are ready. See EMITED EVENTS
section for more information. B<Defaults to:> C<irc_data_pass>

=head3 C<banned>

    ->new( banned => [ qr/aol\.com$/i ] );

B<Optional>. Takes an arrayref of regexes as a value. If the usermask
of the person (or thing) making the request matches any of
the regexes listed in the C<banned> arrayref, plugin will ignore the
request. B<Defaults to:> C<[]> (no bans are set).

=head3 C<root>

    ->new( root => [ qr/\Qjust.me.and.my.friend.net\E$/i ] );

B<Optional>. As opposed to C<banned> argument, the C<root> argument
B<allows> access only to people whose usermasks match B<any> of
the regexen you specify in the arrayref the argument takes as a value.
B<By default:> it is not specified. B<Note:> as opposed to C<banned>
specifying an empty arrayref to C<root> argument will restrict
access to everyone.

=head3 C<trigger>

    ->new( trigger => qr/^pass\s*/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex, irrelevant of the type of the message, will be considered as requests. See also
B<addressed> option below which is enabled by default as well as
B<trigggers> option which is more specific. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed.
B<Defaults to:> C<qr/^pass\s*/i>

=head3 C<triggers>

    ->new( triggers => {
            public  => qr/^pass\s*/i,
            notice  => qr/^pass\s*/i,
            privmsg => qr/^pass\s*/i,
        }
    );

B<Optional>. Takes a hashref as an argument which may contain either
one or all of keys B<public>, B<notice> and B<privmsg> which indicates
the type of messages: channel messages, notices and private messages
respectively. The values of those keys are regexes of the same format and
meaning as for the C<trigger> argument (see above).
Messages matching this
regex will be considered as requests. The difference is that only messages of type corresponding to the key of C<triggers> hashref
are checked for the trigger. B<Note:> the C<trigger> will be matched
irrelevant of the setting in C<triggers>, thus you can have one global and specific "local" triggers. See also
B<addressed> option below which is enabled by default as well as
B<trigggers> option which is more specific. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed.
B<Defaults to:> C<qr/^pass\s*/i>

=head3 C<addressed>

    ->new( addressed => 1 );

B<Optional>. Takes either true or false values. When set to a true value
all the public messages must be I<addressed to the bot>. In other words,
if your bot's nickname is C<Nick> and your trigger is
C<qr/^trig\s+/>
you would make the request by saying C<Nick, trig EXAMPLE>.
When addressed mode is turned on, the bot's nickname, including any
whitespace and common punctuation character will be removed before
matching the C<trigger> (see above). When C<addressed> argument it set
to a false value, public messages will only have to match C<trigger> regex
in order to make a request. Note: this argument has no effect on
C</notice> and C</msg> requests. B<Defaults to:> C<1>

=head3 C<listen_for_input>

    ->new( listen_for_input => [ qw(public  notice  privmsg) ] );

B<Optional>. Takes an arrayref as a value which can contain any of the
three elements, namely C<public>, C<notice> and C<privmsg> which indicate
which kind of input plugin should respond to. When the arrayref contains
C<public> element, plugin will respond to requests sent from messages
in public channels (see C<addressed> argument above for specifics). When
the arrayref contains C<notice> element plugin will respond to
requests sent to it via C</notice> messages. When the arrayref contains
C<privmsg> element, the plugin will respond to requests sent
to it via C</msg> (private messages). You can specify any of these. In
other words, setting C<( listen_for_input => [ qr(notice privmsg) ] )>
will enable functionality only via C</notice> and C</msg> messages.
B<Defaults to:> C<[ qw(public  notice  privmsg) ]>

=head3 C<eat>

    ->new( eat => 0 );

B<Optional>. If set to a false value plugin will return a
C<PCI_EAT_NONE> after
responding. If eat is set to a true value, plugin will return a
C<PCI_EAT_ALL> after responding. See L<POE::Component::IRC::Plugin>
documentation for more information if you are interested. B<Defaults to>:
C<1>

=head3 C<debug>

    ->new( debug => 1 );

B<Optional>. Takes either a true or false value. When C<debug> argument
is set to a true value some debugging information will be printed out.
When C<debug> argument is set to a false value no debug info will be
printed. B<Defaults to:> C<0>.

=head1 EMITED EVENTS

=head2 C<response_event>

    $VAR1 = {
        'out' => 'Y`cP#i-XO].7KIL_V{@Q;~OcHkA0D7-RxIQOSb=ah:,fmr^BW!Z@Gq;kzIug*ko?~2u5<1[A=&f]*^.]-{J/d?i#j$_lanynMNq_',
        'pass' => 'Zoffix, Y`cP#i-XO].7KIL_V{@Q;~OcHkA0D7-RxIQOSb=ah:,fmr^BW!Z@Gq;kzIug*ko?~2u5<1[A=&f]*^.]-{J/d?i#j$_lanynMNq_',
        'length' => '100',
        'chars' => [ '!', '"', '#', .... ] # shortened for brevity
        '_channel' => '#zofbot',
        '_type' => 'public',
        '_who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix',
        '_message' => 'PassBot, pass 100',
    };

The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_data_pass>) will recieve input
every time request is completed. The input will come in C<$_[ARG0]>
on a form of a hashref.
The possible keys/values of that hashrefs are as follows:

=head3 C<out>

    { 'out' => 'Y`cP#i-XO].7KIL_V{@Q;~OcHkA0D7-RxIQOSb=ah:,fmr^BW!Z@Gq;kzIug*ko?~2u5<1[A=&f]*^.]-{J/d?i#j$_lanynMNq_', }

The C<out> key will contain the password that was generated.

=head3 C<pass>

    { 'pass' => 'Zoffix, Y`cP#i-XO].7KIL_V{@Q;~OcHkA0D7-RxIQOSb=ah:,fmr^BW!Z@Gq;kzIug*ko?~2u5<1[A=&f]*^.]-{J/d?i#j$_lanynMNq_', }

The C<pass> key will contain whatever would be spoken to IRC when C<auto> argument (see
CONSTRUCTOR) is set to a true value; generally this will me the same as C<out> unless the
plugin was triggered in a public channel.

=head3 C<length>

    { 'length' => '100', }

The C<length> key will contain the length of the generated password.

=head3 C<chars>

    { 'chars' => [ '!', '"', '#', .... ], } # shortened for brevity 

The C<chars> key will contain an arrayref of characters that were used to generate the
password.

=head3 C<_who>

    { '_who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix', }

The C<_who> key will contain the user mask of the user who sent the request.

=head3 C<_message>

    { '_message' => 'PassBot, pass 100', }

The C<_message> key will contain the actual message which the user sent; that
is before the trigger is stripped.

=head3 C<_type>

    { '_type' => 'public', }

The C<_type> key will contain the "type" of the message the user have sent.
This will be either C<public>, C<privmsg> or C<notice>.

=head3 C<_channel>

    { '_channel' => '#zofbot', }

The C<_channel> key will contain the name of the channel where the message
originated. This will only make sense if C<_type> key contains C<public>.

=head1 AUTHOR

'Zoffix, C<< <'zoffix at cpan.org'> >>
(L<http://zoffix.com/>, L<http://haslayout.net/>, L<http://zofdesign.com/>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-irc-plugin-data-simplepassword at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-IRC-Plugin-Data-SimplePassword>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::IRC::Plugin::Data::SimplePassword

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-IRC-Plugin-Data-SimplePassword>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-IRC-Plugin-Data-SimplePassword>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-IRC-Plugin-Data-SimplePassword>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-IRC-Plugin-Data-SimplePassword>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 'Zoffix, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

