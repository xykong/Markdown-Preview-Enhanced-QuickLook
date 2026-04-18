/**
 * RTL (Right-to-Left) detection tests.
 *
 * Tests the `detectRtlContent` function which determines whether a block of
 * text contains enough RTL characters to justify applying `dir="rtl"` to the
 * rendered markdown container.
 *
 * Unicode ranges covered:
 *   - Arabic:               U+0600–U+06FF
 *   - Arabic Supplement:    U+0750–U+077F
 *   - Hebrew:               U+0590–U+05FF
 *   - Persian (Farsi) uses the Arabic block — covered by Arabic range
 *
 * Threshold: >30% of "strong directional" characters triggers RTL.
 */
import { detectRtlContent } from '../src/rtl';

describe('detectRtlContent', () => {
    // ── Arabic ────────────────────────────────────────────────────────────────
    describe('Arabic text', () => {
        test('returns true for a fully Arabic string', () => {
            // "Hello" in Arabic
            expect(detectRtlContent('مرحبا بالعالم')).toBe(true);
        });

        test('returns true for a paragraph of Arabic prose', () => {
            const arabic = 'هذا نص عربي طويل يحتوي على كلمات وجمل متعددة لاختبار الكشف عن اتجاه النص';
            expect(detectRtlContent(arabic)).toBe(true);
        });

        test('returns true when Arabic chars are >30% of total text', () => {
            // ~50% Arabic, ~50% English
            const mixed = 'Hello مرحبا world كيف حالك';
            expect(detectRtlContent(mixed)).toBe(true);
        });
    });

    // ── Hebrew ────────────────────────────────────────────────────────────────
    describe('Hebrew text', () => {
        test('returns true for a fully Hebrew string', () => {
            // "Hello World" in Hebrew
            expect(detectRtlContent('שלום עולם')).toBe(true);
        });

        test('returns true when Hebrew chars are >30% of total text', () => {
            const mixed = 'Hello שלום world עולם';
            expect(detectRtlContent(mixed)).toBe(true);
        });
    });

    // ── LTR / No RTL ─────────────────────────────────────────────────────────
    describe('left-to-right text', () => {
        test('returns false for purely English text', () => {
            expect(detectRtlContent('Hello, World!')).toBe(false);
        });

        test('returns false for Chinese/CJK text', () => {
            expect(detectRtlContent('你好世界，这是中文文本。')).toBe(false);
        });

        test('returns false for Japanese text', () => {
            expect(detectRtlContent('こんにちは世界')).toBe(false);
        });

        test('returns false for Korean text', () => {
            expect(detectRtlContent('안녕하세요 세계')).toBe(false);
        });

        test('returns false for an empty string', () => {
            expect(detectRtlContent('')).toBe(false);
        });

        test('returns false for whitespace-only string', () => {
            expect(detectRtlContent('   \t\n  ')).toBe(false);
        });

        test('returns false for a string with only numbers and punctuation', () => {
            expect(detectRtlContent('1234567890 !@#$%^&*()')).toBe(false);
        });
    });

    // ── Threshold boundary ────────────────────────────────────────────────────
    describe('RTL ratio threshold (30%)', () => {
        test('returns false when RTL chars are well below 30%', () => {
            // 1 Arabic char in a long English sentence (~2% RTL)
            const text = 'This is a very long English sentence with just one Arabic letter م at the end';
            expect(detectRtlContent(text)).toBe(false);
        });

        test('returns true when RTL chars are clearly above 30%', () => {
            // Roughly half Arabic, half English letters
            const text = 'abc مرحبا def عالم';
            expect(detectRtlContent(text)).toBe(true);
        });
    });

    // ── Markdown content ──────────────────────────────────────────────────────
    describe('markdown-structured content', () => {
        test('returns true for a markdown document written mostly in Arabic', () => {
            const markdown = `# مرحبا بالعالم

هذا مستند مكتوب باللغة العربية.

## القسم الأول

محتوى عربي هنا.
`;
            expect(detectRtlContent(markdown)).toBe(true);
        });

        test('returns true for a markdown document written mostly in Hebrew', () => {
            const markdown = `# שלום עולם

זהו מסמך הכתוב בעברית.

## חלק ראשון

תוכן עברי כאן.
`;
            expect(detectRtlContent(markdown)).toBe(true);
        });

        test('returns false for a typical English markdown document', () => {
            const markdown = `# Hello World

This is an English document with **bold** and *italic* text.

## Section One

- Item one
- Item two
- Item three
`;
            expect(detectRtlContent(markdown)).toBe(false);
        });

        test('returns false for a Chinese markdown document', () => {
            const markdown = `# 你好世界

这是一篇用中文写的文档。

## 第一节

- 第一条
- 第二条
`;
            expect(detectRtlContent(markdown)).toBe(false);
        });
    });
});
