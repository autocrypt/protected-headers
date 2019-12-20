---
title: Protected Headers for Cryptographic E-mail
docname: draft-autocrypt-lamps-protected-headers-03
date: 2019-12-20
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
    name: Bjarni Rúnar Einarsson
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
 xkcd936:
    target: https://www.xkcd.com/936/
    title: "xkcd: Password Strength"
    author: 
      name: Randall Munroe
      ins: R. Munroe
      org: xkcd
    date: 2011-08-10
 I-D.draft-bre-openpgp-samples-00:
 I-D.draft-dkg-lamps-samples-01:
 I-D.draft-luck-lamps-pep-header-protection-03:
 I-D.draft-ietf-lamps-header-protection-requirements-01:
 RFC2634:
 RFC3274:
 RFC3851:
 RFC6736:
 RFC7508:
 RFC8551:
normative:
 RFC2119:
 RFC3156:
 RFC4880:
 RFC5322:
 RFC8174:
--- abstract

This document describes a common strategy to extend the end-to-end cryptographic protections provided by PGP/MIME, etc. to protect message headers in addition to message bodies.
In addition to protecting the authenticity and integrity of headers via signatures, it also describes how to preserve the confidentiality of the Subject header.

--- middle

Introduction
============

E-mail end-to-end security with OpenPGP and S/MIME standards can provide integrity, authentication, non-repudiation and confidentiality to the body of a MIME e-mail message.
However, PGP/MIME ({{RFC3156}}) alone does not protect message headers.
And the structure to protect headers defined in S/MIME 3.1 ({{RFC3851}}) has not seen widespread adoption.

This document defines a scheme, "Protected Headers for Cryptographic E-mail", which has been adopted by multiple existing e-mail clients in order to extend the cryptographic protections provided by PGP/MIME to also protect the message headers.
This scheme is also applicable to S/MIME {{RFC8551}}.

This document describes how these protections can be applied to cryptographically signed messages, and also discusses some of the challenges of encrypting many transit-oriented headers.

It offers guidance for protecting the confidentiality of non-transit-oriented headers like Subject, and also offers a means to preserve backwards compatibility so that an encrypted Subject remains available to recipients using software that does not implement support for the Protected Headers scheme.

The document also discusses some of the compatibility constraints and usability concerns which motivated the design of the scheme, as well as limitations and a comparison with other proposals.

This technique has already proven itself as a useful building block for other improvements to cryptographic e-mail, such as the Autocrypt Level 1.1 ({{Autocrypt}}) "Gossip" mechanism.


Requirements Language
---------------------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 {{RFC2119}} {{RFC8174}} when, and only when, they appear in all capitals, as shown here.


Terminology
-----------

For the purposes of this document, we define the following concepts:

   * *MUA* is short for Mail User Agent; an e-mail client.
   * *Protection* of message data refers to cryptographic encryption and/or signatures, providing confidentiality, authenticity or both.
   * *Cryptographic Layer*, *Cryptographic Envelope* and *Cryptographic Payload* are defined in {{cryptographic-structure}}
   * *Original Headers* are the {{RFC5322}} message headers as known to the sending MUA at the time of message composition.
   * *Protected Headers* are any headers protected by the scheme described in this document.
   * *Exposed Headers* are any headers outside the Cryptographic Payload (protected or not).
   * *Obscured Headers* are any Protected Headers which have been modified or removed from the set of Exposed Headers.
   * *Legacy Display Part* is a MIME construct which provides visibility for users of legacy clients of data from the Original Headers which may have been removed or obscured from the Exposed Headers. It is defined in {{legacy-display}}.
   * *User-Facing Headers* are explained and enumerated in {{user-facing-headers}}.
   * *Structural Headers* are documented in {{structural-headers}}.


### User-Facing Headers {#user-facing-headers}

Of all the headers that an e-mail message may contain, only a handful are typically presented directly to the user.
The user-facing headers are:

 - `Subject`
 - `From`
 - `To`
 - `Cc`
 - `Date`
 - `Reply-To`
 - `Followup-To`

The above is a complete list.  No other headers are considered "user-facing".

Other headers may affect the visible rendering of the message (e.g., `References` and `In-Reply-To` may affect the placement of a message in a threaded discussion), but they are not directly displayed to the user and so are not considered "user-facing" for the purposes of this document.

### Structural Headers {#structural-headers}

A message header whose name begins with `Content-` is referred to in this document as a "structural" header.

These headers indicate something about the specific MIME part they are attached to, and cannot be transferred or copied to other parts without endangering the readability of the message.

This includes (but is not limited to):

 - `Content-Type`
 - `Content-Transfer-Encoding`
 - `Content-Disposition`

Note that no "user-facing" headers ({{user-facing-headers}}) are also "structural" headers.  Of course, many headers are neither "user-facing" nor "structural".

FIXME: are there any non-`Content-*` headers we should consider as structural?

Protected Headers Summary
=========================

The Protected Headers scheme relies on three backward-compatible changes to a cryptographically-protected e-mail message:

 - Headers known to the composing MUA at message composition time are (in addition to their typical placement as Exposed Headers on the outside of the message) also present in the MIME header of the root of the Cryptographic Payload.
   These Protected Headers share cryptographic properties with the rest of the Cryptographic Payload.
 - When the Cryptographic Envelope includes encryption, any Exposed Header MAY be *obscured* by a transformation (including deletion).
 - If the composing MUA intends to obscure any user-facing headers, it MAY add a decorative "Legacy Display" MIME part to the Cryptographic Payload which additionally duplicates the original values of the obscured user-facing headers.

When a composing MUA encrypts a message, it SHOULD obscure the `Subject:` header, by using the literal string `...` (three U+002E FULL STOP characters) as the value of the exposed `Subject:` header.

When a receiving MUA encounters a message with a Cryptographic Envelope, it treats the headers of the Cryptographic Payload as belonging to the message itself, not just the subpart.
In particular, when rendering a header for any such message, the renderer SHOULD prefer the header's Protected value over its Exposed value.

A receiving MUA that understands Protected Headers and discovers a Legacy Display part SHOULD hide the Legacy Display part when rendering the message.

