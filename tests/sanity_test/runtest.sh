#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/tbb/Sanity/upstream
#   Description: Test for package tbb that tests the whole library
#   Author: Filip Holec <fholec@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2012 Red Hat, Inc. All rights reserved.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh

PACKAGES=${PACKAGES:-tbb}
REQUIRES=${REQUIRES:-tbb-devel}

rlJournalStart
    rlPhaseStartSetup
        # Determine what architecture is the test running on
        ARCH=$(rlGetPrimaryArch)

        # work around https://bugzilla.redhat.com/show_bug.cgi?id=1374681
        sed -i 's/\/mnt\/redhat\/scripts\/rel-eng\/utility\/find_package/\/usr\/bin\/find_package/' /usr/share/beakerlib/plugins/rh-internal.sh
        wget -O /usr/bin/find_package http://nfs.englab.brq.redhat.com/scratch/mcermak/conf/find_package
        chmod a+rx /usr/bin/find_package
        # Supported architectures are i386 and x86_64
        if [ $ARCH = "i386" -o $ARCH="x86_64" ] ; then
            # Check if RPMs are installed
            rlAssertRpm --all

            rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
            rlRun "pushd $TmpDir"

            # Download tests from lookaside and decompress them
            PY_COLLECTION=$(echo $COLLECTIONS | egrep -o 'python\w+')
            if [[ -n $PY_COLLECTION ]] && rlIsRHEL 6
            then
                echo "${PY_COLLECTION}-tbb"
                rlRun "rlFetchSrcForInstalled ${PY_COLLECTION}-tbb" \
                0 "Download tbb source RPM"

                if [ "$PY_COLLECTION" == "python27" ]
                then
                    FLAGS="CXXFLAGS='-I/opt/rh/python27/root/usr/include/ -L/opt/rh/python27/root/usr/lib64'"
                    tbb_prefix="/tbb"
                else
                    FLAGS="CXXFLAGS='-I/opt/rh/python33/root/usr/include/ -L/opt/rh/python33/root/usr/lib64'"
                    tbb_prefix=""
                fi

            else
                FLAGS=""
                echo tbb
                rlRun "rlFetchSrcForInstalled tbb" \
                0 "Download tbb source RPM"
            fi
            rlRun "rpm --define '_topdir $TmpDir' -i *src.rpm" \
                0 "Installing the source rpm"
            rlRun "mkdir BUILD" 0 "Creating BUILD directory"
            rlRun "rpmbuild --nodeps --define '_topdir $TmpDir' -bp $TmpDir/SPECS/*spec" \
                0 "Preparing sources"
            rlRun "pushd ./BUILD/" 0 "Go to source directory"
        else
            rlLog "tbb is not available for $ARCH, skipping the test"
        fi
    rlPhaseEnd

    rlPhaseStartTest
        # Test if architecture is supported
        if [ $ARCH = "i386" -o $ARCH="x86_64" ] ; then
            # Make and make fibonacci
            rlRun "pushd .${tbb_prefix}/oneTBB*/examples/test_all/fibonacci; make ${FLAGS}" 0 \
            "Enter fibonacci example directory and make"
            # Run the fibonacci test
            rlRun "./fibonacci" 0 \
                "Testing fibonacci (which is complex testing of nearly all tbb library)"
        fi
    rlPhaseEnd

    rlPhaseStartCleanup
        # Test if architecture is supported
        if [ $ARCH = "i386" -o $ARCH="x86_64" ] ; then
            rlRun "popd"
            rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        fi
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
