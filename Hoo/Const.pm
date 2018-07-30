package Hoo::Const;

use strict;

use constant ERR_DUPLICATE_ENTRY => 1062;
use constant SENDMAIL => ( Hoo::LOCAL ? 'C:\sendmail\sendmail.exe -t' : '/usr/sbin/sendmail -t' );

1;