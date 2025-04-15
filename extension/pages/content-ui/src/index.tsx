// import { createRoot } from 'react-dom/client';
// import App from '@src/App';
// // @ts-expect-error Because file doesn't exist before build
// import tailwindcssOutput from '../dist/tailwind-output.css?inline';
// import { detectSite } from '../../content/src/sites'
// import { PropertyData } from './types';

// console.log('[RealEst] Content UI script loaded at:', new Date().toISOString());

// // Initialize the content UI
// async function initialize() {
//   try {
//     // Detect which real estate site we're on
//     const site = detectSite(window.location.href);
//     if (!site) {
//       console.log('[RealEst] Not on a supported real estate site');
//       return;
//     }

//     console.log(`[RealEst] Detected ${site.name} site`);

//     // Extract property data
//     const propertyData = await site.extractPropertyData();
//     if (!propertyData || !propertyData.price) {
//       console.warn('[RealEst] Could not extract property data');
//       return;
//     }

//     console.log('[RealEst] Extracted property data', propertyData);

//     // Set up the UI with the property data
//     setupUI(propertyData);
//   } catch (error) {
//     console.error('[RealEst] Initialization error:', error);
//   }
// }

// // Set up the UI with the extracted property data
// function setupUI(propertyData: PropertyData) {
//   const root = document.createElement('div');
//   root.id = 'realest-extension-root';
//   document.body.append(root);

//   const rootIntoShadow = document.createElement('div');
//   rootIntoShadow.id = 'shadow-root';

//   const shadowRoot = root.attachShadow({ mode: 'open' });

//   if (navigator.userAgent.includes('Firefox')) {
//     const styleElement = document.createElement('style');
//     styleElement.innerHTML = tailwindcssOutput;
//     shadowRoot.appendChild(styleElement);
//   } else {
//     const globalStyleSheet = new CSSStyleSheet();
//     globalStyleSheet.replaceSync(tailwindcssOutput);
//     shadowRoot.adoptedStyleSheets = [globalStyleSheet];
//   }

//   shadowRoot.appendChild(rootIntoShadow);
//   createRoot(rootIntoShadow).render(<App propertyData={propertyData} />);

//   // Set up a MutationObserver to detect DOM changes and maintain UI visibility
//   setupMutationObserver(propertyData);
// }

// // Set up a MutationObserver to detect DOM changes
// function setupMutationObserver(propertyData: PropertyData) {
//   const observer = new MutationObserver((mutations) => {
//     // Check if our UI root was removed
//     if (!document.getElementById('realest-extension-root')) {
//       console.log('[RealEst] UI root was removed, re-initializing...');
//       setupUI(propertyData);
//     }
//   });
  
//   // Start observing the document body for changes
//   observer.observe(document.body, {
//     childList: true,
//     subtree: true
//   });
// }

// // Initialize when the document is ready
// if (document.readyState === 'loading') {
//   document.addEventListener('DOMContentLoaded', initialize);
// } else {
//   // Document already loaded, wait a moment to ensure DOM is stable
//   setTimeout(initialize, 1000);
// }

// // Listen for messages from the content script
// window.addEventListener('message', (event) => {
//   if (event.data && event.data.type === 'REALEST_PROPERTY_DATA') {
//     console.log('[RealEst] Received property data from content script:', event.data.propertyData);
//     setupUI(event.data.propertyData);
//   }
// });

import { createRoot } from 'react-dom/client';
import App from '@src/App';
// @ts-expect-error Because file doesn't exist before build
import tailwindcssOutput from '../dist/tailwind-output.css?inline';
import { detectSite } from '../../content/src/sites'
import { PropertyData } from './types';

console.log('[RealEst] Content UI script loaded at:', new Date().toISOString());

let currentUrl = window.location.href;
let observer: MutationObserver | null = null;
let urlCheckInterval: number | null = null;

// Initialize the content UI
async function initialize() {
  try {
    // Detect which real estate site we're on
    const site = detectSite(window.location.href);
    if (!site) {
      console.log('[RealEst] Not on a supported real estate site');
      return;
    }

    console.log(`[RealEst] Detected ${site.name} site`);

    // Extract property data
    const propertyData = await site.extractPropertyData();
    if (!propertyData || !propertyData.price) {
      console.warn('[RealEst] Could not extract property data');
      return;
    }

    console.log('[RealEst] Extracted property data', propertyData);

    // Set up the UI with the property data
    setupUI(propertyData);
    
    // Store current URL for change detection
    currentUrl = window.location.href;
    
    // Start monitoring URL changes
    startUrlChangeMonitoring();
  } catch (error) {
    console.error('[RealEst] Initialization error:', error);
  }
}

