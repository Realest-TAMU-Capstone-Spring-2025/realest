import 'dart:math';
import 'package:flutter/material.dart';

class RentalPropertyCalculator extends StatefulWidget {
  const RentalPropertyCalculator({Key? key}) : super(key: key);

  @override
  _RentalPropertyCalculatorState createState() => _RentalPropertyCalculatorState();
}

class _RentalPropertyCalculatorState extends State<RentalPropertyCalculator> {
  // Controllers for user input
  final TextEditingController purchasePriceController = TextEditingController(text: "200000");
  final TextEditingController downPaymentController = TextEditingController(text: "20");
  final TextEditingController interestRateController = TextEditingController(text: "6");
  final TextEditingController loanTermController = TextEditingController(text: "30");
  final TextEditingController closingCostController = TextEditingController(text: "6000");
  final TextEditingController repairCostController = TextEditingController(text: "0");

  final TextEditingController propertyTaxController = TextEditingController(text: "3000");
  final TextEditingController insuranceController = TextEditingController(text: "1200");
  final TextEditingController hoaFeeController = TextEditingController(text: "0");
  final TextEditingController maintenanceController = TextEditingController(text: "2000");
  final TextEditingController otherCostsController = TextEditingController(text: "500");

  final TextEditingController rentController = TextEditingController(text: "2000");
  final TextEditingController vacancyRateController = TextEditingController(text: "5");
  final TextEditingController managementFeeController = TextEditingController(text: "0");

  final TextEditingController appreciationRateController = TextEditingController(text: "3");
  final TextEditingController holdingYearsController = TextEditingController(text: "20");
  final TextEditingController sellingCostController = TextEditingController(text: "0");

  double cashFlow = 0.0;
  double roi = 0.0;

  void _calculateRentalProperty() {
    double purchasePrice = double.tryParse(purchasePriceController.text) ?? 0;
    double downPaymentPercentage = (double.tryParse(downPaymentController.text) ?? 0) / 100;
    double interestRate = (double.tryParse(interestRateController.text) ?? 0) / 100 / 12;
    int loanTerm = (int.tryParse(loanTermController.text) ?? 0) * 12;
    double closingCost = double.tryParse(closingCostController.text) ?? 0;
    double repairCost = double.tryParse(repairCostController.text) ?? 0;

    double loanAmount = purchasePrice * (1 - downPaymentPercentage);
    double monthlyMortgage = (loanAmount * interestRate) /
        (1 - pow((1 + interestRate), -loanTerm));

    double propertyTax = (double.tryParse(propertyTaxController.text) ?? 0) / 12;
    double insurance = (double.tryParse(insuranceController.text) ?? 0) / 12;
    double hoaFee = (double.tryParse(hoaFeeController.text) ?? 0) / 12;
    double maintenance = (double.tryParse(maintenanceController.text) ?? 0) / 12;
    double otherCosts = (double.tryParse(otherCostsController.text) ?? 0) / 12;

    double monthlyExpenses = propertyTax + insurance + hoaFee + maintenance + otherCosts + monthlyMortgage;

    double monthlyRent = double.tryParse(rentController.text) ?? 0;
    double vacancyLoss = monthlyRent * (double.tryParse(vacancyRateController.text) ?? 0) / 100;
    double managementFee = monthlyRent * (double.tryParse(managementFeeController.text) ?? 0) / 100;

    double netMonthlyIncome = monthlyRent - (monthlyExpenses + vacancyLoss + managementFee);
    double netAnnualIncome = netMonthlyIncome * 12;

    double totalInvestment = (purchasePrice * downPaymentPercentage) + closingCost + repairCost;
    double yearlyROI = (netAnnualIncome / totalInvestment) * 100;

    setState(() {
      cashFlow = netAnnualIncome;
      roi = yearlyROI;
    });
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Rental Property Calculator", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),

          _buildTextField("Purchase Price (\$)", purchasePriceController),
          _buildTextField("Down Payment (%)", downPaymentController),
          _buildTextField("Interest Rate (%)", interestRateController),
          _buildTextField("Loan Term (Years)", loanTermController),
          _buildTextField("Closing Cost (\$)", closingCostController),
          _buildTextField("Repairs (\$)", repairCostController),

          const SizedBox(height: 15),
          const Text("Recurring Expenses", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 15),
          _buildTextField("Annual Property Tax (\$)", propertyTaxController),
          _buildTextField("Annual Insurance (\$)", insuranceController),
          _buildTextField("Annual HOA Fees (\$)", hoaFeeController),
          _buildTextField("Annual Maintenance (\$)", maintenanceController),
          _buildTextField("Other Costs (\$)", otherCostsController),

          const SizedBox(height: 15),
          const Text("Income", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 15),
          _buildTextField("Monthly Rent (\$)", rentController),
          _buildTextField("Vacancy Rate (%)", vacancyRateController),
          _buildTextField("Management Fee (%)", managementFeeController),

          const SizedBox(height: 15),
          Center(
            child: ElevatedButton(
              onPressed: _calculateRentalProperty,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                textStyle: Theme.of(context).textTheme.bodyLarge, // Uses theme text style
              ),
              child: Text("Calculate"),
            ),
          ),
          const SizedBox(height: 15),

          Center(
            child: Text(
              "Annual Cash Flow: \$${cashFlow.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
          Center(
            child: Text(
              "ROI: ${roi.toStringAsFixed(2)}%",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
