# The Operator Foundation

[Operator](https://operatorfoundation.org) makes useable tools to help people around the world with censorship, security, and privacy.

## Moonbounce

Moonbounce is graphical user interface for configuring a VPN with Pluggable Transport support designed to connect to [Persona](https://www.github.com/OperatorFoundation/Persona) servers. The goal of Moonbounce is to provide a usability-focused, streamlined user experience to using PT-enabled VPNs.
### VPNs on macOS

The preferred method for VPN integration on macOS is now to use the NetworkExtension framework to configure system VPN settings, as well as to implement an application's custom VPN protocol.

### ReplicantSwiftServer

A conequence of the way that Apple has implement their VPN API on macOS is that incorporating Pluggable Transports into the VPN configuration requires implementing a custom VPN protocol in Swift. This makes it difficult to use existing VPN protocols such as OpenVPN or Wireguard. It is possible to make this work, but it's time consuming to implement. Operator has opted to instead include a very simple protocol written in Swift to convey packets between the client and server. Therefore, Moonbounce can only be used with Operator's VPN server implementation, ReplicantSwiftServer. This provides a VPN server which runs on Linux and includes the Replicant transport.

### Replicant

Replicant is Operator's flagship Pluggable Transport. It is bundled with Moonbounce.
