// strip-thinking.js
// Strips thinking/reasoning parameters that local models don't support.

module.exports = class StripThinking {
  name = "strip-thinking";

  async transformRequestIn(body) {
    // Remove reasoning config from request body
    delete body.reasoning;

    // Remove thinking blocks from message history
    if (Array.isArray(body.messages)) {
      for (const msg of body.messages) {
        delete msg.thinking;
      }
    }

    return body;
  }
};
