GLUON_SITE_PACKAGES := \
gluon-mesh-batman-adv-15 \
gluon-alfred \
gluon-announced \
gluon-autoupdater \
gluon-config-mode-hostname \
gluon-config-mode-autoupdater \
gluon-config-mode-mesh-vpn \
gluon-config-mode-geo-location \
gluon-config-mode-contact-info \
gluon-ebtables-filter-multicast \
gluon-ebtables-filter-ra-dhcp \
gluon-luci-admin \
gluon-luci-autoupdater \
gluon-luci-portconfig \
gluon-next-node \
gluon-mesh-vpn-fastd \
gluon-fffd-autokey \
gluon-radvd \
gluon-status-page \
iwinfo \
iptables \
haveged


DEFAULT_GLUON_RELEASE := stable-snapshot-$(shell date '+%Y%m%d%H%M%S')

# Allow overriding the release number from the command line
GLUON_RELEASE ?= $(DEFAULT_GLUON_RELEASE)

# Default priority for updates.
GLUON_PRIORITY ?= 0

# Languages to include
GLUON_LANGS ?= en de
