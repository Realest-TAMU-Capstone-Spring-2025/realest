// // // // content/index.ts
// import { detectSite } from './sites';

// // function removeWidgetOnScroll() {
// //     // Store a reference to the widget container
// //     let widgetContainer: HTMLElement | null = null;
    
// //     // Function to handle scroll events
// //     const handleScroll = () => {
// //       // Find the widget if it exists
// //       if (!widgetContainer) {
// //         widgetContainer = document.getElementById('cashflow-widget-popup');
// //       }
      
// //       // If widget exists, remove it from the DOM
// //       if (widgetContainer && document.body.contains(widgetContainer)) {
// //         document.body.removeChild(widgetContainer);
// //         console.log('[RealEst] Widget removed due to scrolling');
        
// //         // Clean up scroll event listeners after removing the widget
// //         removeScrollListeners();
// //       }
// //     };
    
// //     // Function to add scroll listeners to all potential scrollable elements
// //     const addScrollListeners = () => {
// //       // 1. Listen for window scroll events (works on all sites)
// //       window.addEventListener('scroll', handleScroll, { passive: true });
      
// //       // 2. Find all potential scrollable containers using generic selectors
// //       // This covers most real estate sites without being specific to one platform
// //       const potentialScrollContainers = [
// //         // Main content containers (generic across sites)
// //         document.querySelector('main'),
// //         document.querySelector('[role="main"]'),
        
// //         // Property detail containers (more generic selectors)
// //         document.querySelector('.property-details'),
// //         document.querySelector('[data-testid*="content"]'),
// //         document.querySelector('[data-testid*="container"]'),
// //         document.querySelector('.content-container'),
// //         document.querySelector('.details-container'),
        
// //         // Common layout containers
// //         document.querySelector('.layout-content-container'),
// //         document.querySelector('.main-content'),
        
// //         // Scrollable sections
// //         ...Array.from(document.querySelectorAll('[class*="scroll"]')),
// //         ...Array.from(document.querySelectorAll('[class*="container"]')),
// //         ...Array.from(document.querySelectorAll('[class*="content"]')),
// //         ...Array.from(document.querySelectorAll('div[style*="overflow"]'))
// //       ].filter(Boolean) as HTMLElement[];
      
// //       // Add scroll listeners to each container
// //       potentialScrollContainers.forEach(container => {
// //         if (container) {
// //           container.addEventListener('scroll', handleScroll, { passive: true });
// //         }
// //       });
      
// //       console.log(`[RealEst] Added scroll listeners to ${potentialScrollContainers.length} containers`);
// //     };
    
// //     // Function to remove all scroll listeners
// //     const removeScrollListeners = () => {
// //       // Remove window scroll listener
// //       window.removeEventListener('scroll', handleScroll);
      
// //       // Remove listeners from all potential containers
// //       const allElements = document.querySelectorAll('*');
// //       allElements.forEach(element => {
// //         const el = element as HTMLElement;
// //         if (el.onscroll) {
// //           el.removeEventListener('scroll', handleScroll);
// //         }
// //       });
      
// //       console.log('[RealEst] Removed all scroll listeners');
// //     };
    
// //     // Return functions to control the behavior
// //     return {
// //       enable: addScrollListeners,
// //       disable: removeScrollListeners
// //     };
// //   }

// // (async () => {
// //     try {
// //       // Check if we're on a supported real estate site
// //       const site = detectSite(window.location.href);
// //       if (!site) {
// //         console.log('RealEst Extension: Not on a supported real estate site');
// //         return;
// //       }
  
// //       console.log(`RealEst Extension: Detected ${site.name} site`);
  
// //       // Extract property data
// //       const propertyData = await site.extractPropertyData();
// //       if (!propertyData || !propertyData.price) {
// //         console.warn('RealEst Extension: Could not extract property data');
// //         return;
// //       }
  
// //       // Set up a function to create and maintain the button
// //       const createAndMaintainButton = () => {
// //         // Find where to inject the widget
// //         const widgetContainer = site.findWidgetLocation();
// //         if (!widgetContainer) {
// //           console.warn('RealEst Extension: Could not find widget location');
// //           return;
// //         }
  
// //         // Check if button already exists to avoid duplicates
// //         if (document.getElementById('realest-cashflow-button')) {
// //           return; // Button already exists
// //         }
  
