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
 RFC8174:
--- abstract

This document describes a common strategy to extend the cryptographic protections provided by PGP/MIME etc. to also protect message headers. In particular, how to encrypt the Subject line.

--- middle

Introduction
============

MIME Security with OpenPGP and S/MIME standards can provide integrity, authentication, non-repudiation and confidentiality to the body of a MIME e-mail message. However, PGP/MIME ({{RFC3156}}) alone does not protect message headers and the structure to protect headers defined in S/MIME 3.1 ({{RFC3851}}) has not seen widespread adoption.

This document defines a scheme, "Protected Headers for Cryptographic E-mail", which has been adopted by multiple existing e-mail clients in order to extend the cryptographic protections provided by PGP/MIME to also protect the {{RFC2822}} message headers.

In particular, we describe how to encrypt the Subject line and how to preserve backwards compatibility so that an encrypted subject remains available to recipients using software that does not implement support for the Protected Headers scheme.

We also discuss some of the compatibility constraints and usability concerns which motivated the design of the scheme, as well as limitations.

The authors believe the technique is broadly applicable would also apply to other MIME-compatible cryptographic e-mail systems, including S/MIME ({{RFC8551}}).  Furthermore, this technique has already proven itself as a useful building block for other improvements to cryptographic e-mail, such as the Autocrypt Level 1.1 ({{Autocrypt}}) "Gossip" mechanism.


Requirements Language
---------------------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 {{RFC2119}} {{RFC8174}} when, and only when, they appear in all capitals, as shown here.


Terminology
-----------

For the purposes of this document, we define the following concepts:

   * *MUA* is short for Mail User Agent; an e-mail client.
   * *Protection* of message data refers to cryptographic encryption and/or signatures, providing confidentiality, authenticity or both.
   * *Cryptographic Envelope* is all MIME structure directly dictated by the cryptographic e-mail system in use.
   * *Cryptographic Payload* is all message data protected by the Cryptographic Envelope.
   * *Original Headers* are the {{RFC2822}} message headers as known to the sending MUA at the time of message composition.
   * *Protected Headers* are any headers protected by the scheme described in this document.
   * *Exposed Headers* are any headers outside the Cryptographic Payload (protected or not).
   * *Obscured Headers* are any headers which have been modified or removed from the set of Exposed Headers.
   * *Legacy Display Part* is a MIME construct which guarantees visibility of data from the Original Headers which may have been removed or obscured from the Unprotected Headers.

The Cryptographic Envelope fully encloses the Cryptographic Payload, whether the message is signed or encrypted. The Original Headers, aside from Content-Type headers which directly pertain to the cryptographic structure, are considered to be outside of both.


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

A generating MUA that wants to make an obscured Subject (or any other typically visible header) visible to a recipient using a legacy MUA SHOULD modify the Cryptographic Payload by wrapping the intended body of the message in a `multipart/mixed` MIME part that prefixes the intended body with a Legacy Display part.

The Legacy Display part MUST be of Content-Type `text/rfc822-headers`, and MUST contain a `protected-headers` parameter whose value is `v1`.
It SHOULD be marked with `Content-Disposition: inline` to encourage recipients to render it.

The conents of the Legacy Display part MUST be only the typically visible headers that the sending MUA intends to obscure after encryption.

The original body (now a subpart) SHOULD also be marked with `Content-Disposition: inline` to discourage legacy clients from presenting it as an attachment.

### Legacy Display Transformation {#legacy-display-transformation}

Consider a message whose Cryptographic Payload, before encrypting, that would have a traditional `multipart/alternative` structure:

    X └┬╴multipart/alternative
    Y  ├─╴text/plain
    Z  └─╴text/html

When adding a Legacy Display part, this structure becomes:

    V └┬╴multipart/mixed
    W  ├─╴text/rfc-822-headers ("Legacy Display" part)
    X  └┬╴multipart/alternative ("original body")
    Y   ├─╴text/plain
    Z   └─╴text/html

Note that with the inclusion of the Legacy Display part, the Cryptographic Payload is the `multipart/mixed` part (part `V` in the example above), so Protected Headers should be placed at that part.

### When to Generate Legacy Display

A MUA SHOULD transform a Cryptographic Payload to include a Legacy Display part only when:

 - The message is going to be encrypted, and
 - At least one typically visible header (see {{#typically-visible-header}}) is going to be obscured

Additionally, if the sender knows that the recipient's MUA is capable of interpreting Protected Headers, it SHOULD NOT attempt to include a Legacy Display part.
(Signalling such a capability is out of scope for this document)

Message Rendering: Omitting a Legacy Display Part
-------------------------------------------------

A MUA that understands Protected Headers may receive an encrypted message that contains a Legacy Display part.
Such an MUA SHOULD avoid rendering the Legacy Display part to the user at all, since it knows and can render the actual Protected Headers.

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
