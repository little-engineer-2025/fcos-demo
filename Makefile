##
# Automate run a VM with fedora core os in aarch64
##

# https://fedoraproject.org/coreos/download?stream=stable&arch=aarch64#download_section
IMG_DISK := fedora-coreos-42.20250623.3.1-metal.aarch64.raw
IMG_DISK_XZ := $(IMG_DISK).xz
IMG_DISK_XZ_URL := https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/42.20250623.3.1/aarch64/$(IMG_DISK).xz
IMG_DISK_XZ_CHECKSUM := $(IMG_DISK).xz-CHECKSUM
RUN_DEPS := config.ign $(IMG_DISK)

.PHONY: run
run: $(RUN_DEPS)
	chcon --verbose unconfined_u:object_r:svirt_home_t:s0 config.ign
	VIRTINSTALL_OSINFO_DISABLE_REQUIRE=1 \
		virt-install \
			--name=fcos \
			--vcpus=2 \
			--ram=2048 \
			--import \
			--network=user \
			--graphics=none \
			--qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${PWD}/config.ign" \
			--disk=size=20,backing_store=${PWD}/$(IMG_DISK)

# You can verify details of the GPG key at:
# https://fedoraproject.org/security
fedora.gpg:
	curl -O https://fedoraproject.org/fedora.gpg

$(IMG_DISK_XZ_CHECKSUM):
	@echo "You must download and copy the file here"
	@echo "Look at: https://fedoraproject.org/coreos/download?stream=stable&arch=aarch64#download_section"

$(IMG_DISK_XZ):
	curl -L -O "$(IMG_DISK_XZ_URL)"

$(IMG_DISK): $(IMG_DISK_XZ) $(IMG_DISK_XZ_CHECKSUM) $(IMG_DISK_XZ).sig $(IMG_DISK_XZ_CHECKSUM) fedora.gpg
	gpgv --keyring ./fedora.gpg $(IMG_DISK_XZ).sig $(IMG_DISK_XZ)
	sha256sum --ignore-missing -c $(IMG_DISK_XZ_CHECKSUM)
	xz -d -k -f $(IMG_DISK_XZ)

$(IMG_DISK_XZ).sig:
	curl -L -O "https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/42.20250623.3.1/aarch64/$(IMG_DISK_XZ).sig"

config.ign: config.yaml
	fcct --output config.ign config.yaml

config.yaml:
	./scripts/generate-config-yaml.sh

.PHONY: clean
clean:
	virsh destroy fcos
	virsh undefine --remove-all-storage fcos --nvram

