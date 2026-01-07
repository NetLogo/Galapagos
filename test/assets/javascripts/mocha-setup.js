/*

This is all necessary to make DOMPurify happy.  It expects to run in a browser context, so we provide a basic browser
environment via JSDOM so we can run the tests.  -Jeremy B January 2026

*/
import { JSDOM } from 'jsdom';

const dom = new JSDOM('<!DOCTYPE html><html><body></body></html>');
global.window = dom.window;
global.document = dom.window.document;
global.navigator = dom.window.navigator;
global.Node = dom.window.Node;
global.Element = dom.window.Element;
