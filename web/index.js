import express from 'express';
import fetch from 'node-fetch';

const port = process.env.WEB_PORT || 8080;
const ghostunnelPort = process.env.WEB_GHOSTUNNEL_PORT || 8081;

const app = express();

app.get('/backends', async (req, res) => {
  let backendStatuses = {};
  try {
    const response = await fetch(`http://localhost:${ghostunnelPort}`)
    const resJson = await response.json();
    backendStatuses.backend1 = resJson;
    res.status(200).json(backendStatuses);
  } catch (err) {
    console.error(err);
    res.status(500).send(err)
  }
});

app.use(express.static('public'));

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
