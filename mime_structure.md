
Signed
------
|_multipart/signed
 |_payload containing headers
 |_application/pgp-signature 


Encrypted
---------
|_multipart/encrypted
 |_application/pgp-encrypted
 |_application/octet-stream
   ||
   (decrypt)
   || 
   payload containing headers


Compat
------
|_multipart/encrypted
 |_application/pgp-encrypted
 |_application/octet-stream
   ||
   (decrypt)
   || 
   multipart/mixed (payload containing headers)
   |_ text/rfc822-headers (legacy display)
   |_ body

Multilayer cryptographic envelope
---------------------------------
└┬╴multipart/encrypted
 ├─╴application/pgp-encrypted
 └─╴application/octet-stream
   ||
   (decrypt)
   || 
   multipart/signed
   |_payload containing headers
   |_application/pgp-signature   


    

