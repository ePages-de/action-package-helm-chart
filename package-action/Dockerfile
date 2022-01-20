FROM alpine/helm:3.6.1

RUN apk add --no-cache bash curl git

# Add non-password-protected Helm repos for pipeline speed-up, beyond-helm to
# be added on runtime in order to prevent leaking the credentials
RUN helm repo add datawire https://getambassador.io \
    && helm repo add elastic https://helm.elastic.co

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]