#!/bin/bash

if [[ $CKAN__PLUGINS == *"dcat"* ]]; then
   if [ -z "$CKAN_SITE_URL" ]; then
      echo "CKAN_SITE_URL not set; skipping DCAT catalogue URL configuration"
   else
      site_url="${CKAN_SITE_URL%/}"
      base_uri="${site_url}/"

      echo "Configuring DCAT catalogue options"
      echo "  ckan.site_url=${site_url}"
      echo "  ckanext.dcat.base_uri=${base_uri}"

      ckan config-tool "$CKAN_INI" \
         "ckan.site_url=${site_url}" \
         "ckanext.dcat.base_uri=${base_uri}"
   fi
else
   echo "Not configuring DCAT"
fi
