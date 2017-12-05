{{- $windowsMetadataImage:="llparse/metadata:dev_windows"}}
{{- $windowsDNSImage:="llparse/dns:dev_windows"}}

version: '2'
services:
  windows-metadata:
    cap_add:
    - NET_ADMIN
    image: {{$windowsMetadataImage}}
    network_mode: nat
    labels:
      io.rancher.container.create_agent: "true"
      io.rancher.container.agent.skip_volumes: "true"
      io.rancher.container.create_agent_label: "no"
      io.rancher.scheduler.affinity:host_label: io.rancher.host.os=windows
      io.rancher.scheduler.global: 'true'
      io.rancher.container.agent_service.metadata: 'true'
    logging:
      driver: json-file
      options:
        max-size: 25m
        max-file: '2'
    sysctls:
      net.ipv4.conf.all.send_redirects: '0'
      net.ipv4.conf.default.send_redirects: '0'
      net.ipv4.conf.eth0.send_redirects: '0'
  windows-dns:
    image: {{$windowsDNSImage}}
    network_mode: nat
    command: powershell /start.ps1 --listen=169.254.169.251:53 --metadata-server=169.254.169.250:80 --answers=C:\\answers.json --never-recurse-to=169.254.169.251 --recurser-timeout=${DNS_RECURSER_TIMEOUT} --ttl=${TTL}
    labels:
      io.rancher.scheduler.affinity:host_label: io.rancher.host.os=windows
      io.rancher.scheduler.global: 'true'
    links:
    - windows-metadata
    logging:
      driver: json-file
      options:
        max-size: 25m
        max-file: '2'
