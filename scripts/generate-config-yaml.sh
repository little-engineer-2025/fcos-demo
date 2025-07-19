#!/bin/bash


# @description Generate config.yaml filling with the information
main() {
    cat > "config.yaml" <<EOF
version: "1.0.0"
variant: fcos
passwd:
  users:
    - name: core
      ssh_authorized_keys:
EOF
    for pubkey_file in ~/.ssh/*.pub; do
        readarray pubkeys < "${pubkey_file}"
        for pubkey in "${pubkeys[@]}"; do
            echo "        - ${pubkey}" >> "config.yaml"
        done
    done
    cat >> "config.yaml" <<EOF
systemd:
  units:
    -
      contents: |
          [Unit]
          Description=Run a hello world web service
          After=network-online.target
          Wants=network-online.target
          [Service]
          ExecStart=/bin/podman run --pull=always   --name=hello --net=host -p 8080:8080 quay.io/cverna/hello
          ExecStop=/bin/podman rm -f hello
          [Install]
          WantedBy=multi-user.target
      enabled: true
      name: hello.service
EOF
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    set -e
    main "$@"
    exit $?
fi

