[![Actions Status](https://github.com/raku-community-modules/Email-SendGrid/actions/workflows/linux.yml/badge.svg)](https://github.com/raku-community-modules/Email-SendGrid/actions) [![Actions Status](https://github.com/raku-community-modules/Email-SendGrid/actions/workflows/macos.yml/badge.svg)](https://github.com/raku-community-modules/Email-SendGrid/actions) [![Actions Status](https://github.com/raku-community-modules/Email-SendGrid/actions/workflows/windows.yml/badge.svg)](https://github.com/raku-community-modules/Email-SendGrid/actions)

NAME
====

Email::SendGrid - Basic email sending via the SendGrid API

DESCRIPTION
===========

A basic Raku module for sending email using the [SendGrid Web API (v3)](https://www.twilio.com/docs/sendgrid/for-developers/sending-email/api-getting-started).

At the time of writing, SendGrid allows sending up to 100 emails a day free of charge. This module most certainly does not provide full coverage of the SendGrid API; if you need more, pull requests are welcome.

Usage
=====

Construct an `Eamil::SendGrid` object using your SendGrid API key:

```raku
my $sendgrid = Email::SendGrid.new(api-key => 'your_key_here');
```

Then call `send-mail` to send email:

```raku
$sendgrid.send-mail:
  from => address('some@address.com', 'Sender name'),
  to => address('target@address.com', 'Recipient name'),
  subject => 'Yay, SendGrid works!',
  content => {
    'text/plain' => 'This is the plain text message',
    'text/html' => '<strong>HTML mail!</strong>'
  };
```

It is not required to including a HTML version of the body. Optionally, pass `cc`, `bcc`, and `reply-to` to send these addresses. It is also possible to pass a list of up to 1000 addresses to `to`, `cc`, and `bcc`. 

If sending the mail fails, an exception will be thrown. Since `Cro::HTTP::Client` is used internally, it will be an exception from that.

```raku
CATCH {
    default {
        note await .response.body;
    }
}
```

Pass `:async` to `send-mail` to get a `Promise` back instead. Otherwise, it will be <await>ed for you by `send-mail`.

Class / Methods reference
=========================

class Email::SendGrid
---------------------

A partial implementation of the SendGrid v3 API, sufficient for using it to do basic email sending. Construct it with your API key (passed as the api-key parameter), and optionally a from address to be used for all of the emails sent. Construct with :persistent to use a persistent Cro HTTP client (can give better throughput if sending many emails).



Minimal validation of an email address - simply that it has an @ sign.

class Email::SendGrid::Address
------------------------------

Pairs together a name and email address, which are often needed together in the SendGrid API. A name is optional.



Recipient lists may be an address or a list of addresses 1 to 1000 addresses.

### multi sub address

```raku
multi sub address(
    $email
) returns Mu
```

Construct an Email::SendGrid::Address object from just an email address.

### multi sub address

```raku
multi sub address(
    $email,
    $name
) returns Mu
```

Construct an Email::SendGrid::Address object from an email address and a name.

### has Str $.api-key

The SendGrid API key.

### has Email::SendGrid::Address $.from

The default from address to use.

### has Cro::HTTP::Client $.client

The Cro HTTP client used for communication.

### method send-mail

```raku
method send-mail(
    :$to! where { ... },
    :$cc where { ... },
    :$bcc where { ... },
    Email::SendGrid::Address :$from = Code.new,
    Email::SendGrid::Address :$reply-to,
    Str :$subject!,
    :%content!,
    :$async,
    :$sandbox
) returns Mu
```

Send an email. The C<to>, C<cc>, and C<bcc> options may be a single Address object or a list of 1 to 1000 C<Address> objects. Only C<to> is required; C<from> is required if there is no object-level from address. Optionally, a C<reply-to> C<Address> may be provided. A C<subject> is required, as is a C<%content> hash that maps mime types into the matching bodies. If `async` is passed, the call to the API will take place asynchronously, and a C<Promise> returned.

AUTHOR
======

Jonathan Worthington

COPYRIGHT AND LICENSE
=====================

Copyright 2020 Jonathan Worthington

Copyright 2024 Raku Community

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

