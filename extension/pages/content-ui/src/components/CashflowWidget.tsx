import React, { useEffect, useState } from 'react';
import { PropertyData, CashflowResult } from '../types';

interface CashflowWidgetProps {
  propertyData: PropertyData;
  cashflowResult: CashflowResult;
  buttonElement: HTMLElement;
  onClose: () => void;
}

const CashflowWidget: React.FC<CashflowWidgetProps> = ({ 
  propertyData, 
  cashflowResult, 
  buttonElement,
  onClose
}) => {
  const [position, setPosition] = useState({ top: 0, left: 0, isLeft: false });
  
  // Format currency helper
  const formatCurrency = (amount: number): string => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };
  
  // Position the widget relative to the button
  useEffect(() => {
    const positionWidget = () => {
      if (!buttonElement) return;
      
      const buttonRect = buttonElement.getBoundingClientRect();
      const windowWidth = window.innerWidth;
      const widgetWidth = 350;
      
      // Default position to the right of button
      let leftPosition = buttonRect.right + 10;
      let isLeft = false;
      
      // Check if widget would go off-screen to the right
      if (leftPosition + widgetWidth > windowWidth) {
        // Position to the left of the button
        leftPosition = buttonRect.left - widgetWidth - 10;
        isLeft = true;
        
        // If it would still go off-screen, center it
        if (leftPosition < 0) {
          leftPosition = Math.max(0, (windowWidth - widgetWidth) / 2);
          isLeft = false;
        }
      }
      
      setPosition({
        top: buttonRect.top,
        left: leftPosition,
        isLeft
      });
    };
    
    // Position initially
    positionWidget();
    
    // Reposition on scroll and resize
    window.addEventListener('scroll', positionWidget);
    window.addEventListener('resize', positionWidget);
    
    // Find and listen to Zillow's scrollable containers
    const scrollableContainers = document.querySelectorAll('.ds-data-view-container, .layout-content-container');
    scrollableContainers.forEach(container => {
      container.addEventListener('scroll', positionWidget);
    });
    
    // Cleanup
    return () => {
      window.removeEventListener('scroll', positionWidget);
      window.removeEventListener('resize', positionWidget);
      
      scrollableContainers.forEach(container => {
        container.removeEventListener('scroll', positionWidget);
      });
    };
  }, [buttonElement]);
  
  // Handle clicks outside the widget
  useEffect(() => {
    const handleOutsideClick = (event: MouseEvent) => {
      if (buttonElement && !buttonElement.contains(event.target as Node) && 
          event.target instanceof Element && !event.target.closest('.cashflow-widget')) {
        onClose();
      }
    };
    
    document.addEventListener('click', handleOutsideClick);
    
    return () => {
      document.removeEventListener('click', handleOutsideClick);
    };
  }, [buttonElement, onClose]);
  
  const isPositive = cashflowResult.isPositive;
  
  return (
    <div 
      className="cashflow-widget fixed z-[9999] shadow-lg rounded-lg border-2 bg-white dark:bg-gray-800 overflow-hidden"
      style={{ 
        top: `${position.top}px`, 
        left: `${position.left}px`,
        width: '350px',
        borderColor: isPositive ? '#4CAF50' : '#F44336'
      }}
    >
      {/* Arrow pointing to the button */}
      <div 
        className="absolute w-3 h-3 bg-white transform rotate-45 z-[-1]"
        style={{
          top: '20px',
          [position.isLeft ? 'right' : 'left']: '-6px',
          borderLeft: position.isLeft ? 'none' : '1px solid #e2e8f0',
          borderRight: position.isLeft ? '1px solid #e2e8f0' : 'none',
          borderTop: position.isLeft ? '1px solid #e2e8f0' : 'none',
          borderBottom: position.isLeft ? 'none' : '1px solid #e2e8f0'
        }}
      />
      
      {/* Header */}
      <div className="flex justify-between items-center p-4 border-b border-gray-200 dark:border-gray-700">
        <h3 className="text-lg font-semibold text-gray-800 dark:text-white">
          RealEst Cashflow Analysis
        </h3>
        <button 
          onClick={onClose}
          className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
        >
          ×
        </button>
      </div>
      
      {/* Main cashflow display */}
      <div className={`p-5 text-center ${isPositive ? 'bg-green-50 dark:bg-green-900/20' : 'bg-red-50 dark:bg-red-900/20'}`}>
        <p className="text-sm text-gray-600 dark:text-gray-400">Estimated Monthly</p>
        <h2 className={`text-2xl font-bold my-1 ${isPositive ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>
          {formatCurrency(cashflowResult.netOperatingIncome)}
        </h2>
        <p className={`text-sm font-medium ${isPositive ? 'text-green-700 dark:text-green-400' : 'text-red-700 dark:text-red-400'}`}>
          {isPositive ? 'Positive Cashflow' : 'Negative Cashflow'}
        </p>
      </div>
      
      {/* Income vs Expenses */}
      <div className="grid grid-cols-2 gap-3 p-4">
        <div className="p-3 bg-green-50 dark:bg-green-900/20 rounded-lg">
          <p className="text-xs text-gray-600 dark:text-gray-400">Monthly Income</p>
          <p className="text-base font-semibold text-green-600 dark:text-green-400">
            {formatCurrency(cashflowResult.rent)}
          </p>
        </div>
        <div className="p-3 bg-red-50 dark:bg-red-900/20 rounded-lg">
          <p className="text-xs text-gray-600 dark:text-gray-400">Monthly Expenses</p>
          <p className="text-base font-semibold text-red-600 dark:text-red-400">
            {formatCurrency(cashflowResult.totalExpenses)}
          </p>
        </div>
      </div>
      
      {/* Expense breakdown */}
      <div className="p-4 pt-0">
        <p className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Expense Breakdown</p>
        <div className="grid grid-cols-2 gap-x-4 gap-y-2 text-sm">
          <div className="flex justify-between">
            <span className="text-gray-600 dark:text-gray-400">Mortgage:</span>
            <span className="font-medium text-gray-800 dark:text-gray-200">{formatCurrency(cashflowResult.monthlyPayment)}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-600 dark:text-gray-400">Property Tax:</span>
            <span className="font-medium text-gray-800 dark:text-gray-200">{formatCurrency(cashflowResult.propertyTax)}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-600 dark:text-gray-400">Insurance:</span>
            <span className="font-medium text-gray-800 dark:text-gray-200">{formatCurrency(cashflowResult.insurance)}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-600 dark:text-gray-400">Maintenance:</span>
            <span className="font-medium text-gray-800 dark:text-gray-200">{formatCurrency(cashflowResult.maintenance)}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-600 dark:text-gray-400">Vacancy:</span>
            <span className="font-medium text-gray-800 dark:text-gray-200">{formatCurrency(cashflowResult.vacancy)}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-600 dark:text-gray-400">HOA:</span>
            <span className="font-medium text-gray-800 dark:text-gray-200">{formatCurrency(cashflowResult.hoaFee)}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-600 dark:text-gray-400">Management:</span>
            <span className="font-medium text-gray-800 dark:text-gray-200">{formatCurrency(cashflowResult.managementFee)}</span>
          </div>
        </div>
      </div>
      
      {/* Footer */}
      <div className="bg-gray-50 dark:bg-gray-700/30 p-3 text-xs text-center text-gray-500 dark:text-gray-400">
        Based on 20% down payment, 30-year fixed mortgage at 6% interest rate
      </div>
    </div>
  );
};

export default CashflowWidget;
