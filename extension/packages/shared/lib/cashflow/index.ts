// packages/shared/src/services/cashflow.ts
import { CashflowSettings, CashflowResult } from '../utils/shared-types.js';

export const calculateCashflow = (
  purchasePrice: number,
  grossMonthlyRent: number,
  settings: CashflowSettings
): CashflowResult => {
  const downPayment = settings.downPayment * purchasePrice;
  const loanAmount = purchasePrice - downPayment;
  const monthlyInterest = settings.interestRate / 12;
  const months = settings.loanTerm * 12;

  const principal = loanAmount / months;
  const monthlyPayment = loanAmount * monthlyInterest / 
    (1 - (1 / Math.pow(1 + monthlyInterest, months)));
  const interest = monthlyPayment - principal;

  const hoaFee = settings.hoaFee;
  const propertyTax = settings.propertyTax * purchasePrice / 12;
  const vacancy = settings.vacancyRate * grossMonthlyRent;
  const insurance = settings.insurance * purchasePrice / 12;
  const maintenance = settings.maintenance * purchasePrice / 12;
  const otherCosts = settings.otherCosts / 12;
  const managementFee = settings.managementFee * grossMonthlyRent;

  const expenses = monthlyPayment + vacancy + propertyTax + insurance + 
                  maintenance + otherCosts + hoaFee + managementFee;
  const netOperatingIncome = grossMonthlyRent - expenses;

  return {
    downPayment,
    hoaFee,
    insurance,
    interest,
    loanAmount,
    maintenance,
    managementFee,
    monthlyInterest,
    monthlyPayment,
    months,
    netOperatingIncome,
    otherCosts,
    principal,
    propertyHoa: hoaFee,
    purchasePrice,
    rent: grossMonthlyRent,
    tax: propertyTax,
    vacancy,
    valuesUsed: settings
  };
};

export const getDefaultSettings = (): CashflowSettings => {
  return {
    downPayment: 0.2,
    interestRate: 0.06,
    loanTerm: 30,
    propertyTax: 0.015,
    insurance: 0.005,
    maintenance: 0.01,
    managementFee: 0.0,
    vacancyRate: 0.05,
    hoaFee: 0.0,
    otherCosts: 0.0,
  };
};