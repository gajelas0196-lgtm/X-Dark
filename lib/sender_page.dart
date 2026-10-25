import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';

class SenderPage extends StatefulWidget {
  final String sessionKey;

  const SenderPage({super.key, required this.sessionKey});

  @override
  State<SenderPage> createState() => _SenderPageState();
}

class _SenderPageState extends State<SenderPage> with TickerProviderStateMixin {
  // Constants
  static const String baseUrl = "http://alfa-store-officials.alfamarket2.my.id:3771";
  
  // TEMA BLACK & BLUE
  static const Color primaryColor = Color(0xFF00D4AA); // Blue
  static const Color accentColor = Color(0xFFFFFFFF); // Putih untuk highlight
  static const Color secondaryColor = Color(0xFF000000); // Hitam Pekat

  // State variables
  Map<String, dynamic> connections = {"private": [], "global": []};
  bool isLoading = false;
  String _currentFilter = "all"; // Filter: "all", "private", "global"
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchSenders();
  }

  void _initializeAnimations() {
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
  }

  Future<void> _fetchSenders() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final res = await ApiService.getMySender(widget.sessionKey);

      if (res['valid'] == true) {
        setState(() {
          connections = res["connections"] ?? {"private": [], "global": []};
        });
      } else {
        _showErrorSnackBar(res['message'] ?? "Failed to fetch senders");
      }
    } catch (e) {
      debugPrint("Error fetching senders: $e");
      _showErrorSnackBar("Failed to fetch senders. Please try again.");
    }

    setState(() => isLoading = false);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani')),
        backgroundColor: Colors.red.shade900.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.red.withOpacity(0.5)),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.black, fontFamily: 'Rajdhani')),
        backgroundColor: primaryColor.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // FITUR BARU: HAPUS SENDER
  Future<void> _deleteSender(String? sessionName) async {
    if (sessionName == null || sessionName.isEmpty) return;

    // Dialog Konfirmasi Hapus
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF111820),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever, color: Colors.red, size: 30),
              ),
              const SizedBox(height: 15),
              const Text(
                "Delete Sender?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani'),
              ),
              const SizedBox(height: 10),
              Text(
                "Are you sure you want to delete \"$sessionName\"?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontFamily: 'Rajdhani'),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    child: const Text("Cancel", style: TextStyle(fontFamily: 'Rajdhani')),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Rajdhani')),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    try {
      final res = await ApiService.deleteSender(widget.sessionKey, sessionName);
      if (res['valid'] == true) {
        if (mounted) _showSuccessSnackBar("Sender deleted successfully");
        _fetchSenders();
      } else {
        if (mounted) _showErrorSnackBar(res['message'] ?? "Failed to delete sender");
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar("An error occurred. Please try again.");
    }
  }

  // FITUR BARU: EDIT SENDER
  void _showEditSenderDialog(Map<String, dynamic> sender) {
    final controller = TextEditingController(text: sender['sessionName'] ?? '');

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF111820),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit, color: primaryColor),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Edit Sender",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Rajdhani',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani'),
                decoration: InputDecoration(
                  hintText: "New session name",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: 'Rajdhani'),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.5),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: primaryColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.edit, color: primaryColor),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    child: const Text("Cancel", style: TextStyle(fontFamily: 'Rajdhani')),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 5,
                      shadowColor: primaryColor.withOpacity(0.5),
                    ),
                    child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Rajdhani')),
                    onPressed: () async {
                      Navigator.pop(context);
                      final newName = controller.text.trim();
                      if (newName.isEmpty) {
                        _showErrorSnackBar("Session name cannot be empty");
                        return;
                      }

                      try {
                        final res = await ApiService.editSender(
                          widget.sessionKey,
                          sender['sessionName'],
                          newName,
                        );

                        if (res['valid'] == true) {
                          if (mounted) _showSuccessSnackBar("Sender updated successfully");
                          _fetchSenders();
                        } else {
                          if (mounted) _showErrorSnackBar("Failed: ${res['message'] ?? 'Unknown error'}");
                        }
                      } catch (e) {
                        if (mounted) _showErrorSnackBar("An error occurred. Please try again.");
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSenderDialog() {
    final controller = TextEditingController();
    String selectedType = 'private';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF111820),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, color: primaryColor),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Add Sender",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Rajdhani',
                          shadows: [Shadow(color: Colors.white, blurRadius: 5)],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani'),
                    decoration: InputDecoration(
                      hintText: "Enter phone number",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: 'Rajdhani'),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.5),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: primaryColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.phone, color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => selectedType = 'private'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: selectedType == 'private' ? primaryColor.withOpacity(0.15) : Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: selectedType == 'private' ? primaryColor : Colors.white.withOpacity(0.1), width: 1.5),
                            ),
                            child: Center(
                              child: Text("PRIVATE", style: TextStyle(color: selectedType == 'private' ? primaryColor : Colors.white.withOpacity(0.4), fontWeight: FontWeight.bold, fontFamily: 'Rajdhani', fontSize: 14)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => selectedType = 'global'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: selectedType == 'global' ? primaryColor.withOpacity(0.15) : Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: selectedType == 'global' ? primaryColor : Colors.white.withOpacity(0.1), width: 1.5),
                            ),
                            child: Center(
                              child: Text("GLOBAL", style: TextStyle(color: selectedType == 'global' ? primaryColor : Colors.white.withOpacity(0.4), fontWeight: FontWeight.bold, fontFamily: 'Rajdhani', fontSize: 14)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: Colors.grey),
                        child: const Text("Cancel", style: TextStyle(fontFamily: 'Rajdhani')),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white, 
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 5,
                          shadowColor: primaryColor.withOpacity(0.5),
                        ),
                        child: const Text("Submit", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Rajdhani')),
                        onPressed: () async {
                          Navigator.pop(context);
                          final number = controller.text.trim();
                          if (number.isEmpty) {
                            _showErrorSnackBar("Phone number cannot be empty");
                            return;
                          }

                          try {
                            final res = await ApiService.getPairing(widget.sessionKey, number, isGlobal: selectedType == 'global');

                            if (res['valid'] == true) {
                              _showPairingCodeDialog(number, res['pairingCode']);
                              _fetchSenders();
                            } else {
                              _showErrorSnackBar("Failed: ${res['message'] ?? 'Unknown error'}");
                            }
                          } catch (e) {
                            debugPrint("Error adding sender: $e");
                            _showErrorSnackBar("An error occurred. Please try again.");
                          }
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPairingCodeDialog(String number, String code) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF111820),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.phonelink_lock, color: primaryColor),
                  ),
                  const SizedBox(width: 12),
                  const Text("Pairing Code", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani', shadows: [Shadow(color: Colors.white, blurRadius: 5)])),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: primaryColor.withOpacity(0.2))),
                child: Column(
                  children: [
                    Text("Number: $number", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontFamily: 'Rajdhani')),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: primaryColor.withOpacity(0.5)), boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 10)]),
                            child: Text(code, textAlign: TextAlign.center, style: const TextStyle(color: accentColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 3, fontFamily: 'Rajdhani', shadows: [Shadow(color: accentColor, blurRadius: 10)])),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text("Enter this code in your WhatsApp app to complete pairing.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Rajdhani')),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor.withOpacity(0.1), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: primaryColor.withOpacity(0.5)))),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text("Copy Code", style: TextStyle(fontFamily: 'Rajdhani')),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        _showSuccessSnackBar("Pairing code copied to clipboard!");
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 5, shadowColor: primaryColor.withOpacity(0.5)),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Rajdhani')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<dynamic> _getFilteredSenders() {
    switch (_currentFilter) {
      case "private": return connections["private"] ?? [];
      case "global": return connections["global"] ?? [];
      default: return [...connections["private"] ?? [], ...connections["global"] ?? []];
    }
  }

  int _getSenderCount() {
    switch (_currentFilter) {
      case "private": return connections["private"]?.length ?? 0;
      case "global": return connections["global"]?.length ?? 0;
      default: return (connections["private"]?.length ?? 0) + (connections["global"]?.length ?? 0);
    }
  }

  int _getTotalSenderCount() {
    return (connections["private"]?.length ?? 0) + (connections["global"]?.length ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final totalSenders = _getTotalSenderCount();

    return Stack(
      children: [
        Container(color: secondaryColor),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text("My Senders (${_getSenderCount()})", style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.white, blurRadius: 2)])),
            actions: [
              IconButton(icon: const Icon(Icons.refresh, color: accentColor), onPressed: _fetchSenders),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: AnimatedBuilder(
            animation: _fabAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _fabAnimation.value,
                child: FloatingActionButton(
                  backgroundColor: primaryColor,
                  elevation: 10,
                  onPressed: () {
                    _fabController.forward().then((_) => _fabController.reverse());
                    _showAddSenderDialog();
                  },
                  child: const Icon(Icons.add, color: Colors.white), 
                ),
              );
            },
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator(color: primaryColor))
              : totalSenders == 0
              ? _buildEmptyState()
              : Column(
            children: [
              _buildFilterChips(),
              Expanded(child: _buildSenderList()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip("All", "all"),
            const SizedBox(width: 8),
            _buildFilterChip("Private", "private"),
            const SizedBox(width: 8),
            _buildFilterChip("Global", "global"),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _currentFilter == filter;
    return FilterChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani')),
      selected: isSelected,
      onSelected: (selected) => setState(() => _currentFilter = filter),
      backgroundColor: Colors.white.withOpacity(0.05),
      selectedColor: primaryColor,
      checkmarkColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? primaryColor : Colors.white.withOpacity(0.2))),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle, boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 20)]),
            child: const Icon(Icons.phone_disabled, color: Colors.white30, size: 60),
          ),
          const SizedBox(height: 20),
          const Text("No senders found", style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Rajdhani', fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Add a sender to get started", style: TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'Rajdhani')),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showAddSenderDialog,
            icon: const Icon(Icons.add, color: Colors.black), 
            label: const Text("Add Sender", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Rajdhani')), 
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 5, shadowColor: primaryColor.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderList() {
    final filteredSenders = _getFilteredSenders();

    if (filteredSenders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.filter_list_off, color: primaryColor.withOpacity(0.5), size: 50),
              const SizedBox(height: 16),
              Text("No senders found in '${_currentFilter.toUpperCase()}' filter", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, fontFamily: 'Rajdhani')),
              const SizedBox(height: 8),
              const Text("Try selecting a different filter or add a new sender.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'Rajdhani')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSenders,
      color: accentColor,
      backgroundColor: const Color(0xFF111820),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredSenders.length,
        itemBuilder: (context, index) {
          final sender = filteredSenders[index];
          final isGlobal = sender['owner'] == "global" || sender['role'] == "high owner";

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF111820).withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isGlobal ? accentColor.withOpacity(0.5) : primaryColor.withOpacity(0.2)),
              boxShadow: isGlobal ? [BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 8, spreadRadius: 1)] : [],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: isGlobal ? accentColor.withOpacity(0.2) : primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.phone, color: isGlobal ? accentColor : primaryColor),
              ),
              title: Text(sender['sessionName'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani', fontSize: 14)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Type: ${sender['type'] ?? 'N/A'}", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontFamily: 'Rajdhani')),
                    Text("Owner: ${isGlobal ? 'Global (VIP)' : sender['owner'] ?? 'N/A'}", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontFamily: 'Rajdhani')),
                  ],
                ),
              ),
              // TRAILING: BADGES + TOMBOL EDIT & HAPUS
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isGlobal)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: accentColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: accentColor.withOpacity(0.3))),
                          child: const Text("VIP", style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani')),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Text("Active", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TOMBOL EDIT
                      GestureDetector(
                        onTap: () => _showEditSenderDialog(sender),
                        child: Icon(Icons.edit_rounded, color: primaryColor.withOpacity(0.8), size: 20),
                      ),
                      const SizedBox(width: 12),
                      // TOMBOL HAPUS
                      GestureDetector(
                        onTap: () => _deleteSender(sender['sessionName']),
                        child: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.8), size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }
}

