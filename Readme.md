# Script for updating MikroTik devices

## Usage

- Enter IP, port, user and password
- wait for finishing

## Demonstration

![](asciicast.svg)

## How it works

- It downloads
  - MikroTik RouterOS main package
  - MikroTik RouterOS wireless package
- Copies both packages to the device
- Reboots for installation
- Reboots for bootloader upgrade
- Shows if it worked

## License

Copyright &copy; 2023 Daniel A. Maierhofer

Thanks for `checkbin` from [lroe](https://github.com/0xff-lroe)
