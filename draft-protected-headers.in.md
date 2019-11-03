---
title: Protected Headers for Cryptographic E-mail
docname: draft-autocrypt-protected-headers-00
date: 2019-10-19
category: info

ipr: trust200902
area: int
workgroup: openpgp
keyword: Internet-Draft

stand_alone: yes
pi: [toc, sortrefs, symrefs]

author:
 -
    ins: B. R. Einarsson
    name: Bjarni Runar Einarsson
    org: Mailpile ehf
    street: Baronsstigur
    country: Iceland
    email: bre@mailpile.is
 -
    name: juga
    email: juga@riseup.net
    org: Independent
 -
    ins: D. K. Gillmor
    name: Daniel Kahn Gillmor
    org: American Civil Liberties Union
    street: 125 Broad St.
    city: New York, NY
    code: 10004
    country: USA
    abbrev: ACLU
    email: dkg@fifthhorseman.net
informative:
 OpenPGP-Email-Summit-2019:
    target: https://wiki.gnupg.org/OpenPGPEmailSummit201910
    title: OpenPGP Email Summit 2019
    date: 2019-10-13
 Autocrypt:
    target: https://autocrypt.org/level1.html
    title: Autocrypt Specification 1.1
    date: 2019-10-13
 I-D.draft-bre-openpgp-samples-00:
 I-D.draft-luck-lamps-pep-header-protection-03:
 I-D.draft-ietf-lamps-header-protection-requirements-00:
 RFC2634:
 RFC3851:
 RFC6736:
 RFC7508:
 RFC8551:
normative:
 RFC2119:
 RFC2822:
 RFC3156:
 RFC4880:
 RFC8174:
--- abstract

This document describes a common strategy to extend the cryptographic protections provided by PGP/MIME, etc. to protect message headers in addition to message bodies.
In addition to protecting the authenticity and integrity of headers via signatures, it also describes how to preserve the confidentiality of the Subject header.

--- middle

Introduction
============

E-mail end-to-end security with OpenPGP and S/MIME standards can provide integrity, authentication, non-repudiation and confidentiality to the body of a MIME e-mail message.
However, PGP/MIME ({{RFC3156}}) alone does not protect message headers.
And the structure to protect headers defined in S/MIME 3.1 ({{RFC3851}}) has not seen widespread adoption.

This document defines a scheme, "Protected Headers for Cryptographic E-mail", which has been adopted by multiple existing e-mail clients in order to extend the cryptographic protections provided by PGP/MIME to also protect the message headers.

This document describes how these protections can be applied to cryptographically signed messages, and also discusses some of the challenges of encrypting many transit-oriented headers.

It offers guidance for encrypting non-transit-oriented headers like Subject, and also offers a means to preserve backwards compatibility so that an encrypted Subject remains available to recipients using software that does not implement support for the Protected Headers scheme.

The document also discusses some of the compatibility constraints and usability concerns which motivated the design of the scheme, as well as limitations and a comparison with other proposals.

