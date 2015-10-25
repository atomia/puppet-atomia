#!/bin/bash
# You can override config options very easily.
# Just create a custom options file; it may be version specific:
# - custom-options.sh
# - custom-options-5.sh
# - custom-options-5.3.sh
# - custom-options-5.3.1.sh
#
# Don't touch this file here - it would prevent you to just "svn up"
# your phpfarm source code.

version=$1
vmajor=$2
vminor=$3
vpatch=$4

#gcov='--enable-gcov'
configoptions="\
--enable-bcmath \
--with-mysqli \
--with-mysql \
--with-curl \
--with-png \
--with-gd \
--enable-gd-native-ttf \
--enable-calendar \
--enable-exif \
--enable-ftp \
--enable-mbstring \
--enable-pcntl \
--enable-soap \
--with-pdo-mysql \
--enable-sockets \
--enable-sqlite-utf8 \
--enable-wddx \
--enable-zip \
--with-openssl \
--with-jpeg-dir=/usr/lib \
--with-zlib \
--with-gettext \
--with-mcrypt \
--enable-intl \
$gcov"

echo $version $vmajor $vminor $vpatch

custom="custom-options.sh"
[ -f $custom ] && source "$custom" $version $vmajor $vminor $vpatch
custom="custom-options-$vmajor.sh"
[ -f $custom ] && source "$custom" $version $vmajor $vminor $vpatch
custom="custom-options-$vmajor.$vminor.sh"
[ -f $custom ] && source "$custom" $version $vmajor $vminor $vpatch
custom="custom-options-$vmajor.$vminor.$vpatch.sh"
[ -f $custom ] && source "$custom" $version $vmajor $vminor $vpatch