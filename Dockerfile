
ARG version="latest"
ARG UID=1000
ARG GID=1000

# Get latest OWASP Dependency Check image
FROM owasp/dependency-check:${version} as source

COPY owasp_db.tar.gz /owasp_db.tar.gz
COPY ./ /

ARG nvdApiKey=""
USER 0

RUN /scripts/update_owasp_db.sh ${nvdApiKey} && \
    /scripts/archive_owasp_db.sh

ARG version="latest"
FROM owasp/dependency-check:${version}

WORKDIR /scripts

COPY --from=source /scripts/unarchive_owasp_db.sh /scripts/
COPY run_owasp_scanner.sh /
COPY --from=source /owasp_db.tar.gz /

USER ${UID}

VOLUME ["/src", "/report"]

WORKDIR /src

CMD ["--help"]
ENTRYPOINT ["/run_owasp_scanner.sh"]