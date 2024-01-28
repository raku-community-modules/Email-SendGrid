=begin pod

=head1 NAME

Email::SendGrid - Basic email sending via the SendGrid API

=head1 DESCRIPTION

A basic Raku module for sending email using the
L<SendGrid Web API (v3)|https://sendgrid.com/docs/API_Reference/api_v3.html>.

At the time of writing, SendGrid allows sending up to 100 emails a
day free of charge.  This module most certainly does not provide full
coverage of the SendGrid API; if you need more, pull requests are
welcome.

=head1 Usage

Construct an `Eamil::SendGrid` object using your SendGrid API key:

=begin code :lang<raku>

my $sendgrid = Email::SendGrid.new(api-key => 'your_key_here');

=end code

Then call `send-mail` to send email:

=begin code :lang<raku>

$sendgrid.send-mail:
  from => address('some@address.com', 'Sender name'),
  to => address('target@address.com', 'Recipient name'),
  subject => 'Yay, SendGrid works!',
  content => {
    'text/plain' => 'This is the plain text message',
    'text/html' => '<strong>HTML mail!</strong>'
  };

=end code

It is not required to including a HTML version of the body. Optionally,
pass C<cc>, C<bcc>, and C<reply-to> to send these addresses. It is also
possible to pass a list of up to 1000 addresses to C<to>, C<cc>, and
C<bcc>. 

If sending the mail fails, an exception will be thrown. Since
C<Cro::HTTP::Client> is used internally, it will be an exception from
that.

=begin code :lang<raku>

CATCH {
    default {
        note await .response.body;
    }
}

=end code 

Pass C<:async> to C<send-mail> to get a C<Promise> back instead.
Otherwise, it will be <await>ed for you by C<send-mail>.

=head1 Class / Methods reference

=end pod

use Cro::HTTP::Client;
use Cro::Uri;

my constant API_BASE = Cro::Uri.parse('https://sendgrid.com/v3/');

#| A partial implementation of the SendGrid v3 API, sufficient for using it to do basic
#| email sending. Construct it with your API key (passed as the api-key parameter), and
#| optionally a from address to be used for all of the emails sent. Construct with
#| :persistent to use a persistent Cro HTTP client (can give better throughput if sending
#| many emails).
class Email::SendGrid {
    #| Minimal validation of an email address - simply that it has an @ sign.
    subset HasEmailSign of Str where .contains('@');

    #| Pairs together a name and email address, which are often needed together in the
    #| SendGrid API. A name is optional.
    class Address {
        has HasEmailSign $.email is required;
        has Str $.name;
        method for-json() {
            { :$!email, (:$!name if $!name) }
        }
    }

    #| Recipient lists may be an address or a list of addresses 1 to 1000 addresses.
    subset AddressOrListOfAddress where { !$^a.defined || $^a.all ~~ Address && 1 <= $^a.elems <= 1000 }

    #| Construct an Email::SendGrid::Address object from just an email address.
    multi sub address($email) is export {
        Address.new(:$email)
    }

    #| Construct an Email::SendGrid::Address object from an email address and a name.
    multi sub address($email, $name) is export {
        Address.new(:$email, :$name)
    }

    #| The SendGrid API key.
    has Str $.api-key is required;

    #| The default from address to use.
    has Address $.from;

    #| The Cro HTTP client used for communication.
    has Cro::HTTP::Client $.client;

    #| Send an email. The C<to>, C<cc>, and C<bcc> options may be a single Address object or
    #| a list of 1 to 1000 C<Address> objects. Only C<to> is required; C<from> is required if there
    #| is no object-level from address. Optionally, a C<reply-to> C<Address> may be provided.
    #| A C<subject> is required, as is a C<%content> hash that maps mime types into the matching
    #| bodies. If `async` is passed, the call to the API will take place asynchronously, and a
    #| C<Promise> returned.
    method send-mail(AddressOrListOfAddress :$to!, AddressOrListOfAddress :$cc,
            AddressOrListOfAddress :$bcc, Address :$from = $!from // die("Must specify a from address"),
            Address :$reply-to, Str :$subject!, :%content!, :$async, :$sandbox) {
        # Form the JSON payload describing the email.
        my %personalization = to => to-email-list($to);
        %personalization<cc> = to-email-list($_) with $cc;
        %personalization<bcc> = to-email-list($_) with $bcc;
        my %request-json =
                from => $from.for-json,
                personalizations => [%personalization,],
                :$subject,
                :content(form-content(%content));
        %request-json<reply-to> = .for-json with $reply-to;
        if $sandbox {
            %request-json<mail_settings><sandbox_mode><enable> = True;
        }

        # Make the HTTP request.
        my $req = $!client.post: API_BASE.add('mail/send'),
                auth => { bearer => $!api-key },
                content-type => 'application/json',
                body => %request-json;
        return $async ?? $req !! await($req);
    }

    multi sub to-email-list(Address $addr) {
        [$addr.for-json,]
    }

    multi sub to-email-list(@addresses) {
        [@addresses.map(*.for-json)]
    }

    sub form-content(%content is copy) {
        # Per API rules, text/plain must be first, then HTML, then anything else.
        my @formed;
        for 'text/plain', 'text/html' -> $type {
            with %content{$type}:delete -> $value {
                @formed.push: { :$type, :$value }
            }
        }
        for %content {
            @formed.push: %(type => .key, value => .value);
        }
        return @formed;
    }
}

=begin pod

=head1 AUTHOR

Jonathan Worthington

=head1 COPYRIGHT AND LICENSE

Copyright 2020 - 2024 Jonathan Worthington

Copyright 2024 Raku Community

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
