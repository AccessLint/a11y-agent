const express = require('express');
const app = express();

app.use('/', (req, res) => {
  res.status(200).sendFile(`${__dirname}/index.html`);
});

app.listen(8080);