While the document (and the authors') focus is primarily PGP/MIME, we believe the technique is broadly applicable and would also apply to other MIME-compatible cryptographic e-mail systems, including S/MIME ({{RFC8551}}).  Furthermore, this technique has already proven itself as a useful building block for other improvements to cryptographic e-mail, such as the Autocrypt Level 1.1 ({{Autocrypt}}) "Gossip" mechanism.


Requirements Language
---------------------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 {{RFC2119}} {{RFC8174}} when, and only when, they appear in all capitals, as shown here.


Terminology
-----------

For the purposes of this document, we define the following concepts:

   * *MUA* is short for Mail User Agent; an e-mail client.
   * *Protection* of message data refers to cryptographic encryption and/or signatures, providing confidentiality, authenticity or both.
   * *Cryptographic Layer*, *Cryptographic Envelope* and *Cryptographic Payload* are defined in {{cryptographic-structure}}
   * *Original Headers* are the {{RFC2822}} message headers as known to the sending MUA at the time of message composition.
   * *Protected Headers* are any headers protected by the scheme described in this document.
   * *Exposed Headers* are any headers outside the Cryptographic Payload (protected or not).
   * *Obscured Headers* are any Protected Headers which have been modified or removed from the set of Exposed Headers.
   * *Legacy Display Part* is a MIME construct which guarantees visibility of data from the Original Headers which may have been removed or obscured from the Unprotected Headers.

Cryptographic MIME Message Structure {#cryptographic-structure}
====================================

Implementations use the structure of an e-mail message to protect the headers.
This section establishes some conventions about how to think about message structure.

Cryptographic Layers {#cryptographic-layer}
--------------------

"Cryptographic Layer" refers to a MIME substructure that supplies some cryptographic protections to an internal MIME subtree.
The internal subtree is known as the "protected part" though of course it may itself be a multipart object.

For PGP/MIME {{RFC3156}} there are two forms of Cryptographic Layers, signing and encryption.

In the diagrams below, <u>↧</u> is used to indicate "decrypts to".

### PGP/MIME Signing Cryptographic Layer (multipart/signed) {#multipart-signed}

    └┬╴multipart/signed
     ├─╴[protected part]
     └─╴application/pgp-signature

### PGP/MIME Encryption Cryptographic Layer (multipart/encrypted) {#multipart-encrypted}

    └┬╴multipart/encrypted
     ├─╴application/pgp-encrypted
     └─╴application/octet-stream
      ↧ (decrypts to)
      └─╴[protected part]

Cryptographic Envelope
----------------------

The Cryptographic Envelope is the largest contiguous set of Cryptographic Layers of an e-mail message starting with the outermost MIME type (that is, with the Content-Type of the message itself).

If the Content-Type of the message itself is not a Cryptographic Layer, then the message has no cryptographic envelope.

"Contiguous" in the definition above indicates that if a Cryptographic Layer is the protected part of another Cryptographic Layer, the layers together comprise a single Cryptographic Envelope.

Note that if a non-Cryptographic Layer intervenes, all Cryptographic Layers within the non-Cryptographic Layer *are not* part of the Cryptographic Envelope (see the example in {{baroque-example}}).

Note also that the ordering of the Cryptographic Layers implies different cryptographic properties.
A signed-then-encrypted message is different than an encrypted-then-signed message.

Cryptographic Payload
---------------------

The Cryptographic Payload of a message is the first non-Cryptographic Layer -- the "protected part" -- within the Cryptographic Envelope.
Since the Cryptographic Payload itself is a MIME part, it has its own set of headers.

Protected headers are placed on (and read from) the Cryptographic Payload, and should be considered to have the same cryptographic properties as the message itself.

### Simple Cryptographic Payloads {#simple-cryptographic-payloads}

As described above, if the "protected part" identified in {{multipart-signed}} or {{multipart-encrypted}} is not itself a Cryptographic Layer, that part *is* the Cryptographic Payload.

If the application wants to generate a message that is both encrypted and signed, it MAY use the simple MIME structure from {{multipart-encrypted}} by ensuring that the {{RFC4880}} Encrypted Message within the `application/octet-stream` part contains an {{RFC4880}} Signed Message.

### Multilayer Cryptographic Envelopes {#multilayer-cryptographic-envelopes}

It is possible to construct a Cryptographic Envelope consisting of multiple layers for PGP/MIME, typically of the following structure:

    A └┬╴multipart/encrypted
    B  ├─╴application/pgp-encrypted
    C  └─╴application/octet-stream
    D   ↧ (decrypts to)
    E   └┬╴multipart/signed
    F    ├─╴[Cryptographic Payload]
    G    └─╴application/pgp-signature

When handling such a message, the properties of the Cryptographic Envelope are derived from the series A, E.

As noted in {{simple-cryptographic-payloads}}, PGP/MIME applications also have a simpler MIME construction available.

### A Baroque Example {#baroque-example}

Consider a message with the following overcomplicated structure:

    H └┬╴multipart/encrypted
    I  ├─╴application/pgp-encrypted
    J  └─╴application/octet-stream
    K   ↧ (decrypts to)
    L   └┬╴multipart/signed
    M    ├┬╴multipart/mixed
    N    │├┬╴multipart/signed
    O    ││├─╴text/plain
    P    ││└─╴application/pgp-signature
    Q    │└─╴text/plain
    R    └─╴application/pgp-signature

The 3 Cryptographic Layers in such a message are rooted in parts H, L, and N.
The Cryptographic Envelope of the message consists of the properties derived from the series H, L.
The Cryptographic Payload of the message is part M.

It is NOT RECOMMENDED to generate messages with such complicated structures.
Even if a receiving MUA can parse this structure properly, it is nearly impossible to render in a way that the user can reason about the cryptographic properties of part O compared to part Q.


Original Headers are Outside
----------------------------

The Cryptographic Envelope fully encloses the Cryptographic Payload, whether the message is signed or encrypted or both.
The Original Headers are considered to be outside of both.


Message Composition
===================

The Protected Headers scheme is summarized as follows:

   1. All message headers known to the MUA at composition time MUST be copied verbatim into the first MIME header of the Cryptographic Payload.
   2. When encrypting, Exposed Headers MAY be *obscured* by a transformation (including deletion).
   3. When encrypting, if the MUA has obscured any user-facing header data, it SHOULD add a Legacy Display Part to the Cryptographic Payload which duplicates this information.

*Note:* The above is not a description of a sequential algorithm.

Details:

   * Encryption SHOULD protect the Subject line
   * When encrypting, the Subject line should be obscured (replaced) by the string `...`
   * Step 3. may require adding a `multipart/mixed` MIME wrapper to the Cryptographic Payload, in turn influencing where to inject the headers from step 1.

See below for a more detailed discussion.


Header Copying
--------------

All headers known to the MUA at composition time MUST be copied verbatim into the header of the target MIME part.

The target MIME part shall always be the first MIME part within the Cryptographic Payload. See {{examples}} for an illustration.

The reason all headers must be copied, is that otherwise it becomes impossible for implementations to reliably detect tampering with the Exposed Headers, which would greatly reduces the strength of the scheme.

Encrypted Subject {#encrypted-subject}
-----------------

When a message is encrypted, the Subject should be obscured by replacing the Exposed Subject with three periods: `...`

This value (`...`) was chosen because it is believed to be language agnostic and avoids communicating any potentially misleading information to the recipient (see {{common-pitfalls}} for a more detailed discussion).

Obscured Headers
----------------

Due to compatibility and usability concerns, a Mail User Agent SHOULD NOT obscure any of: `From`, `To`, `Cc`, `Message-ID`, `References`, `Reply-To`, (FIXME: MORE?), unless the user has indicated they have security constraints which justify the potential downsides (see {{common-pitfalls}} for a more detailed discussion).

Aside from that limitation, this specification does not at this time define or limit the methods a MUA may use to convert Exposed Headers into Obscured Headers.

Legacy Display {#legacy-display}
==============

MUAs typically display some headers directly to the user.
An encrypted message may be read by an decryption-capable MUA that is unaware of this standard.
The user of such a legacy client risks losing access to any obscured headers.

This section presents a workaround to mitigate this risk by restructuring the Cryptographic Payload before encrypting to include a "Legacy Display" part.

Typically Visible Headers {#typically-visible-headers}
-------------------------

Of all the headers that an e-mail message may contain, only a handful are typically presented directly to the user.
The typically visible headers are:

 - `Subject`
 - `From`
 - `To`
 - `Cc`
 - `Date`

The above is a complete list.  No other headers are considered "typically visible".

Other headers may affect the visible rendering of the message (e.g., `References` and `In-Reply-To` may affect the placement of a message in a threaded discussion), but they are not directly displayed to the user and so are not considered "typically visible" for the purposes of this document.

Message Generation: Including a Legacy Display Part
---------------------------------------------------

A generating MUA that wants to make an Obscured Subject (or any other typically visible header) visible to a recipient using a legacy MUA SHOULD modify the Cryptographic Payload by wrapping the intended body of the message in a `multipart/mixed` MIME part that prefixes the intended body with a Legacy Display part.

The Legacy Display part MUST be of Content-Type `text/rfc822-headers`, and MUST contain a `protected-headers` parameter whose value is `v1`.
It SHOULD be marked with `Content-Disposition: inline` to encourage recipients to render it.

The contents of the Legacy Display part MUST be only the typically visible headers that the sending MUA intends to obscure after encryption.

The original body (now a subpart) SHOULD also be marked with `Content-Disposition: inline` to discourage legacy clients from presenting it as an attachment.

### Legacy Display Transformation {#legacy-display-transformation}

Consider a message whose Cryptographic Payload, before encrypting, that would have a traditional `multipart/alternative` structure:

    X └┬╴multipart/alternative
    Y  ├─╴text/plain
    Z  └─╴text/html

When adding a Legacy Display part, this structure becomes:

    V └┬╴multipart/mixed
    W  ├─╴text/rfc822-headers ("Legacy Display" part)
    X  └┬╴multipart/alternative ("original body")
    Y   ├─╴text/plain
    Z   └─╴text/html

Note that with the inclusion of the Legacy Display part, the Cryptographic Payload is the `multipart/mixed` part (part `V` in the example above), so Protected Headers should be placed at that part.

### When to Generate Legacy Display

A MUA SHOULD transform a Cryptographic Payload to include a Legacy Display part only when:

 - The message is going to be encrypted, and
 - At least one typically visible header (see {{typically-visible-headers}}) is going to be obscured

Additionally, if the sender knows that the recipient's MUA is capable of interpreting Protected Headers, it SHOULD NOT attempt to include a Legacy Display part.
(Signalling such a capability is out of scope for this document)

Message Rendering: Omitting a Legacy Display Part {#no-render-legacy-display}
-------------------------------------------------

A MUA that understands Protected Headers may receive an encrypted message that contains a Legacy Display part.
Such an MUA SHOULD avoid rendering the Legacy Display part to the user at all, since it is aware of and can render the actual Protected Headers.

If a Legacy Display part is detected, the Protected Headers should still be pulled from the Cryptographic Payload (part `V` in the example above), but the body of message SHOULD be rendered as though it were only the original body (part `X` in the example above).

### Legacy Display Detection Algorithm

A receiving MUA acting on a message SHOULD detect the presence of a Legacy Display part and the corresponding "original body" with the following simple algorithm:

 - Check that all of the following are true for the message:
  - The Cryptographic Envelope must contain an encrypting Cryptographic Layer
  - The Cryptographic Payload must have a `Content-Type` of `multipart/mixed`
  - The Cryptographic Payload must have exactly two subparts
  - The first subpart of the Cryptographic Payload must have a `Content-Type` of `text/rfc822-headers`
  - The first subpart of the Cryptographic Payload's `Content-Type` must contain a property of `protected-headers`, and its value must be `v1`.
 - If all of the above are true, then the first subpart is the Legacy Display part, and the second subpart is the "original body".  Otherwise, the message does not have a Legacy Display part.

### Legacy Display is Decorative and Transitional

As the above makes clear, the Legacy Display part is strictly decorative, for the benefit of legacy decryption-capable MUAs that may handle the message.
As such, the existence of the Legacy Display part and its `multipart/mixed` wrapper are part of a transition plan.

As the number of decryption-capable clients that understand Protected Headers grows in comparison to the number of legacy decryption-capable clients, it is expected that some senders will decide to stop generating Legacy Display parts entirely.

A MUA developer concerned about accessiblity of the Subject header for their users of encrypted mail when Legacy Display parts are omitted SHOULD implement the Protected Headers scheme described in this document.

Message Interpretation
======================

(Brief discussion about potential strategies to reverse the process above.)

Replying to a Message with Obscured Headers
-------------------------------------------

When replying to a message, many MUAs copy headers from the original message into their reply.

When replying to an encrypted message, users expect the replying MUA to generate an encrypted message if possible.
If it is not possible, and the reply will be cleartext, users typically want the MUA to avoid leaking previously-encrypted content into the cleartext of the reply.

For this reason, an MUA replying to an encrypted message with Obscured Headers SHOULD NOT leak the cleartext of any Obscured Headers into the cleartext of the reply, whether encrypted or not.

In particular, the contents of any Obscured Header from the original message SHOULD NOT be placed in the Exposed Headers of the reply message.

Examples {#examples}
========

(Use diagrams from Juga to explain the envelope/payload concept)

(Add sample messages using this syntax, where E or S tell us which bits are part of the Cryptographic Payload.)

    . From: Alice Lovelace <alice@example.org>
    . To: Bob Babbage <bob@example.org>
    . Subject: ...
    . Content-Type: multipart/encrypted; protocol=...; boundary=1234
    .
    . --1234
    . Content-Type: application/pgp-encrypted
    .
    . Version: 1
    .
    . --1234
    . Content-Type: application/octet-stream; name="encrypted.asc"
    .
    E Content-Type: multipart/mixed; boundary=ABCD
    E (copied headers)
    E
    E --ABCD
    E (Legacy display part)
    E
    E --ABCD
    E (original message)
    E --ABCD--
    . --1234--

Text in `[` and `]` is not part of the message or not as it is, it's a clarification in the examples.
Message-ID and boundary strings have been replaced by `message_id` and `multipart_X_boundary` to make the examples more clear.
Extra new lines have been added to also make the examples more clear.

TODO: Note what we call Cryptographic Envelope in the examples.
FIXME: Enigmail adds `; protected-headers="v1"` to `multipart/mixed`. Is that needed?

Example OpenPGP signed message
-------------------------------

In which the body is "text/plain".

    From: Alice Lovelace <alice@openpgp.example>
    To: Bob Babbage <bob@openpgp.example>
    Subject: Hi
    Message-ID: <message_id>
    Date: Thu, 17 Oct 2019 06:09:00 +0000
    MIME-Version: 1.0
    Content-Type: multipart/signed; micalg=pgp-sha512;
     protocol="application/pgp-signature";
     boundary="multipart_signed_boundary"

    This is an OpenPGP/MIME signed message (RFC 4880 and 3156)

    --multipart_signed_boundary

    [This is the payload containing the headers]
    Content-Type: multipart/mixed; boundary="multipart_mixed_boundary"
    From: Alice Lovelace <alice@openpgp.example>
    To: Alice Lovelace <alice@openpgp.example>
    Message-ID: <message_id>
    Subject: Hi

    --multipart_mixed_boundary

    Content-Type: text/plain; charset=utf-8
    Content-Language: en-US
    Content-Transfer-Encoding: quoted-printable

    Hi Bob!,

    we have a meeting today.

    Best,
    Alice.

    --multipart_mixed_boundary--

    --multipart_signed_boundary
    Content-Type: application/pgp-signature; name="signature.asc"
    Content-Description: OpenPGP digital signature
    Content-Disposition: attachment; filename="signature.asc"

    -----BEGIN PGP SIGNATURE-----

    [Signature of the multipart/mixed structure.]

    -----END PGP SIGNATURE-----

    --multipart_signed_boundary--


Example OpenPGP encrypted message
----------------------------------

In which the body of the message is "text/plain".


    From: Alice Lovelace <alice@openpgp.example>
    To: Bob Babbage <bob@openpgp.example>
    Message-ID: <message_id>
    Date: Thu, 17 Oct 2019 06:09:00 +0000
    MIME-Version: 1.0
    Subject: ...
    Content-Type: multipart/encrypted;
     protocol="application/pgp-encrypted";
     boundary="multipart_encrypted_boundary"

    This is an OpenPGP/MIME encrypted message (RFC 4880 and 3156)
    --multipart_encrypted_boundary
    Content-Type: application/pgp-encrypted
    Content-Description: PGP/MIME version identification

    Version: 1

    --multipart_encrypted_boundary
    Content-Type: application/octet-stream; name="encrypted.asc"
    Content-Description: OpenPGP encrypted message
    Content-Disposition: inline; filename="encrypted.asc"

    -----BEGIN PGP MESSAGE-----

    [Encrypted payload]
    -----END PGP MESSAGE-----

    --multipart_encrypted_boundary--


After decrypting the Cryptographic Payload, this is the payload containing the 
headers:

TODO: would be the decrypted part just "text/plain" with the headers on top of 
the body?

Example encrypted message in the "compat" form
-----------------------------------------------

In which the body of the message is "text/plain".
Note that the outer structure of the message is the same as in the example above.

    From: Alice Lovelace <alice@openpgp.example>
    To: Bob Babbage <bob@openpgp.example>
    Message-ID: <message_id>
    Date: Thu, 17 Oct 2019 06:09:00 +0000
    MIME-Version: 1.0
    Subject: ...
    Content-Type: multipart/encrypted;
     protocol="application/pgp-encrypted";
     boundary="multipart_encrypted_boundary"

    This is an OpenPGP/MIME encrypted message (RFC 4880 and 3156)
    --multipart_encrypted_boundary
    Content-Type: application/pgp-encrypted
    Content-Description: PGP/MIME version identification

    Version: 1

    --multipart_encrypted_boundary
    Content-Type: application/octet-stream; name="encrypted.asc"
    Content-Description: OpenPGP encrypted message
    Content-Disposition: inline; filename="encrypted.asc"

    -----BEGIN PGP MESSAGE-----

    [Encrypted payload]
    -----END PGP MESSAGE-----

    --multipart_encrypted_boundary--

After decrypting the Cryptographic Payload, this is the payload containing the 
headers:

    Content-Type: multipart/mixed; boundary="multipart_mixed_boundary"
    From: Alice Lovelace <alice@openpgp.example>
    To: Bob Babbage <bob@openpgp.example>
    Message-ID: <message_id>
    Subject: Hi

    --multipart_mixed_boundary
    Content-Type: text/rfc822-headers
    Content-Disposition: inline

    [This is the legacy display]
    From: Alice Lovelace <alice@openpgp.example>
    To: Alice Lovelace <alice@openpgp.example>
    Subject: subject, signed and encrypted
    [FIXME: Include Message-ID also here (enigmail does not)?]

    --multipart_mixed_boundary
    Content-Type: text/plain; charset=utf-8

    Hi Bob!,

    we have a meeting today.

    Best,
    Alice.
    --multipart_mixed_boundary--

Example multilayer cryptographic envelope
-----------------------------------------

In which the body of the message is "text/plain".
Note that the outer structure of the message is the same as in the example above.

    From: Alice Lovelace <alice@openpgp.example>
    To: Bob Babbage <bob@openpgp.example>
    Message-ID: <message_id>
    Date: Thu, 17 Oct 2019 06:09:00 +0000
    MIME-Version: 1.0
    Subject: ...
    Content-Type: multipart/encrypted;
     protocol="application/pgp-encrypted";
     boundary="multipart_encrypted_boundary"

    This is an OpenPGP/MIME encrypted message (RFC 4880 and 3156)
    --multipart_encrypted_boundary
    Content-Type: application/pgp-encrypted
    Content-Description: PGP/MIME version identification

    Version: 1

    --multipart_encrypted_boundary
    Content-Type: application/octet-stream; name="encrypted.asc"
    Content-Description: OpenPGP encrypted message
    Content-Disposition: inline; filename="encrypted.asc"

    -----BEGIN PGP MESSAGE-----

    [Encrypted payload]
    -----END PGP MESSAGE-----

    --multipart_encrypted_boundary--

After decrypting the Cryptographic Payload, this is the payload containing the 
headers:
Note that this structure is the same as in the example signed message.

    From: Alice Lovelace <alice@openpgp.example>
    To: Bob Babbage <bob@openpgp.example>
    Subject: Hi
    Message-ID: <message_id>
    Date: Thu, 17 Oct 2019 06:09:00 +0000
    MIME-Version: 1.0
    Content-Type: multipart/signed; micalg=pgp-sha512;
     protocol="application/pgp-signature";
     boundary="multipart_signed_boundary"

    This is an OpenPGP/MIME signed message (RFC 4880 and 3156)

    --multipart_signed_boundary

    [This is the payload containing the headers]
    Content-Type: multipart/mixed; boundary="multipart_mixed_boundary"
    From: Alice Lovelace <alice@openpgp.example>
    To: Alice Lovelace <alice@openpgp.example>
    Message-ID: <message_id>
    Subject: Hi

    --multipart_mixed_boundary

    Content-Type: text/plain; charset=utf-8
    Content-Language: en-US
    Content-Transfer-Encoding: quoted-printable

    Hi Bob!,

    we have a meeting today.

    Best,
    Alice.

    --multipart_mixed_boundary--

    --multipart_signed_boundary
    Content-Type: application/pgp-signature; name="signature.asc"
    Content-Description: OpenPGP digital signature
    Content-Disposition: attachment; filename="signature.asc"

    -----BEGIN PGP SIGNATURE-----

    [Signature of the multipart/mixed structure.]

    -----END PGP SIGNATURE-----

    --multipart_signed_boundary--



Common Pitfalls and Guidelines {#common-pitfalls}
==============================

Misunderstood Obscured Subjects {#misunderstood-obscured-subjects}
-------------------------------

(describe why Encrypted Message is a dangerous subject line)


Reply/Forward Losing Subjects
-----------------------------

(describe Re: `...`)


Usability Impact of Reduced Metadata
-------------------------------------

(describe the problems ProtonMail/TutaNota have, discuss potential solutions)


Usability Impact of Obscured Message-ID
---------------------------------------

(describe why we don't recommend this just yet)


Usability Impact of Obscured From/To/Cc
---------------------------------------

(describe why we don't recommend this just yet)

Mailinglist munges From: or In-Reply-To: headers
------------------------------------------------

(describe the issue, that some mailinglist softwares changes the `From:` line or `Reply-To:` in order to make sure that replies go to the list and not to the author.
This is known as [header munging](https://www.unicom.com/pw/reply-to-harmful.html).
Protected headers break this workaround.
See https://cr.yp.to/proto/replyto.html how this should be fixed properly in a MUA)

Comparison with Other Header Protection Schemes
===============================================

Other header protection schemes have been proposed (in the IETF and elsewhere) that are distinct from this mechanism.
This section documents the differences between those earlier mechanisms and this one, and hypothesizes why it has seen greater interoperable adoption.

The distinctions include:

 * backward compatibility with legacy clients
 * compatibility across PGP/MIME and S/MIME
 * protection for both confidentiality and signing

S/MIME 3.1 Header Protection {#smime-31}
----------------------------

S/MIME 3.1 ({{RFC3851}}) introduces header protection via `message/rfc822` header parts.

The problem with this mechanism is that many legacy clients encountering such a message were likely to interpret it as either a forwarded message, or as an unreadable substructure.

For signed messages, this is particularly problematic -- a message that would otherwise have been easily readable by a client that knows nothing about signed messages suddenly shows up as a message-within-a-message, just by virtue of signing.  This has an impact on *all* clients, whether they are cryptographically-capable or not.

For encrypted messages, whose interpretation only matters on the smaller set of cryptographically-capable legacy clients, the resulting message rendering is awkward at best.

Furthermore, Formulating a reply to such a message on a legacy client can also leave the user with badly-structured quoted and attributed content.

Additionally, a message deliberately forwarded in its own right (without preamble or adjacent explanatory notes) could potentially be confused with a message using the declared structure.

The mechanism described here allows cryptographically-incapable legacy MUAs to read and handle cleartext signed messages without any modifications, and permits cryptographically-capable legacy MUAs to handle encrypted messages without any modifications.

In particular, the Legacy Display part described in {#legacy-display} makes it feasible for a conformant MUA to generate messages with obscured Subject lines that nonetheless give access to the obscured Subject header for recipients with legacy MUAs.

The Content-Type property "forwarded=no" {forwarded=no}
----------------------------------------

{{I-D.draft-ietf-lamps-header-protection-requirements-00}} contains a proposal that attempts to mitigate one of the drawbacks of the scheme described in S/MIME 3.1 ({{smime-31}}).

In particular, it allows *non-legacy* clients to distinguish between deliberately forwarded messages and those intended to use the defined structure for header protection.

However, this fix has no impact on the confusion experienced by legacy clients.

pEp Header protection
---------------------

{{I-D.draft-luck-lamps-pep-header-protection-03}} is applicable only to signed+encrypted mail, and does not contemplate protection of signed-only mail.

In addition, the pEp header protection involved for "pEp message format 2" has an additional `multipart/mixed`  layer designed to facilitate transfer of OpenPGP Transferable Public Keys, which seems orthogonal to the effort to protect headers.

Finally, that draft suggests that the exposed Subject header be one of "=?utf-8?Q?p=E2=89=A1p?=", "pEp", or "Encrypted message".
"pEp" is a mysterious choice for most users, and see {{misunderstood-obscured-subjects}} for more commentary on why "Encrypted message" is likely to be problematic.

DKIM
----

{{RFC6736}} offers DKIM, which is often used to sign headers associated with a message.

DKIM is orthogonal to the work described in this document, since it is typically done by the domain operator and not the end user generating the original message.
That is, DKIM is not "end-to-end" and does not represent the intent of the entity generating the message.

Furthermore, a DKIM signer does not have access to headers inside an encrypted Cryptographic Layer, and a DKIM verifier cannot effectively use DKIM to verify such confidential headers.

S/MIME "Secure Headers"
-----------------------

{{RFC7508}} describes a mechanism that embeds message header fields in the S/MIME signature using ASN.1.

The mechanism proposed in that draft is undefined for use with PGP/MIME.
While all S/MIME clients must be able to handle CMS and ASN.1 as well as MIME, a standard that works at the MIME layer itself should be applicable to any MUA that can work with MIME, regardess of whether end-to-end security layers are provided by S/MIME or PGP/MIME.

That mechanism also does not propose a means to provide confidentiality protection for headers within an encrypted-but-not-signed message.

Finally, that mechanism offers no equivalent to the Legacy Display described in {{legacy-display}}.
Instead, sender and receiver are expected to negotiate in some unspecified way to ensure that it is safe to remove or modify Exposed Headers in an encrypted message.

Triple-wrapping
---------------

{{RFC2634}} defines "Triple Wrapping" as a means of providing cleartext signatures over signed and encrypted material.
While this can be used in combination with the mechanism described in {{RFC7508}} to authenticate some headers for transport using S/MIME.

But it does not offer confidentiality protection for the protected headers, and the signer of the outer layer of a triple-wrapped message may not be the originator of the message either.

In practice on today's Internet, DKIM ({{RFC6736}} provides a more widely-accepted cryptographic header-verification-for-transport mechanism  than triple-wrapped messages.


Test Vectors
============

The subsections below provide example messages that implement the Protected Header scheme.

The secret keys and OpenPGP certificates from {{I-D.draft-bre-openpgp-samples-00}} can be used to decrypt and verify them.

They are provided in textual source form as {{RFC2822}} messages.

Signed Message with Protected Headers {#test-vector-signed-only}
-------------------------------------

This shows a clearsigned message.  Its MIME message structure is:

~~~
└┬╴multipart/signed
 ├─╴text/plain
 └─╴application/pgp-signature
~~~

Note that if this message had been generated without Protected Headers, then an attacker with access to it could modify the Subject without invalidating the signature.
Such an attacker could cause Bob to think that Alice wanted to cancel the contract with BarCorp instead of FooCorp.

~~~
@@signed.eml@@
~~~

Signed and Encrypted Message with Protected Headers {#encryptedsigned}
---------------------------------------------------

This shows a simple encrypted message with protected headers.
The encryption also contains an signature in the OpenPGP Message structure.
Its MIME message structure is:

~~~
└┬╴multipart/encrypted
 ├─╴application/pgp-encrypted
 └─╴application/octet-stream
   ↧ (decrypts to)
   └─╴text/plain
~~~

The `Subject:` header is successfully obscured.

Note that if this message had been generated without Protected Headers, then an attacker with access to it could have read Subject.
Such an attacker would know details about Alice and Bob's business that they wanted to keep confidential.

The protected headers also protect the authenticity of subject line as well.

The session key for this message's crypto layer is an AES-256 key with value `8df4b2d27d5637138ac6de46415661be0bd01ed12ecf8c1db22a33cf3ede82f2` (in hex).

If Bob's MUA is capable of interpreting these protected headers, it should render the `Subject:` of this message as `BarCorp contract signed, let's go!`.

~~~
@@signed+encrypted.eml@@
~~~

Signed and Encrypted Message with Protected Headers and Legacy Display Part
---------------------------------------------------------------------------

If Alice's MUA wasn't sure whether Bob's MUA would know to render the obscured `Subject:` header correctly, it might include a legacy display part in the cryptographic payload.

This message is structured in the following way:

~~~
└┬╴multipart/encrypted
 ├─╴application/pgp-encrypted
 └─╴application/octet-stream
   ↧ (decrypts to)
   └┬╴multipart/mixed
    ├─╴text/rfc822-headers
    └─╴text/plain
~~~

The example below shows the same message as {{encryptedsigned}}.

If Bob's MUA is capable of handling protected headers, the two messages should render in the same way as the message in {{encryptedsigned}}, because it will know to omit the Legacy Display part as documented in {{no-render-legacy-display}}.

But if Bob's MUA is capable of decryption but is unaware of protected headers, it will likely render the Legacy Display part for him so that he can at least see the originally-intended `Subject:` line.

For this message, the session key is an AES-256 key with value `95a71b0e344cce43a4dd52c5fd01deec5118290bfd0792a8a733c653a12d223e` (in hex).

~~~
@@signed+encrypted+legacy-display.eml@@
~~~

Multilayer Message with Protected Headers
-----------------------------------------

Some mailers may generate signed and encrypted messages with a multilayer cryptographic envelope.
We show here how such a mailer might generate the same message from Alice to Bob.

A typical message like this has the following structure:

~~~
└┬╴multipart/encrypted
 ├─╴application/pgp-encrypted
 └─╴application/octet-stream
  ↧ (decrypts to)
  └┬╴multipart/signed
   ├─╴text/plain
   └─╴application/pgp-signature
~~~

For this message, the session key is an AES-256 key with value `5e67165ed1516333daeba32044f88fd75d4a9485a563d14705e41d31fb61a9e9` (in hex).

~~~
@@multilayer.eml@@
~~~

Multilayer Message with Protected Headers and Legacy Display Part
-----------------------------------------------------------------

And, a mailer that generates a multilayer cryptographic envelope might want to provide a Legacy Display part, if it is unsure of the capabilities of the recipient's MUA.

Such a message might have the following structure:

~~~
└┬╴multipart/encrypted
 ├─╴application/pgp-encrypted
 └─╴application/octet-stream
  ↧ (decrypts to)
  └┬╴multipart/signed
   ├┬╴multipart/mixed
   │├─╴text/rfc822-headers
   │└─╴text/plain
   └─╴application/pgp-signature
~~~

For this message, the session key is an AES-256 key with value `b346a2a50fa0cf62895b74e8c0d2ad9e3ee1f02b5d564c77d879caaee7a0aa70` (in hex).

~~~
@@multilayer+legacy-display.eml@@
~~~

An Unfortunately Complex Example
--------------------------------

For all of the potential complexity of the Cryptographic Envelope, the Cryptographic Payload itself can be complex.
The Cryptographic Envelope in this example is the same as the previous example (multilayer signed encrypted).
The Cryptographic Payload has protected headers and a legacy display part (also the same as the previous example), but in addition Alice's MUA composes a message with both plaintext and HTML variants, and Alice includes a single attachment as well.

While this message is complex, a modern MUA could also plausibly generate such a structure based on reasonable commands from the user composing the message (e.g., Alice composes the message with a rich text editor, and attaches a file to the message).

The key takeaway is that the complexity of the Cryptographic Payload (which may contain a Legacy Display part) is independent of and distinct from the complexity of the Cryptographic Envelope.

This message has the following structure:

~~~
└┬╴multipart/encrypted
 ├─╴application/pgp-encrypted
 └─╴application/octet-stream
  ↧ (decrypts to)
  └┬╴multipart/signed
   ├┬╴multipart/mixed
   │├─╴text/rfc822-headers
   │└┬╴multipart/mixed
   │ ├┬╴multipart/alternative
   │ │├─╴text/plain
   │ │└─╴text/html
   │ └─╴text/x-diff
   └─╴application/pgp-signature
~~~

For this message, the session key is an AES-256 key with value `1c489cfad9f3c0bf3214bf34e6da42b7f64005e59726baa1b17ffdefe6ecbb52` (in hex).

~~~
@@unfortunately-complex.eml@@
~~~

IANA Considerations
===================

FIXME: register flag for legacy-display part

Security Considerations
=======================

This document describes a technique that can be used to defend against two security vulnerabilities in traditional end-to-end encrypted e-mail.

Subject Leak
------------

While e-mail structure considers the Subject header to be part of the message metadata, nearly all users consider the Subject header to be part of the message content.

As such, a user sending end-to-end encrypted e-mail may inadvertently leak sensitive material in the Subject line.

If the user's MUA uses Protected Headers and obscures the Subject header as described in {{encrypted-subject}} then they can avoid this breach of confidentiality.

Signature Replay
----------------

Messages without Protected Headers may be subject to a signature replay attack.
Such an attack works by taking a message delivered in one context (e.g., to someone else, at a different time, with a different subject, in reply to a different message), and replaying it with different message headers.

A MUA that generates all its signed messages with Protected Headers gives recipients the opportunity to avoid falling victim to this attack.

Guidance for how a message recipient can use Protected Headers to defend against a signature replay attack are out of scope for this document.

Privacy Considerations
======================

This document only explicitly contemplates confidentiality protection for the Subject header, but not for other headers which may leak associational metadata.
For example, `From` and `To` and `Cc` and `Reply-To` and `Date` and `Message-Id` and `References` and `In-Reply-To` are not explicitly necessary for messages in transit, since the SMTP envelope carries all necessary routing information, but an encrypted {{RFC2822}} message as described in this document will contain all this associational metadata in the clear.

Although this document does not provide guidance for protecting the privacy of this metadata directly, it offers a platform upon which thoughtful implementations may experiment with obscuring additional e-mail headers.

Document Considerations
=======================

\[ RFC Editor: please remove this section before publication ]

This document is currently edited as markdown.  Minor editorial changes can be suggested via merge requests at https://github.com/autocrypt/protected-headers or by e-mail to the authors.  Please direct all significant commentary to the public IETF LAMPS mailing list: spasm@ietf.org

Document History
----------------

Acknowledgements
================

The set of constructs and algorithms in this document has a previous working title of "Memory Hole", but that title is no longer used as different implementations gained experience in working with it.

These ideas were tested and fine-tuned in part by the loose collaboration of MUA developers known as {{Autocrypt}}.

Additional feedback and useful guidance was contributed by attendees of the OpenPGP e-mail summit ({{OpenPGP-Email-Summit-2019}}).
