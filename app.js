const express = require('express');

const prometheus = require('prom-client');
const promBundle = require('express-prom-bundle');
const collectDefaultMetrics = prometheus.collectDefaultMetrics;
const prefix = 'echo_webapp_';

collectDefaultMetrics({ prefix });

const labels = {
  pod: process.env.HOSTNAME,
  test: 'harcoded test'
};

const echoedMessagesCounter = new prometheus.Counter({
    name: 'echoed_messages_total',
    help: 'Total number of echoed messages',
    labelNames: Object.keys(labels)
  });

prometheus.register.registerMetric(echoedMessagesCounter);

// const httpRequestCounter = new prometheus.Counter({
//   name: 'http_requests_total',
//   help: 'Total number of HTTP requests',
//   labelNames: ['method', 'path', 'status'],
// });

const metricsMiddleware = promBundle({
  includeMethod: true,
  includePath: true,
});

const app = express();
app.use(metricsMiddleware);
const port = 8080;

app.get('/', (req, res) => {
  res.json({ message: 'Virtuo technical test echo app' });
});

app.get('/metrics', (req, res) => {
    res.setHeader('Content-Type', prometheus.register.contentType)
    prometheus.register.metrics().then(data => res.send(data));
});

app.get('/echo', (req, res) => {

  if (!req.query.msg) {
    res.status(404).json({ message: `no msg provided` });
  }

  const msg = req.query.msg.toLowerCase().replace(/\s+/g, '') === "helloworld" ?  "Hello World !" : req.query.msg

  echoedMessagesCounter.inc(labels, 1);
  res.status(200).json({ message: `${msg}` });
});



app.get('/healthz', async (req, res) => {
        res.sendStatus(200);
});

app.listen(port, () => {

  console.log(`Server is running on http://localhost:${port}`);

});

