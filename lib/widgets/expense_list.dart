// widgets/expense_list.dart
import 'package:flutter/material.dart';
import '../models/expense.dart';

class ExpenseList extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseList(this.expenses, {super.key});

  @override
  Widget build(BuildContext context) {
    return expenses.isEmpty
        ? const Center(
            child: Text(
              'No expenses added yet!',
              style: TextStyle(fontSize: 20),
            ),
          )
        : ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (ctx, index) {
              final expense = expenses[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: FittedBox(
                        child: Text('Ksh. ${expense.amount.toStringAsFixed(2)}'),
                      ),
                    ),
                  ),
                  title: Text(
                    expense.category,
                    style: Theme.of(context).textTheme.titleLarge,
                    
                  ),
                  subtitle: Text(expense.description),
                  trailing: Text(
                    '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                  ),
                ),
              );
            },
          );
  }
}
