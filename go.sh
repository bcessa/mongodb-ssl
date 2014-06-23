#!/bin/bash
# MongoDB Builder
# This script will:
#    - Get the MongoDB code directly from GitHub
#    - Compiled it with full SSL support
#    - Create a DEB package for it ready to be installed/distributed
#
# Tested on: Ubuntu Server 12.04 64 bit
#
# Author: Ben Cessa <ben@pixative.com>

# BASICS
ARCH=amd64
BASE=$PWD
PKG_NAME=mongodb-ssl

# Text color variables
underline=$(tput sgr 0 1)
bold=$(tput bold)
red=${bold}$(tput setaf 1)
green=${bold}$(tput setaf 2)
yellow=${bold}$(tput setaf 3)
blue=${bold}$(tput setaf 4)
purple=${bold}$(tput setaf 5)
cyan=${bold}$(tput setaf 6)
reset=$(tput sgr0)

# UPGRADE SYSTEM
printf "${green}*${reset} Update the base system. This is HIGHLY recommended ( ${blue}'yes'${reset} or ${red}'no'${reset} ): "
read UPDSRV
if [ "$UPDSRV" == 'yes' ]; then
	sudo apt-get update
	sudo apt-get upgrade
fi

# CONFIGURATION
echo "${blue}>${reset} Some personal details required for package signature"
printf "${green}*${reset} Enter your full name: "
read REALNAME

printf "${green}*${reset} Enter your email address: "
read EMAIL

# DEPENDENCIES
# Install needed packages
echo "${blue}>${reset} Ok, lets install the required packages now"
sleep 2
sudo apt-get install git-core build-essential scons devscripts lintian dh-make \
libpcre3 libpcre3-dev libboost-dev libboost-date-time-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-thread-dev \
libpcap-dev libreadline-dev libssl-dev rng-tools

# GET ORIGINAL CODE AND COMPILE
echo "${blue}>${reset} Get a clone of the original MongoDB repo."
sleep 2
git clone https://github.com/mongodb/mongo.git source

# Show a list of the latest revisions and ask the user for one
cd source
echo "${blue}>${reset} Latest versions on the repository: "
git tag -l | tail

printf "${green}*${reset} Enter the MongoDB version to build ( without the 'r' ): "
read VERSION
TEMP=/var/tmp/$PKG_NAME-$VERSION
mkdir $TEMP

printf "${green}*${reset} Specify how many packages in parrallel to build: "
read PARALLEL

# Checkout selected version and start compilation process
echo "${blue}>${reset} Checking out the selected release"
sleep 2
git checkout r$VERSION

echo "${blue}>${reset} Compilation ahead, this may take a while, go grab a book or something!"
sleep 3
scons --64 --ssl --release --no-glibc-check -j $PARALLEL --prefix=$TEMP install

# PACKING
echo "${blue}>${reset} Binaries are ready, let's create the package."
sleep 3

