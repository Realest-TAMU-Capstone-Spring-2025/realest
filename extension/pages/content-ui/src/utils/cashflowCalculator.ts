// import { PropertyData, CashflowResult } from '../index';

// export function calculateCashflow(propertyData: PropertyData): CashflowResult {
//   // Default assumptions
//   const price = propertyData.price;
//   const downPayment = price * 0.2; // 20% down
//   const loanAmount = price - downPayment;
//   const interestRate = 0.06; // 6%
//   const loanTerm = 30; // 30 years
//   const monthlyInterestRate = interestRate / 12;
//   const totalPayments = loanTerm * 12;
  
//   // Calculate mortgage payment (P&I)
//   const monthlyPayment = loanAmount * monthlyInterestRate * 
//     Math.pow(1 + monthlyInterestRate, totalPayments) / 
//     (Math.pow(1 + monthlyInterestRate, totalPayments) - 1);
  
//   // Estimate monthly rent (0.8% of purchase price is a common rule of thumb)
//   const estimatedRent = price * 0.008;
  
//   // Calculate other expenses
//   const propertyTax = price * 0.015 / 12; // 1.5% annual property tax
//   const insurance = price * 0.005 / 12; // 0.5% annual insurance
//   const maintenance = price * 0.01 / 12; // 1% annual maintenance
//   const vacancy = estimatedRent * 0.05; // 5% vacancy rate
//   const hoaFee = propertyData.propertyHoa || 0;
//   const managementFee = estimatedRent * 0.1; // 10% management fee
  
//   // Calculate total expenses
//   const totalExpenses = monthlyPayment + propertyTax + insurance + maintenance + vacancy + hoaFee + managementFee;
  
//   // Calculate net cashflow
//   const netOperatingIncome = estimatedRent - totalExpenses;
  
//   return {
//     netOperatingIncome,
//     isPositive: netOperatingIncome > 0,
//     monthlyPayment,
//     vacancy,
//     propertyTax,
//     insurance,
//     maintenance,
//     hoaFee,
//     managementFee,
//     totalExpenses,
//     rent: estimatedRent
//   };
// }

import { PropertyData, CashflowResult } from '../types';

export function calculateCashflow(propertyData: PropertyData): CashflowResult {
  // Default assumptions
  const price = propertyData.price;
  const downPayment = price * 0.2; // 20% down
  const loanAmount = price - downPayment;
  const interestRate = 0.06; // 6%
  const loanTerm = 30; // 30 years
  const monthlyInterestRate = interestRate / 12;
  const totalPayments = loanTerm * 12;
  
  // Calculate mortgage payment (P&I)
  const monthlyPayment = loanAmount * monthlyInterestRate * 
    Math.pow(1 + monthlyInterestRate, totalPayments) / 
    (Math.pow(1 + monthlyInterestRate, totalPayments) - 1);
  
  // Estimate monthly rent (0.8% of purchase price is a common rule of thumb)
  const estimatedRent = price * 0.008;
  const rent = propertyData.rent || estimatedRent;
  
  // Calculate other expenses
  const propertyTax = price * 0.015 / 12; // 1.5% annual property tax
  const insurance = price * 0.005 / 12; // 0.5% annual insurance
  const maintenance = price * 0.01 / 12; // 1% annual maintenance
  const vacancy = estimatedRent * 0.05; // 5% vacancy rate
  const hoaFee = propertyData.propertyHoa || 0;
  const managementFee = estimatedRent * 0.1; // 10% management fee
  
  // Calculate total expenses
  const totalExpenses = monthlyPayment + propertyTax + insurance + maintenance + vacancy + hoaFee + managementFee;
  
  // Calculate net cashflow
  const netOperatingIncome = rent - totalExpenses;
  
  return {
    netOperatingIncome,
    isPositive: netOperatingIncome > 0,
    monthlyPayment,
    vacancy,
    propertyTax,
    insurance,
    maintenance,
    hoaFee,
    managementFee,
    totalExpenses,
    rent: estimatedRent
  };
}
