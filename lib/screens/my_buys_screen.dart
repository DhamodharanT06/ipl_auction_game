import 'package:flutter/material.dart';

class MyBuysScreen extends StatefulWidget {
  const MyBuysScreen({
    super.key,
    required this.players,
    required this.teamName,
  });

  final List<Map<String, dynamic>> players;
  final String teamName;

  @override
  State<MyBuysScreen> createState() => _MyBuysScreenState();
}

class _MyBuysScreenState extends State<MyBuysScreen> {
  String _sortBy = 'name'; // name, price

  List<Map<String, dynamic>> _getSortedPlayers() {
    final sorted = List<Map<String, dynamic>>.from(widget.players);
    if (_sortBy == 'price') {
      sorted.sort((a, b) => ((b['soldPrice'] ?? 0) as int).compareTo((a['soldPrice'] ?? 0) as int));
    } else {
      sorted.sort((a, b) => (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? ''));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = _getSortedPlayers();
    final totalSpent = widget.players.fold<int>(0, (sum, p) => sum + (p['soldPrice'] as int? ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: Text('My Bought Players${widget.teamName.isNotEmpty ? ' • ${widget.teamName}' : ''}'),
        backgroundColor: const Color(0xFF111827),
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white.withOpacity(0.02),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total Bought', widget.players.length.toString(), Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Total Spent', '₹${totalSpent}L', Colors.red),
                ),
              ],
            ),
          ),
          // Sort bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.white.withOpacity(0.04),
            child: Wrap(
              spacing: 8,
              children: [
                _buildSortChip('By Name', 'name'),
                _buildSortChip('By Price', 'price'),
              ],
            ),
          ),
          // Table header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: Colors.white.withOpacity(0.04),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('NAME', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white70, fontSize: 12))),
                SizedBox(width: 12),
                SizedBox(width: 76, child: Text('BASE', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white70, fontSize: 12), textAlign: TextAlign.center)),
                SizedBox(width: 12),
                SizedBox(width: 96, child: Text('BOUGHT', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white70, fontSize: 12), textAlign: TextAlign.center)),
                SizedBox(width: 12),
                SizedBox(width: 92, child: Text('ACTION', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white70, fontSize: 12), textAlign: TextAlign.center)),
              ],
            ),
          ),
          // Table rows
          Expanded(
            child: sortedPlayers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.white30),
                        const SizedBox(height: 12),
                        const Text(
                          'No bought players yet',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: sortedPlayers.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.06)),
                    itemBuilder: (context, index) {
                      final player = sortedPlayers[index];
                      final basePrice = player['basePrice'] as int? ?? 0;
                      final boughtPrice = player['soldPrice'] as int? ?? 0;
                      final diff = boughtPrice - basePrice;
                      final priceDiffText = diff > 0 ? '+₹${diff}L' : (diff < 0 ? '-₹${-diff}L' : '±0L');

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: index % 2 == 0 ? Colors.white.withOpacity(0.01) : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Row(
                                children: [
                                  if ((player['isForeign'] as bool? ?? false))
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(Icons.flight_takeoff, color: Colors.lightBlueAccent, size: 18),
                                    )
                                  else
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(Icons.location_on, color: Colors.grey, size: 18),
                                    ),
                                  Expanded(
                                    child: Text(
                                      player['name']?.toString() ?? 'Unknown',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 76,
                              child: Text(
                                '₹${basePrice}L',
                                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w700, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 96,
                              child: Column(
                                children: [
                                  Text(
                                    '₹${boughtPrice}L',
                                    style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w800, fontSize: 12),
                                  ),
                                  Text(
                                    priceDiffText,
                                    style: TextStyle(color: diff > 0 ? Colors.orange : (diff < 0 ? Colors.lightGreen : Colors.grey), fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 92,
                              child: FilledButton.tonal(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: const Color(0xFF111827),
                                      title: Text(player['name']?.toString() ?? 'Player'),
                                      content: Text(
                                        'Role: ${player['role'] ?? '-'}\nForeign: ${(player['isForeign'] ?? false) ? 'Yes' : 'No'}\nBase Price: ₹${basePrice}L\nBought Price: ₹${boughtPrice}L\nPrice Difference: $priceDiffText',
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text('View'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isActive = _sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (selected) {
        setState(() => _sortBy = value);
      },
      selectedColor: Colors.blue.withOpacity(0.3),
      backgroundColor: Colors.white.withOpacity(0.05),
      side: BorderSide(
        color: isActive ? Colors.blue : Colors.white24,
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
