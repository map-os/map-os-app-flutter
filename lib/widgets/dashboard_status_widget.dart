import 'package:flutter/material.dart';
import 'package:mapos_app/pages/listPage.dart';
import 'package:shimmer/shimmer.dart';

class DashboardStatusWidget extends StatelessWidget {
  final int openOrders;
  final int inProgressOrders;
  final int lowStockProducts;
  final List<dynamic> openOrdersItems;
  final List<dynamic> inProgressOrdersItems;
  final List<dynamic> lowStockProductsItems;
  final bool isLoading;

  const DashboardStatusWidget({
    super.key,
    required this.openOrders,
    required this.inProgressOrders,
    required this.lowStockProducts,
    required this.openOrdersItems,
    required this.inProgressOrdersItems,
    required this.lowStockProductsItems,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isLoading) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: _buildLoadingStatusCards(constraints.maxWidth),
          );
        }

        return SizedBox(
          height: 100,
          width: double.infinity,
          child: PageView(
            controller: PageController(viewportFraction: 1),
            children: [
              if (openOrders > 0)
                _buildStatusCard(
                  title: 'OS em Aberto',
                  count: openOrders,
                  color: Colors.red,
                  icon: Icons.assignment,
                  width: constraints.maxWidth * 0.75,
                  context: context,
                  items: openOrdersItems,
                ),
              if (inProgressOrders > 0)
                _buildStatusCard(
                  title: 'OS em Andamento',
                  count: inProgressOrders,
                  color: Colors.orange,
                  icon: Icons.assignment_late,
                  width: constraints.maxWidth * 0.75,
                  context: context,
                  items: inProgressOrdersItems,
                ),
              if (lowStockProducts > 0)
                _buildStatusCard(
                  title: 'Estoque Baixo',
                  count: lowStockProducts,
                  color: Colors.yellow,
                  icon: Icons.warning,
                  width: constraints.maxWidth * 0.75,
                  context: context,
                  items: lowStockProductsItems,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingStatusCards(double maxWidth) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) => _buildLoadingCard(maxWidth * 0.75)),
      ),
    );
  }

  Widget _buildLoadingCard(double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(width: 40, height: 40, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: double.infinity, height: 14, color: Colors.white),
                const SizedBox(height: 4),
                Container(width: 40, height: 20, color: Colors.white),
              ],
            ),
          ),
          Container(width: 40, height: 40, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required double width,
    required BuildContext context,
    required List<dynamic> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemListPage(title: title, items: items),
                  ),
                );
              },
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: Icon(Icons.visibility, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
