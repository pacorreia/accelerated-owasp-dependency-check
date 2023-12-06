ARG nvdApiKey=""
ARG version="latest"
ARG UID=1000
ARG GID=1000

# Get latest OWASP Dependency Check image
FROM owasp/dependency-check:${version}

COPY ./ /

WORKDIR /

USER 0
RUN /scripts/update_owasp_db.sh "${nvdApiKey}"