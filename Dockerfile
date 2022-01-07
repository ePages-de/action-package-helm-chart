FROM alpine/helm:3.6.1

RUN apk add --no-cache bash curl git

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

# USER root

ENTRYPOINT [ "/entrypoint.sh" ]