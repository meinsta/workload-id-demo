import express from "express";
import fetch from "node-fetch";

const port = process.env.WEB_PORT || 8080;
const ghostunnelOnePort = process.env.WEB_GHOSTUNNEL_ONE_PORT || 8081;
const ghostunnelTwoPort = process.env.WEB_GHOSTUNNEL_TWO_PORT || 8082;

const app = express();

app.get("/backend1", async (req, res) => {
  let backendStatuses = {};
  try {
    // AFTER: No Authorization header needed - mTLS handled by ghostunnel + SVID
    // Authentication is cryptographic via client certificate, not bearer token
    const responseOne = await fetch(`http://localhost:${ghostunnelOnePort}`);
    const resJsonOne = await responseOne.json();
    backendStatuses.backend1 = resJsonOne;

    res.status(200).json(backendStatuses);
  } catch (err) {
    console.error(err);
    res.status(500).send(err);
  }
});

app.get("/backend2", async (req, res) => {
  let backendStatuses = {};
  try {
    // AFTER: No Authorization header needed - mTLS handled by ghostunnel + SVID
    // Authentication is cryptographic via client certificate, not bearer token
    const responseTwo = await fetch(`http://localhost:${ghostunnelTwoPort}`);
    const resJsonTwo = await responseTwo.json();
    backendStatuses.backend2 = resJsonTwo;

    res.status(200).json(backendStatuses);
  } catch (err) {
    console.error(err);
    res.status(500).send(err);
  }
});

// Status endpoint - shows certificate expiry countdown (no API key expiry to track!)
app.get("/status", async (req, res) => {
  try {
    // Call backend /whoami to get current certificate status
    const whoamiResponse = await fetch(`http://localhost:${ghostunnelOnePort}/whoami`);
    const whoamiData = await whoamiResponse.json();
    
    const statusData = {
      authentication_method: "mTLS via Teleport Workload Identity",
      no_api_keys: true,
      certificate_status: {
        spiffe_id: whoamiData.spiffe_id,
        expires_in: whoamiData.expires_in,
        auto_rotation: "managed by tbot"
      },
      note: "Identity is cryptographic, not a shared secret"
    };
    
    res.status(200).json(statusData);
  } catch (err) {
    console.error("Status check failed:", err);
    res.status(500).json({
      authentication_method: "mTLS via Teleport Workload Identity", 
      no_api_keys: true,
      error: "Could not fetch certificate status",
      note: "Identity is still cryptographic, not a shared secret"
    });
  }
});

app.use(express.static("public"));

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
