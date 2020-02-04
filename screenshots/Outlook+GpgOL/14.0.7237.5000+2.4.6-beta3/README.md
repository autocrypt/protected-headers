Platform
--------
 - Microsoft Windows 10 Pro
 - 10.0.17763 Build 17763
 - 64-bit

Office Suite
------------
Microsoft Office Professional Plus 2010 (Product Activation Required)

Outlook 14.0.7237.5000 (64-bit)

`bob.p12` bundle loaded via "Manage User Certificates" (certmgr).

Then, from there, Sample Lamps Certificate Authority moved into Trusted Root Store.


Plugins
-------

GpgOL Version 2.4.6-beta3 (from https://files.gpg4win.org/Beta/gpgol/2.4.6-beta3/)

`bob@openpgp.example.sec.asc` and `alice@openpgp.example.pub.asc` loaded by double-clicking in Windows file explorer.

Configuration:

 ![GpgOL Settings](gpgol-settings.png)

I tried to let Outlook handle the S/MIME directly, and just used GpgOL for the PGP/MIME.

This is an improvement over GpgOL 2.4.4 -- legacy display parts in encrypted PGP/MIME messages are [properly hidden](https://dev.gnupg.org/T4796).


Samples
-------

 - `pgpmime-signed`

    ![pgpmime-signed](pgpmime-signed.png)

 - `smime-multipart-signed`

    ![smime-multipart-signed](smime-multipart-signed.png)

 - `smime-onepart-signed`

    ![smime-onepart-signed](smime-onepart-signed.png)

 - `pgpmime-sign+enc`

    ![pgpmime-sign+enc](pgpmime-sign+enc.png)

 - `smime-sign+enc`

    ![smime-sign+enc](smime-sign+enc.png)

 - `pgpmime-sign+enc+legacy-disp`

    ![pgpmime-sign+enc+legacy-disp](pgpmime-sign+enc+legacy-disp.png)

 - `pgpmime-layered`

    ![pgpmime-layered](pgpmime-layered.png)

 - `pgpmime-layered+legacy-disp`

    ![pgpmime-layered+legacy-disp](pgpmime-layered+legacy-disp.png)

 - `smime-sign+enc+legacy-disp`
 
    doesn't display great, the message body is seen as an attachment, which you have to click to preview:

    ![smime-sign+enc+legacy-disp](smime-sign+enc+legacy-disp.png)
    ![smime-sign+enc+legacy-disp-tab-warning](smime-sign+enc+legacy-disp-tab-warning.png)
    ![smime-sign+enc+legacy-disp-tab-preview](smime-sign+enc+legacy-disp-tab-preview.png)

 - `smime-enc+legacy-disp`

    similarly, doesn't display great; the preview is shown here (same warning as above):

    ![smime-enc+legacy-disp](smime-enc+legacy-disp.png)
    ![smime-enc+legacy-disp-tab-preview](smime-enc+legacy-disp-tab-preview.png)

 - `pgpmime-enc+legacy-disp`

    ![pgpmime-enc+legacy-disp](pgpmime-enc+legacy-disp.png)

 - `unfortunately-complex`

    ![unfortunately-complex](unfortunately-complex.png)
