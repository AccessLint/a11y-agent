#!/usr/bin/env node

import { readFileSync } from "node:fs";
import axe from "axe-core"
import { JSDOM } from "jsdom";

const markup = readFileSync(process.argv[2], "utf8");
const { window: { document } } = new JSDOM(markup);

const config = {
  rules: {
    'color-contrast': { enabled: false },
    'region': { enabled: false },
  }
};

axe.run(document.body, config).then((results) => {
  console.log(JSON.stringify(results.violations));
});
