import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ipl_auction_game/models/player_model.dart';
import 'package:ipl_auction_game/providers/app_providers.dart';
import 'package:ipl_auction_game/core/config/sheets_env.dart';
import 'package:flutter/services.dart';
import 'package:ipl_auction_game/widgets/glass_card.dart';
import 'package:ipl_auction_game/widgets/player_image.dart';

class SheetPlayersScreen extends ConsumerStatefulWidget {
  const SheetPlayersScreen({super.key});

  @override
  ConsumerState<SheetPlayersScreen> createState() => _SheetPlayersScreenState();
}

class _SheetPlayersScreenState extends ConsumerState<SheetPlayersScreen> {
  late Future<List<PlayerModel>> _future;
  final Set<int> _selectedIndices = <int>{};
  List<PlayerModel> _cachedPlayers = [];
  bool _importing = false;
  double _progress = 0.0;
  int _importCount = 0;
  int _totalToImport = 0;
  bool _autoSync = false;

  @override
  void initState() {
    super.initState();
    final cache = ref.read(cacheServiceProvider);
    _autoSync = cache.readAutoSync();
    _load();
  }

  void _load() {
    final service = ref.read(playerSheetServiceProvider);
    _future = service.loadPlayers(refresh: true);
  }

  Future<void> _importSelected({bool all = false}) async {
    final db = ref.read(databaseServiceProvider);
    final service = ref.read(playerSheetServiceProvider);
    List<PlayerModel> toImport;
    if (all) {
      toImport = await service.loadPlayers(refresh: true);
    } else {
      toImport = _selectedIndices.map((i) => _cachedPlayers[i]).toList();
    }

    if (toImport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No players selected')));
      return;
    }

    setState(() {
      _importing = true;
      _progress = 0;
      _importCount = 0;
      _totalToImport = toImport.length;
    });

    for (var i = 0; i < toImport.length; i++) {
      try {
        await db.createOrUpdatePlayer(toImport[i]);
        _importCount += 1;
      } catch (_) {
        // ignore row error
      }
      setState(() {
        _progress = (i + 1) / _totalToImport;
      });
    }

    setState(() {
      _importing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $_importCount/$_totalToImport players')));
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sheet Players Preview')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Use Wrap so controls don't overflow on small screens
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload'),
                  onPressed: () {
                    setState(() => _load());
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import Selected'),
                  onPressed: _importing || _selectedIndices.isEmpty ? null : () => _importSelected(all: false),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync All'),
                  onPressed: _importing ? null : () => _importSelected(all: true),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Auto-sync'),
                    const SizedBox(width: 6),
                    Switch(
                      value: _autoSync,
                      onChanged: (v) async {
                        final cache = ref.read(cacheServiceProvider);
                        await cache.setAutoSync(v);
                        setState(() => _autoSync = v);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Description below controls so it can take available width
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: const Text('This preview reads your published Google Sheet CSV. No data is written to Appwrite unless you import.'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<PlayerModel>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  final players = snap.data ?? [];
                  _cachedPlayers = players;
                  if (players.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('No players found in the sheet.'),
                            const SizedBox(height: 8),
                            SelectableText(SheetsEnv.csvExportUrl),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() => _load());
                                  },
                                  child: const Text('Retry Fetch'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(text: SheetsEnv.csvExportUrl));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV URL copied to clipboard')));
                                  },
                                  child: const Text('Copy CSV URL'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      if (_importing)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            children: [
                              LinearProgressIndicator(value: _progress),
                              const SizedBox(height: 6),
                              Text('Importing $_importCount/$_totalToImport'),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: players.length,
                          separatorBuilder: (_, __) => const Divider(height: 8),
                          itemBuilder: (context, index) {
                            final p = players[index];
                            final selected = _selectedIndices.contains(index);
                            return GlassCard(
                              child: CheckboxListTile(
                                value: selected,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selectedIndices.add(index);
                                    } else {
                                      _selectedIndices.remove(index);
                                    }
                                  });
                                },
                                secondary: p.imageUrl != null && p.imageUrl!.isNotEmpty
                                  ? PlayerImage(url: p.imageUrl!, size: 40)
                                  : CircleAvatar(child: Text(p.name.isNotEmpty ? p.name[0] : '?')),
                                title: Text(p.name),
                                subtitle: Text('${p.role} • ${p.country ?? '—'}'),
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                dense: true,
                                selected: selected,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
