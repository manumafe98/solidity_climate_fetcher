const { SecretsManager, createGist } = require("@chainlink/functions-toolkit");
const ethers = require("ethers");
require("@chainlink/env-enc").config();

const encryptSecretGist = async () => {
  const routerAddress = "0xb83E47C2bC239B3bf370bc41e1459A34b41238D0";
  const donId = "fun-ethereum-sepolia-1";
  const secrets = { SOLIDITY_API_KEY: process.env.OPENWEATHER_API_KEY };
  const githubApiToken = process.env.GITHUB_API_TOKEN;

  const privateKey = process.env.PRIVATE_KEY;
  if (!privateKey)
    throw new Error(
      "private key not provided - check your environment variables"
    );

  const rpcUrl = process.env.ETHEREUM_SEPOLIA_RPC_URL;
  if (!rpcUrl)
    throw new Error(`rpcUrl not provided  - check your environment variables`);

  const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(privateKey, provider);

  const secretsManager = new SecretsManager({
    signer: wallet,
    functionsRouterAddress: routerAddress,
    donId: donId,
  });
  await secretsManager.initialize();

  const encryptedSecretsObj = await secretsManager.encryptSecrets(secrets);

  console.log("Creating gist...");

  const gistURL = await createGist(
    githubApiToken,
    JSON.stringify(encryptedSecretsObj)
  );

  console.log(`\n✅Gist created ${gistURL} . Encrypt the URLs..`);

  console.log("\nEncryipting gist...");

  const encryptedSecretsUrls = await secretsManager.encryptSecretsUrls([
    gistURL,
  ]);

  console.log(`\n✅Encrypted Secrets url result: ${encryptedSecretsUrls}`);
}

encryptSecretGist().catch((e) => {
  console.error(e);
  process.exit(1);
});
