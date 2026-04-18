jest.mock('mermaid', () => ({
  initialize: jest.fn(),
  render: jest.fn().mockResolvedValue({ svg: '<svg>mocked</svg>' }),
}));

import '../src/index';

describe('wheel event scroll-fix (issue #21)', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="markdown-preview"></div>';
    Object.defineProperty(window, 'scrollY', { value: 0, writable: true, configurable: true });
  });

  test('normal wheel event (ctrlKey=false) is NOT intercepted', () => {
    const scrollBySpy = jest.spyOn(window, 'scrollBy').mockImplementation(() => {});

    const event = new WheelEvent('wheel', {
      ctrlKey: false,
      deltaY: 100,
      cancelable: true,
      bubbles: true,
    });
    const preventDefaultSpy = jest.spyOn(event, 'preventDefault');

    document.dispatchEvent(event);

    expect(preventDefaultSpy).not.toHaveBeenCalled();
    expect(scrollBySpy).not.toHaveBeenCalled();

    scrollBySpy.mockRestore();
  });

  test('wheel event with ctrlKey=true calls scrollBy instead of zooming', () => {
    const scrollBySpy = jest.spyOn(window, 'scrollBy').mockImplementation(() => {});

    const event = new WheelEvent('wheel', {
      ctrlKey: true,
      deltaY: 50,
      cancelable: true,
      bubbles: true,
    });
    const preventDefaultSpy = jest.spyOn(event, 'preventDefault');

    document.dispatchEvent(event);

    expect(preventDefaultSpy).toHaveBeenCalled();
    expect(scrollBySpy).toHaveBeenCalledWith(0, 50);

    scrollBySpy.mockRestore();
  });

  test('wheel event with ctrlKey=true and negative deltaY scrolls up', () => {
    const scrollBySpy = jest.spyOn(window, 'scrollBy').mockImplementation(() => {});

    const event = new WheelEvent('wheel', {
      ctrlKey: true,
      deltaY: -80,
      cancelable: true,
      bubbles: true,
    });

    document.dispatchEvent(event);

    expect(scrollBySpy).toHaveBeenCalledWith(0, -80);

    scrollBySpy.mockRestore();
  });

  test('wheel event with ctrlKey=true also passes deltaX for horizontal scroll', () => {
    const scrollBySpy = jest.spyOn(window, 'scrollBy').mockImplementation(() => {});

    const event = new WheelEvent('wheel', {
      ctrlKey: true,
      deltaX: 30,
      deltaY: 0,
      cancelable: true,
      bubbles: true,
    });

    document.dispatchEvent(event);

    expect(scrollBySpy).toHaveBeenCalledWith(30, 0);

    scrollBySpy.mockRestore();
  });
});
