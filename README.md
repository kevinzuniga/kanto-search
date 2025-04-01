# Song Search App with Redis Valkey and OpenSearch

## Requisitos

- AWS CLI configurado
- Terraform instalado
- Node.js 18+

## Pasos

1. Crea los secretos en Secrets Manager:
   - `valkey-redis-secret`: `{ "host": "<redis-endpoint>" }`
   - `opensearch-secret`: `{ "username": "admin", "password": "..." }`

2. Ejecuta Terraform:

```bash
cd terraform
terraform init
terraform apply
```

3. Instala dependencias de Node:

```bash
npm install
```

4. Ejecuta localmente:

```bash
node src/index.js
```

La app se expone en `http://localhost:3000`
