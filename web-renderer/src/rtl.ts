const RTL_CHAR_REGEX = /[\u0590-\u05FF\u0600-\u06FF\u0750-\u077F]/g;
const RTL_RATIO_THRESHOLD = 0.3;

export function detectRtlContent(text: string): boolean {
    if (!text || !text.trim()) return false;

    const totalLetters = text.replace(/\s/g, '').length;
    if (totalLetters === 0) return false;

    const rtlMatches = text.match(RTL_CHAR_REGEX);
    const rtlCount = rtlMatches ? rtlMatches.length : 0;

    return rtlCount / totalLetters > RTL_RATIO_THRESHOLD;
}
