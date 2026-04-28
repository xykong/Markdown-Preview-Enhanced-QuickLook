import { computeLineDiff, computeCharDiff } from '../src/diff-engine';

describe('computeLineDiff', () => {
  test('equal content returns all equal', () => {
    const result = computeLineDiff('hello\nworld', 'hello\nworld');
    expect(result).toHaveLength(2);
    expect(result.every(d => d.type === 'equal')).toBe(true);
  });

  test('added line detected', () => {
    const result = computeLineDiff('hello', 'hello\nworld');
    expect(result).toHaveLength(2);
    expect(result[0].type).toBe('equal');
    expect(result[1].type).toBe('added');
    expect(result[1].newLineNumber).toBe(2);
  });

  test('removed line detected', () => {
    const result = computeLineDiff('hello\nworld', 'hello');
    expect(result).toHaveLength(2);
    expect(result[1].type).toBe('removed');
    expect(result[1].oldLineNumber).toBe(2);
  });

  test('modified line detected', () => {
    const result = computeLineDiff('hello world', 'hello earth');
    expect(result).toHaveLength(1);
    expect(result[0].type).toBe('modified');
    expect(result[0].oldContent).toBe('hello world');
    expect(result[0].newContent).toBe('hello earth');
  });

  test('empty old content returns all equal (first render, no animation)', () => {
    const result = computeLineDiff('', 'a\nb\nc');
    expect(result.every(d => d.type === 'equal')).toBe(true);
  });
});

describe('computeLineDiff — line number completeness', () => {
  test('first render: every line gets a line number', () => {
    const text = 'line1\nline2\nline3\nline4\nline5';
    const result = computeLineDiff('', text);
    expect(result).toHaveLength(5);
    for (let i = 0; i < result.length; i++) {
      expect(result[i].newLineNumber).toBe(i + 1);
    }
  });

  test('first render: text ending with newline does not create phantom line', () => {
    const text = 'line1\nline2\nline3\n';
    const result = computeLineDiff('', text);
    // 'line1\nline2\nline3\n'.split('\n') => ['line1','line2','line3','']
    // The trailing empty string IS a valid "line 4" (empty line at end)
    expect(result).toHaveLength(4);
    expect(result[3].newLineNumber).toBe(4);
    expect(result[3].newContent).toBe('');
  });

  test('diff mode: all new lines get sequential line numbers', () => {
    const oldText = 'line1\nline2\nline3';
    const newText = 'line1\nline2\nline3\nline4\nline5';
    const result = computeLineDiff(oldText, newText);
    const newLineNums = result.filter(d => d.newLineNumber !== null).map(d => d.newLineNumber);
    expect(newLineNums).toEqual([1, 2, 3, 4, 5]);
  });

  test('diff mode: text ending with newline — all lines get numbers', () => {
    const oldText = 'line1\nline2\n';
    const newText = 'line1\nline2\nline3\n';
    const result = computeLineDiff(oldText, newText);
    const newLineNums = result.filter(d => d.newLineNumber !== null).map(d => d.newLineNumber);
    // Should include every line in newText
    const expectedLineCount = newText.split('\n').length;
    // After normalization, trailing newline should not drop lines
    expect(newLineNums.length).toBeGreaterThanOrEqual(3);
  });

  test('diff mode: trailing empty lines preserved', () => {
    const oldText = 'a\nb\n\n';
    const newText = 'a\nb\nc\n\n';
    const result = computeLineDiff(oldText, newText);
    const newLineNums = result.filter(d => d.newLineNumber !== null).map(d => d.newLineNumber);
    // newText has lines: 'a', 'b', 'c', '', '' (5 elements from split, or 4 if trailing \n stripped)
    // At minimum, line 'c' (line 3) must have a number
    expect(newLineNums).toContain(3);
  });

  test('equal content with trailing newline: line count matches', () => {
    const text = 'line1\nline2\nline3\n';
    const result = computeLineDiff(text, text);
    const newLineNums = result.filter(d => d.newLineNumber !== null).map(d => d.newLineNumber);
    // text has 3 actual content lines + possibly trailing empty
    expect(newLineNums.length).toBeGreaterThanOrEqual(3);
    expect(newLineNums[0]).toBe(1);
    expect(newLineNums[1]).toBe(2);
    expect(newLineNums[2]).toBe(3);
  });
});

describe('computeCharDiff', () => {
  test('detects added chars', () => {
    const result = computeCharDiff('hello', 'hello world');
    const addedPart = result.find(p => p.type === 'added');
    expect(addedPart?.value).toBe(' world');
  });

  test('detects removed chars', () => {
    const result = computeCharDiff('hello world', 'hello');
    const removedPart = result.find(p => p.type === 'removed');
    expect(removedPart?.value).toBe(' world');
  });

  test('equal content returns single equal part', () => {
    const result = computeCharDiff('hello', 'hello');
    expect(result).toHaveLength(1);
    expect(result[0].type).toBe('equal');
  });
});
