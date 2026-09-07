# AinkradAppKit

The public SDK for building Ainkrad Marketplace plugins. Defines the contract between a plugin
bundle and the host — `AinkradApp`, `AinkradPluginEntryPoint`, and `HostServices` — without
depending on the host binary.

## Building a plugin

Start from the template: https://github.com/AinkradHQ/AinkradPluginTemplate
("Use this template"). For the full scaffold → dev → validate → publish workflow (the
`ainkrad` CLI, the `Info.plist` key reference, and the generation contract this SDK's
`AinkradAppKit.apiVersion` participates in), see
[Build an Ainkrad App](https://github.com/AinkradHQ/AinkradPluginTemplate/blob/master/docs/Build-an-Ainkrad-App.md).
