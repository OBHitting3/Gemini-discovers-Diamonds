"use strict";

const noBannedImports = require("./lib/rules/no-banned-imports");

/** @type {import('eslint').ESLint.Plugin} */
module.exports = {
  meta: {
    name: "eslint-plugin-no-sdk",
    version: "1.0.0",
  },
  rules: {
    "no-banned-imports": noBannedImports,
  },
  configs: {
    recommended: {
      plugins: ["no-sdk"],
      rules: {
        "no-sdk/no-banned-imports": "error",
      },
    },
  },
};
