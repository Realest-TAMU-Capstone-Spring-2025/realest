import React, { useState } from 'react';
import { PropertyData } from '../../content/src/sites';

interface CashflowWidgetProps {
  propertyData: PropertyData;
}

interface CashflowSettings {
  downPayment: number;
  interestRate: number;
  loanTerm: number;
  propertyTax: number;
  insurance: number;
  maintenance: number;
  managementFee: number;
  vacancyRate: number;
  hoaFee: number;
  otherCosts: number;
  customIncome: number;
}

interface CashflowResult {
  netOperatingIncome: number;
  monthlyPayment: number;
  vacancy: number;
  propertyTax: number;
  insurance: number;
  maintenance: number;
  hoaFee: number;
  managementFee: number;
  totalExpenses: number;
  rent: number;
}

const CashflowWidget: React.FC<CashflowWidgetProps> = ({ propertyData }) => {
  const [settings, setSettings] = useState<CashflowSettings>({
    downPayment: 0.2,
    interestRate: 0.06,
    loanTerm: 30,
    propertyTax: 0.015,
    insurance: 0.005,
    maintenance: 0.01,
    managementFee: 0.0,
    vacancyRate: 0.05,
    hoaFee: propertyData.propertyHoa || 0,
    otherCosts: 0,
    customIncome: propertyData.price * 0.008
  });

  const calculateCashflow = (): CashflowResult => {
    const { price } = propertyData;
    const {
      downPayment, interestRate, loanTerm, propertyTax, insurance,
      maintenance, managementFee, vacancyRate, hoaFee, otherCosts, customIncome
    } = settings;
    
    const rent = customIncome;
    const loanAmount = price * (1 - downPayment);
    const monthlyInterestRate = interestRate / 12;
    const totalPayments = loanTerm * 12;
    
    const monthlyPayment = loanAmount * monthlyInterestRate * 
      Math.pow(1 + monthlyInterestRate, totalPayments) / 
      (Math.pow(1 + monthlyInterestRate, totalPayments) - 1);
    
    const vacancy = rent * vacancyRate;
    const propertyTaxMonthly = price * propertyTax / 12;
    const insuranceMonthly = price * insurance / 12;
    const maintenanceMonthly = price * maintenance / 12;
    const managementFeeMonthly = rent * managementFee;
    const otherCostsMonthly = otherCosts / 12;
    
    const totalExpenses = monthlyPayment + vacancy + propertyTaxMonthly + 
                         insuranceMonthly + maintenanceMonthly + hoaFee + 
                         managementFeeMonthly + otherCostsMonthly;
    
    const netOperatingIncome = rent - totalExpenses;
    
    return {
      netOperatingIncome,
      monthlyPayment,
      vacancy,
      propertyTax: propertyTaxMonthly,
      insurance: insuranceMonthly,
      maintenance: maintenanceMonthly,
      hoaFee,
      managementFee: managementFeeMonthly,
      totalExpenses,
      rent
    };
  };

  const cashflowResult = calculateCashflow();
  const isPositive = cashflowResult.netOperatingIncome > 0;

  const formatCurrency = (amount: number): string => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-4 w-[350px]">
      <h3 className="text-lg font-semibold text-gray-800 dark:text-white mb-4">
        Monthly Cashflow
      </h3>
        <div className={`bg-white dark:bg-gray-800 rounded-lg shadow-lg border-2 p-4 ${isPositive ? 'border-green-500' : 'border-red-500'}`}>
        <h3 className="text-lg font-semibold text-gray-800 dark:text-white mb-4">
            Monthly Cashflow
        </h3>
        <div className={`p-4 text-center rounded-md mb-4 ${isPositive ? 'bg-green-50 dark:bg-green-900/20' : 'bg-red-50 dark:bg-red-900/20'}`}>
            <p className="text-sm text-gray-600 dark:text-gray-400">Estimated Monthly</p>
            <h2 className={`text-2xl font-bold my-1 ${isPositive ? 'text-green-600' : 'text-red-600'}`}>
            {formatCurrency(cashflowResult.netOperatingIncome)}
            </h2>
            <p className={`text-sm font-medium ${isPositive ? 'text-green-700 dark:text-green-400' : 'text-red-700 dark:text-red-400'}`}>
            {isPositive ? 'Positive Cashflow' : 'Negative Cashflow'}
            </p>
        </div>
        <div className="grid grid-cols-2 gap-3 mb-4">
            <div className="p-3 bg-green-50 dark:bg-green-900/20 rounded-lg">
            <p className="text-xs text-gray-600 dark:text-gray-400">Monthly Income</p>
            <p className="text-base font-semibold text-green-600">
                {formatCurrency(cashflowResult.rent)}
            </p>
            </div>
            <div className="p-3 bg-red-50 dark:bg-red-900/20 rounded-lg">
            <p className="text-xs text-gray-600 dark:text-gray-400">Monthly Expenses</p>
            <p className="text-base font-semibold text-red-600">
                {formatCurrency(cashflowResult.totalExpenses)}
            </p>
            </div>
        </div>
        <div>
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
            </div>
        </div>
        </div>
    </div>
  );
};

export default CashflowWidget;
