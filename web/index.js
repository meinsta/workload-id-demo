import express from 'express';
import fetch from 'node-fetch';

const app = express();

app.get('/backends', (req, res) => {
  let backendStatuses = {};
  fetch('http://localhost:8081/')
  .then(response => response.json()).then(data => backendStatuses.backend1 = data)
  // .then(() => fetch('http://localhost:8082/')
  // .then(response => backendStatuses.backend2 = response.json())
  // .then(() => fetch('https://localhost:8083/')
  // .then(response => backendStatuses.backend3 = response.json())
  .then(() => res.json(backendStatuses));
  // ));
});

app.get('/test', (req, res) => {
  res.json({
    message: 'Hello from the backend!'
  });
});

app.use(express.static('public'));

app.listen(8080, () => {
  console.log('Server is running on http://localhost:8080');
});