The following sections contain more detailed discussion.

Cryptographic MIME Message Structure {#cryptographic-structure}
====================================

Implementations use the structure of an e-mail message to protect the headers.
This section establishes some conventions about how to think about message structure.

Cryptographic Layers {#cryptographic-layer}
--------------------

"Cryptographic Layer" refers to a MIME substructure that supplies some cryptographic protections to an internal MIME subtree.
The internal subtree is known as the "protected part" though of course it may itself be a multipart object.

In the diagrams below, <u>↧</u> indicates "decrypts to", and <u>⇩</u> indicates "unwraps to".

### PGP/MIME Cryptographic Layers

For PGP/MIME {{RFC3156}} there are two forms of Cryptographic Layers, signing and encryption.

#### PGP/MIME Signing Cryptographic Layer (multipart/signed) {#pgpmime-multipart-signed}

    └┬╴multipart/signed; protocol="application/pgp-signature"
     ├─╴[protected part]
     └─╴application/pgp-signature

#### PGP/MIME Encryption Cryptographic Layer (multipart/encrypted) {#pgpmime-multipart-encrypted}

    └┬╴multipart/encrypted
     ├─╴application/pgp-encrypted
     └─╴application/octet-stream
      ↧ (decrypts to)
      └─╴[protected part]

### S/MIME Cryptographic Layers

For S/MIME {{RFC8551}}, there are four forms of Cryptographic Layers: multipart/signed, PKCS#7 signed-data, PKCS7 enveloped-data, PKCS7 authEnveloped-data.

#### S/MIME Multipart Signed Cryptographic Layer {#smime-multipart-signed}

    └┬╴multipart/signed; protocol="application/pkcs7-signature"
     ├─╴[protected part]
     └─╴application/pkcs7-signature

#### S/MIME PKCS7 signed-data Cryptographic Layer {#smime-pkcs7-signed-data}

    └─╴application/pkcs7-mime; smime-type="signed-data"
     ⇩ (unwraps to)
     └─╴[protected part]
     
#### S/MIME PKCS7 enveloped-data Cryptographic Layer {#smime-pkcs7-enveloped-data}

    └─╴application/pkcs7-mime; smime-type="enveloped-data"
     ↧ (decrypts to)
     └─╴[protected part]
     
#### S/MIME PKCS7 authEnveloped-data Cryptographic Layer {#smime-pkcs7-authenveloped-data}

    └─╴application/pkcs7-mime; smime-type="authEnveloped-data"
     ↧ (decrypts to)
     └─╴[protected part]


Note that `enveloped-data` ({{smime-pkcs7-enveloped-data}}) and `authEnveloped-data` ({{smime-pkcs7-authenveloped-data}}) have identical message structure and semantics.
The only difference between the two is ciphertext malleability.

The examples in this document only include `enveloped-data`, but the implications for that layer apply to `authEnveloped-data` as well.

#### PKCS7 Compression is NOT a Cryptographic Layer

The Cryptographic Message Syntax (CMS) provides a MIME compression layer (`smime-type="compressed-data"`), as defined in {{RFC3274}}.
While the compression layer is technically a part of CMS, it is not considered a Cryptographic Layer for the purposes of this document.


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

As described above, if the "protected part" identified in {{pgpmime-multipart-signed}} or {{pgpmime-multipart-encrypted}} is not itself a Cryptographic Layer, that part *is* the Cryptographic Payload.

If the application wants to generate a message that is both encrypted and signed, it MAY use the simple MIME structure from {{pgpmime-multipart-encrypted}} by ensuring that the {{RFC4880}} Encrypted Message within the `application/octet-stream` part contains an {{RFC4880}} Signed Message.

### Multilayer Cryptographic Envelopes {#multilayer-cryptographic-envelopes}

It is possible to construct a Cryptographic Envelope consisting of multiple layers for PGP/MIME, typically of the following structure:

    A └┬╴multipart/encrypted
    B  ├─╴application/pgp-encrypted
    C  └─╴application/octet-stream
    D   ↧ (decrypts to)
    E   └┬╴multipart/signed
    F    ├─╴[Cryptographic Payload]
    G    └─╴application/pgp-signature

When handling such a message, the properties of the Cryptographic Envelope are derived from the series `A`, `E`.

As noted in {{simple-cryptographic-payloads}}, PGP/MIME applications also have a simpler MIME construction available with the same cryptographic properties.

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

The 3 Cryptographic Layers in such a message are rooted in parts `H`, `L`, and `N`.
But the Cryptographic Envelope of the message consists only of the properties derived from the series `H`, `L`.
The Cryptographic Payload of the message is part `M`.

It is NOT RECOMMENDED to generate messages with such complicated structures.
Even if a receiving MUA can parse this structure properly, it is nearly impossible to render in a way that the user can reason about the cryptographic properties of part `O` compared to part `Q`.


Exposed Headers are Outside
---------------------------

The Cryptographic Envelope fully encloses the Cryptographic Payload, whether the message is signed or encrypted or both.
The Exposed Headers are considered to be outside of both.


Message Composition
===================

This section describes the composition of a cryptographically-protected message with Protected Headers.

We document legacy composition of cryptographically-protected messages (without protected headers) in {{legacy-composition}}, and then describe a revised version of that algorithm in {{protected-header-composition}} that produces conformant Protected Headers.

Copying All Headers
-------------------

All non-structural headers known to the composing MUA are copied to the MIME header of the Cryptographic Payload.
The composing MUA SHOULD protect all known non-structural headers in this way.

If the composing MUA omits protection for some of the headers, the receiving MUA will have difficulty reasoning about the integrity of the headers (see {{signature-replay}}).

Confidential Subject {#confidential-subject}
--------------------

When a message is encrypted, the Subject should be obscured by replacing the Exposed Subject with three periods: `...`

This value (`...`) was chosen because it is believed to be language agnostic and avoids communicating any potentially misleading information to the recipient (see {{misunderstood-obscured-subjects}} for a more detailed discussion).

Obscured Headers
----------------

Due to compatibility and usability concerns, a Mail User Agent SHOULD NOT obscure any of: `From`, `To`, `Cc`, `Message-ID`, `References`, `Reply-To`, `In-Reply-To`, (FIXME: MORE?) unless the user has indicated they have security constraints which justify the potential downsides (see {{common-pitfalls}} for a more detailed discussion).

Aside from that limitation, this specification does not at this time define or limit the methods a MUA may use to convert Exposed Headers into Obscured Headers.

Message Composition without Protected Headers {#legacy-composition}
---------------------------------------------

This section roughly describes the steps that a legacy MUA might use to compose a cryptographically-protected message *without* Protected Headers.

The message composition algorithm takes three parameters:

- `origbody`: the traditional unprotected message body as a well-formed MIME tree (possibly just a single MIME leaf part).
  As a well-formed MIME tree, `origbody` already has structural headers present (see {{structural-headers}}).
- `origheaders`: the intended non-structural headers for the message, represented here as a table mapping from header names to header values..
  For example, `origheaders['From']` refers to the value of the `From` header that the composing MUA would typically place on the message before sending it.
- `crypto`: The series of cryptographic protections to apply (for example, "sign with the secret key corresponding to OpenPGP certificate X, then encrypt to OpenPGP certificates X and Y").
  This is a routine that accepts a MIME tree as input (the Cryptographic Payload), wraps the input in the appropriate Cryptographic Envelope, and returns the resultant MIME tree as output, 

The algorithm returns a MIME object that is ready to be injected into the mail system:

- Apply `crypto` to `origbody`, yielding MIME tree `output`
- For header name `h` in `origheaders`:
  - Set header `h` of `output` to `origheaders[h]`
- Return `output`

Message Composition with Protected Headers {#protected-header-composition}
------------------------------------------

A reasonable sequential algorithm for composing a message *with* protected headers takes two more parameters in addition to `origbody`, `origheaders`, and `crypto`:

- `obscures`: a table of headers to be obscured during encryption, mapping header names to their obscuring values.
  For example, this document recommends only obscuring the subject, so that would be represented by the single-entry table `obscures = {'Subject': '...'}`.
  If header `Foo` is to be deleted entirely, `obscures['Foo']` should be set to the special value `null`.
- `legacy`: a boolean value, indicating whether any recipient of the message is believed to have a legacy client (that is, a MUA that is capable of decryption, but does not understand protected headers).

The revised algorithm for applying cryptographic protection to a message is as follows:

- if `crypto` contains encryption, and `legacy` is `true`, and `obscures` contains any user-facing headers (see {{user-facing-headers}}), wrap `orig` in a structure that carries a Legacy Display part:
  - Create a new MIME leaf part `legacydisplay` with header `Content-Type: text/plain; protected-headers="v1"`
  - For each obscured header name `obh` in `obscures`:
     - If `obh` is user-facing:
        - Add `obh: origheaders[ob]` to the body of `legacydisplay`.  For example, if `origheaders['Subject']` is `lunch plans?`, then add the line `Subject: lunch plans?` to the body of `legacydisplay`
  - Construct a new MIME part `wrapper` with `Content-Type: multipart/mixed`
  - Give `wrapper` exactly two subparts: `legacydisplay` and `origbody`, in that order.
  - Let `payload` be MIME part `wrapper`
- Otherwise:
  - Let `payload` be MIME part `origbody`
- For each header name `h` in `origheaders`:
  - Set header `h` of MIME part `payload` to `origheaders[h]`
- Set the `protected-headers` parameter on the `Content-Type` of `payload` to `v1`
- Apply `crypto` to `payload`, producing MIME tree `output`
- If `crypto` contains encryption:
  - For each obscured header name `obh` in `obscures`:
    - If `obscures[obh]` is `null`:
      - Drop `obh` from `origheaders`
    - Else:
      - Set `origheaders[obh]` to `obscures[obh]`
- For each header name `h` in `origheaders`:
  - Set header `h` of `output` to `origheaders[h]`
- return `output`

Note that both new parameters, `obscured` and `legacy`, are effectively ignored if `crypto` does not contain encryption.
This is by design, because they are irrelevant for signed-only cryptographic protections.

Legacy Display {#legacy-display}
==============

MUAs typically display user-facing headers ({{user-facing-headers}}) directly to the user.
An encrypted message may be read by a decryption-capable legacy MUA that is unaware of this standard.
The user of such a legacy client risks losing access to any obscured headers.

This section presents a workaround to mitigate this risk by restructuring the Cryptographic Payload before encrypting to include a "Legacy Display" part.

Message Generation: Including a Legacy Display Part
---------------------------------------------------

A generating MUA that wants to make an Obscured Subject (or any other user-facing header) visible to a recipient using a legacy MUA SHOULD modify the Cryptographic Payload by wrapping the intended body of the message in a `multipart/mixed` MIME part that prefixes the intended body with a Legacy Display part.

The Legacy Display part MUST be of Content-Type `text/plain` or `text/rfc822-headers` (`text/plain` is RECOMMENDED), and MUST contain a `protected-headers` parameter whose value is `v1`.
It SHOULD be marked with `Content-Disposition: inline` to encourage recipients to render it.

The contents of the Legacy Display part MUST be only the user-facing headers that the sending MUA intends to obscure after encryption.

The original body (now a subpart) SHOULD also be marked with `Content-Disposition: inline` to discourage legacy clients from presenting it as an attachment.

### Legacy Display Transformation {#legacy-display-transformation}

Consider a message whose Cryptographic Payload, before encrypting, that would have a traditional `multipart/alternative` structure:

    X └┬╴multipart/alternative
    Y  ├─╴text/plain
    Z  └─╴text/html

When adding a Legacy Display part, this structure becomes:

    V └┬╴multipart/mixed
    W  ├─╴text/plain ("Legacy Display" part)
    X  └┬╴multipart/alternative ("original body")
    Y   ├─╴text/plain
    Z   └─╴text/html

Note that with the inclusion of the Legacy Display part, the Cryptographic Payload is the `multipart/mixed` part (part `V` in the example above), so Protected Headers should be placed at that part.

### When to Generate Legacy Display

A MUA SHOULD transform a Cryptographic Payload to include a Legacy Display part only when:

 - The message is going to be encrypted, and
 - At least one user-facing header (see {{user-facing-headers}}) is going to be obscured

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
  - The first subpart of the Cryptographic Payload must have a `Content-Type` of `text/plain` or `text/rfc822-headers`
  - The first subpart of the Cryptographic Payload's `Content-Type` must contain a property of `protected-headers`, and its value must be `v1`.
 - If all of the above are true, then the first subpart is the Legacy Display part, and the second subpart is the "original body".  Otherwise, the message does not have a Legacy Display part.

Legacy Display is Decorative and Transitional
---------------------------------------------

As the above makes clear, the Legacy Display part is strictly decorative, for the benefit of legacy decryption-capable MUAs that may handle the message.
As such, the existence of the Legacy Display part and its `multipart/mixed` wrapper are part of a transition plan.

As the number of decryption-capable clients that understand Protected Headers grows in comparison to the number of legacy decryption-capable clients, it is expected that some senders will decide to stop generating Legacy Display parts entirely.

A MUA developer concerned about accessiblity of the Subject header for their users of encrypted mail when Legacy Display parts are omitted SHOULD implement the Protected Headers scheme described in this document.


Message Interpretation
======================

This document does not currently provide comprehensive recommendations on how to interpret Protected Headers. This is deliberate; research and development is still ongoing. We also recognize that the tolerance of different user groups for false positives (benign conditions misidentified as security risks), vs. their need for strong protections varies a great deal and different MUAs will take different approaches as a result.

Some common approaches are discussed below.

Reverse-Copying
---------------

One strategy for interpreting Protected Headers on an incoming message is to simply ignore any Exposed Header for which a Protected counterpart is available.
This is often implemented as a copy operation (copying header back out of the Cryptographic Payload into the main message header) within the code which takes care of parsing the message.

A MUA implementing this strategy should pay special attention to any user facing headers ({{user-facing-headers}}).
If a message has Protected Headers, and a user-facing header is among the Exposed Headers but missing from the Protected Headers, then an MUA implementing this strategy SHOULD delete the identified Exposed Header before presenting the message to the user.

This strategy does not risk raising a false alarm about harmless deviations, but conversely it does nothing to inform the user if they are under attack.
This strategy does successfully mitigate and thwart some attacks, including signature replay attacks ({{signature-replay}}) and participant modification attacks ({{participant-modification}}).

Signature Invalidation
----------------------

An alternate strategy for interpreting Protected Headers is to consider the cryptographic signature on a message to be invalid if the Exposed Headers deviate from their Protected counterparts.

This state should be presented to the user using the same interface as other signature verification failures.

A MUA implementing this strategy MAY want to make a special exception for the `Subject:` header, to avoid invalidating the signature on any signed and encrypted message with a confidential subject.

Note that simple signature invalidation may be insufficient to defend against a participant modification attack ({{participant-modification}}).

The Legacy Display Part
-----------------------

This part is purely decorative, for the benefit of any recipient using a legacy decryption-capable MUA.
See {{no-render-legacy-display}} for details and recommendations on how to handle the Legacy Display part.

Replying to a Message with Obscured Headers
-------------------------------------------

When replying to a message, many MUAs copy headers from the original message into their reply.

When replying to an encrypted message, users expect the replying MUA to generate an encrypted message if possible.
If encryption is not possible, and the reply will be cleartext, users typically want the MUA to avoid leaking previously-encrypted content into the cleartext of the reply.

For this reason, an MUA replying to an encrypted message with Obscured Headers SHOULD NOT leak the cleartext of any Obscured Headers into the cleartext of the reply, whether encrypted or not.

In particular, the contents of any Obscured Protected Header from the original message SHOULD NOT be placed in the Exposed Headers of the reply message.


Common Pitfalls and Guidelines {#common-pitfalls}
==============================

Among the MUA authors who already implemented most of this specification,
several alternative or more encompassing specifications were discussed and
sometimes tried out in practice. This section highlights a few "pitfalls" and
guidelines based on these discussions and lessons learned. 

Misunderstood Obscured Subjects {#misunderstood-obscured-subjects}
-------------------------------

There were many discussions around what text phrase to use to obscure the `Subject:`.
Text phrases such as `Encrypted Message` were tried but resulted in both localization problems and user confusion. 

If the natural language phrase for the obscured `Subject:` is not localized (e.g. just English `Encrypted Message`), then it may be incomprehensible to a non-English-speaking recipient who uses a legacy MUA that renders the obscured `Subject:` directly.

On the other hand, if it is localized based on the sender's MUA language settings, there is no guarantee that the recipient prefers the same language as the sender (consider a German speaker sending English text to an Anglophone).
There is no standard way for a sending MUA to infer the language preferred by the recipient (aside from statistical inference of language based on the composed message, which would in turn leak information about the supposedly-confidential message body).

Furthermore, implementors found that the phrase `Encrypted Message` in the subject line was sometimes understood by users to be an indication from the MUA that the message was actually encrypted.
In practice, when some MUA failed to encrypt a message in a thread that started off with an obscured `Subject:`, the value `Re: Encrypted Message` was retained even on those cleartext replies, resulting in user confusion.

In contrast, using `...` as the obscured `Subject:` was less likely to be seen as an indicator from the MUA of message encryption, and it also neatly sidesteps the localization problems. 

Reply/Forward Losing Subjects
-----------------------------

When the user of a legacy MUA replies to or forwards a message where the Subject has been obscured, it is likely that the new subject will be `Fwd: ...` or `Re: ...` (or the localized equivalent).
This breaks an important feature: people are used to continuity of subject within a thread.  It is especially unfortunate when a new participant is added to a conversation who never saw the original subject.

At this time, there is no known workaround for this problem. The only solution is to upgrade the MUA to support Protected Headers.

The authors consider this to be only a minor concern in cases where encryption is being used because confidentiality is important.
However, in more opportunistic cases, where encryption is being used routinely regardless of the sensitivity of message contents, this cost becomes higher. 


Usability Impact of Reduced Metadata
-------------------------------------

Many mail user agents maintain an index of message metadata (including header data), which is used to rapidly construct mailbox overviews and search result listings.
If the process which generates this index does not have access to the encrypted payload of a message, or does not implement Protected Headers, then the index will only contain the obscured versions Exposed Headers, in particular an obscured Subject of `...`.

For sensitive message content, especially in a hosted MUA-as-a-service situation ("webmail") where the metadata index is maintained and stored by a third party, this may be considered a feature as the subject is protected from the third-party.
However, for more routine communications, this harms usability and goes against user expectations.

Two simple workarounds exist for this use case:

   1. If the metadata index is considered secure enough to handle confidential data,
      the protected content may be stored directly in the index once it has been decrypted.
   2. If the metadata index is not trusted, the protected content could be re-encrypted
      and encrypted versions stored in the index instead, which are then decrypted by
      the client at display time.

In both cases, the process which decrypts the message and processes the Protected Headers must be able to update the metadata index.

FIXME: add notes about research topics and other non-simple workarounds, like oblivious server-side indexing, or searching on encrypted data.

Usability Impact of Obscured Message-ID {#obscured-message-id}
---------------------------------------

Current MUA implementations rely on the outermost Message-ID 
for message processing and indexing purposes. This processing
often happens before any decryption is even attempted. 
Attempting to send a message with an obscured Message-ID header
would result in several MUAs not correctly processing the message,
and would likely be seen as a degradation by users. 

Furthermore, a legacy MUA replying to a message with an obscured `Message-ID:` would be likely to produce threading information (`References:`, `In-Reply-To:`) that would be misunderstood by the original sender.
Implementors generally disapprove of breaking threads.

Usability Impact of Obscured From/To/Cc
---------------------------------------

The impact of obscuring `From:`, `To:`, and `Cc:` headers has similar issues as discussed with obscuring the `Message-ID:` header in {{obscured-message-id}}.

In addition, obscuring these headers is likely to cause difficulties for a legacy client attempting formulate a correct reply (or "reply all") to a given message.

Mailing List Header Modifications
---------------------------------

Some popular mailing-list implementations will modify the Exposed Headers of a message in specific, benign ways. In particular, it is common to add markers to the `Subject` line, and it is also common to modify either `From` or `Reply-To` in order to make sure replies go to the list instead of directly to the author of an individual post.

Depending on how the MUA resolves discrepancies between the Protected Headers and the Exposed Headers of a received message, these mailing list "features" may either break or the MUA may incorrectly interpret them as a security breach.

Implementors may for this reason choose to implement slightly different strategies for resolving discrepancies, if a message is known to come from such a mailing list. MUAs should at the very least avoid presenting false alarms in such cases.

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

Furthermore, formulating a reply to such a message on a legacy client can also leave the user with badly-structured quoted and attributed content.

Additionally, a message deliberately forwarded in its own right (without preamble or adjacent explanatory notes) could potentially be confused with a message using the declared structure.

The mechanism described here allows cryptographically-incapable legacy MUAs to read and handle cleartext signed messages without any modifications, and permits cryptographically-capable legacy MUAs to handle encrypted messages without any modifications.

In particular, the Legacy Display part described in {{legacy-display}} makes it feasible for a conformant MUA to generate messages with obscured Subject lines that nonetheless give access to the obscured Subject header for recipients with legacy MUAs.

The Content-Type Property "forwarded=no" {forwarded=no}
----------------------------------------

Section A.1.2 of {{I-D.draft-ietf-lamps-header-protection-requirements-01}} refers to a proposal that attempts to mitigate one of the drawbacks of the scheme described in S/MIME 3.1 ({{smime-31}}).

In particular, using the Content-Type property `forwarded="no"` allows *non-legacy* clients to distinguish between deliberately forwarded messages and those intended to use the defined structure for header protection.

However, this fix has no impact on the confusion experienced by legacy clients.

pEp Header Protection
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

Triple-Wrapping
---------------

{{RFC2634}} defines "Triple Wrapping" as a means of providing cleartext signatures over signed and encrypted material.
This can be used in combination with the mechanism described in {{RFC7508}} to authenticate some headers for transport using S/MIME.

But it does not offer confidentiality protection for the protected headers, and the signer of the outer layer of a triple-wrapped message may not be the originator of the message either.

In practice on today's Internet, DKIM ({{RFC6736}} provides a more widely-accepted cryptographic header-verification-for-transport mechanism  than triple-wrapped messages.


Test Vectors {#test-vectors}
============

The subsections below provide example messages that implement the Protected Header scheme.

The secret keys and OpenPGP certificates from {{I-D.draft-bre-openpgp-samples-00}} can be used to decrypt and verify the PGP/MIME messages.

The secret keys and X.509 certificates from {{I-D.draft-dkg-lamps-samples-01}} can be used to decrypt and verify the S/MIME messages.

All test vectors are provided in textual source form as {{RFC5322}} messages.

For easy access to these test vectors, they are also available at `imap://bob@protected-headers.cmrg.net/inbox` using any password for authentication.
This IMAP account is read-only, and any flags set or cleared on the messages will persist only for the duration of the specific IMAP session.

Signed PGP/MIME Message with Protected Headers {#test-vector-pgp-signed-only}
----------------------------------------------

This shows a clearsigned PGP/MIME message.  Its MIME message structure is:

~~~
└┬╴multipart/signed
 ├─╴text/plain ← Cryptographic Payload
 └─╴application/pgp-signature
~~~

Note that if this message had been generated without Protected Headers, then an attacker with access to it could modify the Subject without invalidating the signature.
Such an attacker could cause Bob to think that Alice wanted to cancel the contract with BarCorp instead of FooCorp.

~~~
@@pgpmime-signed.eml@@
~~~

S/MIME multipart/signed Message with Protected Headers {#test-vector-smime-multipart-signed}
------------------------------------------------------

This shows a signed-only S/MIME message using the `multipart/signed` style (see Section 3.5.3 of {{RFC8551}}).  Its MIME message structure is:

~~~
└┬╴multipart/signed
 ├─╴text/plain ← Cryptographic Payload
 └─╴application/pkcs7-signature
~~~

Note that if this message had been generated without Protected Headers, then an attacker with access to it could modify the Subject without invalidating the signature.
Such an attacker could cause Bob to think that Alice wanted to cancel the contract with BarCorp instead of FooCorp.

~~~
@@smime-multipart-signed.eml@@
~~~

S/MIME application/pkcs7-mime SignedData Message with Protected Headers {#test-vector-smime-onepart-signed}
-----------------------------------------------------------------------

This shows a signed-only S/MIME message using the `multipart/pkcs7-mime` style (see Section 3.5.2 of {{RFC8551}}).  Its MIME message structure is:

~~~
└─╴application/pkcs7-mime smime-type="signed-data"
 ⇩ (unwraps to)
 └─╴text/plain ← Cryptographic Payload
~~~

Note that if this message had been generated without Protected Headers, then an attacker with access to it could modify the Subject without invalidating the signature.
Such an attacker could cause Bob to think that Alice wanted to cancel the contract with BarCorp instead of FooCorp.

~~~
@@smime-onepart-signed.eml@@
~~~

Unwrapping the PKCS7 SignedData yields the following internal message:

~~~
@@smime-onepart-signed.inner@@
~~~

Signed and Encrypted PGP/MIME Message with Protected Headers {#pgp-encryptedsigned}
------------------------------------------------------------

This shows a simple encrypted PGP/MIME message with protected headers.
The encryption also contains a signature in the OpenPGP Message structure.
Its MIME message structure is:

~~~
└┬╴multipart/encrypted
 ├─╴application/pgp-encrypted
 └─╴application/octet-stream
   ↧ (decrypts to)
   └─╴text/plain ← Cryptographic Payload
~~~

The `Subject:` header is successfully obscured.

Note that if this message had been generated without Protected Headers, then an attacker with access to it could have read the Subject.
Such an attacker would know details about Alice and Bob's business that they wanted to keep confidential.

The protected headers also protect the authenticity of subject line as well.

The session key for this message's Cryptographic Layer is an AES-256 key with value `8df4b2d27d5637138ac6de46415661be0bd01ed12ecf8c1db22a33cf3ede82f2` (in hex).

If Bob's MUA is capable of interpreting these protected headers, it should render the `Subject:` of this message as `BarCorp contract signed, let's go!`.

~~~
@@pgpmime-sign+enc.eml@@
~~~

Unwrapping the Cryptographic Layer yields the following content:

~~~
@@pgpmime-sign+enc.inner@@
~~~

Signed and Encrypted S/MIME Message with Protected Headers {#smime-sign-enc}
----------------------------------------------------------

This shows a simple signed and encrypted S/MIME message with protected headers.
Its MIME message structure is:

~~~
└─╴application/pkcs7-mime smime-type="enveloped-data"
 ↧ (decrypts to)
 └─╴application/pkcs7-mime smime-type="signed-data"
  ⇩ (unwraps to)
  └─╴text/plain ← Cryptographic Payload
~~~

The `Subject:` header is successfully obscured.

Note that if this message had been generated without Protected Headers, then an attacker with access to it could have read the Subject.
Such an attacker would know details about Alice and Bob's business that they wanted to keep confidential.

The protected headers also protect the authenticity of subject line as well.

The session key for this message's Cryptographic Layer is an AES-256 key with value `12e2551896f77e24ce080153cda27dddd789d399bdd87757e65655d956f5f0b7` (in hex).

If Bob's MUA is capable of interpreting these protected headers, it should render the `Subject:` of this message as `BarCorp contract signed, let's go!`.

~~~
@@smime-sign+enc.eml@@
~~~

Unwrapping the outer Cryptographic Layer of this message yields the following MIME part (with its own Cryptographic Layer):

~~~
@@smime-sign+enc.inner@@
~~~

Unwrapping the inner Cryptographic Layer yields the Cryptographic Payload:

~~~
@@smime-sign+enc.inner.inner@@
~~~


Signed and Encrypted PGP/MIME Message with Protected Headers and Legacy Display Part
------------------------------------------------------------------------------------

If Alice's MUA wasn't sure whether Bob's MUA would know to render the obscured `Subject:` header correctly, it might include a legacy display part in the cryptographic payload.

This PGP/MIME message is structured in the following way:

~~~
└┬╴multipart/encrypted
 ├─╴application/pgp-encrypted
 └─╴application/octet-stream
   ↧ (decrypts to)
   └┬╴multipart/mixed ← Cryptographic Payload
    ├─╴text/plain ← Legacy Display Part
    └─╴text/plain
~~~

The example below shows the same message as {{pgp-encryptedsigned}}.

If Bob's MUA is capable of handling protected headers, the two messages should render in the same way as the message in {{pgp-encryptedsigned}}, because it will know to omit the Legacy Display part as documented in {{no-render-legacy-display}}.

But if Bob's MUA is capable of decryption but is unaware of protected headers, it will likely render the Legacy Display part for him so that he can at least see the originally-intended `Subject:` line.

For this message, the session key is an AES-256 key with value `95a71b0e344cce43a4dd52c5fd01deec5118290bfd0792a8a733c653a12d223e` (in hex).

~~~
@@pgpmime-sign+enc+legacy-disp.eml@@
~~~

Decrypting the Cryptographic Layer yields the following content:

~~~
@@pgpmime-sign+enc+legacy-disp.inner@@
~~~

Multilayer PGP/MIME Message with Protected Headers
--------------------------------------------------

Some mailers may generate signed and encrypted messages with a multilayer cryptographic envelope.
We show here how such a mailer might generate the same message as {{pgp-encryptedsigned}}.

A typical PGP/MIME message like this has the following structure:

~~~
└┬╴multipart/encrypted
 ├─╴application/pgp-encrypted
 └─╴application/octet-stream
  ↧ (decrypts to)
  └┬╴multipart/signed
   ├─╴text/plain ← Cryptographic Payload
   └─╴application/pgp-signature
~~~

For this message, the session key is an AES-256 key with value `5e67165ed1516333daeba32044f88fd75d4a9485a563d14705e41d31fb61a9e9` (in hex).

~~~
@@pgpmime-layered.eml@@
~~~

Decrypting the encryption Cryptographic Layer yields the following content:

~~~
@@pgpmime-layered.inner@@
~~~

Note the placement of the Protected Headers on the Cryptographic Payload specifically, which is not the immediate child of the encryption Cryptographic Layer.

Multilayer PGP/MIME Message with Protected Headers and Legacy Display Part {#pgp-multilayer-legacy-display}
--------------------------------------------------------------------------

And, a mailer that generates a multilayer cryptographic envelope might want to provide a Legacy Display part, if it is unsure of the capabilities of the recipient's MUA.
We show here how such a mailer might generate the same message as {{pgp-encryptedsigned}}.

Such a PGP/MIME message might have the following structure:

~~~
└┬╴multipart/encrypted
 ├─╴application/pgp-encrypted
 └─╴application/octet-stream
  ↧ (decrypts to)
  └┬╴multipart/signed
   ├┬╴multipart/mixed ← Cryptographic Payload
   │├─╴text/plain ← Legacy Display Part
   │└─╴text/plain
   └─╴application/pgp-signature
~~~

For this message, the session key is an AES-256 key with value `b346a2a50fa0cf62895b74e8c0d2ad9e3ee1f02b5d564c77d879caaee7a0aa70` (in hex).

~~~
@@pgpmime-layered+legacy-disp.eml@@
~~~

Unwrapping the encryption Cryptographic Layer yields the following content:

~~~
@@pgpmime-layered+legacy-disp.inner@@
~~~

Signed and Encrypted S/MIME Message with Protected Headers and Legacy Display {#smime-sign-enc-legacy}
-----------------------------------------------------------------------------

This shows the same signed and encrypted S/MIME message as {{smime-sign-enc}}, but formulated with a Legacy Display part so that
Its MIME message structure is:

~~~
└─╴application/pkcs7-mime smime-type="enveloped-data"
 ↧ (decrypts to)
 └─╴application/pkcs7-mime smime-type="signed-data"
  ⇩ (unwraps to)
  └┬╴multipart/mixed ← Cryptographic Payload
   ├─╴text/plain ← Legacy Display Part
   └─╴text/plain 445 bytes
~~~

The `Subject:` header is successfully obscured.

Note that if this message had been generated without Protected Headers, then an attacker with access to it could have read the Subject.
Such an attacker would know details about Alice and Bob's business that they wanted to keep confidential.

The protected headers also protect the authenticity of subject line as well.

The session key for this message's Cryptographic Layer is an AES-256 key with value `09e8f2a19d9e97deea7d51ee7d401be8763ab0377b6f30a68206e0bed4a0baec` (in hex).

If Bob's MUA is capable of interpreting these protected headers, it should render the `Subject:` of this message as `BarCorp contract signed, let's go!`.

~~~
@@smime-sign+enc+legacy-disp.eml@@
~~~

Unwrapping the outer Cryptographic Layer of this message yields the following MIME part (with its own Cryptographic Layer):

~~~
@@smime-sign+enc+legacy-disp.inner@@
~~~

Unwrapping the inner Cryptographic Layer yields the Cryptographic Payload, which includes the Legacy Display part:

~~~
@@smime-sign+enc+legacy-disp.inner.inner@@
~~~

Encrypted-only (unsigned) S/MIME Message with Protected Headers and Legacy Display {#smime-encrypted-only}
----------------------------------------------------------------------------------

This shows the same encrypted message as {{smime-sign-enc-legacy}}, but formulated without a signature layer, so it is "encrypted-only".

Note that the lack of any signature layer means that the only forms of cryptographic protection these header receive is confidentiality.

An arbitrary adversary could forge a message with arbitrary headers (and content), and package it in this same form.
Consequently, the only thing "protected" about the headers in this example is confidentiality for any obscured headers (just the `Subject` in this case).

Presenting the cryptographic properties of the headers of such a message in a meaningful way to the end user is a subtle and challenging task, which this document cannot cover.

Its MIME message structure is:

~~~
└─╴application/pkcs7-mime smime-type="enveloped-data"
 ↧ (decrypts to)
 └┬╴multipart/mixed ← Cryptographic Payload
  ├─╴text/plain ← Legacy Display
  └─╴text/plain
~~~

For this message, the session key is an AES-256 key with value `e94f6aaef7f14d6ceeac770c46d7f4885e81fbeaf1462d0fdadfce6c581525e2` (in hex).

~~~
@@smime-enc+legacy-disp.eml@@
~~~

Unwrapping the single-layer Cryptographic Envelope of this message yields the following MIME structure:

~~~
@@smime-enc+legacy-disp.inner@@
~~~

Encrypted-only (unsigned) PGP/MIME Message with Protected Headers and Legacy Display
------------------------------------------------------------------------------------

This shows a comparable encrypted-only (unsigned) message, like {{smime-encrypted-only}} , but using PGP/MIME instead of S/MIME.

Note that the lack of any signature layer means that the only forms of cryptographic protection these header receive is confidentiality.

An arbitrary adversary could forge a message with arbitrary headers (and content), and package it in this same form.
Consequently, the only thing "protected" about the headers in this example is confidentiality for any obscured headers (just the `Subject` in this case).

Presenting the cryptographic properties of the headers of such a message in a meaningful way to the end user is a subtle and challenging task, which this document cannot cover.

Its MIME message structure is:

~~~
└┬╴multipart/encrypted
 ├─╴application/pgp-encrypted
 └─╴application/octet-stream
  ↧ (decrypts to)
  └┬╴multipart/mixed ← Cryptographic Payload
   ├─╴text/plain ← Legacy Display
   └─╴text/plain
~~~

For this message, the session key is an AES-256 key with value `4f3e7e3cb4a49747f88d232601fa98a29d7427e8f80882464cfbca3dcb847356` (in hex).

~~~
@@pgpmime-enc+legacy-disp.eml@@
~~~

Unwrapping the single-layer Cryptographic Envelope of this message yields the following MIME structure:

~~~
@@pgpmime-enc+legacy-disp.inner@@
~~~

An Unfortunately Complex Example
--------------------------------

For all of the potential complexity of the Cryptographic Envelope, the Cryptographic Payload itself can be complex.
The Cryptographic Envelope in this example is the same as ({{pgp-multilayer-legacy-display}}).
The Cryptographic Payload has protected headers and a legacy display part (also the same as {{pgp-multilayer-legacy-display}}), but in addition Alice's MUA composes a message with both plaintext and HTML variants, and Alice includes a single attachment as well.

While this PGP/MIME message is complex, a modern MUA could also plausibly generate such a structure based on reasonable commands from the user composing the message (e.g., Alice composes the message with a rich text editor, and attaches a file to the message).

The key takeaway of this example is that the complexity of the Cryptographic Payload (which may contain a Legacy Display part) is independent of and distinct from the complexity of the Cryptographic Envelope.

This message has the following structure:

~~~
└┬╴multipart/encrypted
 ├─╴application/pgp-encrypted
 └─╴application/octet-stream
  ↧ (decrypts to)
  └┬╴multipart/signed
   ├┬╴multipart/mixed ← Cryptographic Payload
   │├─╴text/plain ← Legacy Display Part
   │└┬╴multipart/mixed
   │ ├┬╴multipart/alternative
   │ │├─╴text/plain
   │ │└─╴text/html
   │ └─╴text/x-diff ← attachment
   └─╴application/pgp-signature
~~~

For this message, the session key is an AES-256 key with value `1c489cfad9f3c0bf3214bf34e6da42b7f64005e59726baa1b17ffdefe6ecbb52` (in hex).

~~~
@@unfortunately-complex.eml@@
~~~

Unwrapping the encryption Cryptographic Layer yields the following content:

~~~
@@unfortunately-complex.inner@@
~~~


IANA Considerations
===================

FIXME: register content-type parameter for legacy-display part

MAYBE: provide a list of user-facing headers, or a new "user-facing" column in some table of known RFC5322 headers?

MAYBE: provide a comparable indicator for which headers are "structural" ?

Security Considerations
=======================

This document describes a technique that can be used to defend against two security vulnerabilities in traditional end-to-end encrypted e-mail.

Subject Leak
------------

While e-mail structure considers the Subject header to be part of the message metadata, nearly all users consider the Subject header to be part of the message content.

As such, a user sending end-to-end encrypted e-mail may inadvertently leak sensitive material in the Subject line.

If the user's MUA uses Protected Headers and obscures the Subject header as described in {{confidential-subject}} then they can avoid this breach of confidentiality.

Signature Replay {#signature-replay}
----------------

A message without Protected Headers may be subject to a signature replay attack, which attempts to violate the recipient's expectations about message authenticity and integrity.
Such an attack works by taking a message delivered in one context (e.g., to someone else, at a different time, with a different subject, in reply to a different message), and replaying it with different message headers.

A MUA that generates all its signed messages with Protected Headers gives recipients the opportunity to avoid falling victim to this attack.

Guidance for how a message recipient can use Protected Headers to defend against a signature replay attack are out of scope for this document.

Participant Modification {#participant-modification}
------------------------

A trivial (if detectable) attack by an active network adversary is to insert an additional e-mail address in a `To` or `Cc` or `Reply-To` or `From` header.
This is a staging attack against message confidentiality -- it relies on followup action by the recipient.

For an encrypted message that is part of an ongoing discussion where users are accustomed to doing "reply all", such an insertion would cause the replying MUA to encrypt the replying message to the additional party, giving them access to the conversation.
If the replying MUA quotes and attributes cleartext from the original message within the reply, then the attacker learns the contents of the encrypted message.

As certificate discovery becomes more automated and less noticeable to the end user, this is an increasing risk.

An MUA that rejects Exposed Headers in favor of Protected Headers should be able to avoid this attack when replying to a signed message.


Privacy Considerations
======================

This document only explicitly contemplates confidentiality protection for the Subject header, but not for other headers which may leak associational metadata.
For example, `From` and `To` and `Cc` and `Reply-To` and `Date` and `Message-Id` and `References` and `In-Reply-To` are not explicitly necessary for messages in transit, since the SMTP envelope carries all necessary routing information, but an encrypted {{RFC5322}} message as described in this document will contain all this associational metadata in the clear.

Although this document does not provide guidance for protecting the privacy of this metadata directly, it offers a platform upon which thoughtful implementations may experiment with obscuring additional e-mail headers.

Document Considerations
=======================

\[ RFC Editor: please remove this section before publication ]

This document is currently edited as markdown.  Minor editorial changes can be suggested via merge requests at https://github.com/autocrypt/protected-headers or by e-mail to the authors.  Please direct all significant commentary to the public IETF LAMPS mailing list: spasm@ietf.org

Document History
----------------

Significant changes between version -01 and -02:

 - Added S/MIME test vectors in addition to PGP/MIME
 - Legacy Display parts should now be `text/plain` and not `text/rfc822-headers`
 - Cryptographic Payload must have `protected-headers` parameter set to `v1`
 - Test vector sample Message-Ids have been normalized
 - Added encrypted-only (unsigned) test vectors, at the suggestion of Russ Housley

Changes between version -00 and -01:

 - Credit Randall for "correct horse battery staple".
 - Adjust test vectors to ensure no line in the generated .txt format exceeds 72 chars.
 - Minor formatting cleanup to appease idnits.
 - Update references to more recent documents (RFC 2822 -> 5322, -00 to -01 of draft-ietf-lamps-header-protection-requirements).

Acknowledgements
================

The set of constructs and algorithms in this document has a previous working title of "Memory Hole", but that title is no longer used as different implementations gained experience in working with it.

These ideas were tested and fine-tuned in part by the loose collaboration of MUA developers known as {{Autocrypt}}.

Additional feedback and useful guidance was contributed by attendees of the OpenPGP e-mail summit ({{OpenPGP-Email-Summit-2019}}).

The following people have contributed implementation experience, documentation, critique, and other feedback:

- Holger Krekel
- Patrick Brunschwig
- Vincent Breitmoser
- Edwin Taylor
- Alexey Melnikov
- Russ Housley
 
The password example used in {{test-vectors}} comes from {{xkcd936}}.
