# Telerising Helper
```bash
###########################################################################
#                     telerising universal installer                      #
#                                  v0.1                                   #
#                                                                         #
#            support on https://www.kodinerds.net/wcf/user/32559          #
#         support telerising https://www.kodinerds.net/thread/72127       #
#                                                                         #
#                       want to spend some drinks?                        #
#                       https://paypal.me/betaface                        #
#                                                                         #
#           want to spend some haribos to the telerising author?          #
#                     https://paypal.me/sunsettrack4                      #
#                                                                         #
###########################################################################
```
```bash
################################################################################################
#                                                                                              #
# usage: [install_dir] [system]                                                                #
#                                                                                              #
# this script needs root for then following tasks: (obsolete, using proot and busybox now)     #
#    - install tzdata       | if not exists in /usr/share/zonedata                             #
#    - modifying /etc/hosts | telerising needs to resolve our own hostname                     #
#    - add user             | if possible create user telerising else run under root           #
#    - package system       | if available try to install needed packages                      #
#                                                                                              #
#                                                                                              #
# system tools needed:                                                                         #
#    - wget or curl                                                                            #
#    - tar                                                                                     #
#    - unzip                                                                                   #
#    - bash                                                                                    #
#                                                                                              #
# params:                                                                                      #
#    - install_dir | where should telerising be installed | default [~/telerising]             #
#    - systems:                                                                                #
#      - empty          | try to autodetect                                                    #
#      - arm64_raspbian | arm64 devices                                                        #
#      - x86-64_linux   | amd64 devices                                                        #
#      - armhf_raspbian | armhf devices                                                        #
#      - x86-64_windows | windows 64bit                                                        #
#                                                                                              #
# other:                                                                                       #
#    - install modified providers.json for waipu support                                       #
#    - put you own modified providers.json into [install_dir] to use it instead                #
#                                                                                              #
# examples:                                                                                    #
#                                                                                              #
# export helper_url=https://raw.githubusercontent.com/DEvmIb/telerising-helper/refs/heads/main #
# curl -s $helper_url/api.sh|bash -s -- /opt/telerising arm64_raspbian                         #
# curl -s $helper_url/api.sh|bash -s -- /opt/telerising x86-64_linux                           #
# curl -s $helper_url/api.sh|bash -s -- /opt/telerising armhf_raspbian                         #
#                                                                                              #
# wget -qO - $helper_url/api.sh|bash -s -- /opt/telerising arm64_raspbian                      #
# wget -qO - $helper_url/api.sh|bash -s -- /opt/telerising x86-64_linux                        #
# wget -qO - $helper_url/api.sh|bash -s -- /opt/telerising armhf_raspbian                      #
#                                                                                              #
# quick install to home dir to test new version:                                               #
# [curl|wget] $helper_url/api.sh|bash -s                                                       #
#                                                                                              #
# docker | multiarch one url                                                                   #
#                                                                                              #
# docker run -d --net host -v ~/telerising:/telerising ad0lar/telerising-alpine                #
#                                                                                              #
# support on kodinerds https://www.kodinerds.net/wcf/user/32559-fds97avvs/                     #
#                                                                                              #
################################################################################################
```

```bash
######################################################################################
#                                                                                    #
#                                     tested devices                                 #
#                                                                                    #
#      * Windows 10 / 11                                                             #
#        - wls1         | debian, ubuntu, no proot                                   #
#        - wls2         | debian, ubuntu                                             #
#        - cygwin       | 64bit | using windows version                              #
#                                                                                    #
#      * Android                                                                     #
#        - termux       | armv7l, armv8l, aarch64 | using proot                      #
#                                                                                    #
#      * Linux                                                                       #
#        - newenigma    | aarch64 | DM AIO Image / Gemini 4.2 Plugin / One/Two       #
#        - terramaster  | x86_64 | TOS6                                              #
#        - freebsd      | x86_64 | needs ABI | script will ask to enable it          #
#        - opensuse     | x86_64 | leap, tumbleweed                                  #
#        - debian       | armv7l, armv8l, aarch64, x86_64                            #
#        - ubuntu       | armv7l, armv8l, aarch64, x86_64                            #
#        - RPI          | armv6l, armv7l, armv8l, aarch64, x86_64                    #
#        - alpine       | armv6l, armv7l, armv8l, aarch64, x86_64                    #
#        - fedora       | aarch64, x86_64                                            #
#        - rocky        | aarch64, x86_64                                            #
#        - oracle       | aarch64, x86_64                                            #
#        - redhat/ubi8  | aarch64, x86_64                                            #
#                                                                                    #
######################################################################################
```
