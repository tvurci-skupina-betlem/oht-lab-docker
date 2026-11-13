# NetBox with the Diode plugin. Built on the deployment node by Compose.
# Plugin compatibility: https://github.com/netboxlabs/diode-netbox-plugin#compatibility
ARG NETBOX_IMAGE_TAG=v4.7.4-5.1.1
FROM docker.io/netboxcommunity/netbox:${NETBOX_IMAGE_TAG}

ARG DIODE_PLUGIN_VERSION=1.19.0
RUN /usr/local/bin/uv pip install --no-cache "netboxlabs-diode-netbox-plugin==${DIODE_PLUGIN_VERSION}"

COPY config/plugins.py /etc/netbox/config/plugins.py

RUN SECRET_KEY="dummyKeyWithMinimumLength-------------------------" \
    /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py collectstatic --no-input
