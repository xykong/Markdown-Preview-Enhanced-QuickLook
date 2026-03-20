import { preprocessMermaidNewlines } from '../src/index';

describe('preprocessMermaidNewlines', () => {
    describe('basic substitution', () => {
        test('replaces \\n inside double-quoted label', () => {
            const input = 'A["line1\\nline2"]';
            expect(preprocessMermaidNewlines(input)).toBe('A["line1<br/>line2"]');
        });

        test('replaces multiple \\n in a single label', () => {
            const input = 'A["原始写法\\n6x get_json_object\\n173 秒"]';
            expect(preprocessMermaidNewlines(input)).toBe('A["原始写法<br/>6x get_json_object<br/>173 秒"]');
        });

        test('replaces \\n across several nodes in one diagram', () => {
            const input = [
                'graph LR',
                '    A["原始写法\\n6x get_json_object\\n173 秒"] -->|"2x 提速"| B["优化写法\\n子对象 + json_tuple\\n52~82 秒"]',
                '    B -->|"未来进一步优化"| C["ETL 拍平\\n独立字段列\\n预计再提速 10x+"]',
            ].join('\n');

            const result = preprocessMermaidNewlines(input);
            expect(result).toContain('"原始写法<br/>6x get_json_object<br/>173 秒"');
            expect(result).toContain('"优化写法<br/>子对象 + json_tuple<br/>52~82 秒"');
            expect(result).toContain('"ETL 拍平<br/>独立字段列<br/>预计再提速 10x+"');
        });
    });

    describe('does not touch content outside quotes', () => {
        test('leaves bare node labels untouched', () => {
            const input = 'A --> B';
            expect(preprocessMermaidNewlines(input)).toBe('A --> B');
        });

        test('leaves diagram keywords untouched', () => {
            const input = 'graph LR\n    A --> B';
            expect(preprocessMermaidNewlines(input)).toBe('graph LR\n    A --> B');
        });

        test('leaves edge labels without \\n untouched', () => {
            const input = 'A -->|"some label"| B';
            expect(preprocessMermaidNewlines(input)).toBe('A -->|"some label"| B');
        });
    });

    describe('edge cases', () => {
        test('returns empty string unchanged', () => {
            expect(preprocessMermaidNewlines('')).toBe('');
        });

        test('handles label with no \\n as a no-op', () => {
            const input = 'A["just a label"]';
            expect(preprocessMermaidNewlines(input)).toBe('A["just a label"]');
        });

        test('handles escaped quote inside label without corrupting surrounding text', () => {
            const input = 'A["say \\"hello\\"\\nworld"]';
            expect(preprocessMermaidNewlines(input)).toBe('A["say \\"hello\\"<br/>world"]');
        });

        test('handles \\n at the very start of a label', () => {
            const input = 'A["\\nfoo"]';
            expect(preprocessMermaidNewlines(input)).toBe('A["<br/>foo"]');
        });

        test('handles \\n at the very end of a label', () => {
            const input = 'A["foo\\n"]';
            expect(preprocessMermaidNewlines(input)).toBe('A["foo<br/>"]');
        });

        test('does not double-process already-converted <br/>', () => {
            const input = 'A["foo<br/>bar"]';
            expect(preprocessMermaidNewlines(input)).toBe('A["foo<br/>bar"]');
        });

        test('handles multiple quoted strings on the same line', () => {
            const input = 'A["foo\\nbar"] --> B["baz\\nqux"]';
            expect(preprocessMermaidNewlines(input)).toBe('A["foo<br/>bar"] --> B["baz<br/>qux"]');
        });
    });
});
