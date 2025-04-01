import { createClient } from 'redis';
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

const secretsClient = new SecretsManagerClient({ region: 'us-east-1' });

async function getSecret(secretId) {
  const command = new GetSecretValueCommand({ SecretId: secretId });
  const response = await secretsClient.send(command);
  return JSON.parse(response.SecretString);
}

const secret = await getSecret('valkey-redis-secret');
const redis = createClient({ url: `redis://${secret.host}:6379` });

redis.on('error', err => console.error('Redis error', err));
await redis.connect();

export default redis;