// //         // Create a button that will show the cashflow analysis when clicked
// //         const button = document.createElement('button');
// //         button.id = 'realest-cashflow-button';
// //         button.textContent = 'Cashflow Analysis';
// //         // Use inline styles to ensure visibility and add animated gradient
// //         button.style.cssText = `
// //           margin-left: 8px;
// //           display: inline-block;
// //           background: linear-gradient(90deg, #6B46C1, #805AD5, #9F7AEA);
// //           background-size: 200% 200%;
// //           color: white;
// //           padding: 4px 8px;
// //           border-radius: 4px;
// //           font-size: 12px;
// //           border: none;
// //           cursor: pointer;
// //           animation: gradient-animation 3s ease infinite;
// //         `;
        
// //         // Add keyframes for the gradient animation
// //         const styleSheet = document.createElement('style');
// //         styleSheet.type = 'text/css';
// //         styleSheet.textContent = `
// //           @keyframes gradient-animation {
// //             0% { background-position: 0% 50%; }
// //             50% { background-position: 100% 50%; }
// //             100% { background-position: 0% 50%; }
// //           }
// //         `;
// //         document.head.appendChild(styleSheet);

// //         widgetContainer.appendChild(button);
  
// //         // In your button click handler
// //         button.addEventListener('click', () => {
// //             // Remove existing widget if present
// //             const existingWidget = document.getElementById('cashflow-widget-popup');
// //             if (existingWidget) {
// //               existingWidget.remove();
// //             }
            
// //             // Get button position
// //             const buttonRect = button.getBoundingClientRect();
            
// //             // Create widget container with high z-index
// //             const widgetContainer = document.createElement('div');
// //             widgetContainer.id = 'cashflow-widget-popup';
// //             widgetContainer.style.cssText = `
// //               position: sticky;
// //               top: ${buttonRect.top}px;
// //               left: ${buttonRect.right + 10}px;
// //               z-index: 9999999;
// //               background-color: white;
// //               border-radius: 8px;
// //               box-shadow: 0 4px 12px rgba(0,0,0,0.15);
// //               max-width: 400px;
// //               max-height: 90vh;
// //               overflow-y: auto;
// //               transform: translateZ(0);
// //             `;
// //             function updateWidgetPosition() {
// //                 const button = document.getElementById('realest-cashflow-button');
// //                 const widget = document.getElementById('realest-cashflow-container');
                
// //                 if (button && widget) {
// //                   const buttonRect = button.getBoundingClientRect();
                  
// //                   // Set position relative to viewport (fixed positioning)
// //                   widget.style.position = 'fixed';
// //                   widget.style.top = `${buttonRect.top}px`;
// //                   widget.style.left = `${buttonRect.right + 10}px`;
// //                   widget.style.zIndex = '9999';
                  
// //                   // Ensure widget stays within viewport bounds
// //                   const widgetWidth = 350; // Adjust to your widget's width
// //                   if (buttonRect.right + widgetWidth + 10 > window.innerWidth) {
// //                     // Position to the left of the button if it would go off-screen
// //                     widget.style.left = `${buttonRect.left - widgetWidth - 10}px`;
// //                   }
// //                 }
// //               }
              
// //             // Add event listeners for scrolling and resizing
// //             window.addEventListener('scroll', updateWidgetPosition);
// //             window.addEventListener('resize', updateWidgetPosition);
// //             // Initial positioning
// //             updateWidgetPosition();
            
// //             // Create placeholder for React component
// //             const reactContainer = document.createElement('div');
// //             reactContainer.id = 'cashflow-widget-root';
// //             widgetContainer.appendChild(reactContainer);
            
// //             // Append to document body instead of a specific element
// //             document.body.appendChild(widgetContainer);
            
// //             // Send message to trigger rendering the widget
// //             chrome.runtime.sendMessage({
// //               type: 'RENDER_CASHFLOW_WIDGET',
// //               data: {
// //                 containerId: 'cashflow-widget-root',
// //                 propertyData
// //               }
// //             });
// //         });

// //         button.addEventListener('click', (e) => {
// //             e.preventDefault();
// //             e.stopPropagation();
            
// //             // Create widget container...
            
// //             console.log('[RealEst] Button clicked, preparing to send data');
            
