#!/bin/bash

output="$(arch-audit -u)"

if [[ -n $output ]]
then
    systemd-cat -t archpkgcheck echo "<2>Security update available. Sending email notification to $MYEMAIL"
    printf -- "%s\n" "$output" | /usr/bin/mail -s "Arch Security Update Available" $MYEMAIL
else
    systemd-cat -t archpkgcheck echo "No security updates available"
fi
