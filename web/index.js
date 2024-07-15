import express from 'express';
import fetch from 'node-fetch';

const port = process.env.WEB_PORT || 8080;
const ghostunnelOnePort = process.env.WEB_GHOSTUNNEL_ONE_PORT || 8081;
const ghostunnelTwoPort = process.env.WEB_GHOSTUNNEL_TWO_PORT || 8082;

const app = express();

app.get('/backends', async (req, res) => {
  let backendStatuses = {};
  try {
    const responseOne = await fetch(`http://localhost:${ghostunnelOnePort}`)
    const resJsonOne = await responseOne.json();
    backendStatuses.backend1 = resJsonOne;

    const responseTwo = await fetch(`http://localhost:${ghostunnelTwoPort}`)
    const resJsonTwo = await responseTwo.json();
    backendStatuses.backend2 = resJsonTwo;

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
