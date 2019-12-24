These Thunderbird/Enigmail screenshots were generated on a Debian
testing/unstable system on amd64, running X11.

~~~
$ dpkg -l enigmail thunderbird
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name           Version       Architecture Description
+++-==============-=============-============-=================================
ii  enigmail       2:2.1.3+ds1-4 all          GPG support for Thunderbird and D
ii  thunderbird    1:68.3.1-1    amd64        mail/news client with RSS, chat a
$
~~~

See also the `distribution/thunderbird` script in this repository for
setup.

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
