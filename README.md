# transport-layer-tcp-protocol
Transport layer TCP-protocol template in which the corrupted blocks are identified and resent to the adressee. Used with **QRadioLink** or **GNU Radio** to effeciently communicate via radio transmitters.

![QRadioLink](https://github.com/faraui/transport-layer-tcp-protocol/assets/170811164/8b8f9a25-015d-4a90-a6db-7bc348543464)


## Installation
```bash
git clone https://github.com/faraui/transport-layer-tcp-protocol.git
cd transport-layer-tcp-protocol
chmod ugo+x *.pl *.pm *.sh
./install.sh
```

## Structure
```diff
[  13K] transport-layer-tcp-protocol
!! [  754] LICENSE.txt
~~ [ 1.6K] README.md
~~ [  508] install.sh
++ [ 1.5K] pack.pl
++ [  694] resend.pl
++ [ 6.7K] transport-layer-tcp-protocol.pm
++ [  637] unpack.pl
++ [ 1019] unpack_auto.pl

8 files, 1 directory
```

## Usage
**./pack.pl** *file* **>** *transmit-file*
> *file* is an original file that is to be obtained by the receiver.\
> *transmit-file* is a file that is transmitted via **QRadioLink** or **GNU Radio** to attain such obtaining.
>> *transmit-file* must be stored untill the radio transmission is succesfully completed.

**./unpack.pl** *received-file*
> *received-file* is a file where the data received by **QRadioLink** or **GNU Radio** is stored.
>> If the transmission was succesfull, the *received-file* is identical to *transmit-file*.\
>> In such case, `unpack.pl` will decode the received-file.\
>> In other case, `unpack.pl` will report on damaged blocks and create a `confimed.txt` file.\
>> `confirmed.txt` should be obtained by the transmitter, e.g. via Telegram =)

**./unpack_tcp.pl**
> Identical to the latter command, except this one listens `127.0.0.1:20000` infinitely and stores each *received-file* in `received-files` direcory.
>> Can process multiple files with different names concurrently.
>> **GNU Radio** should be configured as a client sending data to `127.0.0.1:20000`.

**./resend.pl** *transmit-file* *confirmed-file* > *resend-file*
> *transmit-file* and *confirmed-file* are as stated above.\
> *resend-file* is a file consisting of blocks that are to be resended to the receiver untill the *received-file* is identical to the *resend-file*