// //             // Try multiple methods to communicate with content-ui
// //             const sendDataToContentUI = () => {
// //             console.log('[RealEst] Sending data to content-ui');
            
// //             // 1. Try chrome.runtime.sendMessage
// //             try {
// //                 chrome.runtime.sendMessage({
// //                 type: 'RENDER_CASHFLOW_WIDGET',
// //                 data: {
// //                     containerId: 'cashflow-widget-root',
// //                     propertyData
// //                 }
// //                 }, (response) => {
// //                 if (chrome.runtime.lastError) {
// //                     console.error('[RealEst] Chrome messaging error:', chrome.runtime.lastError);
// //                     // Fall back to other methods
// //                     tryAlternativeMethods();
// //                 } else {
// //                     console.log('[RealEst] Chrome messaging succeeded:', response);
// //                 }
// //                 });
// //             } catch (error) {
// //                 console.error('[RealEst] Failed to send chrome message:', error);
// //                 tryAlternativeMethods();
// //             }
// //             };
            
// //             const tryAlternativeMethods = () => {
// //             console.log('[RealEst] Trying alternative communication methods');
            
// //             // 2. Try DOM custom event
// //             try {
// //                 const event = new CustomEvent('REALEST_RENDER_WIDGET', {
// //                 detail: {
// //                     containerId: 'cashflow-widget-root',
// //                     propertyData
// //                 }
// //                 });
// //                 document.dispatchEvent(event);
// //                 console.log('[RealEst] Dispatched DOM event');
// //             } catch (error) {
// //                 console.error('[RealEst] Failed to dispatch DOM event:', error);
// //             }
            
// //             // 3. Try window.postMessage
// //             try {
// //                 window.postMessage({
// //                 type: 'REALEST_RENDER_WIDGET',
// //                 containerId: 'cashflow-widget-root',
// //                 propertyData
// //                 }, '*');
// //                 console.log('[RealEst] Posted window message');
// //             } catch (error) {
// //                 console.error('[RealEst] Failed to post window message:', error);
// //             }
// //             };
            
// //             // Check if content-ui is ready before sending data
// //             const checkContentUIReady = () => {
// //             // @ts-ignore
// //             if (window.contentUIReady) {
// //                 console.log('[RealEst] Content-UI is ready (window property)');
// //                 sendDataToContentUI();
// //                 return;
// //             }
            
// //             console.log('[RealEst] Content-UI not ready yet, waiting...');
            
// //             // Set up event listener for content-ui ready signal
// //             const readyHandler = (event: Event): void => {
// //                 console.log('[RealEst] Received content-ui ready signal');
// //                 document.removeEventListener('REALEST_CONTENT_UI_READY', readyHandler);
// //                 window.removeEventListener('message', messageHandler);
// //                 sendDataToContentUI();
// //             };
            
// //             interface ContentUIReadyEvent extends Event {
// //                 data?: {
// //                     type?: string;
// //                 };
// //             }

// //             const messageHandler = (event: ContentUIReadyEvent): void => {
// //             if (event.data?.type === 'REALEST_CONTENT_UI_READY') {
// //                 console.log('[RealEst] Received content-ui ready message');
// //                 document.removeEventListener('REALEST_CONTENT_UI_READY', readyHandler);
// //                 window.removeEventListener('message', messageHandler);
// //                 sendDataToContentUI();
// //             }
// //             };
            
// //             document.addEventListener('REALEST_CONTENT_UI_READY', readyHandler);
// //             window.addEventListener('message', messageHandler);
            
// //             // Set a timeout in case we never get the ready signal
// //             setTimeout(() => {
// //                 console.log('[RealEst] Timeout waiting for content-ui ready signal, trying anyway');
// //                 document.removeEventListener('REALEST_CONTENT_UI_READY', readyHandler);
// //                 window.removeEventListener('message', messageHandler);
// //                 sendDataToContentUI();
// //             }, 2000);
// //             };

// //             const scrollHandler = removeWidgetOnScroll();
// //             scrollHandler.enable();
            
// //             // Start the process
// //             checkContentUIReady();
// //         });

// //       };
      
// //       // Create the button initially
// //       createAndMaintainButton();
      