// API Service
class ApiService {
  static const String _baseUrl = "http://alfa-store-officials.alfamarket2.my.id:3771";

  static Future<Map<String, dynamic>> getMySender(String sessionKey) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/api/whatsapp/mySender?key=$sessionKey"));
      if (response.statusCode == 200) return jsonDecode(response.body);
      else throw Exception('Failed to fetch senders: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching senders: $e');
    }
  }

  static Future<Map<String, dynamic>> getPairing(String sessionKey, String number, {bool isGlobal = false}) async {
    try {
      final url = "$_baseUrl/api/whatsapp/getPairing?key=$sessionKey&number=$number" + (isGlobal ? "&isGlobal=true" : "");
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return jsonDecode(response.body);
      else throw Exception('Failed to get pairing code: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error getting pairing code: $e');
    }
  }

  // API BARU: EDIT SENDER
  static Future<Map<String, dynamic>> editSender(String sessionKey, String? oldName, String newName) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/api/whatsapp/editSender?key=$sessionKey&oldSessionName=$oldName&newSessionName=$newName"));
      if (response.statusCode == 200) return jsonDecode(response.body);
      else throw Exception('Failed to edit sender: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error editing sender: $e');
    }
  }

  // API BARU: DELETE SENDER
  static Future<Map<String, dynamic>> deleteSender(String sessionKey, String? sessionName) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/api/whatsapp/deleteSender?key=$sessionKey&sessionName=$sessionName"));
      if (response.statusCode == 200) return jsonDecode(response.body);
      else throw Exception('Failed to delete sender: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error deleting sender: $e');
    }
  }
}