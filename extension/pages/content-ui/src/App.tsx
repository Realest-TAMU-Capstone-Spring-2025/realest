import { useEffect, useState } from 'react';
import { PropertyData } from './types';
import { calculateCashflow } from './utils/cashflowCalculator';
// import CashflowButton from './components/CashflowButton';
import CashflowWidget from './components/CashflowWidget';

interface AppProps {
  propertyData: PropertyData;
}

export default function App({ propertyData }: AppProps) {
  const [showWidget, setShowWidget] = useState(false);
  const [buttonElement, setButtonElement] = useState<HTMLElement | null>(null);
  
  useEffect(() => {
    console.log('Content UI loaded with property data:', propertyData);
    
    // Find the price element to inject our button
    const priceElement = document.querySelector('[data-testid="price"]');
    if (!priceElement) {
      console.warn('[RealEst] Could not find price element');
      return;
    }
    
    // Find the price span to insert our button after
    const priceSpan = priceElement.querySelector('span');
    if (!priceSpan) {
      console.warn('[RealEst] Could not find price span');
      return;
    }
    
    // Create a container for our button
    const buttonContainer = document.createElement('span');
    buttonContainer.id = 'realest-cashflow-button-container';
    buttonContainer.style.marginLeft = '8px';
    buttonContainer.style.display = 'inline-block';
    
    // Insert after the price span
    priceSpan.insertAdjacentElement('afterend', buttonContainer);
    
    // Store the button element for positioning the widget
    setButtonElement(buttonContainer);
    
    // Calculate cashflow
    const cashflowResult = calculateCashflow(propertyData);
    
    // Create and inject the button
    const button = document.createElement('button');
    button.id = 'realest-cashflow-button';
    button.textContent = `${formatCurrency(cashflowResult.netOperatingIncome)}/mo`;
    button.style.cssText = `
      display: inline-block;
      background-color: ${cashflowResult.isPositive ? '#4CAF50' : '#F44336'};
      color: white;
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 12px;
      border: none;
      cursor: pointer;
      font-weight: bold;
      line-height: normal; /* Prevents line-height from affecting alignment */
      transform: translateY(-1px); /* Fine-tune vertical position if needed */
    `;
    
    button.addEventListener('mouseover', () => {
      button.style.backgroundColor = cashflowResult.isPositive ? '#45a049' : '#e53935';
      button.style.transform = 'scale(1.05)';
    });

    button.addEventListener('mouseout', () => {
      button.style.backgroundColor = cashflowResult.isPositive ? '#4CAF50' : '#F44336';
      button.style.transform = 'scale(1)';
    });
    // Add click event to show/hide the widget
    button.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      setShowWidget(prev => !prev);
    });
    
    buttonContainer.appendChild(button);
    
    // Cleanup function
    return () => {
      if (buttonContainer.parentNode) {
        buttonContainer.parentNode.removeChild(buttonContainer);
      }
    };
  }, [propertyData]);
  
  // Format currency helper
  const formatCurrency = (amount: number): string => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };
  
  // Calculate cashflow result
  const cashflowResult = calculateCashflow(propertyData);
  
  return (
    <>
      {showWidget && buttonElement && (
        <CashflowWidget 
          propertyData={propertyData} 
          cashflowResult={cashflowResult} 
          buttonElement={buttonElement}
          onClose={() => setShowWidget(false)}
        />
      )}
    </>
  );
}
