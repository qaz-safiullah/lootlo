import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/request_service.dart';

class MyRequestsScreen extends StatefulWidget {
  final int initialIndex; // <-- Added to support deep-linking from Profile!

  const MyRequestsScreen({super.key, this.initialIndex = 0});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final RequestService _requestService = RequestService();
  List<dynamic> _sentRequests = [];
  List<dynamic> _receivedRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllRequests();
  }

  Future<void> _fetchAllRequests() async {
    setState(() => _isLoading = true);
    final sent = await _requestService.getMyRequests();
    final received = await _requestService.getReceivedRequests();
    
    if (mounted) {
      setState(() {
        _sentRequests = sent;
        _receivedRequests = received;
        _isLoading = false;
      });
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.error : AppColors.primary));
  }

  Future<void> _proposeTime(int requestId) async {
    DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
    if (pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (pickedTime == null) return;

    final finalDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
    
    setState(() => _isLoading = true);
    bool success = await _requestService.proposeTime(requestId, finalDateTime.toIso8601String());
    if (success) {
      _showToast('Time proposed!');
      _fetchAllRequests();
    } else {
      setState(() => _isLoading = false);
      _showToast('Error proposing time', isError: true);
    }
  }

  Future<void> _executeAction(Future<dynamic> Function() action, String successMsg) async {
    setState(() => _isLoading = true);
    var result = await action();
    
    if (result is bool && result == true) {
      _showToast(successMsg);
    } else if (result is Map && result['success'] == true) {
      _showToast(result['message']);
    } else {
      _showToast('Action failed.', isError: true);
    }
    _fetchAllRequests();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialIndex, // <-- Wires up the deep link
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7F9FA),
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
          elevation: 0,
          title: Text('My Requests', style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black, letterSpacing: -0.5)),
          leading: IconButton(icon: Icon(CupertinoIcons.bars, color: isDark ? Colors.white : Colors.black), onPressed: () => Scaffold.of(context).openDrawer()),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            indicatorColor: AppColors.primary,
            tabs: const [Tab(text: 'Sent (Taking)'), Tab(text: 'Received (Giving)')],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                children: [
                  _buildList(_sentRequests, true, isDark),
                  _buildList(_receivedRequests, false, isDark),
                ],
              ),
      ),
    );
  }

  Widget _buildList(List<dynamic> items, bool isSent, bool isDark) {
    if (items.isEmpty) return _buildEmptyState(isDark);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchAllRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) => isSent ? _buildSentCard(items[index], isDark) : _buildReceivedCard(items[index], isDark),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.doc_text_search, size: 80, color: isDark ? Colors.grey[800] : Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No Active Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildSentCard(dynamic req, bool isDark) {
    String status = req['request_status'];
    String parsedTime = req['proposed_time'] != null ? DateFormat('MMM d, h:mm a').format(DateTime.parse(req['proposed_time']).toLocal()) : 'Waiting...';

    return _buildCardBase(isDark, req['item_title'], req['giver_name'], status,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Proposed Pickup: $parsedTime', style: const TextStyle(fontWeight: FontWeight.bold)),
          if (status == 'accepted') Text('Address: ${req['address']}\nPhone: ${req['giver_phone']}', style: TextStyle(color: isDark ? AppColors.textMutedDark : Colors.grey[700])),
          const SizedBox(height: 16),
          
          if (status == 'pending')
            const Text('Waiting for Giver to propose a time...', style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic)),
            
          if (status == 'proposed')
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () => _executeAction(() => _requestService.acceptProposal(req['request_id']), 'Pickup Accepted!'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Accept Time', style: TextStyle(color: Colors.white)))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: () => _executeAction(() => _requestService.cancelRequest(req['request_id']), 'Request Cancelled'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Decline', style: TextStyle(color: Colors.white)))),
              ],
            ),
            
          if (status == 'accepted')
            req['taker_confirmed'] == 1 
              ? const Text('✅ Waiting for Giver to confirm handover.', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
              : ElevatedButton(
                  onPressed: () => _executeAction(() => _requestService.confirmHandshake(req['request_id']), 'Confirmed!'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45), backgroundColor: AppColors.primary),
                  child: const Text('I Received the Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
    );
  }

  Widget _buildReceivedCard(dynamic req, bool isDark) {
    String status = req['request_status'];
    String parsedTime = req['proposed_time'] != null ? DateFormat('MMM d, h:mm a').format(DateTime.parse(req['proposed_time']).toLocal()) : 'None';

    return _buildCardBase(isDark, req['item_title'], req['requester_name'], status,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (req['requester_score'] != null) Text('Requester Score: ${req['requester_score']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
          if (status == 'accepted') Text('Phone: ${req['requester_phone']}', style: TextStyle(color: isDark ? AppColors.textMutedDark : Colors.grey[700])),
          const SizedBox(height: 16),

          if (status == 'pending')
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () => _proposeTime(req['request_id']), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Propose Time', style: TextStyle(color: Colors.white)))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: () => _executeAction(() => _requestService.cancelRequest(req['request_id']), 'Rejected'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Reject', style: TextStyle(color: Colors.white)))),
              ],
            ),
            
          if (status == 'proposed')
            Text('You proposed: $parsedTime. Waiting for Taker to accept.', style: const TextStyle(color: Colors.orange, fontStyle: FontStyle.italic)),
            
          if (status == 'accepted')
            req['giver_confirmed'] == 1 
              ? const Text('✅ Waiting for Taker to confirm receipt.', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
              : ElevatedButton(
                  onPressed: () => _executeAction(() => _requestService.confirmHandshake(req['request_id']), 'Confirmed!'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45), backgroundColor: AppColors.primary),
                  child: const Text('I Gave the Item Away', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
    );
  }

  Widget _buildCardBase(bool isDark, String title, String personName, String status, {required Widget child}) {
    Color badgeColor = status == 'accepted' ? Colors.green : (status == 'completed' ? Colors.blue : Colors.orange);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(status.toUpperCase(), style: TextStyle(fontSize: 11, color: badgeColor, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 4),
          Text('With: $personName', style: TextStyle(color: isDark ? AppColors.textMutedDark : Colors.grey[600])),
          Divider(height: 24, color: isDark ? AppColors.borderDark : AppColors.borderLight),
          child, 
        ],
      ),
    );
  }
}