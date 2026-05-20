/*

This is all necessary to make DOMPurify happy.  It expects to run in a browser context, so we provide a basic browser
environment via JSDOM so we can run the tests.  -Jeremy B January 2026

*/
import { JSDOM } from 'jsdom';

const dom = new JSDOM('<!DOCTYPE html><html><body></body></html>');
global.window = dom.window;
global.document = dom.window.document;
// Node 21+ made global.navigator a read-only getter, so we must use defineProperty.
Object.defineProperty(global, 'navigator', { value: dom.window.navigator, configurable: true, writable: true });
global.Node = dom.window.Node;
global.Element = dom.window.Element;

// Minimal stub for the workspace global accessed by the DOMPurify uponSanitizeElement hook
// in tortoise-utils.coffee. Tests that exercise image resource substitution can populate
// global.workspace.resources directly and restore it afterward.
global.workspace = { resources: {} };