// //       // Set up a MutationObserver to detect DOM changes and maintain button visibility
// //       const observer = new MutationObserver(() => {
// //         if (!document.getElementById('realest-cashflow-button')) {
// //           createAndMaintainButton();
// //         }
// //       });
      
// //       // Start observing the document body for changes
// //       observer.observe(document.body, {
// //         childList: true,
// //         subtree: true
// //       });
      
// //       // Also set a periodic check as a backup
// //       setInterval(() => {
// //         if (!document.getElementById('realest-cashflow-button')) {
// //           createAndMaintainButton();
// //         }
// //       }, 2000);
      
// //     } catch (error) {
// //       console.error('RealEst Extension Error:', error);
// //     }
// //   })();

// // Initialize content script
// (async () => {
//     try {
//       // Check if we're on a supported real estate site
//       const site = detectSite(window.location.href);
//       if (!site) {
//         console.log('RealEst Extension: Not on a supported real estate site');
//         return;
//       }
  
//       console.log(`RealEst Extension: Detected ${site.name} site`);
  
//       // Extract property data
//       const propertyData = await site.extractPropertyData();
//       if (!propertyData || !propertyData.price) {
//         console.warn('RealEst Extension: Could not extract property data');
//         return;
//       }
  
//       // Find where to inject the button
//       const widgetContainer = site.findWidgetLocation();
//       if (!widgetContainer) {
//         console.warn('RealEst Extension: Could not find widget location');
//         return;
//       }
  
//       // Calculate cashflow directly
//       const cashflowResult = calculateCashflow(propertyData);
      
//       // Create a color-coded button based on cashflow result
//       const button = createCashflowButton(cashflowResult);
//       widgetContainer.appendChild(button);
      
//       console.log('RealEst Extension: Cashflow button injected successfully');
      
//     } catch (error) {
//       console.error('RealEst Extension Error:', error);
//     }
//   })();
  
//   // Function to calculate cashflow
// interface PropertyData {
//     price: number;
//     propertyHoa?: number;
// }

// interface CashflowCalculation {
//     netCashflow: number;
//     estimatedRent: number;
//     totalExpenses: number;
// }

// function calculateCashflow(propertyData: PropertyData): CashflowCalculation {
//     // Default assumptions
//     const price = propertyData.price;
//     const downPayment = price * 0.2; // 20% down
//     const loanAmount = price - downPayment;
//     const interestRate = 0.06; // 6%
//     const loanTerm = 30; // 30 years
//     const monthlyInterestRate = interestRate / 12;
//     const totalPayments = loanTerm * 12;
    
//     // Calculate mortgage payment (P&I)
//     const monthlyPayment = loanAmount * monthlyInterestRate * 
//         Math.pow(1 + monthlyInterestRate, totalPayments) / 
//         (Math.pow(1 + monthlyInterestRate, totalPayments) - 1);
    
//     // Estimate monthly rent (0.8% of purchase price is a common rule of thumb)
//     const estimatedRent = price * 0.008;
    
//     // Calculate other expenses
//     const propertyTax = price * 0.015 / 12; // 1.5% annual property tax
//     const insurance = price * 0.005 / 12; // 0.5% annual insurance
//     const maintenance = price * 0.01 / 12; // 1% annual maintenance
//     const vacancy = estimatedRent * 0.05; // 5% vacancy rate
//     const hoaFee = propertyData.propertyHoa || 0;
    
//     // Calculate total expenses
//     const totalExpenses = monthlyPayment + propertyTax + insurance + maintenance + vacancy + hoaFee;
    
//     // Calculate net cashflow
//     const netCashflow = estimatedRent - totalExpenses;
    
//     return {
//         netCashflow,
//         estimatedRent,
//         totalExpenses
//     };
// }
  
//   // Function to create a color-coded button
// interface CashflowResult {
//     netCashflow: number;
//     estimatedRent: number;
//     totalExpenses: number;
// }

// function createCashflowButton(cashflowResult: CashflowResult): HTMLButtonElement {
//     const button = document.createElement('button');
//     button.id = 'realest-cashflow-button';
//     button.textContent = formatCurrency(cashflowResult.netCashflow) + '/mo';
    
