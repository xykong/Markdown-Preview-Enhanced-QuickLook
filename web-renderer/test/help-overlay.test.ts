import { HelpOverlay } from '../src/help-overlay';

jest.useFakeTimers();

function fireKeydown(key: string, extra: Partial<KeyboardEvent> = {}): void {
    document.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true, ...extra }));
}

function fireKeyup(key: string): void {
    document.dispatchEvent(new KeyboardEvent('keyup', { key, bubbles: true }));
}

describe('HelpOverlay — Cmd-hold trigger', () => {
    let overlay: HelpOverlay;

    beforeEach(() => {
        document.body.innerHTML = '';
        localStorage.clear();
        overlay = new HelpOverlay();
    });

    afterEach(() => {
        jest.clearAllTimers();
    });

    test('pure Cmd hold for 2s shows the overlay', () => {
        fireKeydown('Meta');
        jest.advanceTimersByTime(2000);
        expect(overlay['isVisible']).toBe(true);
    });

    test('Cmd released before 2s does NOT show overlay', () => {
        fireKeydown('Meta');
        jest.advanceTimersByTime(1000);
        fireKeyup('Meta');
        jest.advanceTimersByTime(2000);
        expect(overlay['isVisible']).toBe(false);
    });

    test('Cmd+Tab (non-modifier key while Cmd held) does NOT show overlay', () => {
        fireKeydown('Meta');
        jest.advanceTimersByTime(500);
        fireKeydown('Tab');
        jest.advanceTimersByTime(2000);
        expect(overlay['isVisible']).toBe(false);
    });

    test('Cmd+Space (boss key pattern) does NOT show overlay', () => {
        fireKeydown('Meta');
        jest.advanceTimersByTime(500);
        fireKeydown(' ');
        jest.advanceTimersByTime(2000);
        expect(overlay['isVisible']).toBe(false);
    });

    test('Cmd+Ctrl (modifier-only combo) still allows overlay to show', () => {
        fireKeydown('Meta');
        jest.advanceTimersByTime(500);
        fireKeydown('Control');
        jest.advanceTimersByTime(2000);
        expect(overlay['isVisible']).toBe(true);
    });

    test('Cmd+Shift (modifier-only combo) still allows overlay to show', () => {
        fireKeydown('Meta');
        jest.advanceTimersByTime(500);
        fireKeydown('Shift');
        jest.advanceTimersByTime(2000);
        expect(overlay['isVisible']).toBe(true);
    });

    test('Cmd+Ctrl+X (boss key with extra key) does NOT show overlay', () => {
        fireKeydown('Meta');
        jest.advanceTimersByTime(200);
        fireKeydown('Control');
        jest.advanceTimersByTime(200);
        fireKeydown('x');
        jest.advanceTimersByTime(2000);
        expect(overlay['isVisible']).toBe(false);
    });
});

describe('HelpOverlay — Cmd-hold checkbox preference', () => {
    let overlay: HelpOverlay;

    beforeEach(() => {
        document.body.innerHTML = '';
        localStorage.clear();
        overlay = new HelpOverlay();
    });

    afterEach(() => {
        jest.clearAllTimers();
    });

    test('Cmd-hold enabled by default (no localStorage entry)', () => {
        expect(overlay['isCmdHoldEnabled']()).toBe(true);
    });

    test('setCmdHoldEnabled(false) persists to localStorage', () => {
        overlay['setCmdHoldEnabled'](false);
        expect(overlay['isCmdHoldEnabled']()).toBe(false);
    });

    test('setCmdHoldEnabled(true) restores to enabled', () => {
        overlay['setCmdHoldEnabled'](false);
        overlay['setCmdHoldEnabled'](true);
        expect(overlay['isCmdHoldEnabled']()).toBe(true);
    });

    test('Cmd hold does NOT show overlay when disabled', () => {
        overlay['setCmdHoldEnabled'](false);
        fireKeydown('Meta');
        jest.advanceTimersByTime(2000);
        expect(overlay['isVisible']).toBe(false);
    });

    test('Cmd hold shows overlay when re-enabled', () => {
        overlay['setCmdHoldEnabled'](false);
        overlay['setCmdHoldEnabled'](true);
        fireKeydown('Meta');
        jest.advanceTimersByTime(2000);
        expect(overlay['isVisible']).toBe(true);
    });

    test('checkbox is rendered in footer in App mode', () => {
        window.__fluxContext = 'app';
        overlay.show();
        const checkbox = document.querySelector('#help-cmd-hold-checkbox');
        expect(checkbox).not.toBeNull();
        window.__fluxContext = undefined;
    });

    test('checkbox is NOT rendered in QuickLook mode', () => {
        window.__fluxContext = 'quicklook';
        overlay.show();
        const checkbox = document.querySelector('#help-cmd-hold-checkbox');
        expect(checkbox).toBeNull();
        window.__fluxContext = undefined;
    });

    test('checkbox is checked by default', () => {
        window.__fluxContext = 'app';
        overlay.show();
        const checkbox = document.querySelector<HTMLInputElement>('#help-cmd-hold-checkbox');
        expect(checkbox?.checked).toBe(true);
        window.__fluxContext = undefined;
    });

    test('checkbox unchecked when preference is disabled', () => {
        overlay['setCmdHoldEnabled'](false);
        window.__fluxContext = 'app';
        overlay.show();
        const checkbox = document.querySelector<HTMLInputElement>('#help-cmd-hold-checkbox');
        expect(checkbox?.checked).toBe(false);
        window.__fluxContext = undefined;
    });
});
