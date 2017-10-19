#!/bin/bash
echo $HOME, $MAIL, $USER, $SHELL, $SHLVL >> ~/init.log
cd $HOME/bin/crm114/
./crm114_tre mailfilter.crm --fileprefix=$HOME/bin/crm114/ >> /var/spool/mail/$USER
