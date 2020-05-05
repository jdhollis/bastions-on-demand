FROM alpine:3.11

WORKDIR /root

ADD fetch_authorized_keys.sh /usr/local/bin/fetch_authorized_keys.sh
ADD entrypoint.sh /usr/local/bin/entrypoint.sh

RUN echo "Installing dependencies..." && \
  apk --no-cache \
    add \
      bash \
      curl \
      openssh \
      python \
      tini \
  && \
  echo "Installing AWS CLI..." && \
  wget https://s3.amazonaws.com/aws-cli/awscli-bundle.zip && \
  unzip awscli-bundle.zip && \
  rm awscli-bundle.zip && \
  ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws && \
  rm -R awscli-bundle && \
  /usr/local/bin/aws --version

RUN echo "Creating user \"pilot\"..." && \
  adduser pilot --disabled-password

RUN echo "Unlocking \"pilot\"..." && \
  sed -i "s/pilot:!::0:::::/pilot:*::0:::::/g" /etc/shadow

RUN echo "Configuring sshd..." && \
  sed -i "s:#AuthorizedKeysCommand none:AuthorizedKeysCommand /usr/local/bin/fetch_authorized_keys.sh:g" /etc/ssh/sshd_config && \
  sed -i "s:#AuthorizedKeysCommandUser nobody:AuthorizedKeysCommandUser nobody:g" /etc/ssh/sshd_config && \
  sed -i "s:#GatewayPorts no:GatewayPorts yes:g" /etc/ssh/sshd_config && \
  sed -i "s:#PasswordAuthentication yes:PasswordAuthentication no:g" /etc/ssh/sshd_config && \
  sed -i "s:#PermitTunnel no:PermitTunnel yes:g" /etc/ssh/sshd_config && \
  sed -i "s:AllowTcpForwarding no:AllowTcpForwarding yes:g" /etc/ssh/sshd_config && \
  sed -i "s:AuthorizedKeysFile	.ssh/authorized_keys:AuthorizedKeysFile	none:g" /etc/ssh/sshd_config

ENTRYPOINT [ "/sbin/tini", "--" ]
CMD [ "/bin/sh", "/usr/local/bin/entrypoint.sh" ]
