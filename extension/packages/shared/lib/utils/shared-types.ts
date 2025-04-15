export type ValueOf<T> = T[keyof T];

// Cashflow
export interface PropertyData {
    price: number;
    listingId: string;
    propertyHoa?: number;
    address?: string;
    bedrooms?: number;
    bathrooms?: number;
    squareFeet?: number;
  }
  
  export interface CashflowSettings {
    downPayment: number;  // Decimal (0.2 = 20%)
    interestRate: number; // Decimal (0.06 = 6%)
    loanTerm: number;     // Years (typically 15, 30)
    propertyTax: number;  // Decimal (0.015 = 1.5%)
    insurance: number;    // Decimal (0.005 = 0.5%)
    maintenance: number;  // Decimal (0.01 = 1%)
    managementFee: number;// Decimal (0.1 = 10%)
    vacancyRate: number;  // Decimal (0.05 = 5%)
    hoaFee: number;       // Dollar amount
    otherCosts: number;   // Dollar amount
    customIncome?: number;// Optional custom monthly income
  }
  
  export interface CashflowResult {
    downPayment: number;
    hoaFee: number;
    insurance: number;
    interest: number;
    loanAmount: number;
    maintenance: number;
    managementFee: number;
    monthlyInterest: number;
    monthlyPayment: number;
    months: number;
    netOperatingIncome: number;
    otherCosts: number;
    principal: number;
    propertyHoa: number;
    purchasePrice: number;
    rent: number;
    tax: number;
    vacancy: number;
    valuesUsed: CashflowSettings;
  }