const express = require('express');
const app = express();
app.use(express.static(`${__dirname}/public`));


app.use('/', (req, res) => {
  res.status(200).sendFile(`${__dirname}/public/index.html`);
});

app.listen(8080);