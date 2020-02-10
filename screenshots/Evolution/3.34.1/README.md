These Evolution screenshots were generated on a Debian
testing/unstable system on amd64, running X11.

~~~
$ dpkg -l evolution
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name           Version      Architecture Description
+++-==============-============-============-==============================================
ii  evolution      3.34.1-3     amd64        groupware suite with mail client and organizer
~~~

Configuration was simple and straightforward.  No plugins were needed for either S/MIME or OpenPGP.
Certificates and secret keys were loaded from the draft documents.

Samples:

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

    ![smime-sign+enc+legacy-disp](smime-sign+enc+legacy-disp.png)

 - `smime-enc+legacy-disp`

    ![smime-enc+legacy-disp](smime-enc+legacy-disp.png)

 - `pgpmime-enc+legacy-disp`

    ![pgpmime-enc+legacy-disp](pgpmime-enc+legacy-disp.png)

 - `unfortunately-complex`

    ![unfortunately-complex](unfortunately-complex.png)
