Screenshots of Protected Header Test Vectors
============================================

The Test Vector e-mails are available as `*.eml` files in this
repository, or online at imap://bob@protected-headers.cmrg.net/inbox

Please take screenshots of your MUA rendering these messages and
[submit them as a pull
request](https://github.com/autocrypt/protected-headers/pulls) here.

To prepare your MUA, you should load the secret key material for Bob
for both S/MIME and PGP/MIME:

 - https://www.ietf.org/id/draft-dkg-lamps-samples-01.html#name-bobs-sample
 - https://www.ietf.org/id/draft-bre-openpgp-samples-01.html#name-bobs-openpgp-secret-key-mat

And also load a bit of public key material, including Alice's OpenPGP
certificate:

 - https://www.ietf.org/id/draft-bre-openpgp-samples-01.html#name-alices-openpgp-certificate

And the LAMPS sample CA's certificate:

 - https://www.ietf.org/id/draft-dkg-lamps-samples-01.html#name-certificate-authority-certi

You should mark the LAMPS sample CA's certificate as "Trusted" to
identify S/MIME users.  For example, for Mozilla's NSS, use:

    certutil -A -d "sql:$profidr" -a -n 'Sample CA' -t ,TC, -i sample-ca.pem

Please make the screenshots are in png format, and name them after the
left-hand-side of the Message-Id for each message.
(e.g. `pgpmime-sign+enc.png`).

Place the screenshots in a folder named after the MUA and version number.

If your MUA has plugins installed, please separate the name of the MUA
and the plugin with a `+` character, and include the versions of both
MUA and plugin in the version string as well.

For example, screenshots for
[Thunderbird](https://www.thunderbird.net/) 68.3.1 using
[Enigmail](https://enigmail.net) 2.1.3 are placed in:

    ./screenshots/Thunderbird+Enigmail/68.3.1+2.1.3/

Feel free to include any additional relevant information in a
markdown-formatted `README.md` file in the same directory.

Thanks for submitting your screenshots!
