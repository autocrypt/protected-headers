---
title: Protected Headers for Cryptographic E-mail
docname: draft-autocrypt-protected-headers-00
date: 2019-10-14
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
 I-D.draft-melnikov-smime-header-signing-05:
 I-D.draft-luck-lamps-pep-header-protection-03:
 RFC822:
normative:
 RFC2119:
 RFC8174:
 RFC3156:
--- abstract

Cryptographic e-mails do not protect headers.  This document describes how several implementations protect headers.

--- middle

Introduction
============

FIXME
(Mention {{I-D.draft-melnikov-smime-header-signing-05}} and
{{I-D.draft-luck-lamps-pep-header-protection-03}})

Requirements Language
---------------------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 {{RFC2119}} {{RFC8174}} when, and only when, they appear in all capitals, as shown here.

Cryptographic Payload
=====================

The bode of an Email message encrypted or signed.

"multipart/encrypted" has content type of "application/octet-stream"
"multipart/signed" has content type of "text/plain"


Message Composition (Header Copying)
====================================

(Headers in Email message)
(All vs headers not to mangle with: From, To, CC, Date, Message-ID)

Encrypted Subject
=================

Legacy Display
--------------

The cryptographic payload containing the headers is content type of
"multipart/mixed" composed by a content type of "text/rfc822-headers" and a
body. 

Examples
========

IANA Considerations
===================

FIXME: register flag for legacy-display part

Document Considerations
=======================

\[ RFC Editor: please remove this section before publication ]

This document is currently edited as markdown.  Minor editorial
changes can be suggested via merge requests at
https://github.com/autocrypt/protected-headers or by e-mail to the
authors.  Please direct all significant commentary to the public IETF
LAMPS mailing list: spasm@ietf.org

Document History
----------------

Acknowledgements
================

The authors would like to acknowledge the help and input of the
other participants at the OpenPGP e-mail summmit 2019.
