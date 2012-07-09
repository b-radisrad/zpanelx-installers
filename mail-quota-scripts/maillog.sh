#!/bin/sh


#
# Can be used to get bandwidth usage on pop3 and IMAP per account on a ZPanelX server.
# Great for finding high usage accounts
#


for d in `ls /var/zpanel/vmail/`; do
   {
     for eu in `ls /var/zpanel/vmail/$d/`; do
     {
       echo "$eu@$d";
       echo -n "POP3: "
       expr `grep "($eu@d)" /var/log/maillog | awk '/pop3/ && /retr/ && /Disconnected/ {print $10}' | cut -d/ -f2 | cut -d, -f1 | awk '{sum+=$1} END {printf("%0.0f\n", sum)}'` + `grep "($eu@d)" /var/log/maillog | awk '/POP3/ && /retr/ && /Disconnected/ {print $11}' | cut -d/ -f2 | cut -d, -f1 | awk '{sum+=$1} END {printf("%0.0f\n", sum)}'`
       echo -n "IMAP: "
       grep "($eu@$d)" /var/log/maillog | awk '/imap/ && /bytes/ && /Disconnected/ {print $10}' | cut -d/ -f2 | cut -d, -f1 | awk '{sum+=$1} END {printf("%0.0f\n", sum)}'
      }
      done;
   }
   done;
exit 0;