# Move binaries, man, conf and upstart files
cd $BASE
mkdir -p $PKG_NAME/$PKG_NAME-$VERSION/{compiled,conf,man,upstart}
mv $TEMP/bin/* $PKG_NAME/$PKG_NAME-$VERSION/compiled/.
cp source/debian/*.1 $PKG_NAME/$PKG_NAME-$VERSION/man/.
# It seems that at on some mongoversion this file is called mongod.conf not mongodb.conf, that leads to failed building package
cp source/debian/mongod*.conf $PKG_NAME/$PKG_NAME-$VERSION/conf/.
cp source/debian/mongod*.upstart $PKG_NAME/$PKG_NAME-$VERSION/upstart/mongodb.conf

# Create the basic package layout
export DEBFULLNAME=$REALNAME
export DEBEMAIL=$EMAIL
cd $PKG_NAME/$PKG_NAME-$VERSION
dh_make -c gpl3 -e $EMAIL -n -s
cd debian
rm *.ex *.EX README*
cp $BASE/template/* .
cd ..

# Any modifications to the changelog?
printf "${green}*${reset} Any modifications to the default changelog file? ( ${blue}'yes'${reset} or ${red}'no'${reset} ): "
read MODCLOG
if [ "$MODCLOG" == 'yes' ]; then
	nano debian/changelog
fi

# Add a description to the control file?
printf "${green}*${reset} Any modifications to the default control file (description)? ( ${blue}'yes'${reset} or ${red}'no'${reset} ): "
read MODCTRL
if [ "$MODCTRL" == 'yes' ]; then
	nano debian/control
fi

# GPG key
echo "${blue}>${reset} Let's create a brand new GPG key to sign the package."
echo "${red}!!${reset} Use the same name and email that was used on the package itself!"
sleep 2
sudo rngd -b -r /dev/urandom
gpg --gen-key --no-use-agent

# Build the actual package
debuild -b

# CLIENTS EXTRA PACKAGE
printf "${green}*${reset} Do you wish to create an additional clients-apps-only package? ( ${blue}'yes'${reset} or ${red}'no'${reset} ): "
read DO_CLIENTS
if [ "$DO_CLIENTS" == 'yes' ]; then
	# Working dirs
	PKG_CLIENTS=${PKG_NAME}-clients
	PKG_CLIENTS_DIR=$PKG_CLIENTS/$PKG_CLIENTS-$VERSION
	
	# Move binaries, and man files
	cd $BASE
	mkdir -p $PKG_CLIENTS_DIR/{compiled,man}
	cp $PKG_NAME/$PKG_NAME-$VERSION/compiled/mongo $PKG_CLIENTS_DIR/compiled/.
	cp $PKG_NAME/$PKG_NAME-$VERSION/compiled/mongodump $PKG_CLIENTS_DIR/compiled/.
	cp $PKG_NAME/$PKG_NAME-$VERSION/compiled/mongoexport $PKG_CLIENTS_DIR/compiled/.
	cp $PKG_NAME/$PKG_NAME-$VERSION/compiled/mongofiles $PKG_CLIENTS_DIR/compiled/.
	cp $PKG_NAME/$PKG_NAME-$VERSION/compiled/mongoimport $PKG_CLIENTS_DIR/compiled/.
	cp $PKG_NAME/$PKG_NAME-$VERSION/compiled/mongorestore $PKG_CLIENTS_DIR/compiled/.
	cp $PKG_NAME/$PKG_NAME-$VERSION/compiled/mongostat $PKG_CLIENTS_DIR/compiled/.
	cp source/debian/mongo.1 $PKG_CLIENTS_DIR/man/.
	cp source/debian/mongodump.1 $PKG_CLIENTS_DIR/man/.
	cp source/debian/mongoexport.1 $PKG_CLIENTS_DIR/man/.
	cp source/debian/mongofiles.1 $PKG_CLIENTS_DIR/man/.
	cp source/debian/mongoimport.1 $PKG_CLIENTS_DIR/man/.
	cp source/debian/mongorestore.1 $PKG_CLIENTS_DIR/man/.
	cp source/debian/mongostat.1 $PKG_CLIENTS_DIR/man/.
	
	# Create the basic package layout
	export DEBFULLNAME=$REALNAME
	export DEBEMAIL=$EMAIL
	cd $PKG_CLIENTS_DIR
	dh_make -c gpl3 -e $EMAIL -n -s
	cd debian
	rm *.ex *.EX README*
	cp $BASE/template/clients/* .
	cd ..
	
	# Any modifications to the changelog?
	printf "${green}*${reset} Any modifications to the clients package changelog file? ( ${blue}'yes'${reset} or ${red}'no'${reset} ): "
	read MODCLOG_C
	if [ "$MODCLOG_C" == 'yes' ]; then
		nano debian/changelog
	fi
	
	# Add a description to the control file?
	printf "${green}*${reset} Any modifications to the clients package control file (description)? ( ${blue}'yes'${reset} or ${red}'no'${reset} ): "
	read MODCTRL_C
	if [ "$MODCTRL_C" == 'yes' ]; then
		nano debian/control
	fi
	
	# Build the clients package
	debuild -b
fi

# CLEANUP
echo "${blue}>${reset} All is done, let's clean up!"
sleep 2
cd $BASE
mv $PKG_NAME/*.deb .
if [ "$DO_CLIENTS" == 'yes' ]; then
	mv $PKG_CLIENTS/*.deb .
	rm -rf $PKG_CLIENTS
fi
rm -rf $TEMP
rm -rf $BASE/source
rm -rf $PKG_NAME

# EXIT
echo "${blue}>${reset} Package ready for installation and distribution!"
sleep 1