//     // Style the button based on cashflow result
//     if (cashflowResult.netCashflow > 0) {
//         button.style.backgroundColor = '#4CAF50'; // Green for positive cashflow
//     } else if (cashflowResult.netCashflow > -200) {
//         button.style.backgroundColor = '#FF9800'; // Orange for slightly negative
//     } else {
//         button.style.backgroundColor = '#F44336'; // Red for significantly negative
//     }
    
//     // Common button styling
//     button.style.cssText += `
//         margin-left: 8px;
//         display: inline-block;
//         color: white;
//         padding: 4px 8px;
//         border-radius: 4px;
//         font-size: 12px;
//         border: none;
//         font-weight: bold;
//     `;
    
//     // Add tooltip with more details
//     button.title = `Monthly Cashflow: ${formatCurrency(cashflowResult.netCashflow)}
// Est. Rent: ${formatCurrency(cashflowResult.estimatedRent)}
// Expenses: ${formatCurrency(cashflowResult.totalExpenses)}
// Based on 20% down, 6% interest, 30yr mortgage`;

//     return button;
// }
  
//   // Helper function to format currency
// function formatCurrency(amount: number): string {
//     return new Intl.NumberFormat('en-US', {
//         style: 'currency',
//         currency: 'USD',
//         minimumFractionDigits: 0,
//         maximumFractionDigits: 0
//     }).format(amount);
// }


import { detectSite } from './sites';
import { createRoot } from 'react-dom/client';
import React from 'react';
import CashflowWidget from '../../content-ui/src/CashflowWidget';
import '../index.css'; // Import Tailwind CSS

// Check if user is authenticated before running the script
const checkAuth = async (): Promise<boolean> => {
  return new Promise((resolve) => {
    chrome.storage.local.get('user', (result) => {
      resolve(!!result.user);
    });
  });
};

// Initialize content script
(async () => {
  try {
    // Initialize dark mode
    const darkMode = await new Promise<boolean>((resolve) => {
      chrome.storage.sync.get('darkMode', ({ darkMode }) => {
        resolve(darkMode || false);
      });
    });

    if (darkMode) {
      document.documentElement.classList.add('dark');
    }

    // Detect which real estate site we're on
    const site = detectSite(window.location.href);
    if (!site) {
      console.log('RealEst Extension: Not a supported real estate site');
      return;
    }

    console.log(`RealEst Extension: Detected ${site.name} site`);

    // Extract property data
    const propertyData = await site.extractPropertyData();
    if (!propertyData || !propertyData.price) {
      console.warn('RealEst Extension: Could not extract property data');
      return;
    }

    console.log('RealEst Extension: Extracted property data', propertyData);
    // Get default settings
    const defaultSettings = await new Promise<any>((resolve) => {
      chrome.storage.sync.get('defaultValues', (result) => {
        const defaults = result.defaultValues || {};
        resolve({
          downPayment: defaults.downPayment / 100 || 0.2,
          interestRate: defaults.interestRate / 100 || 0.06,
          loanTerm: defaults.loanTerm || 30,
          propertyTax: defaults.propertyTax / 100 || 0.015,
          insurance: defaults.insurance / 100 || 0.005,
          maintenance: defaults.maintenance / 100 || 0.01,
          managementFee: defaults.managementFee / 100 || 0.0,
          vacancyRate: defaults.vacancyRate / 100 || 0.05,
          hoaFee: defaults.hoaFee || propertyData.propertyHoa || 0,
          otherCosts: defaults.otherCosts || 0,
        });
      });
    });

    // Find widget location and inject it
    const injectionPoint = site.findWidgetLocation();
    if (!injectionPoint) {
      console.warn('RealEst Extension: Could not find widget location');
      return;
    }

    // Create a container for the widget
    const container = document.createElement('div');
    container.id = 'realest-cashflow-widget';
    container.className = 'realest-cashflow-widget';
    injectionPoint.appendChild(container);

    // Render the widget
    const root = createRoot(container);
    root.render(
      React.createElement(CashflowWidget, {
        propertyData
      })
    );
    
    console.log('RealEst Extension: Widget injected successfully');
    
  } catch (error) {
    console.error('RealEst Extension Error:', error);
  }
})();

// Listen for messages from popup or background
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'TOGGLE_DARK_MODE') {
    const isDarkMode = message.payload;
    if (isDarkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
    sendResponse({ success: true });
  }
  return true;
});
