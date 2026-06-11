FROM ckan/ckan-base:2.11

# Install any extensions needed by your CKAN instance
# See Dockerfile.dev for more details and examples

### DCAT ###
# ckanext-dcat 2.4.3 — CKAN 2.11 compatible (https://github.com/ckan/ckanext-dcat/releases/tag/v2.4.3)
USER root
RUN pip3 install ckanext-dcat==2.4.3

# Copy custom initialization scripts
COPY --chown=ckan-sys:ckan-sys docker-entrypoint.d/* /docker-entrypoint.d/

# Apply any patches needed to CKAN core or any of the built extensions (not the
# runtime mounted ones)
COPY --chown=ckan-sys:ckan-sys patches ${APP_DIR}/patches

USER ckan

RUN for d in $APP_DIR/patches/*; do \
        if [ -d $d ]; then \
            for f in `ls $d/*.patch | sort -g`; do \
                cd $SRC_DIR/`basename "$d"` && echo "$0: Applying patch $f to $SRC_DIR/`basename $d`"; patch -p1 < "$f" ; \
            done ; \
        fi ; \
    done