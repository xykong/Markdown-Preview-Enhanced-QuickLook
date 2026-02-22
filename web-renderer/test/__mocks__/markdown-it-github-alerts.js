function MarkdownItGitHubAlerts(md) {
    const CALLOUT_TYPES = ['note', 'tip', 'important', 'warning', 'caution'];
    const originalBlockquote = md.renderer.rules.blockquote_open || function(tokens, idx, options, env, self) {
        return self.renderToken(tokens, idx, options);
    };

    md.core.ruler.push('github_alerts', function(state) {
        const tokens = state.tokens;
        for (let i = 0; i < tokens.length; i++) {
            if (tokens[i].type !== 'blockquote_open') continue;
            const inlineToken = tokens[i + 2];
            if (!inlineToken || inlineToken.type !== 'inline') continue;
            const content = inlineToken.content || '';
            const match = content.match(/^\[!([A-Z]+)\]\n?/);
            if (!match) continue;
            const typeLower = match[1].toLowerCase();
            if (!CALLOUT_TYPES.includes(typeLower)) continue;
            tokens[i].attrSet('data-callout-type', typeLower);
            tokens[i].attrSet('class', 'callout');
            inlineToken.content = content.replace(/^\[![A-Z]+\]\n?/, '');
        }
    });
}
module.exports = MarkdownItGitHubAlerts;
module.exports.default = MarkdownItGitHubAlerts;
