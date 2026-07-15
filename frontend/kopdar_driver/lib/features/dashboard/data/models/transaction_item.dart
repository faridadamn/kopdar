/// Display model for recent transactions on the dashboard.
/// This is a lightweight view model — distinct from [TransactionModel]
/// which is the full persistence/API model.
class TransactionItem {
  final String icon; // emoji
  final String title;
  final String subtitle;
  final double amount;
  final bool isIncome;
  final DateTime createdAt;

  const TransactionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    required this.createdAt,
  });
}
