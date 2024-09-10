#!/bin/bash

rman target / <<EOF
run
{
    crosscheck backup;
    delete noprompt obsolete;
    delete expired archivelog all;
}
exit
EOF