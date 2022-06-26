# Particl Protocol

Particl Protocol is a protocol deployed on [Internet Computer Blockchain](https://internetcomputer.org/). This is a proof of concept for how NFT's could be manipulated by users on a binary level in a seamless way. For a full walk through you can check the [demo](https://www.youtube.com/watch?v=7TbfGFpjTSk).

## General Info

The Smart Contracts are written in [Motoko](https://github.com/dfinity/motoko), the official language of Internet Computer. Contracts make use of dynamic actor creation for storage.

## Install

In order to start the project you will need to have installed [dfx](https://internetcomputer.org/docs/current/developer-docs/quickstart/hello10mins#dfx). You will also need to configure your environment by replacing values in env.mo.

#### Commands

```bash
dfx start --clean
dfx deploy
dfx canister call manager createStorage
```

## Contributing

If you are interested in the project please follow the offical [discord](https://discord.gg/5GZYmJjG) or reach directly to me using [this](https://cristianbuta.eth.limo/).

## License

[BSD-3-Clause](https://opensource.org/licenses/BSD-3-Clause)
