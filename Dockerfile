FROM ubuntu:22.04

RUN apt update && apt upgrade -y

RUN apt install -y strongswan strongswan-pki libcharon-extra-plugins libcharon-extauth-plugins
RUN apt install -y net-tools

WORKDIR /root

RUN mkdir -p pki/cacerts
RUN mkdir -p pki/certs
RUN mkdir -p pki/private

RUN chmod 700 pki

RUN pki --gen --type rsa --size 4096 --outform pem > pki/private/ca-key.pem

RUN pki --self --ca --lifetime 3650 --in pki/private/ca-key.pem \
    --type rsa --dn "CN=VPN root CA" --outform pem > pki/cacerts/ca-cert.pem

RUN pki --gen --type rsa --size 4096 --outform pem > pki/private/server-key.pem

ARG IP_ADDRESS
ENV IP_ADDRESS=${IP_ADDRESS?err}

RUN echo IP_ADDRESS=${IP_ADDRESS}

RUN pki --pub --in pki/private/server-key.pem --type rsa \
    | pki --issue --lifetime 1825 \
    --cacert pki/cacerts/ca-cert.pem \
    --cakey pki/private/ca-key.pem \
    # --dn "CN=${DOMAIN_NAME}" --san ${DOMAIN_NAME} \
    --dn "CN=${IP_ADDRESS}" --san @${IP_ADDRESS} --san ${IP_ADDRESS} \
    --flag serverAuth --flag ikeIntermediate --outform pem \
    >  pki/certs/server-cert.pem

RUN cp -r pki/* /etc/ipsec.d/

