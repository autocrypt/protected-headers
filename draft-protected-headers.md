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
 I-D.draft-luck-lamps-pep-header-protection-03:
 I-D.draft-melnikov-lamps-header-protection-00:
 RFC3851:
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
   * *Cryptographic Layer*, *Cryptographic Envelope* and * *Cryptographic Payload* are defined in {{cryptographic-structure}}
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

Note that if a non-Cryptographic Layer intervenes, the inner-most Cryptographic Layer *is not* part of the Cryptographic Envelope (see the example in {{baroque-example}}).

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

As noted in {#simple-cryptographic-payloads}, PGP/MIME applications also have a simpler MIME construction available.

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
Even if a receiving MUA can parse this structure properly, it is nearly impossible to render in a way that the user can reason about the cryptographic properties of part O.


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
   * When encrypting, the Subject line should be obscured (replaced) by the string "..."
   * Step 3. may require adding a `multipart/mixed` MIME wrapper to the Cryptographic Payload, in turn influencing where to inject the headers from step 1.

See below for a more detailed discussion.


Header Copying
--------------

All headers known to the MUA at composition time MUST be copied verbatim into the header of the target MIME part.

The target MIME part shall always be the first MIME part within the Cryptographic Payload. See Examples below for an illustration.

The reason all headers must be copied, is that otherwise it becomes impossible for implementations to reliably detect tampering with the Exposed Headers, which would greatly reduces the strength of the scheme.

Encrypted Subject {#encrypted-subject}
-----------------

When a message is encrypted, the Subject should be obscured by replacing the Exposed Subject with three periods: ...

This value (...) was chosen because it is believed to be language agnostic and avoids communicating any potentially misleading information to the recipient (see Common Pitfalls below for a more detailed discussion).

Obscured Headers
----------------

Due to compatibility and usability concerns, a Mail User Agent SHOULD NOT obscure any of: `From`, `To`, `Cc`, `Message-ID`, `References`, `Reply-To`, (FIXME: MORE?), unless the user has indicated they have security constraints which justify the potential downsides (see Common Pitfalls below for a more detailed discussion).

Aside from that limitation, this specification does not at this time define or limit the methods a MUA may use to convert Exposed Headers into Obscured Headers.

Legacy Display
--------------


Message Interpretation
======================

(Brief discussion about potential strategies to reverse the process above.)


Examples
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



Common Pitfalls and Guidelines
==============================

Misunderstood Obscured Subjects
-------------------------------

(describe why Encrypted Message is a dangerous subject line)


Reply/Forward Losing Subjects
-----------------------------

(describe Re: ...)


Usability Impact of Reduced Metadata
-------------------------------------

(describe the problems ProtonMail/TutaNota have, discuss potential solutions)


Usability Impact of Obscured Message-ID
---------------------------------------

(describe why we don't recommend this just yet)


Usability Impact of Obscured From/To/Cc
---------------------------------------

(describe why we don't recommend this just yet)

Mailinglist mungles From field
------------------------------

(describe the issue, that some mailinglist softwares mungles the From line in order to make sure, that replys go to the list and not to the author. Protected headers break this workaround. See https://cr.yp.to/proto/replyto.html how this should be fixed properly in a MUA)

Comparison with Other Header Protection Schemes
===============================================

S/MIME 3.1 Header Protection
----------------------------

S/MIME 3.1 ({{RFC3851}}) introduces header protection via message/rfc822 header parts.

The problem with this is that legacy clients are likely to interpret such a part as either a forwarded message, or as an unreadable substructure.

forwarded=no
------------

{{I-D.draft-melnikov-lamps-header-protection-00}}

pEp Header protection
---------------------

{{I-D.draft-luck-lamps-pep-header-protection-03}}

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

These ideas were tested and fine-tuned in part by the loose collaboration of MUA developers known as Autocrypt.

Additional feedback and useful guidance was contributed by attendees of the OpenPGP e-mail summit ({{OpenPGP-Email-Summit-2019}}).
