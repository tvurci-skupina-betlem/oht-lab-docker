# NetBox plugin configuration, loaded by the netbox-docker configuration from
# /etc/netbox/config/. Values come from the container environment.
from os import environ

PLUGINS = ["netbox_diode_plugin"]

PLUGINS_CONFIG = {
    "netbox_diode_plugin": {
        # Diode gRPC endpoint, as reached from the NetBox container.
        "diode_target_override": environ.get(
            "DIODE_TARGET_OVERRIDE", "grpc://localhost:8080/diode"
        ),
        # NetBox user that changes applied by Diode are attributed to.
        # Do not change it after the first start.
        "diode_username": "diode",
        # Secret of the netbox-to-diode OAuth2 client in the Diode stack.
        "netbox_to_diode_client_secret": environ.get(
            "NETBOX_TO_DIODE_CLIENT_SECRET", ""
        ),
    },
}
