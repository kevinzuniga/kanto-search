import express from 'express';
import redis from './redis.js';
import client from './opensearch.js';

const app = express();
app.use(express.json());

app.get('/search', async (req, res) => {
  const { q, userId, country } = req.query;

  const result = await client.search({
    index: 'songs',
    body: { query: { match: { title: q } } }
  });

  const hits = result.hits.hits;

  for (let hit of hits) {
    await redis.zIncrBy(`popular:songs:${country}`, 1, hit._id);
  }

  res.json(hits);
});

app.get('/top', async (req, res) => {
  const { country } = req.query;
  const top = await redis.zRange(`popular:songs:${country}`, -5, -1, { REV: true });
  res.json(top);
});

app.listen(3000, () => console.log('App running on port 3000'));
