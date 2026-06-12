"use strict";

/**
 * @fileoverview ESLint rule: no-banned-imports
 * Prevents direct SDK imports that violate MCP-only architecture.
 * Banned packages: @supabase/*, @stripe/*, @elevenlabs/*
 */

const BANNED_PREFIXES = [
  "@supabase/",
  "@stripe/",
  "@elevenlabs/",
];

/** @type {import('eslint').Rule.RuleModule} */
module.exports = {
  meta: {
    type: "problem",
    docs: {
      description:
        "Disallow direct SDK imports — use MCP tools instead (@supabase/*, @stripe/*, @elevenlabs/*)",
      category: "Architecture",
      recommended: true,
    },
    messages: {
      bannedImport:
        "Direct SDK import '{{ importPath }}' is banned. Use MCP tools instead. " +
        "This project enforces an MCP-only architecture.",
    },
    schema: [
      {
        type: "object",
        properties: {
          additionalBanned: {
            type: "array",
            items: { type: "string" },
          },
        },
        additionalProperties: false,
      },
    ],
  },

  create(context) {
    const options = context.options[0] || {};
    const additionalBanned = options.additionalBanned || [];
    const allBanned = [...BANNED_PREFIXES, ...additionalBanned];

    function isBanned(importPath) {
      return allBanned.some((prefix) => importPath.startsWith(prefix));
    }

    return {
      ImportDeclaration(node) {
        const importPath = node.source.value;
        if (isBanned(importPath)) {
          context.report({
            node,
            messageId: "bannedImport",
            data: { importPath },
          });
        }
      },

      // Also catch require() calls
      CallExpression(node) {
        if (
          node.callee.type === "Identifier" &&
          node.callee.name === "require" &&
          node.arguments.length > 0 &&
          node.arguments[0].type === "Literal" &&
          typeof node.arguments[0].value === "string"
        ) {
          const importPath = node.arguments[0].value;
          if (isBanned(importPath)) {
            context.report({
              node,
              messageId: "bannedImport",
              data: { importPath },
            });
          }
        }
      },
    };
  },
};
