# Dockerfile for sybase server

# docker build -t sybase .


FROM centos:7

MAINTAINER Tuan Vo <fervincent@gmail.com>
ARG sybase_installer=51047759.ZIP
# Adding resources

## SAP ASE Developer Edition 
## https://go.sap.com/cmp/syb/crm-xu15-int-asewindm/typ.html
# http://d1cuw2q49dpd0p.cloudfront.net/ASE16.0/Linux16SP02/ASE_Suite.linuxamd64.tgz
# http://d1cuw2q49dpd0p.cloudfront.net/ASE16.0/Windows16SP02/ASE_Suite.winx64.zip

## SAP ASE Express Edition
# http://d1cuw2q49dpd0p.cloudfront.net/ASE16.0/ExpressEdition/ase160_linuxx86-64.zip
# http://d1cuw2q49dpd0p.cloudfront.net/ASE16.0/DeveloperEdition/ase160_winx64.zip

# Docker docs
# If <src> is a local tar archive in a recognized compression format (identity, gzip, bzip2 or xz) then it is unpacked as a directory.
# Resources from remote URLs are not decompressed.
# Because image size matters, using ADD to fetch packages from remote URLs is strongly discouraged; you should use curl or wget instead.

# ADD http://d1cuw2q49dpd0p.cloudfront.net/ASE16.0/Linux16SP02/ASE_Suite.linuxamd64.tgz /opt/tmp/
# install for library /lib/ld-linux.so.2
RUN yum -y install libgcc.i686 glibc.i686 --setopt=protected_multilib=false

RUN mkdir -p /opt/tmp/ \
  && yum install -y atk gdk-pixbuf2 pango unzip openmotif libXp libXt libXtst libXi libXmu libXext libSM libICE libX11 \
  libXtst-devel libXi-devel openmotif-devel libXmu-devel libXt-devel libXext-devel libXp-devel libX11-devel libSM-devel libICE-devel libXcomposite \
  && yum clean all && rm -rf /tmp/* /var/tmp/* /var/cache/yum/*
 
COPY .assets_tmp/* /opt/tmp/


RUN set -x \
 && cd /opt/tmp/ \
 && unzip -q $sybase_installer -d /opt/tmp/ \
 && rm -rf $sybase_installer 


COPY assets/* /opt/tmp/


# Setting kernel.shmmax and 
RUN set -x \
 && cp /opt/tmp/sysctl.conf /etc/ \
 && true || /sbin/sysctl -p

# Installing Sybase RPMs
RUN set -x \
 && rpm -ivh --nodeps /opt/tmp/libaio-0.3.109-13.el7.x86_64.rpm \
 && rpm -ivh --nodeps /opt/tmp/gtk2-2.24.28-8.el7.x86_64.rpm


# Install Sybase
RUN set -x \
 && /opt/tmp/setup.bin -f /opt/tmp/sybase-response.txt \
    -i silent \
    -DAGREE_TO_SAP_LICENSE=true \
    -DRUN_SILENT=true


# Copy resource file
RUN cp /opt/tmp/sybase-ase.rs /opt/sybase/ASE-16_0/sybase-ase.rs

# Build ASE server
RUN source /opt/sybase/SYBASE.sh \
 && /opt/sybase/ASE-16_0/bin/srvbuildres -r /opt/sybase/ASE-16_0/sybase-ase.rs

# Change the Sybase interface
# Set the Sybase startup script in entrypoint.sh

RUN mv /opt/sybase/interfaces /opt/sybase/interfaces.backup \
 && cp /opt/tmp/interfaces /opt/sybase/ \
 && cp /opt/tmp/sybase-entrypoint.sh /usr/local/bin/ \
 && chmod +x /usr/local/bin/sybase-entrypoint.sh \
 && ln -s /usr/local/bin/sybase-entrypoint.sh /sybase-entrypoint.sh
 

# Setup the ENV
# https://docs.docker.com/engine/reference/builder/#run
# RUN ["/bin/bash", "-c", "source /opt/sybase/SYBASE.sh"]

ENTRYPOINT ["/sybase-entrypoint.sh"]

# CMD []

EXPOSE 5000

# Remove tmp
RUN find /opt/tmp/ -type f | xargs -L1 rm -f

# Share the Sybase data directory
#VOLUME ["/opt/sybase/data"]

# When run it
# docker run -d -p 8000:5000 -p 8001:5001 --name my-sybase sybase
