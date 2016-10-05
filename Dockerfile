FROM centos:latest

# Install fpm (to make distro packages) & nginx to serve produced assets
RUN set -e && \
    set -x && \
    yum install -y \
        epel-release && \
    yum update -y && \
    yum upgrade -y && \
    yum groupinstall -y \
        "Development Tools" && \
    yum install -y \
        ruby-devel && \
    gem install fpm && \
    yum install -y \
        nginx \
        createrepo && \
    rm -rf /usr/share/nginx/html/*

COPY dist/nginx.conf /etc/nginx/nginx.conf

COPY cinder-docker-driver /opt/payload/usr/bin/
COPY dist/cinder-docker-driver.service /opt/payload/usr/lib/systemd/system/
COPY dist/post-install.sh /opt/post-install.sh

RUN chmod 644 /opt/payload/usr/lib/systemd/system/cinder-docker-driver.service


RUN set -e && \
    set -x && \
    cd /tmp && \
    export PACKAGE_NAME="cinder-docker-driver" && \
    export PACKAGE_VERSION="0.1" && \
    export PACKAGE_ARCH="x86_64" && \
    export PACKAGE_URL="https://github.com/j-griffith/cinder-docker-driver" && \
    export ITERATIONS=$(date +%s) && \
    fpm \
      -s dir \
      -t rpm \
    	--after-install /opt/post-install.sh \
      --name $PACKAGE_NAME \
      --log info \
      --verbose \
      --version $PACKAGE_VERSION \
      --iteration $ITERATIONS \
      --architecture $PACKAGE_ARCH \
      --epoch 1 \
      --license "Apache 2.0" \
      --vendor "Harbor OpenStack" \
      --description "${PACKAGE_NAME} package for Harbor Atomic Host" \
      --url $PACKAGE_URL \
      /opt/payload && \
    mkdir -p /srv/repo/atomic-host/7/$PACKAGE_ARCH/ && \
    cp $PACKAGE_NAME-$PACKAGE_VERSION-$ITERATIONS.$PACKAGE_ARCH.rpm /srv/repo/atomic-host/7/$PACKAGE_ARCH/ && \
    rm -rf /srv/repo/atomic-host/7/$PACKAGE_ARCH/repodata && \
    cd /srv/repo/atomic-host/7/$PACKAGE_ARCH && \
      createrepo . && \
    mkdir -p /usr/share/nginx/html/$PACKAGE_ARCH/ && \
    mv /srv/repo/atomic-host/7/$PACKAGE_ARCH/* /usr/share/nginx/html/$PACKAGE_ARCH/


ENTRYPOINT []

CMD ["nginx"]
