const { SecretsManager } = require("@chainlink/functions-toolkit");
const ethers = require("ethers"); // ethers v5
require("@chainlink/env-enc").config();

const encryptSecretGist = async () => {
  const routerAddress = "0xb83E47C2bC239B3bf370bc41e1459A34b41238D0";
  const donId = "fun-ethereum-sepolia-1";

  const privateKey = process.env.PRIVATE_KEY;
  if (!privateKey)
    throw new Error(
      "private key not provided - check your environment variables"
    );

  const rpcUrl = process.env.ETHEREUM_SEPOLIA_RPC_URL;
  if (!rpcUrl)
    throw new Error(`rpcUrl not provided  - check your environment variables`);

  const secrets = { SOLIDITY_API_KEY: process.env.OPENWEATHER_API_KEY };

  const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(privateKey, provider);

  const secretsManager = new SecretsManager({
    signer: wallet,
    functionsRouterAddress: routerAddress,
    donId: donId,
  });
  await secretsManager.initialize();

  const encryptedSecretsObj = await secretsManager.encryptSecrets(secrets);

  console.log(`Secret encrypted:`, encryptedSecretsObj);
};

encryptSecretGist().catch((e) => {
  console.error(e);
  process.exit(1);
});
