#!/usr/bin/env python

import sys

device_type = sys.argv[1].strip()
firmware_version = sys.argv[2].strip()

if device_type == 'YubiKey 4':
    major, minor, patch = firmware_version.split('.')

    if major == 4 and minor == 2 and patch >= 6 or \
       major == 4 and minor == 3 and patch <= 4:
       sys.exit('Device type {} firmware version {} probably '\
                'VULNERABLE to ROCA: https://www.yubico.com/keycheck/'\
                .format(device_type, firmware_version))

    else:
       print('Device type {} firmware version {} '\
             'NOT known to be vulnerable to ROCA'\
             .format(device_type, firmware_version))

else:
    print('Device type {} NOT known to be '\
          'vulnerable to ROCA'.format(device_type))

