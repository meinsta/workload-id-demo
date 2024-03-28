import express from 'express';
import fetch from 'node-fetch';

const port = process.env.WEB_PORT || 8080;
const ghostunnelPort = process.env.WEB_GHOSTUNNEL_PORT || 8081;

const app = express();

app.get('/backends', (req, res) => {
  let backendStatuses = {};
  fetch(`http://localhost:${ghostunnelPort}`)
  .then(response => response.json()).then(data => backendStatuses.backend1 = data)
  // .then(() => fetch('http://localhost:8082/')
  // .then(response => backendStatuses.backend2 = response.json())
  // .then(() => fetch('https://localhost:8083/')
  // .then(response => backendStatuses.backend3 = response.json())
  .then(() => res.json(backendStatuses));
  // ));
});

app.use(express.static('public'));

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
