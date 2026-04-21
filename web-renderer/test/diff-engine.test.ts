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
