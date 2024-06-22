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

## Usage
**./pack.pl** *file* **>** *transmit-file*
> *file* - an original file that is to be obtained by the receiver.\
> *transmit-file* is a file that is transmitted via **QRadioLink** or **GNU Radio** to attain such obtaining.
>> *transmit-file* must be stored untill the radio transmission is succesfully completed.