// Set up the UI with the extracted property data
function setupUI(propertyData: PropertyData) {
  // Remove existing UI if present
  cleanupExistingUI();
  
  const root = document.createElement('div');
  root.id = 'realest-extension-root';
  document.body.append(root);

  const rootIntoShadow = document.createElement('div');
  rootIntoShadow.id = 'shadow-root';

  const shadowRoot = root.attachShadow({ mode: 'open' });

  if (navigator.userAgent.includes('Firefox')) {
    const styleElement = document.createElement('style');
    styleElement.innerHTML = tailwindcssOutput;
    shadowRoot.appendChild(styleElement);
  } else {
    const globalStyleSheet = new CSSStyleSheet();
    globalStyleSheet.replaceSync(tailwindcssOutput);
    shadowRoot.adoptedStyleSheets = [globalStyleSheet];
  }

  shadowRoot.appendChild(rootIntoShadow);
  createRoot(rootIntoShadow).render(<App propertyData={propertyData} />);

  // Set up a MutationObserver to detect DOM changes and maintain UI visibility
  setupMutationObserver(propertyData);
}

// Clean up existing UI elements
function cleanupExistingUI() {
  const existingRoot = document.getElementById('realest-extension-root');
  if (existingRoot) {
    existingRoot.remove();
  }
  
  // Stop existing observer
  if (observer) {
    observer.disconnect();
    observer = null;
  }
}

// Set up a MutationObserver to detect DOM changes
function setupMutationObserver(propertyData: PropertyData) {
  // Disconnect existing observer if any
  if (observer) {
    observer.disconnect();
  }
  
  observer = new MutationObserver((mutations) => {
    // Check if our UI root was removed
    if (!document.getElementById('realest-extension-root')) {
      console.log('[RealEst] UI root was removed, re-initializing...');
      setupUI(propertyData);
    }
  });
  
  // Start observing the document body for changes
  observer.observe(document.body, {
    childList: true,
    subtree: true
  });
}

// Start monitoring URL changes to detect navigation between properties
function startUrlChangeMonitoring() {
  // Clear existing interval if any
  if (urlCheckInterval) {
    clearInterval(urlCheckInterval);
  }
  
  // Check for URL changes every 500ms
  urlCheckInterval = window.setInterval(() => {
    if (currentUrl !== window.location.href) {
      console.log('[RealEst] URL changed, re-initializing...');
      currentUrl = window.location.href;
      initialize();
    }
  }, 500);
  
  // Also listen for history state changes (for SPA navigation)
  setupHistoryChangeListeners();
}

// Set up listeners for history state changes
function setupHistoryChangeListeners() {
  // Create wrapped history functions to detect navigation
  const originalPushState = history.pushState;
  const originalReplaceState = history.replaceState;
  
  // Override pushState
  history.pushState = function(...args) {
    originalPushState.apply(this, args);
    handleHistoryChange();
  };
  
  // Override replaceState
  history.replaceState = function(...args) {
    originalReplaceState.apply(this, args);
    handleHistoryChange();
  };
  
  // Listen for popstate events (back/forward navigation)
  window.addEventListener('popstate', handleHistoryChange);
}

// Handle history state changes
function handleHistoryChange() {
  if (currentUrl !== window.location.href) {
    console.log('[RealEst] History state changed, re-initializing...');
    currentUrl = window.location.href;
    setTimeout(initialize, 500); // Small delay to let the page render
  }
}

// Initialize when the document is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initialize);
} else {
  // Document already loaded, wait a moment to ensure DOM is stable
  setTimeout(initialize, 1000);
}

// Listen for messages from the content script
window.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'REALEST_PROPERTY_DATA') {
    console.log('[RealEst] Received property data from content script:', event.data.propertyData);
    setupUI(event.data.propertyData);
  }
});

// Cleanup function to remove listeners when extension is disabled
function cleanup() {
  if (urlCheckInterval) {
    clearInterval(urlCheckInterval);
  }
  
  if (observer) {
    observer.disconnect();
  }
  
  window.removeEventListener('popstate', handleHistoryChange);
  cleanupExistingUI();
}

// Add listener for extension unload/disable
window.addEventListener('beforeunload', cleanup);
