import { Client } from '@opensearch-project/opensearch';
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

const secretsClient = new SecretsManagerClient({ region: 'us-east-1' });

async function getSecret(secretId) {
  const command = new GetSecretValueCommand({ SecretId: secretId });
  const response = await secretsClient.send(command);
  return JSON.parse(response.SecretString);
}

const secret = await getSecret('opensearch-secret');
const client = new Client({
  node: 'https://search-kanto-prod--iitfloqgled4ypbtjq4t7ddqxa.us-east-1.es.amazonaws.com',
  auth: { username: secret.username, password: secret.password }
});

export default client;
